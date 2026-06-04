<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\CropGrowthStage;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // ---------------------------------------------------------
        // 1. Seed Users of All Roles
        // ---------------------------------------------------------
        
        $admin = User::updateOrCreate(
            ['phone_number' => '0771234567'],
            [
                'full_name' => 'Super Administrator',
                'email' => 'admin@aswenna.lk',
                'password' => Hash::make('adminpassword'),
                'role' => ['admin'],
                'is_verified' => true,
                'is_active' => true,
            ]
        );

        $farmer = User::updateOrCreate(
            ['phone_number' => '0777123456'],
            [
                'full_name' => 'Saman Kumara',
                'email' => 'saman@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['farmer'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '124, Nuwara Eliya Rd',
                'city' => 'Nuwara Eliya',
                'district' => 'Nuwara Eliya',
                'province' => 'Central',
                'latitude' => 6.9497,
                'longitude' => 80.7891,
            ]
        );

        $buyer = User::updateOrCreate(
            ['phone_number' => '0777234567'],
            [
                'full_name' => 'Keeri Samba Mills Ltd',
                'email' => 'buyer@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['buyer'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '45, Industrial Zone',
                'city' => 'Polonnaruwa',
                'district' => 'Polonnaruwa',
                'province' => 'North Central',
                'latitude' => 7.9403,
                'longitude' => 81.0188,
            ]
        );

        $retailSeller = User::updateOrCreate(
            ['phone_number' => '0777345678'],
            [
                'full_name' => 'Agro Retail Mart',
                'email' => 'retail@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['retail_seller'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '78, High Level Road',
                'city' => 'Maharagama',
                'district' => 'Colombo',
                'province' => 'Western',
                'latitude' => 6.8480,
                'longitude' => 79.9265,
            ]
        );

        $deliveryPartner = User::updateOrCreate(
            ['phone_number' => '0777456789'],
            [
                'full_name' => 'Nuwara Courier Express',
                'email' => 'delivery@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['delivery_partner'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '22, Main Street',
                'city' => 'Kandy',
                'district' => 'Kandy',
                'province' => 'Central',
                'latitude' => 7.2906,
                'longitude' => 80.6337,
            ]
        );

        $customer = User::updateOrCreate(
            ['phone_number' => '0777567890'],
            [
                'full_name' => 'Lakmal Perera',
                'email' => 'customer@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['customer'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '99/A, Galle Road',
                'city' => 'Colombo 03',
                'district' => 'Colombo',
                'province' => 'Western',
                'latitude' => 6.9142,
                'longitude' => 79.8517,            ]
        );

        // ---------------------------------------------------------
        // 2. User Verification Documents
        // ---------------------------------------------------------
        $users = [$farmer, $buyer, $retailSeller, $deliveryPartner, $customer];
        foreach ($users as $u) {
            DB::table('user_verification_documents')->insert([
                'user_id' => $u->id,
                'document_type' => 'national_id',
                'front_image_path' => 'verifications/nic_front.jpg',
                'back_image_path' => 'verifications/nic_back.jpg',
                'verification_status' => 'approved',
                'verified_at' => now(),
                'verified_by' => $admin->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // ---------------------------------------------------------
        // 3. Role-Specific Verification Data
        // ---------------------------------------------------------
        DB::table('farmer_verification_data')->insert([
            'user_id' => $farmer->id,
            'farming_license_number' => 'FL-99388',
            'farming_license_path' => 'verifications/farming_license.pdf',
            'organic_certificate_number' => 'ORG-4482',
            'organic_certificate_path' => 'verifications/organic_cert.pdf',
            'organic_certificate_expiry' => now()->addYear(),
            'gap_certificate_number' => 'GAP-2281',
            'gap_certificate_path' => 'verifications/gap_cert.pdf',
            'gap_certificate_expiry' => now()->addYear(),
            'total_lands' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('retail_seller_verification_data')->insert([
            'user_id' => $retailSeller->id,
            'br_number' => 'BR-8849',
            'br_image_path' => 'verifications/br_cert.pdf',
            'br_issue_date' => now()->subYears(2),
            'br_expiry_date' => now()->addYears(5),
            'business_type' => 'sole_proprietorship',
            'shop_address' => '78, High Level Road, Maharagama',
            'postal_code' => '10280',
            'latitude' => 6.8480,
            'longitude' => 79.9265,
            'ownership_type' => 'owned',
            'status' => 'verified',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('delivery_partner_verification_data')->insert([
            'user_id' => $deliveryPartner->id,
            'driving_license_expiry_date' => now()->addYears(3),
            'vehicle_type' => 'motorcycle',
            'vehicle_make' => 'Honda',
            'model' => 'Super Cub',
            'year' => 2022,
            'color' => 'Red',
            'registration_number' => 'WP-BCC-8849',
            'insurance_expiry' => now()->addYear(),
            'revenue_license_expiry' => now()->addYear(),
            'max_weight' => 50.00,
            'status' => 'verified',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // 4. Default Crops & Growth Stages
        // ---------------------------------------------------------
        $defaultStages = [
            'land_preparation', 'sowing_planting', 'germination', 'seedling',
            'vegetative_early', 'vegetative_mid', 'vegetative_late',
            'flowering_bud_formation', 'flowering_full_bloom', 'fruit_set',
            'fruit_development', 'maturation_ripening', 'harvest_ongoing',
            'harvest_complete', 'fallow'
        ];

        foreach ($defaultStages as $stageName) {
            CropGrowthStage::firstOrCreate(['name' => $stageName]);
        }

        $cropPaddy = DB::table('crops')->insertGetId([
            'cropname' => 'Paddy',
            'image_path' => 'crops/paddy.jpg',
            'status' => 'approved',
            'added_by' => $admin->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $cropCarrot = DB::table('crops')->insertGetId([
            'cropname' => 'Carrot',
            'image_path' => 'crops/carrot.jpg',
            'status' => 'approved',
            'added_by' => $admin->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $cropPotato = DB::table('crops')->insertGetId([
            'cropname' => 'Potato',
            'image_path' => 'crops/potato.jpg',
            'status' => 'approved',
            'added_by' => $admin->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // 5. Lands, Land Crops & Daily Logs
        // ---------------------------------------------------------
        $landId = DB::table('lands')->insertGetId([
            'farmer_id' => $farmer->id,
            'size' => 2.50,
            'ownership_type' => 'owned',
            'registration_number' => 'REG-99238',
            'latitude' => 6.9490,
            'longitude' => 80.7895,
            'status' => 'verified',
            'notes' => 'Potato Valley fertile farm land.',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $landCropId = DB::table('land_crops')->insertGetId([
            'land_id' => $landId,
            'crop_id' => $cropPotato,
            'text' => 'Red Lasoda variety, extent 1.5 acres, expected yield 3000kg.',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $stageId = DB::table('crop_growth_stages')->where('name', 'vegetative_late')->value('id');

        DB::table('daily_cultivation_logs')->insert([
            'farmer_id' => $farmer->id,
            'land_id' => $landId,
            'log_date' => now()->subDays(2),
            'growth_stage_id' => $stageId,
            'leaf_appearance' => 'Healthy green leaves',
            'disease_detected' => false,
            'pest_detected' => false,
            'pesticide_applied' => false,
            'notes' => 'Potato plants looking healthy. Watering kept at optimum stream intake.',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // 6. Market Rates (Crop Rates)
        // ---------------------------------------------------------
        DB::table('crop_rates')->insert([
            [
                'buyer_id' => $buyer->id,
                'crop_id' => $cropPaddy,
                'date_and_time' => now()->subDays(1),
                'rate_per_kg_grade_a' => 125.00,
                'rate_per_kg_grade_b' => 110.00,
                'rate_per_kg_grade_c' => 95.00,
                'min_qty_required' => 500.00,
                'accepted_grade' => 'All',
                'max_qty_required' => 5000.00,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'buyer_id' => $buyer->id,
                'crop_id' => $cropCarrot,
                'date_and_time' => now()->subDays(1),
                'rate_per_kg_grade_a' => 320.00,
                'rate_per_kg_grade_b' => 280.00,
                'rate_per_kg_grade_c' => 240.00,
                'min_qty_required' => 100.00,
                'accepted_grade' => 'A',
                'max_qty_required' => 1000.00,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // ---------------------------------------------------------
        // 7. Harvest Listings & Bidding Engine
        // ---------------------------------------------------------
        $harvestId = DB::table('harvest_listings')->insertGetId([
            'farmer_id' => $farmer->id,
            'crop_id' => $cropPotato,
            'date_and_time' => now(),
            'notes' => 'Superb grade A red potatoes harvested organically in Nuwara Eliya. Cleaned and packed in 50kg sacks.',
            'grade' => 'A',
            'available_quantity' => 2000.00,
            'unit' => 'kg',
            'minimum_order_quantity' => 100.00,
            'maximum_order_quantity' => 2000.00,
            'price_per_unit' => 220.00,
            'min_bid_price_per_unit' => 210.00,
            'harvest_date' => now()->subDays(5),
            'harvest_condition' => 'fresh',
            'storage_method' => 'room_temp',
            'pickup_latitude' => 6.9490,
            'pickup_longitude' => 80.7895,
            'delivery_available' => true,
            'delivery_fee_per_km' => 50.00,
            'max_delivery_distance' => 30.00,
            'available_from_date' => now()->subDays(5),
            'available_to_date' => now()->addDays(10),
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $bidId = DB::table('harvest_bids')->insertGetId([
            'buyer_id' => $buyer->id,
            'harvest_listing_id' => $harvestId,
            'bid_amount_per_unit' => 215.00,
            'bid_quantity_unit' => 2000.00,
            'notes' => 'We will pick it up using our small truck tomorrow morning.',
            'status' => 'accepted',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $confirmedBidId = DB::table('confirmed_bids')->insertGetId([
            'buyer_id' => $buyer->id,
            'harvest_listing_id' => $harvestId,
            'farmer_id' => $farmer->id,
            'bid_id' => $bidId,
            'notes' => 'Potato purchase deal completed successfully.',
            'total_amount' => 430000.00,
            'payment_status' => 'paid',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('confirmed_bids_payments')->insert([
            'buyer_id' => $buyer->id,
            'farmer_id' => $farmer->id,
            'confirmed_bid_id' => $confirmedBidId,
            'total_amount' => 438600.00,
            'system_commission' => 8600.00,
            'farmer_amount' => 430000.00,
            'payment_id' => 'PAYHERE-CONFIRMED-8849',
            'date_and_time' => now(),
            'payment_status' => 'paid',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('buyer_farmer_reviews')->insert([
            'buyer_id' => $buyer->id,
            'farmer_id' => $farmer->id,
            'confirmed_bid_id' => $confirmedBidId,
            'ratings' => 5,
            'feedback' => 'Red potatoes were exceptional, perfectly cleaned and weighed. Recommended seller!',
            'reviewed_by' => $buyer->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // 8. Communication (Harvest Deal Chat)
        // ---------------------------------------------------------
        DB::table('chats')->insert([
            [
                'sender_id' => $buyer->id,
                'receiver_id' => $farmer->id,
                'message_text' => 'Hello Saman, I submitted a bid for your Potato listing. Can you please review it?',
                'type' => 'text',
                'is_read' => true,
                'sent_at' => now()->subHours(2),
                'created_at' => now()->subHours(2),
                'updated_at' => now()->subHours(2),
            ],
            [
                'sender_id' => $farmer->id,
                'receiver_id' => $buyer->id,
                'message_text' => 'Hi Keeri Mills, yes, I saw the bid. LKR 215 is acceptable. I will accept it now.',
                'type' => 'text',
                'is_read' => true,
                'sent_at' => now()->subHour(),
                'created_at' => now()->subHour(),
                'updated_at' => now()->subHour(),
            ]
        ]);

        // ---------------------------------------------------------
        // 9. AI Chatbot
        // ---------------------------------------------------------
        DB::table('chatbot_sessions')->insert([
            'user_id' => $farmer->id,
            'session_id' => 'SES-' . Str::random(10),
            'message' => 'How can I prevent potato late blight?',
            'response' => 'To prevent late blight, use certified seed tubers, avoid overhead irrigation, and apply organic neem oil.',
            'role' => 'user',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // 10. Financials (Wallets & Transactions)
        // ---------------------------------------------------------
        foreach ($users as $u) {
            $walletId = DB::table('user_wallets')->insertGetId([
                'user_id' => $u->id,
                'available_balance' => $u->id === $buyer->id ? 10000.00 : 50000.00,
                'pending_balance' => 0.00,
                'total_earned' => $u->id === $buyer->id ? 10000.00 : 50000.00,
                'total_withdrawn' => 0.00,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('wallet_transactions')->insert([
                'user_id' => $u->id,
                'amount' => 500.00,
                'balance_before' => 0.00,
                'balance_after' => 500.00,
                'transaction_type' => 'other',
                'description' => 'Account setup welcome deposit',
                'status' => 'completed',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        DB::table('withdraw_requests')->insert([
            'user_id' => $farmer->id,
            'request_amount' => 20000.00,
            'bank_name' => 'Bank of Ceylon',
            'bank_branch' => 'Nuwara Eliya',
            'bank_account_holder_name' => 'S. Kumara',
            'bank_account_number' => '10293847',
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // 11. Gamification (Offers & Campaigns)
        // ---------------------------------------------------------
        $offerGoalId = DB::table('offer_goals')->insertGetId([
            'name' => 'List 5 retail products',
            'description' => 'List 5 retail products to fulfill the requirements',
            'goal_type' => 'total_products',
            'target_value' => 5.00,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $campaignId = DB::table('offer_campaigns')->insertGetId([
            'offer_goal_id' => $offerGoalId,
            'title' => 'Fresh Start Seller Boost',
            'code' => 'FRESHSTART1000',
            'description' => 'Register and list 5 products to earn LKR 1000 cashback.',
            'type' => 'fixed_amount',
            'discount_amount' => 1000.00,
            'valid_from' => now()->subDays(5),
            'valid_until' => now()->addMonth(),
            'is_active' => true,
            'applied_user_role' => 'retail_seller',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('user_offer_progress')->insert([
            'user_id' => $retailSeller->id,
            'offer_campaign_id' => $campaignId,
            'is_completed' => false,
            'notes' => 'Currently listed 3 products.',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // 12. Retail Products
        // ---------------------------------------------------------
        $prodPotato = DB::table('retailer_products')->insertGetId([
            'seller_id' => $retailSeller->id,
            'crop_id' => $cropPotato,
            'product_name' => 'Nuwara Eliya Red Potatoes',
            'price_per_unit' => 290.00,
            'discount_price_per_unit' => 275.00,
            'unit_type' => 'kg',
            'stock_quantity' => 450.00,
            'grade' => 'A',
            'thumbnail_path' => 'products/potatoes.jpg',
            'description' => 'Fresh premium Nuwara Eliya potatoes packed from local harvests.',
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $prodCarrot = DB::table('retailer_products')->insertGetId([
            'seller_id' => $retailSeller->id,
            'crop_id' => $cropCarrot,
            'product_name' => 'Nuwara Eliya Crisp Carrots',
            'price_per_unit' => 380.00,
            'discount_price_per_unit' => 0.00,
            'unit_type' => 'kg',
            'stock_quantity' => 250.00,
            'grade' => 'A',
            'thumbnail_path' => 'products/carrots.jpg',
            'description' => 'Sweet crisp local carrots, perfect for culinary uses.',
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // 13. Retail Orders & Logistics
        // ---------------------------------------------------------
        $orderId = DB::table('customer_orders')->insertGetId([
            'order_number' => 'ORD-RETAIL-4482-17182918',
            'customer_id' => $customer->id,
            'delivery_partner_id' => $deliveryPartner->id,
            'delivery_address' => '99/A, Galle Road, Colombo 03',
            'delivery_latitude' => 6.9142,
            'delivery_longitude' => 79.8517,
            'customer_note' => 'Deliver before 5 PM please.',
            'subtotal_amount' => 930.00,
            'discount_amount' => 30.00,
            'delivery_fee' => 380.00,
            'system_commission_amount' => 46.50,
            'tax_amount' => 0.00,
            'total_amount' => 1310.00,
            'payment_status' => 'paid',
            'payment_id' => 'PAYHERE-REF-3392182',
            'order_status' => 'delivered',
            'placed_at' => now()->subDays(1),
            'confirmed_at' => now()->subDays(1)->addMinutes(15),
            'picked_up_at' => now()->subDays(1)->addHours(1),
            'delivered_at' => now()->subDays(1)->addHours(2),
            'created_at' => now()->subDays(1),
            'updated_at' => now()->subDays(1),
        ]);

        DB::table('order_items')->insert([
            [
                'order_id' => $orderId,
                'retailer_product_id' => $prodPotato,
                'retailer_id' => $retailSeller->id,
                'quantity' => 2.00,
                'total_price' => 580.00,
                'discount_amount' => 30.00,
                'final_price' => 550.00,
                'grade' => 'A',
                'created_at' => now()->subDays(1),
                'updated_at' => now()->subDays(1),
            ],
            [
                'order_id' => $orderId,
                'retailer_product_id' => $prodCarrot,
                'retailer_id' => $retailSeller->id,
                'quantity' => 1.00,
                'total_price' => 380.00,
                'discount_amount' => 0.00,
                'final_price' => 380.00,
                'grade' => 'A',
                'created_at' => now()->subDays(1),
                'updated_at' => now()->subDays(1),
            ]
        ]);

        DB::table('retailer_customer_delivery_partner_reviews')->insert([
            'reviewed_to' => $retailSeller->id,
            'reviewed_by' => $customer->id,
            'order_id' => $orderId,
            'feedback' => 'Good packaging, fast processing!',
            'ratings' => 5,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $deliveryReqId = DB::table('order_delivery_requests')->insertGetId([
            'order_id' => $orderId,
            'request_status' => 'completed',
            'pickup_address' => '78, High Level Road, Maharagama',
            'pickup_latitude' => 6.8480,
            'pickup_longitude' => 79.9265,
            'delivery_address' => '99/A, Galle Road, Colombo 03',
            'delivery_latitude' => 6.9142,
            'delivery_longitude' => 79.8517,
            'delivery_fee' => 300.00,
            'system_commission' => 30.00,
            'estimated_distance_km' => 12.50,
            'estimated_distance_minutes' => 35,
            'created_at' => now()->subDays(1),
            'updated_at' => now()->subDays(1),
        ]);

        DB::table('order_delivery_requests_assigned_partners')->insert([
            'delivery_request_id' => $deliveryReqId,
            'delivery_partner_id' => $deliveryPartner->id,
            'status' => 'accepted',
            'created_at' => now()->subDays(1),
            'updated_at' => now()->subDays(1),
        ]);

        DB::table('order_delivery_tracking')->insert([
            'order_id' => $orderId,
            'delivery_partner_id' => $deliveryPartner->id,
            'status' => 'delivered',
            'current_latitude' => 6.9142,
            'current_longitude' => 79.8517,
            'tracking_note' => 'Parcel handed over to customer.',
            'tracked_at' => now()->subDays(1)->addHours(2),
            'created_at' => now()->subDays(1)->addHours(2),
            'updated_at' => now()->subDays(1)->addHours(2),
        ]);

        DB::table('order_payments')->insert([
            'order_id' => $orderId,
            'customer_id' => $customer->id,
            'payment_status' => 'paid',
            'transaction_reference' => 'PAYHERE-REF-3392182',
            'paid_amount' => 1310.00,
            'paid_at' => now()->subDays(1),
            'created_at' => now()->subDays(1),
            'updated_at' => now()->subDays(1),
        ]);

        DB::table('order_status_histories')->insert([
            [
                'order_id' => $orderId,
                'changed_by_user_id' => $customer->id,
                'old_status' => null,
                'new_status' => 'pending',
                'status_note' => 'Order created by customer.',
                'changed_at' => now()->subDays(1),
                'created_at' => now()->subDays(1),
                'updated_at' => now()->subDays(1),
            ],
            [
                'order_id' => $orderId,
                'changed_by_user_id' => $deliveryPartner->id,
                'old_status' => 'picked_up',
                'new_status' => 'delivered',
                'status_note' => 'Delivered successfully.',
                'changed_at' => now()->subDays(1)->addHours(2),
                'created_at' => now()->subDays(1)->addHours(2),
                'updated_at' => now()->subDays(1)->addHours(2),
            ]
        ]);
    }
}
