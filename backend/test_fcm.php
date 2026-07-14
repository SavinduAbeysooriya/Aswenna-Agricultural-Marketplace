<?php
require 'vendor/autoload.php';

$app = require 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Services\FcmService;

echo "Instantiating FcmService...\n";
$fcm = new FcmService();

// Get the user with fcm_token
$user = \App\Models\User::whereNotNull('fcm_token')->first();

if (!$user) {
    echo "No user has FCM token registered. Please open the app to register.\n";
    exit;
}

echo "Found user: {$user->full_name} (token: ...".substr($user->fcm_token, -12).")\n";
echo "Sending test push notification...\n";

$result = $fcm->sendPush(
    $user->fcm_token,
    'Aswenna Test Push',
    'This is a live Firebase Cloud Messaging test!',
    ['type' => 'admin_push']
);

echo $result ? "SUCCESS - Push sent!\n" : "FAILED - Check logs/laravel.log\n";
