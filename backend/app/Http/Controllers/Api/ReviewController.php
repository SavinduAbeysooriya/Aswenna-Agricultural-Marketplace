<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\ConfirmedBid;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Exception;

class ReviewController extends Controller
{
    /**
     * POST /api/confirmed-bids/{confirmedBidId}/reviews
     * Submit a review for a completed bid transaction.
     */
    public function submitReview(Request $request, $confirmedBidId)
    {
        $user = $request->user();

        $confirmedBid = ConfirmedBid::find($confirmedBidId);
        if (!$confirmedBid) {
            return response()->json(['success' => false, 'message' => 'Confirmed bid not found.'], 404);
        }

        // Only the buyer or farmer of this bid can review
        if ($confirmedBid->buyer_id !== $user->id && $confirmedBid->farmer_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized.'], 403);
        }

        // Check if user has already reviewed
        $existing = Review::where('confirmed_bid_id', $confirmedBidId)
            ->where('reviewed_by', $user->id)
            ->first();

        if ($existing) {
            return response()->json(['success' => false, 'message' => 'You have already reviewed this transaction.'], 400);
        }

        $validator = Validator::make($request->all(), [
            'ratings'  => 'required|integer|min:1|max:5',
            'feedback' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        try {
            // Determine review subject: if reviewer is buyer → reviewing the farmer, and vice versa
            $reviewedFarmerId = $confirmedBid->farmer_id;
            $reviewedBuyerId  = $confirmedBid->buyer_id;

            $review = Review::create([
                'buyer_id'         => $reviewedBuyerId,
                'farmer_id'        => $reviewedFarmerId,
                'confirmed_bid_id' => $confirmedBidId,
                'feedback'         => $request->feedback ?? '',
                'ratings'          => $request->ratings,
                'reviewed_by'      => $user->id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Review submitted successfully. Thank you!',
                'review'  => $review,
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to submit review.',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/farmers/{farmerId}/reviews
     * Get all reviews for a specific farmer.
     */
    public function getFarmerReviews(Request $request, $farmerId)
    {
        $reviews = DB::table('buyer_farmer_reviews')
            ->join('users as reviewers', 'buyer_farmer_reviews.reviewed_by', '=', 'reviewers.id')
            ->where('buyer_farmer_reviews.farmer_id', $farmerId)
            ->select(
                'buyer_farmer_reviews.*',
                'reviewers.full_name as reviewer_name',
                'reviewers.profile_picture_path as reviewer_photo'
            )
            ->orderByDesc('buyer_farmer_reviews.created_at')
            ->get();

        $avgRating = $reviews->avg('ratings');

        return response()->json([
            'success'     => true,
            'reviews'     => $reviews,
            'avg_rating'  => round($avgRating, 1),
            'total_count' => $reviews->count(),
        ], 200);
    }
}
