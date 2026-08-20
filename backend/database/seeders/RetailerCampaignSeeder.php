<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class RetailerCampaignSeeder extends Seeder
{
    public function run(): void
    {
        $retailer = DB::table('users')->where('role', 'like', '%retail_seller%')->orWhere('role', 'like', '%retailer%')->first();
        $retailerId = $retailer ? $retailer->id : 1;

        $goal = DB::table('offer_goals')->first();
        $goalId = $goal ? $goal->id : 1;

        DB::table('offer_campaigns')->updateOrInsert(
            [
                'code' => 'WEEKEND-HARVEST-15',
            ],
            [
                'retailer_id' => $retailerId,
                'offer_goal_id' => $goalId,
                'title' => 'Weekend Harvest Festival',
                'description' => 'Special 15% OFF Flash Sale discount on all Fresh Vegetables for 3 days!',
                'type' => 'percentage',
                'discount_percentage' => 15.00,
                'max_discount_amount' => 1500.00,
                'minimum_completion_count' => 1,
                'valid_from' => Carbon::now(),
                'valid_until' => Carbon::now()->addDays(3),
                'usage_limit_per_user' => 3,
                'total_usage_limit' => 500,
                'is_active' => true,
                'status' => 'pending_admin_approval',
                'target_category' => 'Fresh Vegetables',
                'applied_user_role' => 'customer',
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );
    }
}
