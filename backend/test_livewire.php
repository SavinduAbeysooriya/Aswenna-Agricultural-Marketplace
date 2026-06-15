<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\OfferGoal;
use App\Models\OfferCampaign;
use Illuminate\Support\Facades\DB;

try {
    // 1. Clean up old test records if any
    OfferCampaign::where('code', 'HI_EARN_10')->delete();
    OfferGoal::where('name', 'Active Farmer Milestone')->delete();

    echo "Creating Offer Goal...\n";
    $goal = OfferGoal::create([
        'name' => 'Active Farmer Milestone',
        'description' => 'Target earnings milestone for active farmers',
        'goal_type' => 'total_earnings',
        'target_value' => 100000.00,
        'is_active' => true,
    ]);
    echo "Goal created: ID " . $goal->id . "\n";

    echo "Creating Offer Campaign...\n";
    $campaign = OfferCampaign::create([
        'offer_goal_id' => $goal->id,
        'title' => 'High Earner Reward',
        'code' => 'HI_EARN_10',
        'description' => '10% off for achieving the active farmer milestone',
        'type' => 'percentage',
        'discount_percentage' => 10.00,
        'minimum_completion_count' => 1,
        'valid_from' => now(),
        'valid_until' => now()->addMonth(),
        'is_active' => true,
        'applied_user_role' => 'farmer',
    ]);
    echo "Campaign created: ID " . $campaign->id . "\n";

    // Test Relationships
    echo "Testing relationships...\n";
    $fetchedCampaign = OfferCampaign::with('goal')->where('code', 'HI_EARN_10')->first();
    echo "Fetched Campaign title: " . $fetchedCampaign->title . "\n";
    echo "Fetched Campaign goal name: " . $fetchedCampaign->goal->name . "\n";

    $fetchedGoal = OfferGoal::with('campaigns')->find($goal->id);
    echo "Fetched Goal name: " . $fetchedGoal->name . "\n";
    echo "Fetched Goal campaign count: " . $fetchedGoal->campaigns->count() . "\n";

    // Clean up
    $fetchedCampaign->delete();
    $fetchedGoal->delete();
    echo "All tests passed successfully!\n";

} catch (\Exception $e) {
    echo "TEST FAILED: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
}
