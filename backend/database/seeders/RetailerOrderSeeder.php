<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\CustomerOrder;
use App\Models\OrderItem;
use App\Models\RetailerProduct;
use Illuminate\Support\Facades\DB;

class RetailerOrderSeeder extends Seeder
{
    /**
     * Seed order #ORD-9912 for Test Case RET-003: Accept Consumer Retail Order & Mark Ready for Pickup
     */
    public function run(): void
    {
        // 1. Resolve Customer User
        $customer = User::where('email', 'customer@aswenna.com')->first();
        if (!$customer) {
            $customer = User::firstOrCreate(
                ['phone_number' => '0755555555'],
                [
                    'full_name' => 'Lakmal Perera (Customer)',
                    'email' => 'customer@aswenna.com',
                    'password' => bcrypt('password123'),
                    'role' => ['customer'],
                    'is_verified' => true,
                    'is_active' => true,
                ]
            );
        }

        // 2. Resolve Retailer Seller User
        $retailer = User::where('email', 'retailer@aswenna.com')->first();
        if (!$retailer) {
            $retailer = User::firstOrCreate(
                ['phone_number' => '0733333333'],
                [
                    'full_name' => 'Agro Retail Mart',
                    'email' => 'retailer@aswenna.com',
                    'password' => bcrypt('password123'),
                    'role' => ['retail_seller'],
                    'is_verified' => true,
                    'is_active' => true,
                ]
            );
        }

        // 3. Resolve or Create a Retailer Product
        $product = RetailerProduct::where('seller_id', $retailer->id)->first();
        if (!$product) {
            $cropId = DB::table('crops')->value('id') ?? 1;
            $product = RetailerProduct::create([
                'seller_id' => $retailer->id,
                'crop_id' => $cropId,
                'product_name' => 'Fresh Nuwara Eliya Carrots',
                'unit_type' => 'kg',
                'grade' => 'A',
                'price_per_unit' => 250.00,
                'stock_quantity' => 100.0,
                'status' => 'active',
            ]);
        }

        // 4. Create or Update Order #ORD-9912
        $order = CustomerOrder::updateOrCreate(
            ['order_number' => 'ORD-9912'],
            [
                'customer_id' => $customer->id,
                'delivery_address' => 'No. 45, Main Street, Colombo 03',
                'delivery_latitude' => 6.9271,
                'delivery_longitude' => 79.8612,
                'customer_note' => 'Please confirm and pack for pickup at 14:00 slot.',
                'subtotal_amount' => 1250.00,
                'discount_amount' => 0.00,
                'delivery_fee' => 150.00,
                'system_commission_amount' => 50.00,
                'tax_amount' => 0.00,
                'total_amount' => 1400.00,
                'payment_status' => 'paid',
                'payment_id' => 'PAY-PYH-991288',
                'order_status' => 'confirmed',
                'pickup_slot' => '14:00',
                'placed_at' => now(),
            ]
        );

        // 5. Attach Order Items
        OrderItem::updateOrCreate(
            [
                'order_id' => $order->id,
                'retailer_product_id' => $product->id,
            ],
            [
                'retailer_id' => $retailer->id,
                'quantity' => 5.0,
                'total_price' => 1250.00,
                'discount_amount' => 0.00,
                'final_price' => 1250.00,
                'grade' => 'A',
            ]
        );
    }
}
