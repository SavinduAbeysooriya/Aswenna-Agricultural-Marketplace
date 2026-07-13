<?php

namespace App\Services;

use App\Models\User;
use App\Models\OfferCampaign;
use App\Models\UserOfferProgress;
use Illuminate\Support\Facades\DB;

class OfferProgressionService
{
    /**
     * Update progress for a given goal type and user.
     *
     * @param int $userId
     * @param string $goalType
     * @param float $value
     * @param bool $isAbsolute If true, set the value directly instead of incrementing
     */
    public static function updateProgress(int $userId, string $goalType, float $value, bool $isAbsolute = false): void
    {
        $user = User::find($userId);
        if (!$user) {
            return;
        }

        // Decode roles
        $roles = $user->role;
        if (is_string($roles)) {
            $roles = json_decode($roles, true);
        }
        if (!is_array($roles)) {
            $roles = [$roles];
        }

        $now = now();

        // Get all active campaigns for the user's roles that match the goal type
        $campaigns = OfferCampaign::where('is_active', true)
            ->where('valid_from', '<=', $now)
            ->where('valid_until', '>=', $now)
            ->whereIn('applied_user_role', $roles)
            ->whereHas('goal', function ($query) use ($goalType) {
                $query->where('goal_type', $goalType)
                      ->where('is_active', true);
            })
            ->with('goal')
            ->get();

        foreach ($campaigns as $campaign) {
            // Find or create progress record
            $progress = UserOfferProgress::firstOrCreate(
                [
                    'offer_campaign_id' => $campaign->id,
                    'user_id' => $user->id,
                ],
                [
                    'progress_value' => 0,
                    'is_completed' => false,
                    'reward_claimed' => false,
                ]
            );

            if ($progress->is_completed) {
                continue;
            }

            if ($isAbsolute) {
                $progress->progress_value = $value;
            } else {
                $progress->progress_value += $value;
            }

            // Check if goal is met
            $target = (float) $campaign->goal->target_value;
            if ($progress->progress_value >= $target) {
                $progress->is_completed = true;
                $progress->completed_at = $now;
                $progress->notes = "Goal met: reached progress " . $progress->progress_value . " / " . $target;
            } else {
                $progress->notes = "Progress updated to " . $progress->progress_value . " / " . $target;
            }

            $progress->save();
        }
    }

    /**
     * Recalculate average rating progression.
     */
    public static function recalculateRatingProgress(int $userId): void
    {
        $user = User::find($userId);
        if (!$user) {
            return;
        }

        $roles = $user->role;
        if (is_string($roles)) {
            $roles = json_decode($roles, true);
        }
        if (!is_array($roles)) {
            $roles = [$roles];
        }

        $avgRating = 0.0;
        if (in_array('farmer', $roles)) {
            $avgRating = DB::table('buyer_farmer_reviews')->where('farmer_id', $userId)->avg('ratings') ?: 0.0;
        } else {
            $avgRating = DB::table('retailer_customer_delivery_partner_reviews')->where('reviewed_to', $userId)->avg('ratings') ?: 0.0;
        }

        self::updateProgress($userId, 'rating_average', (float)$avgRating, true);
    }

    /**
     * Recalculate total active products listed.
     */
    public static function recalculateProductsProgress(int $userId): void
    {
        $count = DB::table('retailer_products')->where('seller_id', $userId)->where('status', 'active')->count();
        self::updateProgress($userId, 'total_products', (float)$count, true);
    }
}
