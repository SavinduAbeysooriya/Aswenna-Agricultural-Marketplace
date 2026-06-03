<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomerOrder;
use App\Models\OrderItem;
use App\Models\RetailerProduct;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class CustomerOrderController extends Controller
{
    /**
     * GET /api/customer/orders
     * List all orders for the authenticated customer.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $orders = CustomerOrder::with(['retailer', 'items.product.crop'])
            ->where('customer_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'orders' => $orders,
        ], 200);
    }

    /**
     * GET /api/customer/orders/{id}
     * Get order details.
     */
    public function show($id, Request $request)
    {
        $user = $request->user();
        $order = CustomerOrder::with(['retailer', 'items.product.crop', 'deliveryPartner'])
            ->where('id', $id)
            ->where('customer_id', $user->id)
            ->first();

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'order' => $order,
        ], 200);
    }

    /**
     * POST /api/customer/orders
     * Checkout checkout: place orders, automatically split orders by retailer.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'delivery_address' => 'required|string|max:500',
            'delivery_latitude' => 'nullable|numeric|between:-90,90',
            'delivery_longitude' => 'nullable|numeric|between:-180,180',
            'customer_note' => 'nullable|string',
            'cart_items' => 'required|array|min:1',
            'cart_items.*.retailer_product_id' => 'required|exists:retailer_products,id',
            'cart_items.*.quantity' => 'required|numeric|min:0.01',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $cartReqItems = $request->input('cart_items');
        $deliveryAddress = $request->input('delivery_address');
        $custLat = $request->input('delivery_latitude');
        $custLng = $request->input('delivery_longitude');
        $customerNote = $request->input('customer_note');

        // Resolve all products and check stock availability
        $productIds = collect($cartReqItems)->pluck('retailer_product_id')->all();
        $products = RetailerProduct::with('seller')->whereIn('id', $productIds)->get()->keyBy('id');

        // Validate stock beforehand to fail early
        foreach ($cartReqItems as $item) {
            $prodId = $item['retailer_product_id'];
            $reqQty = (float) $item['quantity'];
            $product = $products->get($prodId);

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => "Product not found or unavailable.",
                ], 404);
            }

            if ($product->status !== 'active') {
                return response()->json([
                    'success' => false,
                    'message' => "Product {$product->product_name} is no longer active.",
                ], 400);
            }

            if ($product->stock_quantity < $reqQty) {
                return response()->json([
                    'success' => false,
                    'message' => "Insufficient stock for {$product->product_name}. Available: {$product->stock_quantity} {$product->unit_type}, requested: $reqQty.",
                ], 400);
            }
        }

        // Group the request cart items by their retailer seller ID
        $itemsByRetailer = [];
        foreach ($cartReqItems as $item) {
            $product = $products->get($item['retailer_product_id']);
            $retailerId = $product->seller_id;
            $itemsByRetailer[$retailerId][] = [
                'product' => $product,
                'quantity' => (float) $item['quantity'],
            ];
        }

        DB::beginTransaction();
        $createdOrders = [];

        try {
            foreach ($itemsByRetailer as $retailerId => $group) {
                $retailerUser = $group[0]['product']->seller;

                // 1. Calculate Distance & Delivery Fee
                $distanceKm = null;
                $deliveryFee = 250.00; // default flat rate

                if ($custLat !== null && $custLng !== null && $retailerUser->latitude !== null && $retailerUser->longitude !== null) {
                    $distanceKm = $this->calculateHaversineDistance(
                        (float)$custLat,
                        (float)$custLng,
                        (float)$retailerUser->latitude,
                        (float)$retailerUser->longitude
                    );
                    // LKR 200 Base + LKR 80 per kilometer
                    $deliveryFee = round(200.00 + ($distanceKm * 80.00), 2);
                }

                // 2. Compute Totals
                $subtotal = 0.00;
                $discountAmount = 0.00;

                foreach ($group as $entry) {
                    $prod = $entry['product'];
                    $qty = $entry['quantity'];

                    $unitPrice = (float) $prod->price_per_unit;
                    $discountPrice = $prod->discount_price_per_unit ? (float) $prod->discount_price_per_unit : null;

                    if ($discountPrice !== null && $discountPrice > 0) {
                        $subtotal += ($discountPrice * $qty);
                        $discountAmount += (($unitPrice - $discountPrice) * $qty);
                    } else {
                        $subtotal += ($unitPrice * $qty);
                    }
                }

                $systemCommission = round($subtotal * 0.05, 2); // 5% marketplace fee
                $totalAmount = $subtotal + $deliveryFee;

                // 3. Create the Order Record
                $orderNumber = 'ORD-RETAIL-' . strtoupper(Str::random(4)) . '-' . time();
                $order = CustomerOrder::create([
                    'order_number' => $orderNumber,
                    'customer_id' => $user->id,
                    'retailer_seller_id' => $retailerId,
                    'delivery_address' => $deliveryAddress,
                    'delivery_latitude' => $custLat,
                    'delivery_longitude' => $custLng,
                    'customer_note' => $customerNote,
                    'subtotal_amount' => $subtotal,
                    'discount_amount' => $discountAmount,
                    'delivery_fee' => $deliveryFee,
                    'system_commission_amount' => $systemCommission,
                    'tax_amount' => 0.00,
                    'total_amount' => $totalAmount,
                    'payment_status' => 'pending',
                    'order_status' => 'pending',
                    'placed_at' => now(),
                ]);

                // 4. Create Order Items & Deduct Stock
                foreach ($group as $entry) {
                    $prod = $entry['product'];
                    $qty = $entry['quantity'];

                    $unitPrice = (float) $prod->price_per_unit;
                    $discountPrice = $prod->discount_price_per_unit ? (float) $prod->discount_price_per_unit : null;
                    
                    $itemTotal = $unitPrice * $qty;
                    $itemDiscount = $discountPrice !== null ? (($unitPrice - $discountPrice) * $qty) : 0.00;
                    $itemFinal = $itemTotal - $itemDiscount;

                    OrderItem::create([
                        'order_id' => $order->id,
                        'retailer_product_id' => $prod->id,
                        'quantity' => $qty,
                        'total_price' => $itemTotal,
                        'discount_amount' => $itemDiscount,
                        'final_price' => $itemFinal,
                        'grade' => $prod->grade,
                    ]);

                    // Deduct stock
                    $prod->stock_quantity -= $qty;
                    if ($prod->stock_quantity <= 0) {
                        $prod->stock_quantity = 0;
                        $prod->status = 'out_of_stock';
                    }
                    $prod->save();
                }

                $createdOrders[] = $order->load(['retailer', 'items.product.crop']);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Checkout processed successfully. Created ' . count($createdOrders) . ' orders.',
                'orders' => $createdOrders,
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to place order due to server error.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Haversine formula calculation in PHP
     */
    private function calculateHaversineDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371; // km

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        $distance = $earthRadius * $c;

        return $distance;
    }
}
