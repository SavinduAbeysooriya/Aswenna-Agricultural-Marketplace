<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\CropRateController;

$buyer = User::where('role', 'like', '%buyer%')->first();

$req = Request::create('/api/crop-rates/13/history?days=30', 'GET');
$req->setUserResolver(fn() => $buyer);

$controller = new CropRateController();
$response = $controller->history($req, 13);

$data = json_decode($response->getContent(), true);

echo "Status: " . $response->getStatusCode() . "\n";
echo "Crop: " . $data['crop']['cropname'] . "\n";
echo "Days: " . $data['days'] . "\n";
echo "Total History Data Points: " . count($data['history']) . "\n\n";

echo "First 5 Daily Price Fluctuation Trajectories:\n";
foreach (array_slice($data['history'], 0, 5) as $h) {
    echo " Date: {$h['date']} | Min A: LKR {$h['min_rate_a']} | Max A: LKR {$h['max_rate_a']} | Avg A: LKR {$h['avg_rate_a']} | Buyers: {$h['total_submissions']}\n";
}

echo "\nLast 5 Daily Price Fluctuation Trajectories (Up to Today):\n";
foreach (array_slice($data['history'], -5) as $h) {
    echo " Date: {$h['date']} | Min A: LKR {$h['min_rate_a']} | Max A: LKR {$h['max_rate_a']} | Avg A: LKR {$h['avg_rate_a']} | Buyers: {$h['total_submissions']}\n";
}
