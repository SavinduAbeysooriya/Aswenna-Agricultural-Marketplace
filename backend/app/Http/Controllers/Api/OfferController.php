<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OfferCampaign;
use App\Models\UserOfferProgress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OfferController extends Controller
{
    /**
     * GET /api/offers
     * Retrieve all active campaigns matching the user's role, including progress details.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Decode roles
        $roles = $user->role;
        if (is_string($roles)) {
            $roles = json_decode($roles, true);
        }
        if (!is_array($roles)) {
            $roles = [$roles];
        }

        $now = now();

        // Get campaigns for the user's role
        $campaigns = OfferCampaign::where('is_active', true)
            ->where('valid_from', '<=', $now)
            ->where('valid_until', '>=', $now)
            ->whereIn('applied_user_role', $roles)
            ->with('goal')
            ->get();

        $offers = $campaigns->map(function ($campaign) use ($user) {
            $progress = UserOfferProgress::where('offer_campaign_id', $campaign->id)
                ->where('user_id', $user->id)
                ->first();

            return [
                'campaign_id' => $campaign->id,
                'title' => $campaign->title,
                'code' => $campaign->code,
                'description' => $campaign->description,
                'type' => $campaign->type,
                'discount_percentage' => $campaign->discount_percentage,
                'discount_amount' => $campaign->discount_amount,
                'max_discount_amount' => $campaign->max_discount_amount,
                'applied_user_role' => $campaign->applied_user_role,
                'valid_until' => $campaign->valid_until->toIso8601String(),
                'goal' => [
                    'name' => $campaign->goal->name,
                    'description' => $campaign->goal->description,
                    'goal_type' => $campaign->goal->goal_type,
                    'target_value' => (float)$campaign->goal->target_value,
                ],
                'progress' => [
                    'progress_id' => $progress ? $progress->id : null,
                    'current_value' => $progress ? (float)$progress->progress_value : 0.0,
                    'is_completed' => $progress ? (bool)$progress->is_completed : false,
                    'completed_at' => $progress && $progress->completed_at ? $progress->completed_at->toIso8601String() : null,
                    'reward_claimed' => $progress ? (bool)$progress->reward_claimed : false,
                    'reward_claimed_at' => $progress && $progress->reward_claimed_at ? $progress->reward_claimed_at->toIso8601String() : null,
                    'notes' => $progress ? $progress->notes : 'No progress made yet.',
                ]
            ];
        });

        return response()->json([
            'success' => true,
            'offers' => $offers
        ], 200);
    }

    /**
     * POST /api/offers/{id}/claim
     * Claim completed offer rewards (wallet cash bonus deposit).
     */
    public function claim(Request $request, $progressId)
    {
        $user = $request->user();

        $progress = UserOfferProgress::where('id', $progressId)
            ->where('user_id', $user->id)
            ->with('campaign')
            ->first();

        if (!$progress) {
            return response()->json([
                'success' => false,
                'message' => 'Offer progress record not found.'
            ], 404);
        }

        if (!$progress->is_completed) {
            return response()->json([
                'success' => false,
                'message' => 'Goal not yet met. Keep going!'
            ], 400);
        }

        if ($progress->reward_claimed) {
            return response()->json([
                'success' => false,
                'message' => 'Reward has already been claimed.'
            ], 400);
        }

        $campaign = $progress->campaign;

        // If the reward is fixed_amount, deposit to wallet
        if ($campaign->type === 'fixed_amount') {
            $bonus = (float) $campaign->discount_amount;

            DB::beginTransaction();
            try {
                // Update wallet balance
                $wallet = DB::table('user_wallets')->where('user_id', $user->id)->first();
                if ($wallet) {
                    $before = (float)$wallet->available_balance;
                    $after = $before + $bonus;
                    $totalEarned = (float)$wallet->total_earned + $bonus;

                    DB::table('user_wallets')
                        ->where('user_id', $user->id)
                        ->update([
                            'available_balance' => $after,
                            'total_earned' => $totalEarned,
                            'last_updated_at' => now(),
                            'updated_at' => now(),
                        ]);
                } else {
                    $before = 0.00;
                    $after = $bonus;

                    DB::table('user_wallets')->insert([
                        'user_id' => $user->id,
                        'available_balance' => $after,
                        'pending_balance' => 0.00,
                        'total_earned' => $after,
                        'total_withdrawn' => 0.00,
                        'last_updated_at' => now(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                // Record transaction
                DB::table('wallet_transactions')->insert([
                    'user_id' => $user->id,
                    'amount' => $bonus,
                    'balance_before' => $before,
                    'balance_after' => $after,
                    'transaction_type' => 'other',
                    'description' => "Reward Bonus: completed campaign '{$campaign->title}'",
                    'status' => 'completed',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // Mark progress claimed
                $progress->update([
                    'reward_claimed' => true,
                    'reward_claimed_at' => now(),
                    'notes' => 'Reward claimed: deposited LKR ' . $bonus . ' into user wallet.',
                ]);

                DB::commit();

                return response()->json([
                    'success' => true,
                    'message' => "Successfully claimed! LKR {$bonus} has been added to your wallet balance.",
                    'progress' => $progress
                ], 200);

            } catch (\Exception $e) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to deposit bonus: ' . $e->getMessage()
                ], 500);
            }
        }

        // Coupon based (percentage or free shipping)
        return response()->json([
            'success' => false,
            'message' => 'This campaign grants a discount coupon code. Simply copy and enter the code during checkout to apply.'
        ], 400);
    }
}
