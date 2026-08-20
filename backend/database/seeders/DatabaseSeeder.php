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
        // 6. Market Rates (Today & 30-Day Historical Wholesale Buyer Data)
        // ---------------------------------------------------------
        $additionalBuyerDefs = [
            [
                'phone_number' => '0778899001',
                'full_name' => 'Lanka Wholesale Produce Ltd',
                'email' => 'lanka_produce@aswenna.lk',
                'city' => 'Nuwara Eliya',
                'district' => 'Nuwara Eliya',
                'province' => 'Central',
            ],
            [
                'phone_number' => '0778899002',
                'full_name' => 'Nuwara Eliya Agri Hub',
                'email' => 'nuwara_agri@aswenna.lk',
                'city' => 'Nuwara Eliya',
                'district' => 'Nuwara Eliya',
                'province' => 'Central',
            ],
            [
                'phone_number' => '0778899003',
                'full_name' => 'Ceylinco Agro Buying Corp',
                'email' => 'ceylinco_agro@aswenna.lk',
                'city' => 'Colombo',
                'district' => 'Colombo',
                'province' => 'Western',
            ]
        ];

        foreach ($additionalBuyerDefs as $bDef) {
            User::firstOrCreate(
                ['phone_number' => $bDef['phone_number']],
                [
                    'full_name' => $bDef['full_name'],
                    'email' => $bDef['email'],
                    'password' => Hash::make('password123'),
                    'role' => ['buyer'],
                    'is_verified' => true,
                    'is_active' => true,
                    'address' => 'Central Wholesale Market',
                    'city' => $bDef['city'],
                    'district' => $bDef['district'],
                    'province' => $bDef['province'],
                    'latitude' => 6.9497,
                    'longitude' => 80.7891,
                ]
            );
        }

        $allBuyerIds = DB::table('users')->where('role', 'like', '%buyer%')->pluck('id')->toArray();
        $allCrops = DB::table('crops')->get(['id', 'cropname']);

        $cropConfigs = [
            'Green Chilli'       => ['base_a' => 480.00, 'min_qty' => 50,  'max_qty' => 1000],
            'Potato'             => ['base_a' => 240.00, 'min_qty' => 100, 'max_qty' => 5000],
            'Carrot'             => ['base_a' => 340.00, 'min_qty' => 100, 'max_qty' => 3000],
            'Tomato'             => ['base_a' => 210.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Paddy'              => ['base_a' => 135.00, 'min_qty' => 500, 'max_qty' => 10000],
            'Aloe Vera'          => ['base_a' => 175.00, 'min_qty' => 30,  'max_qty' => 500],
            'Ambarella'          => ['base_a' => 180.00, 'min_qty' => 40,  'max_qty' => 800],
            'Arecanut'           => ['base_a' => 520.00, 'min_qty' => 20,  'max_qty' => 1500],
            'Capsicum'           => ['base_a' => 420.00, 'min_qty' => 50,  'max_qty' => 1500],
            'Brinjal'            => ['base_a' => 190.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Leeks'              => ['base_a' => 280.00, 'min_qty' => 60,  'max_qty' => 2500],
            'Beetroot'           => ['base_a' => 310.00, 'min_qty' => 80,  'max_qty' => 2000],
            'Cabbage'            => ['base_a' => 160.00, 'min_qty' => 100, 'max_qty' => 4000],
            'Banana'             => ['base_a' => 220.00, 'min_qty' => 100, 'max_qty' => 5000],
            'Maize'              => ['base_a' => 140.00, 'min_qty' => 200, 'max_qty' => 8000],
            'Big Onion'          => ['base_a' => 290.00, 'min_qty' => 100, 'max_qty' => 5000],
            'Red Onion'          => ['base_a' => 350.00, 'min_qty' => 100, 'max_qty' => 4000],
            'Pumpkin'            => ['base_a' => 120.00, 'min_qty' => 100, 'max_qty' => 3000],
            'Cucumber'           => ['base_a' => 110.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Bitter Gourd'       => ['base_a' => 260.00, 'min_qty' => 40,  'max_qty' => 1500],
            'Snake Gourd'        => ['base_a' => 180.00, 'min_qty' => 50,  'max_qty' => 1500],
            'Ridge Gourd'        => ['base_a' => 190.00, 'min_qty' => 50,  'max_qty' => 1500],
            'Luffa'              => ['base_a' => 170.00, 'min_qty' => 50,  'max_qty' => 1500],
            'Ash Plantain'       => ['base_a' => 210.00, 'min_qty' => 50,  'max_qty' => 2500],
            'Ladies Finger'      => ['base_a' => 160.00, 'min_qty' => 40,  'max_qty' => 1500],
            'Winged Bean'        => ['base_a' => 240.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Long Bean'          => ['base_a' => 180.00, 'min_qty' => 40,  'max_qty' => 1500],
            'Beans'              => ['base_a' => 320.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Cauliflower'        => ['base_a' => 450.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Radish'             => ['base_a' => 140.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Turnip'             => ['base_a' => 160.00, 'min_qty' => 50,  'max_qty' => 1500],
            'Gotukola'           => ['base_a' => 150.00, 'min_qty' => 20,  'max_qty' => 500],
            'Manioc'             => ['base_a' => 130.00, 'min_qty' => 100, 'max_qty' => 3000],
            'Sweet Potato'       => ['base_a' => 160.00, 'min_qty' => 100, 'max_qty' => 3000],
            'Yam'                => ['base_a' => 220.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Taro'               => ['base_a' => 190.00, 'min_qty' => 50,  'max_qty' => 1500],
            'Papaya'             => ['base_a' => 180.00, 'min_qty' => 50,  'max_qty' => 3000],
            'Mango'              => ['base_a' => 280.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Pineapple'          => ['base_a' => 250.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Avocado'            => ['base_a' => 480.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Guava'              => ['base_a' => 210.00, 'min_qty' => 40,  'max_qty' => 1500],
            'Wood Apple'         => ['base_a' => 150.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Orange'             => ['base_a' => 380.00, 'min_qty' => 40,  'max_qty' => 1500],
            'Lime'               => ['base_a' => 320.00, 'min_qty' => 20,  'max_qty' => 1000],
            'Lemon'              => ['base_a' => 350.00, 'min_qty' => 20,  'max_qty' => 1000],
            'Passion Fruit'      => ['base_a' => 420.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Rambutan'           => ['base_a' => 550.00, 'min_qty' => 20,  'max_qty' => 800],
            'Mangosteen'         => ['base_a' => 650.00, 'min_qty' => 20,  'max_qty' => 500],
            'Durian'             => ['base_a' => 850.00, 'min_qty' => 10,  'max_qty' => 500],
            'Jackfruit'          => ['base_a' => 160.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Breadfruit'         => ['base_a' => 190.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Coconut'            => ['base_a' => 95.00,  'min_qty' => 100, 'max_qty' => 5000],
            'Cashew'             => ['base_a' => 1850.00,'min_qty' => 10,  'max_qty' => 500],
            'Coffee'             => ['base_a' => 1200.00,'min_qty' => 20,  'max_qty' => 1000],
            'Tea'                => ['base_a' => 280.00, 'min_qty' => 100, 'max_qty' => 5000],
            'Pepper'             => ['base_a' => 1450.00,'min_qty' => 20,  'max_qty' => 1000],
            'Cinnamon'           => ['base_a' => 2800.00,'min_qty' => 10,  'max_qty' => 500],
            'Cardamom'           => ['base_a' => 4500.00,'min_qty' => 5,   'max_qty' => 200],
            'Clove'              => ['base_a' => 3200.00,'min_qty' => 5,   'max_qty' => 300],
            'Nutmeg'             => ['base_a' => 2600.00,'min_qty' => 5,   'max_qty' => 300],
            'Turmeric'           => ['base_a' => 650.00, 'min_qty' => 20,  'max_qty' => 1000],
            'Ginger'             => ['base_a' => 850.00, 'min_qty' => 20,  'max_qty' => 1000],
            'Betel'              => ['base_a' => 420.00, 'min_qty' => 20,  'max_qty' => 500],
            'Sesame'             => ['base_a' => 580.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Groundnut'          => ['base_a' => 420.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Soybean'            => ['base_a' => 380.00, 'min_qty' => 100, 'max_qty' => 3000],
            'Black Gram'         => ['base_a' => 490.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Green Gram'         => ['base_a' => 520.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Cowpea'             => ['base_a' => 440.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Finger Millet'      => ['base_a' => 360.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Sorghum'            => ['base_a' => 280.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Kurakkan'           => ['base_a' => 380.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Mustard'            => ['base_a' => 620.00, 'min_qty' => 20,  'max_qty' => 1000],
            'Murunga'            => ['base_a' => 310.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Thibbatu'           => ['base_a' => 290.00, 'min_qty' => 20,  'max_qty' => 500],
            'Kekiri'             => ['base_a' => 120.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Pathola'            => ['base_a' => 170.00, 'min_qty' => 50,  'max_qty' => 1500],
            'Bandakka'           => ['base_a' => 160.00, 'min_qty' => 40,  'max_qty' => 1500],
            'Dragon Fruit'       => ['base_a' => 650.00, 'min_qty' => 20,  'max_qty' => 1000],
            'Watermelon'         => ['base_a' => 140.00, 'min_qty' => 100, 'max_qty' => 4000],
            'Muskmelon'          => ['base_a' => 220.00, 'min_qty' => 50,  'max_qty' => 2000],
            'Strawberry'         => ['base_a' => 1400.00,'min_qty' => 10,  'max_qty' => 500],
            'Star Fruit'         => ['base_a' => 210.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Rose Apple'         => ['base_a' => 280.00, 'min_qty' => 20,  'max_qty' => 800],
            'Velvet Tamarind'    => ['base_a' => 450.00, 'min_qty' => 20,  'max_qty' => 500],
            'Tamarind'           => ['base_a' => 380.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Soursop'            => ['base_a' => 320.00, 'min_qty' => 20,  'max_qty' => 800],
            'Bilimbi'            => ['base_a' => 180.00, 'min_qty' => 20,  'max_qty' => 500],
            'Jambu'              => ['base_a' => 240.00, 'min_qty' => 20,  'max_qty' => 800],
            'Pomelo'             => ['base_a' => 310.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Roselle'            => ['base_a' => 250.00, 'min_qty' => 20,  'max_qty' => 500],
            'Curry Leaf'         => ['base_a' => 180.00, 'min_qty' => 10,  'max_qty' => 300],
            'Pandan'             => ['base_a' => 150.00, 'min_qty' => 10,  'max_qty' => 300],
            'Mint'               => ['base_a' => 220.00, 'min_qty' => 10,  'max_qty' => 300],
            'Basil'              => ['base_a' => 240.00, 'min_qty' => 10,  'max_qty' => 300],
            'Lemongrass'         => ['base_a' => 290.00, 'min_qty' => 15,  'max_qty' => 500],
            'Ceylon Spinach Red' => ['base_a' => 160.00, 'min_qty' => 20,  'max_qty' => 500],
            'Chayote'            => ['base_a' => 180.00, 'min_qty' => 50,  'max_qty' => 1500],
            'Winged Yam'         => ['base_a' => 250.00, 'min_qty' => 30,  'max_qty' => 1000],
            'Date'               => ['base_a' => 1200.00,'min_qty' => 20,  'max_qty' => 1000],
        ];

        for ($dayOffset = 29; $dayOffset >= 0; $dayOffset--) {
            $date = \Carbon\Carbon::now()->subDays($dayOffset);
            $isToday = ($dayOffset === 0);
            $trendFactor = 1.0 + (sin($dayOffset * 0.2) * 0.08) + (($dayOffset % 5 - 2) * 0.015);

            foreach ($allCrops as $crop) {
                $cName = $crop->cropname;
                $cId = $crop->id;

                if (isset($cropConfigs[$cName])) {
                    $cfg = $cropConfigs[$cName];
                } else {
                    $calcBase = 150.00 + (($cId * 17) % 250);
                    $cfg = ['base_a' => (float)$calcBase, 'min_qty' => 50, 'max_qty' => 2000];
                }

                $baseA = $cfg['base_a'] * $trendFactor;

                foreach ($allBuyerIds as $idx => $bId) {
                    $buyerVar = 1.0 + (($idx * 0.025) - 0.03);
                    $rA = round($baseA * $buyerVar, 2);
                    $rB = round($rA * 0.88, 2);
                    $rC = round($rA * 0.75, 2);

                    if ($isToday) {
                        $dt = \Carbon\Carbon::now()->startOfDay()->addHours(8 + ($idx * 2))->addMinutes(15 * $idx);
                    } else {
                        $dt = $date->copy()->setHour(8 + ($idx * 2))->setMinute(15 * $idx);
                    }

                    DB::table('crop_rates')->updateOrInsert(
                        [
                            'buyer_id' => $bId,
                            'crop_id' => $cId,
                            'date_and_time' => $dt->toDateTimeString(),
                        ],
                        [
                            'rate_per_kg_grade_a' => $rA,
                            'rate_per_kg_grade_b' => $rB,
                            'rate_per_kg_grade_c' => $rC,
                            'min_qty_required' => $cfg['min_qty'],
                            'max_qty_required' => $cfg['max_qty'],
                            'accepted_grade' => 'All',
                            'created_at' => $dt,
                            'updated_at' => $dt,
                        ]
                    );
                }
            }
        }

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

        $this->call(DigitalContractSeeder::class);
        $this->call(RetailerCampaignSeeder::class);
        $this->call(RetailerOrderSeeder::class);
        $this->call(CargoDeliverySeeder::class);
    }
}
