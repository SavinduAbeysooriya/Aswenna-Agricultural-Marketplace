<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RetailerProduct;
use App\Models\Crop;
use App\Models\CropRate;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class RetailerProductController extends Controller
{
    /**
     * GET /api/retailer/products
     * List all products for the authenticated retailer.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $products = RetailerProduct::with('crop')
            ->where('seller_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'products' => $products,
        ], 200);
    }

    /**
     * GET /api/retailer/products/rate-limit/{cropId}/{grade}
     * Pre-check route for frontend to retrieve rate bounds.
     */
    public function rateLimitInfo(Request $request, $cropId, $grade)
    {
        $info = $this->calculateCropRateLimit($cropId, $grade);

        return response()->json([
            'success' => true,
            'crop_id' => $cropId,
            'grade' => $grade,
            'rate_info' => $info,
        ], 200);
    }

    /**
     * POST /api/retailer/products
     * Create a new product.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'crop_id' => 'required|exists:crops,id',
            'product_name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price_per_unit' => 'required|numeric|min:0.01',
            'discount_price_per_unit' => 'nullable|numeric|min:0|lt:price_per_unit',
            'stock_quantity' => 'required|numeric|min:0',
            'unit_type' => 'required|in:kg,g,liter,ml',
            'grade' => 'required|in:A,B,C',
            'status' => 'nullable|in:active,inactive,out_of_stock',
            'thumbnail' => 'nullable|image|max:4096',
            'images.*' => 'nullable|image|max:4096',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // Calculate maximum allowed price
        $cropId = $request->crop_id;
        $grade = $request->grade;
        $price = (float) $request->price_per_unit;
        $discountPrice = $request->discount_price_per_unit ? (float) $request->discount_price_per_unit : null;

        $rateInfo = $this->calculateCropRateLimit($cropId, $grade);

        if ($rateInfo['max_allowed_price'] !== null) {
            $maxAllowed = $rateInfo['max_allowed_price'];
            if ($price > $maxAllowed) {
                return response()->json([
                    'success' => false,
                    'message' => "Price LKR $price exceeds the maximum allowed retailer price limit of LKR $maxAllowed (+30% above daily rate average LKR {$rateInfo['avg_rate']}).",
                    'errors' => [
                        'price_per_unit' => ["Price exceeds maximum rate limit of LKR $maxAllowed for Grade $grade."]
                    ]
                ], 422);
            }

            if ($discountPrice !== null && $discountPrice > $maxAllowed) {
                return response()->json([
                    'success' => false,
                    'message' => "Discount price LKR $discountPrice exceeds the maximum allowed retailer price limit of LKR $maxAllowed.",
                    'errors' => [
                        'discount_price_per_unit' => ["Discount price exceeds maximum rate limit of LKR $maxAllowed."]
                    ]
                ], 422);
            }
        }

        // Handle image uploads
        $thumbnailPath = null;
        if ($request->hasFile('thumbnail')) {
            $thumbnailPath = $request->file('thumbnail')->store('retailer-products/' . $user->id, 'public');
        }

        $imagePaths = [];
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $img) {
                $imagePaths[] = $img->store('retailer-products/' . $user->id, 'public');
            }
        }

        // If thumbnail wasn't specifically provided but images were, use the first image as thumbnail
        if (!$thumbnailPath && !empty($imagePaths)) {
            $thumbnailPath = $imagePaths[0];
        }

        $product = RetailerProduct::create([
            'seller_id' => $user->id,
            'crop_id' => $cropId,
            'product_name' => $request->product_name,
            'description' => $request->description,
            'price_per_unit' => $price,
            'discount_price_per_unit' => $discountPrice,
            'stock_quantity' => $request->stock_quantity,
            'unit_type' => $request->unit_type,
            'grade' => $grade,
            'status' => $request->status ?? 'active',
            'thumbnail_path' => $thumbnailPath,
            'image_paths' => $imagePaths,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Product created successfully.',
            'product' => $product->load('crop'),
        ], 201);
    }

    /**
     * GET /api/retailer/products/{id}
     * Fetch detail of a single product.
     */
    public function show($id, Request $request)
    {
        $product = RetailerProduct::with('crop')
            ->where('id', $id)
            ->where('seller_id', $request->user()->id)
            ->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'product' => $product,
        ], 200);
    }

    /**
     * PUT/POST /api/retailer/products/{id} (since multipart form-data update with images requires POST method sometimes in Laravel)
     * Update an existing product.
     */
    public function update(Request $request, $id)
    {
        $user = $request->user();
        $product = RetailerProduct::where('id', $id)
            ->where('seller_id', $user->id)
            ->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found.',
            ], 404);
        }

        // Support PUT spoofing/PATCH or direct form data post
        $validator = Validator::make($request->all(), [
            'crop_id' => 'required|exists:crops,id',
            'product_name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price_per_unit' => 'required|numeric|min:0.01',
            'discount_price_per_unit' => 'nullable|numeric|min:0|lt:price_per_unit',
            'stock_quantity' => 'required|numeric|min:0',
            'unit_type' => 'required|in:kg,g,liter,ml',
            'grade' => 'required|in:A,B,C',
            'status' => 'nullable|in:active,inactive,out_of_stock',
            'thumbnail' => 'nullable|image|max:4096',
            'images.*' => 'nullable|image|max:4096',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // Calculate price bounds
        $cropId = $request->crop_id;
        $grade = $request->grade;
        $price = (float) $request->price_per_unit;
        $discountPrice = $request->discount_price_per_unit ? (float) $request->discount_price_per_unit : null;

        $rateInfo = $this->calculateCropRateLimit($cropId, $grade);

        if ($rateInfo['max_allowed_price'] !== null) {
            $maxAllowed = $rateInfo['max_allowed_price'];
            if ($price > $maxAllowed) {
                return response()->json([
                    'success' => false,
                    'message' => "Price LKR $price exceeds the maximum allowed retailer price limit of LKR $maxAllowed (+30% above daily rate average LKR {$rateInfo['avg_rate']}).",
                    'errors' => [
                        'price_per_unit' => ["Price exceeds maximum rate limit of LKR $maxAllowed for Grade $grade."]
                    ]
                ], 422);
            }

            if ($discountPrice !== null && $discountPrice > $maxAllowed) {
                return response()->json([
                    'success' => false,
                    'message' => "Discount price LKR $discountPrice exceeds the maximum allowed retailer price limit of LKR $maxAllowed.",
                    'errors' => [
                        'discount_price_per_unit' => ["Discount price exceeds maximum rate limit of LKR $maxAllowed."]
                    ]
                ], 422);
            }
        }

        // Update fields
        $product->crop_id = $cropId;
        $product->product_name = $request->product_name;
        $product->description = $request->description;
        $product->price_per_unit = $price;
        $product->discount_price_per_unit = $discountPrice;
        $product->stock_quantity = $request->stock_quantity;
        $product->unit_type = $request->unit_type;
        $product->grade = $grade;
        if ($request->filled('status')) {
            $product->status = $request->status;
        }

        // Handle thumbnail upload
        if ($request->hasFile('thumbnail')) {
            if ($product->thumbnail_path) {
                Storage::disk('public')->delete($product->thumbnail_path);
            }
            $product->thumbnail_path = $request->file('thumbnail')->store('retailer-products/' . $user->id, 'public');
        }

        // Handle additional images uploads
        if ($request->hasFile('images')) {
            // Delete old images
            if (!empty($product->image_paths)) {
                foreach ($product->image_paths as $oldImg) {
                    Storage::disk('public')->delete($oldImg);
                }
            }

            $imagePaths = [];
            foreach ($request->file('images') as $img) {
                $imagePaths[] = $img->store('retailer-products/' . $user->id, 'public');
            }
            $product->image_paths = $imagePaths;

            if (!$product->thumbnail_path && !empty($imagePaths)) {
                $product->thumbnail_path = $imagePaths[0];
            }
        }

        $product->save();

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully.',
            'product' => $product->load('crop'),
        ], 200);
    }

    /**
     * DELETE /api/retailer/products/{id}
     * Delete a product.
     */
    public function destroy($id, Request $request)
    {
        $product = RetailerProduct::where('id', $id)
            ->where('seller_id', $request->user()->id)
            ->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found.',
            ], 404);
        }

        // Delete associated files
        if ($product->thumbnail_path) {
            Storage::disk('public')->delete($product->thumbnail_path);
        }
        if (!empty($product->image_paths)) {
            foreach ($product->image_paths as $img) {
                Storage::disk('public')->delete($img);
            }
        }

        $product->delete();

        return response()->json([
            'success' => true,
            'message' => 'Product deleted successfully.',
        ], 200);
    }

    /**
     * Helper: Calculate Crop Rate Limit based on daily rates
     */
    private function calculateCropRateLimit($cropId, $grade)
    {
        $today = Carbon::today()->toDateString();
        $gradeColumn = 'rate_per_kg_grade_' . strtolower($grade);

        // Try getting today's average
        $todayAvg = DB::table('crop_rates')
            ->where('crop_id', $cropId)
            ->whereDate('date_and_time', $today)
            ->avg($gradeColumn);

        $isFallback = false;
        $rateDate = $today;

        if ($todayAvg === null) {
            // Find the most recent historical rate for this crop and grade
            $latestRate = DB::table('crop_rates')
                ->where('crop_id', $cropId)
                ->whereNotNull($gradeColumn)
                ->orderBy('date_and_time', 'desc')
                ->first();

            if ($latestRate) {
                $rateDate = Carbon::parse($latestRate->date_and_time)->toDateString();
                $todayAvg = DB::table('crop_rates')
                    ->where('crop_id', $cropId)
                    ->whereDate('date_and_time', $rateDate)
                    ->avg($gradeColumn);
                $isFallback = true;
            }
        }

        $maxAllowed = null;
        if ($todayAvg !== null && $todayAvg > 0) {
            $maxAllowed = round($todayAvg * 1.30, 2);
            $todayAvg = round($todayAvg, 2);
        }

        return [
            'avg_rate' => $todayAvg,
            'max_allowed_price' => $maxAllowed,
            'is_fallback' => $isFallback,
            'rate_date' => $rateDate,
        ];
    }
}
