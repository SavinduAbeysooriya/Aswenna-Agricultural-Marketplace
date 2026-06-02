<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ConfirmedBid;
use App\Models\ConfirmedBidPayment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Exception;

class PaymentController extends Controller
{
    // PayHere Sandbox credentials — replace with live keys in production
    private string $merchantId   = '1228822';
    private string $merchantSecret = 'MTk3MjI5NTQ1NTk4NTM3NjIwMDc4NDk0MjE4MjA0NzU5NzY5NA==';
    private bool   $sandbox      = true;

    /**
     * POST /api/buyer/confirmed-bids/{confirmedBidId}/initiate-payment
     * Returns PayHere payment parameters including a signed hash.
     */
    public function initiatePayment(Request $request, $confirmedBidId)
    {
        $user = $request->user();

        $confirmedBid = DB::table('confirmed_bids')
            ->leftJoin('harvest_bids', 'confirmed_bids.bid_id', '=', 'harvest_bids.id')
            ->leftJoin('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
            ->leftJoin('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->leftJoin('users as farmers', 'confirmed_bids.farmer_id', '=', 'farmers.id')
            ->where('confirmed_bids.id', $confirmedBidId)
            ->where('confirmed_bids.buyer_id', $user->id)
            ->select(
                'confirmed_bids.*',
                'harvest_bids.bid_amount_per_unit',
                'harvest_bids.bid_quantity_unit',
                'harvest_listings.unit',
                'crops.cropname',
                'farmers.full_name as farmer_name'
            )
            ->first();

        if (!$confirmedBid) {
            return response()->json(['success' => false, 'message' => 'Confirmed bid not found.'], 404);
        }

        if ($confirmedBid->payment_status === 'paid') {
            return response()->json(['success' => false, 'message' => 'This order has already been paid.'], 400);
        }

        $orderId       = 'ASWENNA-' . $confirmedBidId . '-' . time();
        $amount        = number_format((float)$confirmedBid->total_amount, 2, '.', '');
        $currency      = 'LKR';
        $itemName      = $confirmedBid->cropname . ' (' . $confirmedBid->bid_quantity_unit . ' ' . $confirmedBid->unit . ')';
        $returnUrl     = url('/api/payment/return');
        $cancelUrl     = url('/api/payment/cancel');
        $notifyUrl     = url('/api/payment/notify');

        // Generate hash per PayHere spec: MD5(merchant_id + order_id + amount + currency + MD5(merchant_secret))
        $hashedSecret  = strtoupper(md5($this->merchantSecret));
        $hash          = strtoupper(md5(
            $this->merchantId . $orderId . $amount . $currency . $hashedSecret
        ));

        $paymentParams = [
            'sandbox'       => $this->sandbox,
            'merchant_id'   => $this->merchantId,
            'return_url'    => $returnUrl,
            'cancel_url'    => $cancelUrl,
            'notify_url'    => $notifyUrl,
            'order_id'      => $orderId,
            'items'         => $itemName,
            'amount'        => $amount,
            'currency'      => $currency,
            'first_name'    => $user->full_name,
            'last_name'     => '',
            'email'         => $user->email ?? '',
            'phone'         => $user->phone_number ?? '',
            'address'       => $user->address ?? 'Sri Lanka',
            'city'          => $user->city ?? 'Colombo',
            'country'       => 'Sri Lanka',
            'hash'          => $hash,
            'confirmed_bid_id' => $confirmedBidId,
        ];

        return response()->json([
            'success'        => true,
            'payment_params' => $paymentParams,
        ], 200);
    }

    /**
     * POST /api/payment/notify  (unauthenticated - called by PayHere server)
     * Verifies PayHere notification and updates payment status.
     */
    public function notifyPayment(Request $request)
    {
        $merchantId    = $request->merchant_id;
        $orderId       = $request->order_id;
        $paymentId     = $request->payment_id;
        $payheStatus   = $request->status_code;
        $currency      = $request->currency;
        $amount        = $request->payhere_amount;
        $payhereMd5sig = $request->md5sig;

        // Verify hash
        $hashedSecret = strtoupper(md5($this->merchantSecret));
        $localMd5Sig  = strtoupper(md5($merchantId . $orderId . $amount . $currency . $payheStatus . $hashedSecret));

        if ($localMd5Sig !== $payhereMd5sig) {
            return response('INVALID_HASH', 400);
        }

        if ($payheStatus == 2) { // 2 = success
            // Extract confirmedBidId from orderId (ASWENNA-{id}-{timestamp})
            preg_match('/ASWENNA-(\d+)-/', $orderId, $matches);
            $confirmedBidId = $matches[1] ?? null;

            if ($confirmedBidId) {
                DB::beginTransaction();
                try {
                    $confirmedBid = ConfirmedBid::find($confirmedBidId);
                    if ($confirmedBid && $confirmedBid->payment_status === 'unpaid') {
                        $confirmedBid->update(['payment_status' => 'paid']);

                        // Record payment
                        $totalAmount       = (float)$confirmedBid->total_amount;
                        $commission        = round($totalAmount * 0.05, 2); // 5% platform commission
                        $farmerAmount      = round($totalAmount - $commission, 2);

                        DB::table('confirmed_bids_payments')->insert([
                            'buyer_id'          => $confirmedBid->buyer_id,
                            'farmer_id'         => $confirmedBid->farmer_id,
                            'confirmed_bid_id'  => $confirmedBid->id,
                            'total_amount'      => $totalAmount,
                            'system_commission' => $commission,
                            'farmer_amount'     => $farmerAmount,
                            'payment_id'        => $paymentId,
                            'date_and_time'     => Carbon::now(),
                            'payment_status'    => 'paid',
                            'created_at'        => now(),
                            'updated_at'        => now(),
                        ]);
                    }
                    DB::commit();
                } catch (Exception $e) {
                    DB::rollBack();
                }
            }
        }

        return response('OK', 200);
    }
}
