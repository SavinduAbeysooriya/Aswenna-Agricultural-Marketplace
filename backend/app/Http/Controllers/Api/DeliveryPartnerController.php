<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class DeliveryPartnerController extends Controller
{
    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Update live location
    // POST /api/delivery/location
    // ─────────────────────────────────────────────────────────────────────────
    public function updateLocation(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        DB::table('users')->where('id', $user->id)->update([
            'latitude'   => $request->input('latitude'),
            'longitude'  => $request->input('longitude'),
            'updated_at' => now(),
        ]);

        return response()->json(['success' => true, 'message' => 'Location updated.']);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Get nearby open delivery requests
    // GET /api/delivery/nearby-orders
    // ─────────────────────────────────────────────────────────────────────────
    public function getNearbyOrders(Request $request)
    {
        $user = $request->user();

        // Get all open delivery requests with order details
        $requests = DB::table('order_delivery_requests as odr')
            ->join('customer_orders as co', 'odr.order_id', '=', 'co.id')
            ->join('users as cu', 'co.customer_id', '=', 'cu.id')
            ->where('odr.request_status', 'open')
            ->whereNotExists(function ($query) use ($user) {
                // Exclude orders that this partner already rejected or has an assignment for
                $query->select(DB::raw(1))
                    ->from('order_delivery_requests_assigned_partners as ap')
                    ->whereColumn('ap.delivery_request_id', 'odr.id')
                    ->where('ap.delivery_partner_id', $user->id);
            })
            ->select(
                'odr.id as delivery_request_id',
                'odr.order_id',
                'odr.pickup_address',
                'odr.pickup_latitude',
                'odr.pickup_longitude',
                'odr.delivery_address',
                'odr.delivery_latitude',
                'odr.delivery_longitude',
                'odr.delivery_fee',
                'odr.system_commission',
                'odr.estimated_distance_km',
                'odr.expires_at',
                'co.order_number',
                'co.subtotal_amount',
                'co.total_amount',
                'co.order_status',
                'cu.full_name as customer_name'
            )
            ->orderBy('odr.created_at', 'desc')
            ->get();

        // For each request, get the pickup points (distinct retailer shops)
        $enriched = [];
        foreach ($requests as $req) {
            $pickupPoints = DB::table('order_items as oi')
                ->join('users as r', 'oi.retailer_id', '=', 'r.id')
                ->where('oi.order_id', $req->order_id)
                ->select(
                    'r.id as retailer_id',
                    'r.full_name as retailer_name',
                    'r.latitude as pickup_lat',
                    'r.longitude as pickup_lng',
                    DB::raw('SUM(oi.final_price) as retailer_total')
                )
                ->groupBy('r.id', 'r.full_name', 'r.latitude', 'r.longitude')
                ->get();

            $item = (array) $req;
            // Net delivery payout = delivery_fee - 5% commission
            $item['partner_payout'] = round((float)$req->delivery_fee * 0.95, 2);
            $item['pickup_points']  = $pickupPoints;
            $enriched[] = $item;
        }

        return response()->json(['success' => true, 'delivery_requests' => $enriched]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Accept a delivery request
    // POST /api/delivery/requests/{requestId}/accept
    // ─────────────────────────────────────────────────────────────────────────
    public function acceptDeliveryRequest(Request $request, $requestId)
    {
        $user = $request->user();

        DB::beginTransaction();
        try {
            $deliveryRequest = DB::table('order_delivery_requests')
                ->where('id', $requestId)
                ->where('request_status', 'open')
                ->first();

            if (!$deliveryRequest) {
                DB::rollBack();
                return response()->json(['success' => false, 'message' => 'Delivery request not found or no longer available.'], 404);
            }

            // Check partner hasn't already responded
            $existingAssignment = DB::table('order_delivery_requests_assigned_partners')
                ->where('delivery_request_id', $requestId)
                ->where('delivery_partner_id', $user->id)
                ->first();

            if ($existingAssignment) {
                DB::rollBack();
                return response()->json(['success' => false, 'message' => 'You have already responded to this request.'], 409);
            }

            // Create assignment record
            DB::table('order_delivery_requests_assigned_partners')->insert([
                'delivery_request_id'  => $requestId,
                'delivery_partner_id'  => $user->id,
                'status'               => 'accepted',
                'requested_at'         => now(),
                'accepted_at'          => now(),
                'created_at'           => now(),
                'updated_at'           => now(),
            ]);

            // Update delivery request status to 'assigned'
            DB::table('order_delivery_requests')
                ->where('id', $requestId)
                ->update(['request_status' => 'assigned', 'updated_at' => now()]);

            // Assign delivery partner to the customer order
            DB::table('customer_orders')
                ->where('id', $deliveryRequest->order_id)
                ->update([
                    'delivery_partner_id' => $user->id,
                    'order_status'        => 'delivery_partner_assigned',
                    'updated_at'          => now(),
                ]);

            // Record status history
            DB::table('order_status_histories')->insert([
                'order_id'          => $deliveryRequest->order_id,
                'changed_by_user_id'=> $user->id,
                'old_status'        => 'confirmed',
                'new_status'        => 'delivery_partner_assigned',
                'status_note'       => 'Delivery partner ' . $user->full_name . ' accepted the delivery.',
                'changed_at'        => now(),
                'created_at'        => now(),
                'updated_at'        => now(),
            ]);

            // Insert initial tracking entry
            $partnerUser = DB::table('users')->where('id', $user->id)->first();
            DB::table('order_delivery_tracking')->insert([
                'order_id'           => $deliveryRequest->order_id,
                'delivery_partner_id'=> $user->id,
                'status'             => 'assigned',
                'current_latitude'   => $partnerUser->latitude ?? $deliveryRequest->pickup_latitude,
                'current_longitude'  => $partnerUser->longitude ?? $deliveryRequest->pickup_longitude,
                'tracking_note'      => 'Delivery partner assigned and heading to first pickup.',
                'tracked_at'         => now(),
                'created_at'         => now(),
                'updated_at'         => now(),
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Delivery accepted successfully. Head to the first pickup point.',
                'order_id'=> $deliveryRequest->order_id,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Failed to accept delivery: ' . $e->getMessage()], 500);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Reject a delivery request
    // POST /api/delivery/requests/{requestId}/reject
    // ─────────────────────────────────────────────────────────────────────────
    public function rejectDeliveryRequest(Request $request, $requestId)
    {
        $user = $request->user();

        $deliveryRequest = DB::table('order_delivery_requests')
            ->where('id', $requestId)
            ->first();

        if (!$deliveryRequest) {
            return response()->json(['success' => false, 'message' => 'Delivery request not found.'], 404);
        }

        DB::table('order_delivery_requests_assigned_partners')->insert([
            'delivery_request_id'  => $requestId,
            'delivery_partner_id'  => $user->id,
            'status'               => 'rejected',
            'requested_at'         => now(),
            'rejected_at'          => now(),
            'rejection_reason'     => $request->input('reason', 'No reason provided'),
            'created_at'           => now(),
            'updated_at'           => now(),
        ]);

        return response()->json(['success' => true, 'message' => 'Delivery request rejected.']);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Get my active assigned deliveries
    // GET /api/delivery/my-deliveries
    // ─────────────────────────────────────────────────────────────────────────
    public function getMyDeliveries(Request $request)
    {
        $user = $request->user();

        $orders = DB::table('customer_orders as co')
            ->join('users as cu', 'co.customer_id', '=', 'cu.id')
            ->where('co.delivery_partner_id', $user->id)
            ->whereIn('co.order_status', ['delivery_partner_assigned', 'delivery_requested', 'picked_up', 'on_the_way', 'confirmed'])
            ->select(
                'co.id as order_id',
                'co.order_number',
                'co.delivery_address',
                'co.delivery_latitude',
                'co.delivery_longitude',
                'co.delivery_fee',
                'co.order_status',
                'co.subtotal_amount',
                'co.total_amount',
                'cu.full_name as customer_name',
                'cu.phone_number as customer_phone'
            )
            ->orderBy('co.updated_at', 'desc')
            ->get();

        $enriched = [];
        foreach ($orders as $order) {
            $pickupPoints = DB::table('order_items as oi')
                ->join('users as r', 'oi.retailer_id', '=', 'r.id')
                ->where('oi.order_id', $order->order_id)
                ->select(
                    'r.id as retailer_id',
                    'r.full_name as shop_name',
                    'r.latitude as pickup_lat',
                    'r.longitude as pickup_lng',
                    'r.address as shop_address',
                    DB::raw('SUM(oi.final_price) as subtotal'),
                    DB::raw('COUNT(oi.id) as item_count')
                )
                ->groupBy('r.id', 'r.full_name', 'r.latitude', 'r.longitude', 'r.address')
                ->get();

            // Latest tracking for this order
            $latestTracking = DB::table('order_delivery_tracking')
                ->where('order_id', $order->order_id)
                ->where('delivery_partner_id', $user->id)
                ->orderBy('tracked_at', 'desc')
                ->first();

            $item = (array) $order;
            $item['pickup_points']   = $pickupPoints;
            $item['latest_tracking'] = $latestTracking;
            $item['partner_payout']  = round((float)$order->delivery_fee * 0.95, 2);
            $enriched[] = $item;
        }

        return response()->json(['success' => true, 'deliveries' => $enriched]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Update delivery status + live location (one pickup at a time)
    // POST /api/delivery/orders/{orderId}/update-status
    // ─────────────────────────────────────────────────────────────────────────
    public function updateDeliveryStatus(Request $request, $orderId)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'status'    => 'required|in:heading_to_pickup,arrived_pickup,picked_up,on_the_way,arrived_destination,delivered',
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'note'      => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $order = DB::table('customer_orders')
            ->where('id', $orderId)
            ->where('delivery_partner_id', $user->id)
            ->first();

        if (!$order) {
            return response()->json(['success' => false, 'message' => 'Order not found or not assigned to you.'], 404);
        }

        $newStatus  = $request->input('status');
        $lat        = $request->input('latitude');
        $lng        = $request->input('longitude');
        $note       = $request->input('note', '');

        DB::beginTransaction();
        try {
            // Update partner live location
            DB::table('users')->where('id', $user->id)->update([
                'latitude'   => $lat,
                'longitude'  => $lng,
                'updated_at' => now(),
            ]);

            // Insert tracking record
            DB::table('order_delivery_tracking')->insert([
                'order_id'            => $orderId,
                'delivery_partner_id' => $user->id,
                'status'              => $newStatus,
                'current_latitude'    => $lat,
                'current_longitude'   => $lng,
                'tracking_note'       => $note ?: $this->getStatusNote($newStatus),
                'tracked_at'          => now(),
                'created_at'          => now(),
                'updated_at'          => now(),
            ]);

            // Update order status if delivered
            $orderUpdate = ['updated_at' => now()];
            if ($newStatus === 'delivered') {
                $orderUpdate['order_status'] = 'delivered';
                $orderUpdate['delivered_at'] = now();

                // Mark delivery request as completed
                DB::table('order_delivery_requests')
                    ->where('order_id', $orderId)
                    ->update(['request_status' => 'completed', 'updated_at' => now()]);

                DB::table('order_delivery_requests_assigned_partners')
                    ->where('delivery_partner_id', $user->id)
                    ->whereIn('delivery_request_id', function ($q) use ($orderId) {
                        $q->select('id')->from('order_delivery_requests')->where('order_id', $orderId);
                    })
                    ->update(['status' => 'completed', 'updated_at' => now()]);

                // ── Wallet credit for delivery partner ───────────────────────
                $deliveryFee    = (float)($order->delivery_fee ?? 0);
                $commission     = round($deliveryFee * 0.05, 2);   // 5% platform fee
                $partnerPayout  = round($deliveryFee - $commission, 2);

                // Upsert wallet row (create if not exists)
                $wallet = DB::table('user_wallets')->where('user_id', $user->id)->first();
                if (!$wallet) {
                    DB::table('user_wallets')->insert([
                        'user_id'           => $user->id,
                        'available_balance' => 0,
                        'pending_balance'   => 0,
                        'total_earned'      => 0,
                        'total_withdrawn'   => 0,
                        'last_updated_at'   => now(),
                        'created_at'        => now(),
                        'updated_at'        => now(),
                    ]);
                    $wallet = DB::table('user_wallets')->where('user_id', $user->id)->first();
                }

                $balanceBefore = (float)$wallet->available_balance;
                $balanceAfter  = round($balanceBefore + $partnerPayout, 2);

                // Credit partner payout
                DB::table('user_wallets')->where('user_id', $user->id)->update([
                    'available_balance' => $balanceAfter,
                    'total_earned'      => DB::raw('total_earned + ' . $partnerPayout),
                    'last_updated_at'   => now(),
                    'updated_at'        => now(),
                ]);

                // Record earning transaction
                DB::table('wallet_transactions')->insert([
                    'user_id'          => $user->id,
                    'amount'           => $partnerPayout,
                    'balance_before'   => $balanceBefore,
                    'balance_after'    => $balanceAfter,
                    'transaction_type' => 'other',
                    'description'      => 'Delivery payout for Order #' . $order->order_number . ' (Fee: LKR ' . number_format($deliveryFee, 2) . ' – 5% commission LKR ' . number_format($commission, 2) . ')',
                    'status'           => 'completed',
                    'record_created_at'=> now(),
                    'created_at'       => now(),
                    'updated_at'       => now(),
                ]);

                // Record commission deduction transaction (for audit)
                DB::table('wallet_transactions')->insert([
                    'user_id'          => $user->id,
                    'amount'           => -$commission,
                    'balance_before'   => $balanceBefore,
                    'balance_after'    => $balanceAfter,
                    'transaction_type' => 'commission',
                    'description'      => 'Platform 5% commission for Order #' . $order->order_number,
                    'status'           => 'completed',
                    'record_created_at'=> now(),
                    'created_at'       => now(),
                    'updated_at'       => now(),
                ]);
                // ────────────────────────────────────────────────────────────

            } elseif ($newStatus === 'picked_up') {
                $orderUpdate['order_status'] = 'picked_up';
                $orderUpdate['picked_up_at'] = now();
            }

            DB::table('customer_orders')->where('id', $orderId)->update($orderUpdate);

            // Record in status histories
            DB::table('order_status_histories')->insert([
                'order_id'           => $orderId,
                'changed_by_user_id' => $user->id,
                'old_status'         => $order->order_status,
                'new_status'         => $newStatus === 'delivered' ? 'delivered' : $order->order_status,
                'status_note'        => $note ?: $this->getStatusNote($newStatus),
                'changed_at'         => now(),
                'created_at'         => now(),
                'updated_at'         => now(),
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Status updated to: ' . strtoupper($newStatus),
                'status'  => $newStatus,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Failed to update status: ' . $e->getMessage()], 500);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CUSTOMER: Track order - get partner live location + full tracking history
    // GET /api/customer/orders/{orderId}/track
    // ─────────────────────────────────────────────────────────────────────────
    public function trackOrder(Request $request, $orderId)
    {
        $user = $request->user();

        $order = DB::table('customer_orders as co')
            ->leftJoin('users as dp', 'co.delivery_partner_id', '=', 'dp.id')
            ->where('co.id', $orderId)
            ->where('co.customer_id', $user->id)
            ->select(
                'co.id as order_id',
                'co.order_number',
                'co.order_status',
                'co.delivery_address',
                'co.delivery_latitude',
                'co.delivery_longitude',
                'co.delivery_fee',
                'co.delivery_partner_id',
                'dp.full_name as partner_name',
                'dp.phone_number as partner_phone',
                'dp.latitude as partner_lat',
                'dp.longitude as partner_lng',
                'dp.updated_at as partner_location_updated_at'
            )
            ->first();

        if (!$order) {
            return response()->json(['success' => false, 'message' => 'Order not found.'], 404);
        }

        // Get tracking history
        $trackingHistory = DB::table('order_delivery_tracking')
            ->where('order_id', $orderId)
            ->orderBy('tracked_at', 'asc')
            ->get();

        // Latest tracking entry
        $latestTracking = $trackingHistory->last();

        // Get pickup points
        $pickupPoints = DB::table('order_items as oi')
            ->join('users as r', 'oi.retailer_id', '=', 'r.id')
            ->where('oi.order_id', $orderId)
            ->select(
                'r.id as retailer_id',
                'r.full_name as shop_name',
                'r.latitude as lat',
                'r.longitude as lng',
                'r.address as shop_address'
            )
            ->groupBy('r.id', 'r.full_name', 'r.latitude', 'r.longitude', 'r.address')
            ->get();

        return response()->json([
            'success'          => true,
            'order'            => $order,
            'tracking_history' => $trackingHistory,
            'latest_tracking'  => $latestTracking,
            'pickup_points'    => $pickupPoints,
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Get full earnings, wallet balance & transaction history
    // GET /api/delivery/earnings
    // ─────────────────────────────────────────────────────────────────────────
    public function getEarnings(Request $request)
    {
        $user = $request->user();

        // Wallet summary
        $wallet = DB::table('user_wallets')->where('user_id', $user->id)->first();

        // All transactions (credits + commissions)
        $transactions = DB::table('wallet_transactions')
            ->where('user_id', $user->id)
            ->orderBy('id', 'desc')
            ->limit(100)
            ->get();

        // Completed deliveries with order details
        $completedOrders = DB::table('customer_orders as co')
            ->join('users as cu', 'co.customer_id', '=', 'cu.id')
            ->where('co.delivery_partner_id', $user->id)
            ->where('co.order_status', 'delivered')
            ->select(
                'co.id as order_id',
                'co.order_number',
                'co.delivery_fee',
                'co.delivered_at',
                'co.total_amount',
                'cu.full_name as customer_name'
            )
            ->orderBy('co.delivered_at', 'desc')
            ->limit(50)
            ->get()
            ->map(function ($order) {
                $fee        = (float) $order->delivery_fee;
                $commission = round($fee * 0.05, 2);
                $payout     = round($fee - $commission, 2);
                return array_merge((array)$order, [
                    'commission'    => $commission,
                    'payout'        => $payout,
                    'commission_pct'=> 5,
                ]);
            });

        // Summary stats
        $totalEarned     = (float)($wallet->total_earned ?? 0);
        $totalCommission = $transactions->where('transaction_type', 'commission')->sum(function ($t) {
            return abs((float)$t->amount);
        });
        $totalWithdrawn  = (float)($wallet->total_withdrawn ?? 0);
        $completedCount  = $completedOrders->count();

        return response()->json([
            'success'              => true,
            'wallet'               => $wallet,
            'transactions'         => $transactions,
            'completed_orders'     => $completedOrders,
            'completed_deliveries' => $completedCount,
            'summary'              => [
                'total_gross_earned'    => round($totalEarned + $totalCommission, 2),
                'total_commission_paid' => round($totalCommission, 2),
                'total_net_earned'      => round($totalEarned, 2),
                'available_balance'     => (float)($wallet->available_balance ?? 0),
                'total_withdrawn'       => $totalWithdrawn,
            ],
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ADMIN/INTERNAL: Create delivery request when order is confirmed & paid
    // Called internally from PaymentController after retail order payment
    // POST /api/delivery/create-request (internal helper - protected)
    // ─────────────────────────────────────────────────────────────────────────
    public static function createDeliveryRequestForOrder($orderId)
    {
        $order = DB::table('customer_orders')->where('id', $orderId)->first();
        if (!$order) return false;

        // Check not already created
        $existing = DB::table('order_delivery_requests')->where('order_id', $orderId)->first();
        if ($existing) return true;

        // Build pickup address from first retailer in order
        $firstRetailer = DB::table('order_items as oi')
            ->join('users as r', 'oi.retailer_id', '=', 'r.id')
            ->where('oi.order_id', $orderId)
            ->select('r.full_name', 'r.address', 'r.latitude', 'r.longitude')
            ->first();

        $pickupAddress = $firstRetailer ? ($firstRetailer->address ?? $firstRetailer->full_name . ' Shop') : 'Retailer Location';
        $pickupLat     = $firstRetailer->latitude ?? null;
        $pickupLng     = $firstRetailer->longitude ?? null;

        DB::table('order_delivery_requests')->insert([
            'order_id'               => $orderId,
            'request_status'         => 'open',
            'pickup_address'         => $pickupAddress,
            'pickup_latitude'        => $pickupLat,
            'pickup_longitude'       => $pickupLng,
            'delivery_address'       => $order->delivery_address,
            'delivery_latitude'      => $order->delivery_latitude,
            'delivery_longitude'     => $order->delivery_longitude,
            'delivery_fee'           => $order->delivery_fee,
            'system_commission'      => round((float)$order->delivery_fee * 0.05, 2),
            'estimated_distance_km'  => null,
            'expires_at'             => now()->addHours(2),
            'created_at'             => now(),
            'updated_at'             => now(),
        ]);

        return true;
    }

    private function getStatusNote(string $status): string
    {
        $notes = [
            'heading_to_pickup'    => 'Delivery partner is heading to pickup location.',
            'arrived_pickup'       => 'Delivery partner has arrived at pickup location.',
            'picked_up'            => 'Order has been picked up.',
            'on_the_way'           => 'Order is on the way to the delivery destination.',
            'arrived_destination'  => 'Delivery partner has arrived at the destination.',
            'delivered'            => 'Order has been delivered successfully!',
        ];
        return $notes[$status] ?? 'Status updated.';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 🧪 DEBUG / TESTING: Promote a real paid order to an open delivery request
    // POST /api/delivery/debug-create-test-request
    // Finds an existing paid customer_order that has no delivery request yet
    // and marks it as open so the delivery dashboard can see it.
    // No fake data — uses real orders from the DB.
    // ─────────────────────────────────────────────────────────────────────────
    public function debugCreateTestRequest(Request $request)
    {
        // 1. Find any paid order that does NOT already have a delivery request
        $order = DB::table('customer_orders as co')
            ->whereIn('co.payment_status', ['paid', 'completed'])
            ->whereNotExists(function ($q) {
                $q->select(DB::raw(1))
                    ->from('order_delivery_requests as odr')
                    ->whereColumn('odr.order_id', 'co.id');
            })
            ->orderBy('co.created_at', 'desc')
            ->first();

        if (!$order) {
            // 2. Fallback: any confirmed order without a delivery request
            $order = DB::table('customer_orders as co')
                ->whereIn('co.order_status', ['confirmed', 'pending'])
                ->whereNotExists(function ($q) {
                    $q->select(DB::raw(1))
                        ->from('order_delivery_requests as odr')
                        ->whereColumn('odr.order_id', 'co.id');
                })
                ->orderBy('co.created_at', 'desc')
                ->first();
        }

        if (!$order) {
            // 3. Last resort: use any order and reset its delivery request to 'open'
            $existingRequest = DB::table('order_delivery_requests')
                ->whereIn('request_status', ['open', 'assigned', 'completed'])
                ->orderBy('created_at', 'desc')
                ->first();

            if ($existingRequest) {
                DB::table('order_delivery_requests')
                    ->where('id', $existingRequest->id)
                    ->update([
                        'request_status' => 'open',
                        'expires_at'     => now()->addHours(2),
                        'updated_at'     => now(),
                    ]);

                // Also remove prior assignments so partner can accept
                DB::table('order_delivery_requests_assigned_partners')
                    ->where('delivery_request_id', $existingRequest->id)
                    ->delete();

                // Reset the order status to confirmed
                DB::table('customer_orders')
                    ->where('id', $existingRequest->order_id)
                    ->update([
                        'order_status'        => 'confirmed',
                        'delivery_partner_id' => null,
                        'updated_at'          => now(),
                    ]);

                return response()->json([
                    'success' => true,
                    'message' => '♻️ Recycled existing delivery request #' . $existingRequest->order_id . ' — reset to OPEN. Refresh to see it.',
                    'order_id'=> $existingRequest->order_id,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'No paid or confirmed orders found. Place an order as a customer first, then try again.',
            ], 422);
        }

        // Get first retailer from order items
        $firstRetailer = DB::table('order_items as oi')
            ->join('users as r', 'oi.retailer_id', '=', 'r.id')
            ->where('oi.order_id', $order->id)
            ->select(
                'r.full_name',
                'r.address',
                'r.latitude',
                'r.longitude'
            )
            ->first();

        $pickupAddress = $firstRetailer?->address ?? ($firstRetailer?->full_name . ' Shop') ?? 'Retailer Location';
        $pickupLat     = $firstRetailer?->latitude;
        $pickupLng     = $firstRetailer?->longitude;

        // Use order delivery_fee if set, otherwise calculate a default
        $deliveryFee = (float)($order->delivery_fee ?? 0);
        if ($deliveryFee <= 0) {
            $deliveryFee = 350.00; // sensible default
        }

        $commission = round($deliveryFee * 0.05, 2);

        DB::table('order_delivery_requests')->insert([
            'order_id'              => $order->id,
            'request_status'        => 'open',
            'pickup_address'        => $pickupAddress,
            'pickup_latitude'       => $pickupLat,
            'pickup_longitude'      => $pickupLng,
            'delivery_address'      => $order->delivery_address ?? 'Customer Location',
            'delivery_latitude'     => $order->delivery_latitude,
            'delivery_longitude'    => $order->delivery_longitude,
            'delivery_fee'          => $deliveryFee,
            'system_commission'     => $commission,
            'estimated_distance_km' => $order->delivery_fee > 0
                ? round($deliveryFee / 100, 1) // rough reverse calc
                : null,
            'expires_at'            => now()->addHours(2),
            'created_at'            => now(),
            'updated_at'            => now(),
        ]);

        // Ensure order is in 'confirmed' status
        DB::table('customer_orders')
            ->where('id', $order->id)
            ->update(['order_status' => 'confirmed', 'updated_at' => now()]);

        $customer = DB::table('users')->where('id', $order->customer_id)->first();

        return response()->json([
            'success'        => true,
            'message'        => '✅ Order #' . $order->order_number . ' promoted to open delivery request. Refresh to see it.',
            'order_id'       => $order->id,
            'order_number'   => $order->order_number,
            'delivery_fee'   => $deliveryFee,
            'partner_payout' => round($deliveryFee * 0.95, 2),
            'customer'       => $customer?->full_name ?? 'Customer',
            'retailer'       => $firstRetailer?->full_name ?? 'Retailer',
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Request a payout withdrawal
    // POST /api/delivery/withdraw
    // ─────────────────────────────────────────────────────────────────────────
    public function requestWithdrawal(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'amount'                   => 'required|numeric|min:100',
            'bank_name'                => 'required|string|max:255',
            'bank_branch'              => 'required|string|max:255',
            'bank_account_holder_name' => 'required|string|max:255',
            'bank_account_number'      => 'required|string|max:255',
        ], [
            'amount.min' => 'The minimum withdrawal amount is LKR 100.00.',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors(), 'message' => $validator->errors()->first()], 422);
        }

        $amount = round((float)$request->input('amount'), 2);

        DB::beginTransaction();
        try {
            // Lock the wallet row for update to prevent race conditions
            $wallet = DB::table('user_wallets')
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->first();

            if (!$wallet || (float)$wallet->available_balance < $amount) {
                DB::rollBack();
                return response()->json(['success' => false, 'message' => 'Insufficient wallet balance for this withdrawal.'], 400);
            }

            $balanceBefore = (float)$wallet->available_balance;
            $balanceAfter  = round($balanceBefore - $amount, 2);

            // 1. Create the withdraw request
            $requestId = DB::table('withdraw_requests')->insertGetId([
                'user_id'                  => $user->id,
                'request_amount'           => $amount,
                'bank_name'                => $request->input('bank_name'),
                'bank_branch'              => $request->input('bank_branch'),
                'bank_account_holder_name' => $request->input('bank_account_holder_name'),
                'bank_account_number'      => $request->input('bank_account_number'),
                'status'                   => 'pending',
                'requested_ip'             => $request->ip(),
                'created_at'               => now(),
                'updated_at'               => now(),
            ]);

            // 2. Hold the amount in wallet (deduct from available, add to pending)
            DB::table('user_wallets')->where('user_id', $user->id)->update([
                'available_balance' => $balanceAfter,
                'pending_balance'   => DB::raw('pending_balance + ' . $amount),
                'last_updated_at'   => now(),
                'updated_at'        => now(),
            ]);

            // 3. Record pending withdrawal transaction
            DB::table('wallet_transactions')->insert([
                'user_id'           => $user->id,
                'amount'            => -$amount,
                'balance_before'    => $balanceBefore,
                'balance_after'     => $balanceAfter,
                'transaction_type'  => 'withdrawal',
                'description'       => 'Withdrawal request to ' . $request->input('bank_name') . ' (Acc: ' . $request->input('bank_account_number') . ')',
                'status'            => 'pending',
                'record_created_at' => now(),
                'created_at'        => now(),
                'updated_at'        => now(),
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Withdrawal request submitted successfully.',
                'withdraw_request_id' => $requestId,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Failed to process withdrawal request: ' . $e->getMessage()], 500);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARTNER: Get past and pending withdrawal requests
    // GET /api/delivery/withdrawals
    // ─────────────────────────────────────────────────────────────────────────
    public function getMyWithdrawals(Request $request)
    {
        $user = $request->user();

        $withdrawals = DB::table('withdraw_requests')
            ->where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->limit(100)
            ->get();

        return response()->json([
            'success'     => true,
            'withdrawals' => $withdrawals,
        ]);
    }
}
