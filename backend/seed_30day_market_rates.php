<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

echo "Starting Fast Today & 30-Day Historical Market Rates Seeding...\n";

// 1. Ensure buyer users exist
$buyerIds = DB::table('users')->where('role', 'like', '%buyer%')->pluck('id')->toArray();

$additionalBuyers = [
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

foreach ($additionalBuyers as $bData) {
    $user = User::firstOrCreate(
        ['phone_number' => $bData['phone_number']],
        [
            'full_name' => $bData['full_name'],
            'email' => $bData['email'],
            'password' => Hash::make('password123'),
            'role' => ['buyer'],
            'is_verified' => true,
            'is_active' => true,
            'address' => 'Central Market Complex',
            'city' => $bData['city'],
            'district' => $bData['district'],
            'province' => $bData['province'],
            'latitude' => 6.9497,
            'longitude' => 80.7891,
        ]
    );
    if (!in_array($user->id, $buyerIds)) {
        $buyerIds[] = $user->id;
    }
}

echo "Using Buyer IDs: " . implode(', ', $buyerIds) . "\n";

// 2. Define crop base price configurations
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

$allCrops = DB::table('crops')->get(['id', 'cropname']);
echo "Found " . count($allCrops) . " crops in database.\n";

// Truncate to ensure clean bulk insertion
DB::statement('SET FOREIGN_KEY_CHECKS=0;');
DB::table('crop_rates')->truncate();
DB::statement('SET FOREIGN_KEY_CHECKS=1;');

$records = [];
for ($dayOffset = 29; $dayOffset >= 0; $dayOffset--) {
    $date = Carbon::now()->subDays($dayOffset);
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

        foreach ($buyerIds as $idx => $bId) {
            $buyerVar = 1.0 + (($idx * 0.025) - 0.03);
            $rA = round($baseA * $buyerVar, 2);
            $rB = round($rA * 0.88, 2);
            $rC = round($rA * 0.75, 2);

            if ($isToday) {
                $dt = Carbon::now()->startOfDay()->addHours(8 + ($idx * 2))->addMinutes(15 * $idx)->toDateTimeString();
            } else {
                $dt = $date->copy()->setHour(8 + ($idx * 2))->setMinute(15 * $idx)->toDateTimeString();
            }

            $records[] = [
                'buyer_id' => $bId,
                'crop_id' => $cId,
                'date_and_time' => $dt,
                'rate_per_kg_grade_a' => $rA,
                'rate_per_kg_grade_b' => $rB,
                'rate_per_kg_grade_c' => $rC,
                'min_qty_required' => $cfg['min_qty'],
                'max_qty_required' => $cfg['max_qty'],
                'accepted_grade' => 'All',
                'created_at' => $dt,
                'updated_at' => $dt,
            ];
        }
    }
}

// Insert in bulk chunks of 1000
$chunkSize = 1000;
foreach (array_chunk($records, $chunkSize) as $chunk) {
    DB::table('crop_rates')->insert($chunk);
}

echo "Successfully seeded " . count($records) . " market rate records for today (" . Carbon::today()->toDateString() . ") and past 30 days across " . count($allCrops) . " crops and " . count($buyerIds) . " buyers!\n";
