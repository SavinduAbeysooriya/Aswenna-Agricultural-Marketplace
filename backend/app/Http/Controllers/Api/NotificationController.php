<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class NotificationController extends Controller
{
    /**
     * Fetch all notifications for the authenticated user, automatically generating context-aware notifications.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        // 1. Automatically generate daily market rate notifications based on the farmer's crops
        $this->generateMarketRateNotifications($user);

        // 2. Automatically generate notifications for new bids on the farmer's listings
        $this->generateBidNotifications($user);

        $notifications = Notification::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'notifications' => $notifications
        ]);
    }

    /**
     * Mark all or specific notifications as read.
     */
    public function markAsRead(Request $request)
    {
        $user = $request->user();
        $id = $request->input('id');

        if ($id) {
            Notification::where('user_id', $user->id)
                ->where('id', $id)
                ->update(['read_at' => Carbon::now()]);
        } else {
            Notification::where('user_id', $user->id)
                ->whereNull('read_at')
                ->update(['read_at' => Carbon::now()]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Notifications updated successfully.'
        ]);
    }

    /**
     * Register FCM Push Notification Token.
     */
    public function registerFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = $request->user();
        $user->fcm_token = $request->input('fcm_token');
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'FCM Token registered successfully.'
        ]);
    }

    /**
     * Helper to generate Crop Price notifications based on the farmer's lands and listings
     */
    private function generateMarketRateNotifications($user)
    {
        // Get Crop IDs from farmer's lands
        $landCropIds = DB::table('lands')
            ->join('land_crops', 'lands.id', '=', 'land_crops.land_id')
            ->where('lands.farmer_id', $user->id)
            ->pluck('land_crops.crop_id')
            ->toArray();

        // Get Crop IDs from farmer's harvest listings
        $listingCropIds = DB::table('harvest_listings')
            ->where('farmer_id', $user->id)
            ->pluck('crop_id')
            ->toArray();

        $cropIds = array_unique(array_merge($landCropIds, $listingCropIds));

        if (empty($cropIds)) {
            return;
        }

        // Get the latest rates for these crops
        $rates = DB::table('crop_rates')
            ->join('crops', 'crop_rates.crop_id', '=', 'crops.id')
            ->select('crop_rates.*', 'crops.cropname')
            ->whereIn('crop_rates.crop_id', $cropIds)
            ->orderBy('crop_rates.date_and_time', 'desc')
            ->get();

        foreach ($rates as $rate) {
            $rateDate = Carbon::parse($rate->date_and_time);
            
            // Only generate notifications for rates within the last 3 days
            if ($rateDate->diffInDays(Carbon::now()) > 3) {
                continue;
            }

            // Check if notification already exists for this crop and date
            $exists = Notification::where('user_id', $user->id)
                ->where('type', 'market_rate')
                ->where('title', 'like', '%' . $rate->cropname . '%')
                ->whereDate('created_at', $rateDate->toDateString())
                ->exists();

            if (!$exists) {
                $avgRate = number_format($rate->rate_per_kg_grade_a, 2);
                Notification::create([
                    'user_id' => $user->id,
                    'title' => "Market Price Update: {$rate->cropname}",
                    'message' => "Today's average market rate for Grade A {$rate->cropname} is LKR {$avgRate} per kg. Check the pricing engine for detailed limits.",
                    'type' => 'market_rate',
                    'created_at' => $rateDate->startOfDay()->addHours(8) // Simulated at 8 AM of the rate date
                ]);
            }
        }
    }

    /**
     * Helper to generate notifications for bids placed on the farmer's listings
     */
    private function generateBidNotifications($user)
    {
        // Get all listings for this farmer
        $listings = DB::table('harvest_listings')
            ->where('farmer_id', $user->id)
            ->pluck('id')
            ->toArray();

        if (empty($listings)) {
            return;
        }

        // Get all bids placed on these listings
        $bids = DB::table('harvest_bids')
            ->join('harvest_listings', 'harvest_bids.harvest_listing_id', '=', 'harvest_listings.id')
            ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->join('users', 'harvest_bids.buyer_id', '=', 'users.id')
            ->select('harvest_bids.*', 'crops.cropname', 'users.full_name as buyer_name')
            ->whereIn('harvest_bids.harvest_listing_id', $listings)
            ->get();

        foreach ($bids as $bid) {
            // Check if notification already exists for this bid
            $exists = Notification::where('user_id', $user->id)
                ->where('type', 'bid')
                ->where('message', 'like', '%' . $bid->buyer_name . '%')
                ->where('message', 'like', '%' . number_format($bid->bid_amount_per_unit, 2) . '%')
                ->exists();

            if (!$exists) {
                $price = number_format($bid->bid_amount_per_unit, 2);
                Notification::create([
                    'user_id' => $user->id,
                    'title' => "New Bid Received!",
                    'message' => "{$bid->buyer_name} has placed a bid of LKR {$price} per unit on your {$bid->cropname} listing.",
                    'type' => 'bid',
                    'created_at' => $bid->created_at
                ]);
            }
        }
    }
}
