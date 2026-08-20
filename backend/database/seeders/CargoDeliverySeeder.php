<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\CustomerOrder;
use App\Models\OrderItem;
use App\Models\RetailerProduct;
use Illuminate\Support\Facades\DB;

class CargoDeliverySeeder extends Seeder
{
    /**
     * Seed test data for Delivery Partner Test Cases:
     * DEL-003: Cargo Pickup & OTP Verification (OTP: 849201)
     * DEL-004: Real-Time Status Updates & Arrived Status
     * DEL-005: Proof of Delivery & Payout Crediting (OTP: 392014, Payout: LKR 4,500)
     */
    public function run(): void
    {
        // 1. Resolve Farmer/Seller User
        $farmer = User::where('email', 'farmer@aswenna.com')->first();
        if (!$farmer) {
            $farmer = User::firstOrCreate(
                ['phone_number' => '0711111111'],
                [
                    'full_name' => 'Saman Kumara (Farmer)',
                    'email' => 'farmer@aswenna.com',
                    'password' => bcrypt('password123'),
                    'role' => ['farmer'],
                    'is_verified' => true,
                    'is_active' => true,
                ]
            );
        }

        // 2. Resolve Buyer/Customer User
        $buyer = User::where('email', 'buyer@aswenna.com')->first();
        if (!$buyer) {
            $buyer = User::firstOrCreate(
                ['phone_number' => '0722222222'],
                [
                    'full_name' => 'Keeri Samba Mills (Buyer)',
                    'email' => 'buyer@aswenna.com',
                    'password' => bcrypt('password123'),
                    'role' => ['buyer'],
                    'is_verified' => true,
                    'is_active' => true,
                ]
            );
        }

        // 3. Resolve Delivery Partner User (ID: 5 - Priyantha Mahaulpathagama / priyantha@gmail.com)
        $delivery = User::find(5) ?? User::where('email', 'priyantha@gmail.com')->first();
        if (!$delivery) {
            $delivery = User::where('email', 'delivery@aswenna.com')->first();
        }
        if (!$delivery) {
            $delivery = User::firstOrCreate(
                ['phone_number' => '0777456789'],
                [
                    'id' => 5,
                    'full_name' => 'Priyantha Mahaulpathagama',
                    'email' => 'priyantha@gmail.com',
                    'password' => bcrypt('password123'),
                    'role' => ['delivery_partner'],
                    'is_verified' => true,
                    'is_active' => true,
                ]
            );
        }

        // Ensure Delivery Partner Wallet Exists
        $walletExists = DB::table('user_wallets')->where('user_id', $delivery->id)->exists();
        if (!$walletExists) {
            DB::table('user_wallets')->insert([
                'user_id' => $delivery->id,
                'available_balance' => 0.00,
                'pending_balance' => 0.00,
                'total_earned' => 0.00,
                'total_withdrawn' => 0.00,
                'last_updated_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 4. Create or Update Order #ORD-CARGO-8492 (Status: delivery_partner_assigned)
        $order1 = CustomerOrder::updateOrCreate(
            ['order_number' => 'ORD-CARGO-8492'],
            [
                'customer_id' => $buyer->id,
                'delivery_partner_id' => $delivery->id,
                'delivery_address' => 'No. 120, Industrial Zone, Dambulla',
                'delivery_latitude' => 7.8731,
                'delivery_longitude' => 80.6517,
                'customer_note' => 'Bulk harvest transport cargo. Verify OTP 849201 at pickup.',
                'subtotal_amount' => 45000.00,
                'discount_amount' => 0.00,
                'delivery_fee' => 4500.00,
                'system_commission_amount' => 225.00,
                'tax_amount' => 0.00,
                'total_amount' => 49500.00,
                'payment_status' => 'paid',
                'payment_id' => 'PAY-CRG-849201',
                'order_status' => 'delivery_partner_assigned',
                'pickup_slot' => '10:00',
                'pickup_barcode' => 'PKUP-ORD-CARGO-8492',
                'pickup_otp' => '849201',
                'delivery_otp' => '392014',
                'placed_at' => now(),
            ]
        );

        DB::table('order_delivery_requests')->updateOrInsert(
            ['order_id' => $order1->id],
            [
                'request_status' => 'assigned',
                'pickup_address' => 'Farm 14, Nuwara Eliya Road, Welimada',
                'pickup_latitude' => 6.9497,
                'pickup_longitude' => 80.7891,
                'delivery_address' => 'No. 120, Industrial Zone, Dambulla',
                'delivery_latitude' => 7.8731,
                'delivery_longitude' => 80.6517,
                'delivery_fee' => 4500.00,
                'system_commission' => 225.00,
                'estimated_distance_km' => 85.5,
                'estimated_distance_minutes' => 120,
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );

        // 5. Create or Update Order #ORD-DEL004-9901 (Status: in_transit for DEL-004)
        $order2 = CustomerOrder::updateOrCreate(
            ['order_number' => 'ORD-DEL004-9901'],
            [
                'customer_id' => $buyer->id,
                'delivery_partner_id' => $delivery->id,
                'delivery_address' => 'Central Market Hub, Dambulla',
                'delivery_latitude' => 7.8740,
                'delivery_longitude' => 80.6520,
                'customer_note' => 'Fresh vegetable shipment in transit. Test case DEL-004.',
                'subtotal_amount' => 32000.00,
                'discount_amount' => 0.00,
                'delivery_fee' => 4500.00,
                'system_commission_amount' => 225.00,
                'tax_amount' => 0.00,
                'total_amount' => 36500.00,
                'payment_status' => 'paid',
                'payment_id' => 'PAY-DEL004-9901',
                'order_status' => 'in_transit',
                'pickup_slot' => '11:30',
                'pickup_barcode' => 'PKUP-ORD-DEL004-9901',
                'pickup_otp' => '849201',
                'delivery_otp' => '392014',
                'cargo_photo_path' => 'cargo_loaded.jpg',
                'placed_at' => now(),
            ]
        );

        DB::table('order_delivery_requests')->updateOrInsert(
            ['order_id' => $order2->id],
            [
                'request_status' => 'assigned',
                'pickup_address' => 'Vegetable Farm, Welimada',
                'pickup_latitude' => 6.9500,
                'pickup_longitude' => 80.7900,
                'delivery_address' => 'Central Market Hub, Dambulla',
                'delivery_latitude' => 7.8740,
                'delivery_longitude' => 80.6520,
                'delivery_fee' => 4500.00,
                'system_commission' => 225.00,
                'estimated_distance_km' => 84.0,
                'estimated_distance_minutes' => 115,
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );
    }
}
