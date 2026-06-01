<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HarvestListing;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Exception;

class HarvestListingController extends Controller
{
    /**
     * GET /api/farmer/harvest-listings
     * Get all listings for the authenticated farmer.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $listings = DB::table('harvest_listings')
            ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->where('harvest_listings.farmer_id', $user->id)
            ->select(
                'harvest_listings.*',
                'crops.cropname',
                'crops.image_path as crop_image'
            )
            ->orderByDesc('harvest_listings.created_at')
            ->get()
            ->map(function ($listing) {
                // Decode or format images if required
                return $listing;
            });

        return response()->json([
            'success' => true,
            'listings' => $listings,
        ], 200);
    }

    /**
     * POST /api/farmer/harvest-listings
     * Store a new harvest listing with bounds checks against crop_rates.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'crop_id' => 'required|integer|exists:crops,id',
            'notes' => 'nullable|string|max:1000',
            'grade' => 'required|string|in:A,B,C',
            'available_quantity' => 'required|numeric|min:0.01',
            'unit' => 'required|string|in:kg,g,ton,piece,bunch,dozen,liter',
            'minimum_order_quantity' => 'required|numeric|min:0.01',
            'maximum_order_quantity' => 'required|numeric|min:0.01',
            'price_per_unit' => 'required|numeric|min:0.01',
            'min_bid_price_per_unit' => 'nullable|numeric|min:0.01',
            'harvest_date' => 'required|date',
            'harvest_condition' => 'required|string|max:255',
            'storage_method' => 'nullable|string|max:255',
            'pickup_latitude' => 'nullable|numeric|between:-90,90',
            'pickup_longitude' => 'nullable|numeric|between:-180,180',
            'delivery_available' => 'nullable|boolean',
            'delivery_fee_per_km' => 'nullable|numeric|min:0',
            'max_delivery_distance' => 'nullable|numeric|min:0',
            'available_from_date' => 'required|date',
            'available_to_date' => 'required|date',
            'bidding_start_date_and_time' => 'nullable|date_format:Y-m-d H:i:s',
            'bidding_end_date_and_time' => 'nullable|date_format:Y-m-d H:i:s',
            'image_1' => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
            'image_2' => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
            'image_3' => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
            'image_4' => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $cropId = $request->crop_id;
        $grade = $request->grade;
        $submittedPrice = (float) $request->price_per_unit;
        $today = Carbon::today()->toDateString();

        // Enforce market pricing logic matching the buyer side averages
        $gradeColumn = 'rate_per_kg_grade_' . strtolower($grade);

        $avgRow = DB::table('crop_rates')
            ->where('crop_id', $cropId)
            ->whereDate('date_and_time', $today)
            ->select(DB::raw("AVG($gradeColumn) as avg_rate"))
            ->first();

        $todayAvg = $avgRow ? $avgRow->avg_rate : null;

        if ($todayAvg !== null && $todayAvg > 0) {
            $minAllowed = round($todayAvg * 0.95, 2);
            $maxAllowed = round($todayAvg * 1.10, 2);

            if ($submittedPrice < $minAllowed || $submittedPrice > $maxAllowed) {
                return response()->json([
                    'success' => false,
                    'message' => "Your listing price (LKR " . number_format($submittedPrice, 2) . ") for Grade $grade must be within the market limits LKR " . number_format($minAllowed, 2) . " (−5%) and LKR " . number_format($maxAllowed, 2) . " (+10%) based on today's average buyer rate LKR " . number_format($todayAvg, 2) . ".",
                    'min_allowed_price' => $minAllowed,
                    'max_allowed_price' => $maxAllowed,
                    'today_average' => round($todayAvg, 2),
                ], 422);
            }
        }

        DB::beginTransaction();
        try {
            $imagePaths = [];
            for ($i = 1; $i <= 4; $i++) {
                $fileKey = 'image_' . $i;
                if ($request->hasFile($fileKey)) {
                    $imagePaths[$fileKey] = $request->file($fileKey)->store('harvest-listings/' . $user->id, 'public');
                } else {
                    $imagePaths[$fileKey] = null;
                }
            }

            $harvestListing = HarvestListing::create(array_merge([
                'farmer_id' => $user->id,
                'crop_id' => $request->crop_id,
                'date_and_time' => Carbon::now(),
                'notes' => $request->notes,
                'grade' => $request->grade,
                'available_quantity' => $request->available_quantity,
                'unit' => $request->unit,
                'minimum_order_quantity' => $request->minimum_order_quantity,
                'maximum_order_quantity' => $request->maximum_order_quantity,
                'price_per_unit' => $request->price_per_unit,
                'min_bid_price_per_unit' => $request->min_bid_price_per_unit,
                'harvest_date' => $request->harvest_date,
                'harvest_condition' => $request->harvest_condition,
                'storage_method' => $request->storage_method,
                'pickup_latitude' => $request->pickup_latitude,
                'pickup_longitude' => $request->pickup_longitude,
                'delivery_available' => $request->boolean('delivery_available', false),
                'delivery_fee_per_km' => $request->delivery_fee_per_km,
                'max_delivery_distance' => $request->max_delivery_distance,
                'available_from_date' => $request->available_from_date,
                'available_to_date' => $request->available_to_date,
                'bidding_start_date_and_time' => $request->bidding_start_date_and_time,
                'bidding_end_date_and_time' => $request->bidding_end_date_and_time,
                'status' => 'active',
            ], $imagePaths));

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Harvest listing published successfully.',
                'listing' => $harvestListing,
            ], 201);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to publish harvest listing.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/farmer/harvest-listings/{id}
     * Get a single listing detail (Farmer and Buyer viewable).
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();

        $listing = DB::table('harvest_listings')
            ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->join('users as farmers', 'harvest_listings.farmer_id', '=', 'farmers.id')
            ->where('harvest_listings.id', $id)
            ->select(
                'harvest_listings.*',
                'crops.cropname',
                'crops.image_path as crop_image',
                'farmers.full_name as farmer_name',
                'farmers.phone_number as farmer_phone'
            )
            ->first();

        if (!$listing) {
            return response()->json([
                'success' => false,
                'message' => 'Harvest listing not found.',
            ], 404);
        }

        // Get bids for this listing
        $bidsQuery = DB::table('harvest_bids')
            ->join('users as buyers', 'harvest_bids.buyer_id', '=', 'buyers.id')
            ->where('harvest_bids.harvest_listing_id', $id);

        if ($user->id === $listing->farmer_id) {
            $bids = $bidsQuery->select('harvest_bids.*', 'buyers.full_name as buyer_name', 'buyers.phone_number as buyer_phone')
                ->orderByDesc('harvest_bids.bid_amount_per_unit')
                ->get();
        } else {
            $bids = $bidsQuery->select(
                'harvest_bids.id',
                'harvest_bids.harvest_listing_id',
                'harvest_bids.bid_amount_per_unit',
                'harvest_bids.bid_quantity_unit',
                'harvest_bids.status',
                'harvest_bids.created_at',
                DB::raw("CASE WHEN harvest_bids.buyer_id = {$user->id} THEN buyers.full_name ELSE 'Other Buyer' END as buyer_name"),
                DB::raw("CASE WHEN harvest_bids.buyer_id = {$user->id} THEN 1 ELSE 0 END as is_own_bid")
            )
                ->orderByDesc('harvest_bids.bid_amount_per_unit')
                ->get();
        }

        return response()->json([
            'success' => true,
            'listing' => $listing,
            'bids' => $bids,
        ], 200);
    }

    /**
     * POST /api/farmer/harvest-listings/{id}
     * Update an existing harvest listing (Farmer facing).
     */
    public function update(Request $request, $id)
    {
        $user = $request->user();

        $listing = HarvestListing::where('id', $id)
            ->where('farmer_id', $user->id)
            ->first();

        if (!$listing) {
            return response()->json([
                'success' => false,
                'message' => 'Harvest listing not found.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'crop_id' => 'required|integer|exists:crops,id',
            'notes' => 'nullable|string|max:1000',
            'grade' => 'required|string|in:A,B,C',
            'available_quantity' => 'required|numeric|min:0.01',
            'unit' => 'required|string|in:kg,g,ton,piece,bunch,dozen,liter',
            'minimum_order_quantity' => 'required|numeric|min:0.01',
            'maximum_order_quantity' => 'required|numeric|min:0.01',
            'price_per_unit' => 'required|numeric|min:0.01',
            'min_bid_price_per_unit' => 'nullable|numeric|min:0.01',
            'harvest_date' => 'required|date',
            'harvest_condition' => 'required|string|max:255',
            'storage_method' => 'nullable|string|max:255',
            'pickup_latitude' => 'nullable|numeric|between:-90,90',
            'pickup_longitude' => 'nullable|numeric|between:-180,180',
            'delivery_available' => 'nullable|boolean',
            'delivery_fee_per_km' => 'nullable|numeric|min:0',
            'max_delivery_distance' => 'nullable|numeric|min:0',
            'available_from_date' => 'required|date',
            'available_to_date' => 'required|date',
            'bidding_start_date_and_time' => 'nullable|date_format:Y-m-d H:i:s',
            'bidding_end_date_and_time' => 'nullable|date_format:Y-m-d H:i:s',
            'image_1' => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
            'image_2' => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
            'image_3' => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
            'image_4' => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $cropId = $request->crop_id;
        $grade = $request->grade;
        $submittedPrice = (float) $request->price_per_unit;
        $today = Carbon::today()->toDateString();

        // Enforce pricing average validation checks
        $gradeColumn = 'rate_per_kg_grade_' . strtolower($grade);
        $avgRow = DB::table('crop_rates')
            ->where('crop_id', $cropId)
            ->whereDate('date_and_time', $today)
            ->select(DB::raw("AVG($gradeColumn) as avg_rate"))
            ->first();

        $todayAvg = $avgRow ? $avgRow->avg_rate : null;

        if ($todayAvg !== null && $todayAvg > 0) {
            $minAllowed = round($todayAvg * 0.95, 2);
            $maxAllowed = round($todayAvg * 1.10, 2);

            if ($submittedPrice < $minAllowed || $submittedPrice > $maxAllowed) {
                return response()->json([
                    'success' => false,
                    'message' => "Your listing price (LKR " . number_format($submittedPrice, 2) . ") for Grade $grade must be within the market limits LKR " . number_format($minAllowed, 2) . " (−5%) and LKR " . number_format($maxAllowed, 2) . " (+10%) based on today's average buyer rate LKR " . number_format($todayAvg, 2) . ".",
                    'min_allowed_price' => $minAllowed,
                    'max_allowed_price' => $maxAllowed,
                    'today_average' => round($todayAvg, 2),
                ], 422);
            }
        }

        DB::beginTransaction();
        try {
            $imagePaths = [];
            $keepImages = $request->input('keep_images', []);
            if (!is_array($keepImages)) {
                $keepImages = json_decode($keepImages, true) ?: [];
            }

            for ($i = 1; $i <= 4; $i++) {
                $fileKey = 'image_' . $i;
                if ($request->hasFile($fileKey)) {
                    $imagePaths[$fileKey] = $request->file($fileKey)->store('harvest-listings/' . $user->id, 'public');
                } else {
                    if (in_array($fileKey, $keepImages) || in_array($listing->$fileKey, $keepImages)) {
                        $imagePaths[$fileKey] = $listing->$fileKey;
                    } else {
                        $imagePaths[$fileKey] = null;
                    }
                }
            }

            $listing->update(array_merge([
                'crop_id' => $request->crop_id,
                'notes' => $request->notes,
                'grade' => $request->grade,
                'available_quantity' => $request->available_quantity,
                'unit' => $request->unit,
                'minimum_order_quantity' => $request->minimum_order_quantity,
                'maximum_order_quantity' => $request->maximum_order_quantity,
                'price_per_unit' => $request->price_per_unit,
                'min_bid_price_per_unit' => $request->min_bid_price_per_unit,
                'harvest_date' => $request->harvest_date,
                'harvest_condition' => $request->harvest_condition,
                'storage_method' => $request->storage_method,
                'pickup_latitude' => $request->pickup_latitude,
                'pickup_longitude' => $request->pickup_longitude,
                'delivery_available' => $request->boolean('delivery_available', false),
                'delivery_fee_per_km' => $request->delivery_fee_per_km,
                'max_delivery_distance' => $request->max_delivery_distance,
                'available_from_date' => $request->available_from_date,
                'available_to_date' => $request->available_to_date,
                'bidding_start_date_and_time' => $request->bidding_start_date_and_time,
                'bidding_end_date_and_time' => $request->bidding_end_date_and_time,
            ], $imagePaths));

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Harvest listing updated successfully.',
                'listing' => $listing,
            ], 200);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to update harvest listing.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/buyer/harvest-listings
     * Get all active harvest listings prioritized by buyer's daily crop rates updated list.
     */
    public function buyerIndex(Request $request)
    {
        $user = $request->user();
        $today = Carbon::today()->toDateString();

        // 1. Get crops this buyer updated today in crop_rates
        $buyerCropIds = DB::table('crop_rates')
            ->where('buyer_id', $user->id)
            ->whereDate('date_and_time', $today)
            ->pluck('crop_id')
            ->toArray();

        // 2. Query all active listings
        $listings = DB::table('harvest_listings')
            ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->join('users as farmers', 'harvest_listings.farmer_id', '=', 'farmers.id')
            ->where('harvest_listings.status', 'active')
            ->select(
                'harvest_listings.*',
                'crops.cropname',
                'crops.image_path as crop_image',
                'farmers.full_name as farmer_name'
            )
            ->orderByDesc('harvest_listings.created_at')
            ->get();

        // 3. Prioritize matching crops
        if (!empty($buyerCropIds)) {
            $listings = $listings->sortByDesc(function ($listing) use ($buyerCropIds) {
                return in_array($listing->crop_id, $buyerCropIds) ? 1 : 0;
            })->values();
        }

        return response()->json([
            'success' => true,
            'listings' => $listings,
            'buyer_rate_crop_ids' => $buyerCropIds,
        ], 200);
    }
}
