<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HarvestBid;
use App\Models\HarvestListing;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;
use Exception;

class HarvestBidController extends Controller
{
    /**
     * POST /api/harvest-listings/{id}/bids
     * Place a new bid on a harvest listing (Buyer facing).
     */
    public function placeBid(Request $request, $listingId)
    {
        $user = $request->user();

        $listing = HarvestListing::where('id', $listingId)->first();
        if (!$listing) {
            return response()->json([
                'success' => false,
                'message' => 'Harvest listing not found.',
            ], 404);
        }

        if ($listing->status !== 'active') {
            return response()->json([
                'success' => false,
                'message' => 'This harvest listing is not open for bidding.',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'bid_amount_per_unit' => 'required|numeric|min:0.01',
            'bid_quantity_unit' => 'required|numeric|min:0.01',
            'notes' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $bidAmount = (float) $request->bid_amount_per_unit;
        $bidQty = (float) $request->bid_quantity_unit;

        // Verify bid amount is >= min_bid_price_per_unit (if set)
        if ($listing->min_bid_price_per_unit !== null) {
            $minBid = (float) $listing->min_bid_price_per_unit;
            if ($bidAmount < $minBid) {
                return response()->json([
                    'success' => false,
                    'message' => "Your bid amount (LKR " . number_format($bidAmount, 2) . ") must be at least the minimum bid price (LKR " . number_format($minBid, 2) . ").",
                ], 422);
            }
        } else {
            // If no minimum bid is specified, it must be >= direct price per unit or positive.
            $directPrice = (float) $listing->price_per_unit;
            if ($bidAmount <= 0) {
                return response()->json([
                    'success' => false,
                    'message' => "Bid amount must be positive.",
                ], 422);
            }
        }

        // Verify quantity constraints
        $minQty = (float) $listing->minimum_order_quantity;
        $maxQty = (float) $listing->maximum_order_quantity;
        $availQty = (float) $listing->available_quantity;

        if ($bidQty < $minQty) {
            return response()->json([
                'success' => false,
                'message' => "Your bid quantity ($bidQty $listing->unit) is below the minimum order quantity ($minQty $listing->unit).",
            ], 422);
        }

        if ($bidQty > $maxQty) {
            return response()->json([
                'success' => false,
                'message' => "Your bid quantity ($bidQty $listing->unit) exceeds the maximum order quantity ($maxQty $listing->unit).",
            ], 422);
        }

        if ($bidQty > $availQty) {
            return response()->json([
                'success' => false,
                'message' => "Your bid quantity ($bidQty $listing->unit) exceeds the available quantity ($availQty $listing->unit).",
            ], 422);
        }

        DB::beginTransaction();
        try {
            // Place/Update bid for this buyer on this listing
            $existingBid = HarvestBid::where('buyer_id', $user->id)
                ->where('harvest_listing_id', $listingId)
                ->where('status', 'pending')
                ->first();

            if ($existingBid) {
                $existingBid->update([
                    'bid_amount_per_unit' => $bidAmount,
                    'bid_quantity_unit' => $bidQty,
                    'notes' => $request->notes,
                ]);
                $bid = $existingBid;
                $message = 'Your bid has been updated successfully.';
            } else {
                $bid = HarvestBid::create([
                    'buyer_id' => $user->id,
                    'harvest_listing_id' => $listingId,
                    'bid_amount_per_unit' => $bidAmount,
                    'bid_quantity_unit' => $bidQty,
                    'notes' => $request->notes,
                    'status' => 'pending',
                ]);
                $message = 'Your bid has been placed successfully.';
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => $message,
                'bid' => $bid,
            ], 201);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to place bid.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/farmer/bids
     * Get all bids received on the authenticated farmer's harvest listings.
     */
    public function indexFarmerBids(Request $request)
    {
        $user = $request->user();

        $bids = DB::table('harvest_bids')
            ->join('harvest_listings', 'harvest_bids.harvest_listing_id', '=', 'harvest_listings.id')
            ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->join('users as buyers', 'harvest_bids.buyer_id', '=', 'buyers.id')
            ->where('harvest_listings.farmer_id', $user->id)
            ->select(
                'harvest_bids.*',
                'harvest_listings.available_quantity',
                'harvest_listings.unit',
                'harvest_listings.price_per_unit',
                'crops.cropname',
                'crops.image_path as crop_image',
                'buyers.name as buyer_name'
            )
            ->orderByDesc('harvest_bids.created_at')
            ->get();

        return response()->json([
            'success' => true,
            'bids' => $bids,
        ], 200);
    }

    /**
     * POST /api/farmer/bids/{id}/accept
     * Accept a pending bid (Farmer facing).
     */
    public function acceptBid(Request $request, $bidId)
    {
        $user = $request->user();

        $bid = HarvestBid::where('id', $bidId)->first();
        if (!$bid) {
            return response()->json([
                'success' => false,
                'message' => 'Bid not found.',
            ], 404);
        }

        $listing = HarvestListing::where('id', $bid->harvest_listing_id)
            ->where('farmer_id', $user->id)
            ->first();

        if (!$listing) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized or listing not found.',
            ], 403);
        }

        if ($bid->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'This bid is not pending.',
            ], 400);
        }

        DB::beginTransaction();
        try {
            // Update accepted bid
            $bid->update(['status' => 'accepted']);

            // Reject all other pending bids for this listing
            HarvestBid::where('harvest_listing_id', $listing->id)
                ->where('id', '!=', $bid->id)
                ->where('status', 'pending')
                ->update(['status' => 'rejected']);

            // Set listing to sold_out
            $listing->update(['status' => 'sold_out']);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Bid accepted and listing marked as sold out.',
                'bid' => $bid,
            ], 200);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to accept bid.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/farmer/bids/{id}/reject
     * Reject a pending bid (Farmer facing).
     */
    public function rejectBid(Request $request, $bidId)
    {
        $user = $request->user();

        $bid = HarvestBid::where('id', $bidId)->first();
        if (!$bid) {
            return response()->json([
                'success' => false,
                'message' => 'Bid not found.',
            ], 404);
        }

        $listing = HarvestListing::where('id', $bid->harvest_listing_id)
            ->where('farmer_id', $user->id)
            ->first();

        if (!$listing) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized or listing not found.',
            ], 403);
        }

        if ($bid->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'This bid is not pending.',
            ], 400);
        }

        try {
            $bid->update(['status' => 'rejected']);
            return response()->json([
                'success' => true,
                'message' => 'Bid rejected successfully.',
                'bid' => $bid,
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to reject bid.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
