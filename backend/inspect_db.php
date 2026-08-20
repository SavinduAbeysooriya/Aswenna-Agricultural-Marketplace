<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$buyers = DB::table('users')->where('role', 'like', '%buyer%')->get();
echo "Found " . count($buyers) . " Buyers:\n";
foreach ($buyers as $b) {
    echo " - ID: {$b->id} | Name: {$b->full_name} | Phone: {$b->phone_number} | City: {$b->city}\n";
}

$crops = DB::table('crops')->get();
echo "\nFound " . count($crops) . " Crops:\n";
foreach ($crops as $c) {
    echo " - ID: {$c->id} | Name: {$c->cropname} | Status: {$c->status}\n";
}
