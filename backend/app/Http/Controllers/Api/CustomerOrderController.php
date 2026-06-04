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
        $orders = CustomerOrder::with(['items.retailer', 'items.product.crop'])
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
        $order = CustomerOrder::with(['items.retailer', 'items.product.crop', 'deliveryPartner'])
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

        DB::beginTransaction();

        try {
            // Find distinct retailers and compile calculations
            $distinctRetailers = [];
            $subtotal = 0.00;
            $discountAmount = 0.00;

            foreach ($cartReqItems as $item) {
                $prod = $products->get($item['retailer_product_id']);
                $qty = (float) $item['quantity'];

                // Add retailer to distinct list
                if ($prod->seller) {
                    $distinctRetailers[$prod->seller_id] = $prod->seller;
                }

                $unitPrice = (float) $prod->price_per_unit;
                $discountPrice = $prod->discount_price_per_unit ? (float) $prod->discount_price_per_unit : null;

                if ($discountPrice !== null && $discountPrice > 0) {
                    $subtotal += ($discountPrice * $qty);
                    $discountAmount += (($unitPrice - $discountPrice) * $qty);
                } else {
                    $subtotal += ($unitPrice * $qty);
                }
            }

            // Calculate Route-based Delivery Fee
            $retailerCoords = [];
            foreach ($distinctRetailers as $retailer) {
                if ($retailer->latitude !== null && $retailer->longitude !== null) {
                    $retailerCoords[] = [
                        'lat' => (float)$retailer->latitude,
                        'lng' => (float)$retailer->longitude
                    ];
                }
            }

            $totalDistance = 0.0;
            if (count($retailerCoords) > 0) {
                $currLat = $retailerCoords[0]['lat'];
                $currLng = $retailerCoords[0]['lng'];

                for ($i = 1; $i < count($retailerCoords); $i++) {
                    $nextLat = $retailerCoords[$i]['lat'];
                    $nextLng = $retailerCoords[$i]['lng'];
                    $totalDistance += $this->calculateHaversineDistance($currLat, $currLng, $nextLat, $nextLng);
                    $currLat = $nextLat;
                    $currLng = $nextLng;
                }

                if ($custLat !== null && $custLng !== null) {
                    $totalDistance += $this->calculateHaversineDistance($currLat, $currLng, (float)$custLat, (float)$custLng);
                } else {
                    $totalDistance += 10.0;
                }
            } else {
                $totalDistance = 10.0;
            }

            $totalWeight = 0.0;
            foreach ($cartReqItems as $item) {
                $totalWeight += (float)$item['quantity'];
            }

            $ratePerKm = 100.0;
            if ($totalWeight >= 20.0) {
                $ratePerKm = 200.0;
            } elseif ($totalWeight >= 10.0) {
                $ratePerKm = 175.0;
            } elseif ($totalWeight >= 5.0) {
                $ratePerKm = 150.0;
            }

            $totalDeliveryFee = round($totalDistance * $ratePerKm, 2);

            $systemCommission = round(($subtotal * 0.05) + ($totalDeliveryFee * 0.05), 2); // 5% marketplace fee + 5% of delivery fee
            $totalAmount = $subtotal + $totalDeliveryFee;

            // 1. Create the Order Record
            $orderNumber = 'ORD-RETAIL-' . strtoupper(Str::random(4)) . '-' . time();
            $order = CustomerOrder::create([
                'order_number' => $orderNumber,
                'customer_id' => $user->id,
                'delivery_address' => $deliveryAddress,
                'delivery_latitude' => $custLat,
                'delivery_longitude' => $custLng,
                'customer_note' => $customerNote,
                'subtotal_amount' => $subtotal,
                'discount_amount' => $discountAmount,
                'delivery_fee' => $totalDeliveryFee,
                'system_commission_amount' => $systemCommission,
                'tax_amount' => 0.00,
                'total_amount' => $totalAmount,
                'payment_status' => 'pending',
                'order_status' => 'pending',
                'placed_at' => now(),
            ]);

            // 2. Create Order Items & Deduct Stock
            foreach ($cartReqItems as $item) {
                $prod = $products->get($item['retailer_product_id']);
                $qty = (float) $item['quantity'];

                $unitPrice = (float) $prod->price_per_unit;
                $discountPrice = $prod->discount_price_per_unit ? (float) $prod->discount_price_per_unit : null;
                
                $itemTotal = $unitPrice * $qty;
                $itemDiscount = $discountPrice !== null ? (($unitPrice - $discountPrice) * $qty) : 0.00;
                $itemFinal = $itemTotal - $itemDiscount;

                OrderItem::create([
                    'order_id' => $order->id,
                    'retailer_product_id' => $prod->id,
                    'retailer_id' => $prod->seller_id,
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

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Checkout processed successfully.',
                'orders' => [$order->load(['items.retailer', 'items.product.crop'])],
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
     * POST /api/customer/orders/calculate-delivery
     * Calculate route distance and dynamic delivery fee based on total weight.
     */
    public function calculateDelivery(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'delivery_latitude' => 'required|numeric|between:-90,90',
            'delivery_longitude' => 'required|numeric|between:-180,180',
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
        $custLat = $request->input('delivery_latitude');
        $custLng = $request->input('delivery_longitude');

        // Resolve all products
        $productIds = collect($cartReqItems)->pluck('retailer_product_id')->all();
        $products = RetailerProduct::with('seller')->whereIn('id', $productIds)->get()->keyBy('id');

        $distinctRetailers = [];
        $totalWeight = 0.0;
        foreach ($cartReqItems as $item) {
            $prod = $products->get($item['retailer_product_id']);
            if ($prod) {
                $totalWeight += (float)$item['quantity'];
                if ($prod->seller) {
                    $distinctRetailers[$prod->seller_id] = $prod->seller;
                }
            }
        }

        $retailerCoords = [];
        foreach ($distinctRetailers as $retailer) {
            if ($retailer->latitude !== null && $retailer->longitude !== null) {
                $retailerCoords[] = [
                    'lat' => (float)$retailer->latitude,
                    'lng' => (float)$retailer->longitude
                ];
            }
        }

        $totalDistance = 0.0;
        if (count($retailerCoords) > 0) {
            $currLat = $retailerCoords[0]['lat'];
            $currLng = $retailerCoords[0]['lng'];

            for ($i = 1; $i < count($retailerCoords); $i++) {
                $nextLat = $retailerCoords[$i]['lat'];
                $nextLng = $retailerCoords[$i]['lng'];
                $totalDistance += $this->calculateHaversineDistance($currLat, $currLng, $nextLat, $nextLng);
                $currLat = $nextLat;
                $currLng = $nextLng;
            }

            if ($custLat !== null && $custLng !== null) {
                $totalDistance += $this->calculateHaversineDistance($currLat, $currLng, (float)$custLat, (float)$custLng);
            } else {
                $totalDistance += 10.0;
            }
        } else {
            $totalDistance = 10.0;
        }

        $ratePerKm = 100.0;
        if ($totalWeight >= 20.0) {
            $ratePerKm = 200.0;
        } elseif ($totalWeight >= 10.0) {
            $ratePerKm = 175.0;
        } elseif ($totalWeight >= 5.0) {
            $ratePerKm = 150.0;
        }

        $deliveryFee = round($totalDistance * $ratePerKm, 2);

        return response()->json([
            'success' => true,
            'distance_km' => round($totalDistance, 2),
            'total_weight_kg' => round($totalWeight, 2),
            'rate_per_km' => $ratePerKm,
            'delivery_fee' => $deliveryFee,
        ], 200);
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
