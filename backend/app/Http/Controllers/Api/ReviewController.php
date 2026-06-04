<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\ConfirmedBid;
use App\Models\CustomerOrder;
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

    /**
     * POST /api/orders/{orderId}/reviews
     * Submit a review for a user (Retailer or Delivery Partner) associated with a retail order.
     */
    public function submitOrderReview(Request $request, $orderId)
    {
        $user = $request->user();

        $order = CustomerOrder::with(['items', 'deliveryPartner'])->find($orderId);
        if (!$order) {
            return response()->json(['success' => false, 'message' => 'Order not found.'], 404);
        }

        // The order must be delivered or completed
        if (!in_array($order->order_status, ['delivered', 'completed'])) {
            return response()->json([
                'success' => false,
                'message' => 'Reviews can only be submitted after the order is delivered or completed.'
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'reviewed_to' => 'required|exists:users,id',
            'ratings'     => 'required|integer|min:1|max:5',
            'feedback'    => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $reviewedToId = $request->reviewed_to;
        $ratings = $request->ratings;
        $feedback = $request->feedback ?? '';

        if ($reviewedToId == $user->id) {
            return response()->json(['success' => false, 'message' => 'You cannot review yourself.'], 400);
        }

        // Find all retailer IDs associated with this order
        $retailerIds = $order->items->pluck('retailer_id')->unique()->toArray();
        $deliveryPartnerId = $order->delivery_partner_id;
        $customerId = $order->customer_id;

        $isCustomer = ($user->id == $customerId);
        $isRetailer = in_array($user->id, $retailerIds);

        if (!$isCustomer && !$isRetailer) {
            return response()->json(['success' => false, 'message' => 'You are not authorized to review this order.'], 403);
        }

        if ($isCustomer) {
            // Customer can review Retailer or Delivery Partner
            $isValidTarget = (in_array($reviewedToId, $retailerIds) || ($deliveryPartnerId && $reviewedToId == $deliveryPartnerId));
            if (!$isValidTarget) {
                return response()->json(['success' => false, 'message' => 'Invalid review target user for this order.'], 400);
            }
        } elseif ($isRetailer) {
            // Retailer can only review the Delivery Partner
            $isValidTarget = ($deliveryPartnerId && $reviewedToId == $deliveryPartnerId);
            if (!$isValidTarget) {
                return response()->json(['success' => false, 'message' => 'Retailers can only submit reviews for the delivery partner of this order.'], 400);
            }
        }

        // Check if review already exists
        $existing = DB::table('retailer_customer_delivery_partner_reviews')
            ->where('order_id', $orderId)
            ->where('reviewed_by', $user->id)
            ->where('reviewed_to', $reviewedToId)
            ->first();

        if ($existing) {
            return response()->json(['success' => false, 'message' => 'You have already submitted a review for this recipient on this order.'], 400);
        }

        try {
            $reviewId = DB::table('retailer_customer_delivery_partner_reviews')->insertGetId([
                'order_id'    => $orderId,
                'reviewed_by' => $user->id,
                'reviewed_to' => $reviewedToId,
                'ratings'     => $ratings,
                'feedback'    => $feedback,
                'created_at'  => now(),
                'updated_at'  => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Review submitted successfully!',
                'review'  => [
                    'id'          => $reviewId,
                    'order_id'    => $orderId,
                    'reviewed_by' => $user->id,
                    'reviewed_to' => $reviewedToId,
                    'ratings'     => $ratings,
                    'feedback'    => $feedback,
                ]
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
     * GET /api/orders/{orderId}/reviews
     * Get reviews submitted for a specific order.
     */
    public function getOrderReviews(Request $request, $orderId)
    {
        $reviews = DB::table('retailer_customer_delivery_partner_reviews')
            ->where('order_id', $orderId)
            ->get();

        return response()->json([
            'success' => true,
            'reviews' => $reviews,
        ], 200);
    }
}
