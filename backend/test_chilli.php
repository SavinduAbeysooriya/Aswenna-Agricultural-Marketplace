<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\CropRateController;

$buyer = User::where('role', 'like', '%buyer%')->first();

$req = Request::create('/api/crop-rates/13', 'GET');
$req->setUserResolver(fn() => $buyer);

$controller = new CropRateController();
$response = $controller->show($req, 13);

$data = json_decode($response->getContent(), true);
echo "Status: " . $response->getStatusCode() . "\n";
print_r($data);
