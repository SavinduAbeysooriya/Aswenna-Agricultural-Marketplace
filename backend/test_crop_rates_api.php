<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\CropRateController;

$buyer = User::where('role', 'like', '%buyer%')->first();

$req = Request::create('/api/crop-rates', 'GET');
$req->setUserResolver(fn() => $buyer);

$controller = new CropRateController();
$response = $controller->index($req);

$data = json_decode($response->getContent(), true);

echo "Status: " . $response->getStatusCode() . "\n";
echo "Date: " . $data['date'] . "\n";
echo "Crops returned: " . count($data['crops']) . "\n\n";

foreach (array_slice($data['crops'], 0, 10) as $c) {
    echo "Crop: {$c['cropname']} (ID: {$c['id']})\n";
    echo "  - Submissions today: {$c['total_submissions']}\n";
    echo "  - Avg Grade A: LKR {$c['avg_rate_grade_a']}\n";
    echo "  - Avg Grade B: LKR {$c['avg_rate_grade_b']}\n";
    echo "  - Avg Grade C: LKR {$c['avg_rate_grade_c']}\n";
    echo "  - Has submitted today: " . ($c['has_submitted_today'] ? 'YES' : 'NO') . "\n";
    echo "----------------------------------------\n";
}
