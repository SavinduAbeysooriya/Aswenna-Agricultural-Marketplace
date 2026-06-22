<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ConfirmedBid;
use App\Models\HarvestBid;
use App\Models\HarvestListing;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Exception;

class ConfirmedBidController extends Controller
{
    /**
     * POST /api/farmer/confirmed-bids/{bidId}/confirm
     * Farmer confirms an accepted bid → creates a confirmed_bids record.
     */
    public function confirmBid(Request $request, $bidId)
    {
        $user = $request->user();

        $bid = HarvestBid::where('id', $bidId)->first();
        if (!$bid) {
            return response()->json(['success' => false, 'message' => 'Bid not found.'], 404);
        }

        if ($bid->status !== 'accepted') {
            return response()->json(['success' => false, 'message' => 'Only accepted bids can be confirmed.'], 400);
        }

        $listing = HarvestListing::where('id', $bid->harvest_listing_id)
            ->where('farmer_id', $user->id)
            ->first();

        if (!$listing) {
            return response()->json(['success' => false, 'message' => 'Unauthorized.'], 403);
        }

        // Check if already confirmed
        $existing = ConfirmedBid::where('bid_id', $bidId)->first();
        if ($existing) {
            return response()->json([
                'success' => true,
                'message' => 'Bid is already confirmed.',
                'confirmed_bid' => $existing,
            ], 200);
        }

        DB::beginTransaction();
        try {
            $totalAmount = (float)$bid->bid_amount_per_unit * (float)$bid->bid_quantity_unit;

            $confirmedBid = ConfirmedBid::create([
                'buyer_id'           => $bid->buyer_id,
                'farmer_id'          => $user->id,
                'harvest_listing_id' => $bid->harvest_listing_id,
                'bid_id'             => $bid->id,
                'notes'              => $bid->notes,
                'total_amount'       => $totalAmount,
                'payment_status'     => 'unpaid',
            ]);

            DB::commit();

            return response()->json([
                'success'       => true,
                'message'       => 'Deal confirmed successfully. Buyer can now proceed with payment.',
                'confirmed_bid' => $confirmedBid,
            ], 201);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Failed to confirm bid.', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * GET /api/farmer/confirmed-bids
     * Get all confirmed bids for the authenticated farmer.
     */
    public function getFarmerConfirmedBids(Request $request)
    {
        $user = $request->user();

        $confirmedBids = DB::table('confirmed_bids')
            ->leftJoin('harvest_bids', 'confirmed_bids.bid_id', '=', 'harvest_bids.id')
            ->leftJoin('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
            ->leftJoin('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->leftJoin('users as buyers', 'confirmed_bids.buyer_id', '=', 'buyers.id')
            ->where('confirmed_bids.farmer_id', $user->id)
            ->select(
                'confirmed_bids.*',
                'harvest_bids.bid_amount_per_unit',
                'harvest_bids.bid_quantity_unit',
                'harvest_listings.unit',
                'crops.cropname',
                'crops.image_path as crop_image',
                'buyers.full_name as buyer_name',
                'buyers.phone_number as buyer_phone'
            )
            ->orderByDesc('confirmed_bids.created_at')
            ->get();

        return response()->json(['success' => true, 'confirmed_bids' => $confirmedBids], 200);
    }

    /**
     * GET /api/buyer/confirmed-bids
     * Get all confirmed bids for the authenticated buyer.
     */
    public function getBuyerConfirmedBids(Request $request)
    {
        $user = $request->user();

        $confirmedBids = DB::table('confirmed_bids')
            ->leftJoin('harvest_bids', 'confirmed_bids.bid_id', '=', 'harvest_bids.id')
            ->leftJoin('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
            ->leftJoin('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->leftJoin('users as farmers', 'confirmed_bids.farmer_id', '=', 'farmers.id')
            ->where('confirmed_bids.buyer_id', $user->id)
            ->select(
                'confirmed_bids.*',
                'harvest_bids.bid_amount_per_unit',
                'harvest_bids.bid_quantity_unit',
                'harvest_listings.unit',
                'harvest_listings.pickup_latitude',
                'harvest_listings.pickup_longitude',
                'crops.cropname',
                'crops.image_path as crop_image',
                'farmers.full_name as farmer_name',
                'farmers.phone_number as farmer_phone',
                'farmers.profile_picture_path as farmer_photo'
            )
            ->orderByDesc('confirmed_bids.created_at')
            ->get();

        // Check which confirmed bids have existing reviews
        $reviewedBidIds = DB::table('buyer_farmer_reviews')
            ->where('reviewed_by', $user->id)
            ->pluck('confirmed_bid_id')
            ->toArray();

        $confirmedBids = $confirmedBids->map(function ($bid) use ($reviewedBidIds) {
            $bid->has_review = in_array($bid->id, $reviewedBidIds);
            return $bid;
        });

        return response()->json(['success' => true, 'confirmed_bids' => $confirmedBids], 200);
    }
}
