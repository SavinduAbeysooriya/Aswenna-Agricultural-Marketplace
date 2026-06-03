<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RetailerProduct;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CustomerProductController extends Controller
{
    /**
     * GET /api/customer/products
     * Search and browse retailer products within a 30 km radius of customer coordinates.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        $lat = $request->input('latitude');
        $lng = $request->input('longitude');

        // Fall back to user's saved profile location if not passed in request
        if (($lat === null || $lng === null) && $user) {
            $lat = $user->latitude;
            $lng = $user->longitude;
        }

        // Base query joining retailer product with the seller user details
        $query = RetailerProduct::with(['crop', 'seller'])
            ->select('retailer_products.*')
            ->join('users', 'retailer_products.seller_id', '=', 'users.id')
            ->where('retailer_products.status', 'active');

        // If coordinates are available, filter by 30km radius using Haversine formula
        if ($lat !== null && $lng !== null && is_numeric($lat) && is_numeric($lng)) {
            $lat = (float) $lat;
            $lng = (float) $lng;

            $query->selectRaw(
                '(6371 * acos(cos(radians(?)) * cos(radians(users.latitude)) * cos(radians(users.longitude) - radians(?)) + sin(radians(?)) * sin(radians(users.latitude)))) AS distance',
                [$lat, $lng, $lat]
            )
            ->having('distance', '<=', 30.0) // 30 km radius limit
            ->orderBy('distance', 'asc');
        } else {
            // No location fallback: return all active products but add distance as null
            $query->selectRaw('NULL as distance')
                ->orderBy('retailer_products.created_at', 'desc');
        }

        // Advanced Search & Filter Options
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('retailer_products.product_name', 'like', "%{$search}%")
                  ->orWhere('retailer_products.description', 'like', "%{$search}%")
                  ->orWhereExists(function ($subQuery) use ($search) {
                      $subQuery->select(DB::raw(1))
                          ->from('crops')
                          ->whereColumn('crops.id', 'retailer_products.crop_id')
                          ->where('crops.cropname', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('crop_id')) {
            $query->where('retailer_products.crop_id', $request->input('crop_id'));
        }

        if ($request->filled('grade')) {
            $query->where('retailer_products.grade', $request->input('grade'));
        }

        $products = $query->get();

        return response()->json([
            'success' => true,
            'customer_location' => [
                'latitude' => $lat,
                'longitude' => $lng,
            ],
            'radius_km' => 30,
            'products' => $products,
        ], 200);
    }
}
