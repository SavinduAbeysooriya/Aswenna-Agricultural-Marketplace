<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CropRate;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CropRateController extends Controller
{
    /**
     * GET /api/crop-rates
     * List all approved crops with today's average Grade A rate.
     */
    public function index(Request $request)
    {
        $today = Carbon::today()->toDateString();
        $buyerId = $request->user()->id;

        $crops = DB::table('crops')
            ->where('crops.status', 'approved')
            ->leftJoin('crop_rates', function ($join) use ($today) {
                $join->on('crops.id', '=', 'crop_rates.crop_id')
                     ->whereDate('crop_rates.date_and_time', $today);
            })
            ->select(
                'crops.id',
                'crops.cropname',
                'crops.image_path',
                DB::raw('ROUND(AVG(crop_rates.rate_per_kg_grade_a), 2) as avg_rate_grade_a'),
                DB::raw('ROUND(AVG(crop_rates.rate_per_kg_grade_b), 2) as avg_rate_grade_b'),
                DB::raw('ROUND(AVG(crop_rates.rate_per_kg_grade_c), 2) as avg_rate_grade_c'),
                DB::raw('COUNT(DISTINCT crop_rates.buyer_id) as total_submissions')
            )
            ->groupBy('crops.id', 'crops.cropname', 'crops.image_path')
            ->orderBy('crops.cropname')
            ->get();

        // Check if this buyer already submitted today for each crop (all grades)
        $buyerSubmissions = DB::table('crop_rates')
            ->where('buyer_id', $buyerId)
            ->whereDate('date_and_time', $today)
            ->get()
            ->keyBy('crop_id')
            ->toArray();

        $crops = $crops->map(function ($crop) use ($buyerSubmissions) {
            $submission = $buyerSubmissions[$crop->id] ?? null;
            $crop->buyer_today_rate_a = $submission ? $submission->rate_per_kg_grade_a : null;
            $crop->buyer_today_rate_b = $submission ? $submission->rate_per_kg_grade_b : null;
            $crop->buyer_today_rate_c = $submission ? $submission->rate_per_kg_grade_c : null;
            $crop->has_submitted_today = isset($buyerSubmissions[$crop->id]);
            return $crop;
        });

        return response()->json([
            'success' => true,
            'date' => $today,
            'crops' => $crops,
        ], 200);
    }

    /**
     * GET /api/crop-rates/{crop_id}
     * Get detailed rate info for a single crop.
     */
    public function show(Request $request, $cropId)
    {
        $today = Carbon::today()->toDateString();
        $buyerId = $request->user()->id;

        $crop = DB::table('crops')->where('id', $cropId)->first();
        if (!$crop) {
            return response()->json([
                'success' => false,
                'message' => 'Crop not found.',
            ], 404);
        }

        $todayRates = DB::table('crop_rates')
            ->where('crop_id', $cropId)
            ->whereDate('date_and_time', $today)
            ->get();

        $avgA = $todayRates->avg('rate_per_kg_grade_a');
        $avgB = $todayRates->avg('rate_per_kg_grade_b');
        $avgC = $todayRates->avg('rate_per_kg_grade_c');

        $buyerRate = $todayRates->where('buyer_id', $buyerId)->first();

        // Calculate allowed ranges for all grades
        $minAllowedA = null; $maxAllowedA = null;
        $minAllowedB = null; $maxAllowedB = null;
        $minAllowedC = null; $maxAllowedC = null;

        if ($avgA && $todayRates->count() > 0) {
            $minAllowedA = round($avgA * 0.95, 2);
            $maxAllowedA = round($avgA * 1.10, 2);
        }
        if ($avgB && $todayRates->count() > 0) {
            $minAllowedB = round($avgB * 0.95, 2);
            $maxAllowedB = round($avgB * 1.10, 2);
        }
        if ($avgC && $todayRates->count() > 0) {
            $minAllowedC = round($avgC * 0.95, 2);
            $maxAllowedC = round($avgC * 1.10, 2);
        }

        return response()->json([
            'success' => true,
            'crop' => $crop,
            'today' => [
                'date' => $today,
                'avg_rate_grade_a' => $avgA ? round($avgA, 2) : null,
                'avg_rate_grade_b' => $avgB ? round($avgB, 2) : null,
                'avg_rate_grade_c' => $avgC ? round($avgC, 2) : null,
                'total_submissions' => $todayRates->unique('buyer_id')->count(),
                'min_allowed_rate_a' => $minAllowedA,
                'max_allowed_rate_a' => $maxAllowedA,
                'min_allowed_rate_b' => $minAllowedB,
                'max_allowed_rate_b' => $maxAllowedB,
                'min_allowed_rate_c' => $minAllowedC,
                'max_allowed_rate_c' => $maxAllowedC,
            ],
            'buyer_rate' => $buyerRate,
        ], 200);
    }

    /**
     * POST /api/crop-rates
     * Submit or update buyer's today rate for a crop.
     * Rate must be within [avg * 0.95, avg * 1.10] of today's average.
     * If no average exists yet, any positive value is accepted.
     */
    public function store(Request $request)
    {
        $request->validate([
            'crop_id' => 'required|integer|exists:crops,id',
            'rate_per_kg_grade_a' => 'required|numeric|min:0.01',
            'rate_per_kg_grade_b' => 'nullable|numeric|min:0',
            'rate_per_kg_grade_c' => 'nullable|numeric|min:0',
            'min_qty_required' => 'nullable|numeric|min:0',
            'max_qty_required' => 'nullable|numeric|min:0',
            'accepted_grade' => 'nullable|string|max:100',
        ]);

        $buyerId = $request->user()->id;
        $cropId = $request->crop_id;
        $today = Carbon::today()->toDateString();
        $submittedRateA = (float) $request->rate_per_kg_grade_a;
        $submittedRateB = $request->rate_per_kg_grade_b !== null ? (float) $request->rate_per_kg_grade_b : null;
        $submittedRateC = $request->rate_per_kg_grade_c !== null ? (float) $request->rate_per_kg_grade_c : null;

        // Get today's averages (excluding this buyer's own rate to avoid self-bias on update)
        $todayAvgRow = DB::table('crop_rates')
            ->where('crop_id', $cropId)
            ->where('buyer_id', '!=', $buyerId)
            ->whereDate('date_and_time', $today)
            ->select(
                DB::raw('AVG(rate_per_kg_grade_a) as avg_a'),
                DB::raw('AVG(rate_per_kg_grade_b) as avg_b'),
                DB::raw('AVG(rate_per_kg_grade_c) as avg_c')
            )
            ->first();

        $todayAvgA = $todayAvgRow ? $todayAvgRow->avg_a : null;
        $todayAvgB = $todayAvgRow ? $todayAvgRow->avg_b : null;
        $todayAvgC = $todayAvgRow ? $todayAvgRow->avg_c : null;

        // Enforce rate bounds for Grade A if average exists
        if ($todayAvgA !== null && $todayAvgA > 0) {
            $minAllowedA = round($todayAvgA * 0.95, 2);
            $maxAllowedA = round($todayAvgA * 1.10, 2);

            if ($submittedRateA < $minAllowedA || $submittedRateA > $maxAllowedA) {
                return response()->json([
                    'success' => false,
                    'message' => "Grade A rate must be between LKR $minAllowedA (−5%) and LKR $maxAllowedA (+10%) of the current average LKR " . round($todayAvgA, 2) . ".",
                    'min_allowed' => $minAllowedA,
                    'max_allowed' => $maxAllowedA,
                    'current_avg' => round($todayAvgA, 2),
                ], 422);
            }
        }

        // Enforce rate bounds for Grade B if average exists and Grade B rate is submitted
        if ($submittedRateB !== null && $todayAvgB !== null && $todayAvgB > 0) {
            $minAllowedB = round($todayAvgB * 0.95, 2);
            $maxAllowedB = round($todayAvgB * 1.10, 2);

            if ($submittedRateB < $minAllowedB || $submittedRateB > $maxAllowedB) {
                return response()->json([
                    'success' => false,
                    'message' => "Grade B rate must be between LKR $minAllowedB (−5%) and LKR $maxAllowedB (+10%) of the current average LKR " . round($todayAvgB, 2) . ".",
                    'min_allowed' => $minAllowedB,
                    'max_allowed' => $maxAllowedB,
                    'current_avg' => round($todayAvgB, 2),
                ], 422);
            }
        }

        // Enforce rate bounds for Grade C if average exists and Grade C rate is submitted
        if ($submittedRateC !== null && $todayAvgC !== null && $todayAvgC > 0) {
            $minAllowedC = round($todayAvgC * 0.95, 2);
            $maxAllowedC = round($todayAvgC * 1.10, 2);

            if ($submittedRateC < $minAllowedC || $submittedRateC > $maxAllowedC) {
                return response()->json([
                    'success' => false,
                    'message' => "Grade C rate must be between LKR $minAllowedC (−5%) and LKR $maxAllowedC (+10%) of the current average LKR " . round($todayAvgC, 2) . ".",
                    'min_allowed' => $minAllowedC,
                    'max_allowed' => $maxAllowedC,
                    'current_avg' => round($todayAvgC, 2),
                ], 422);
            }
        }

        // Upsert: one rate per buyer per crop per day
        $existing = DB::table('crop_rates')
            ->where('crop_id', $cropId)
            ->where('buyer_id', $buyerId)
            ->whereDate('date_and_time', $today)
            ->first();

        $rateData = [
            'buyer_id' => $buyerId,
            'crop_id' => $cropId,
            'date_and_time' => Carbon::now(),
            'rate_per_kg_grade_a' => $submittedRateA,
            'rate_per_kg_grade_b' => $submittedRateB,
            'rate_per_kg_grade_c' => $submittedRateC,
            'min_qty_required' => $request->min_qty_required,
            'max_qty_required' => $request->max_qty_required,
            'accepted_grade' => $request->accepted_grade ?? 'All',
        ];

        if ($existing) {
            DB::table('crop_rates')
                ->where('id', $existing->id)
                ->update(array_merge($rateData, ['updated_at' => Carbon::now()]));
            $rateId = $existing->id;
            $statusMsg = 'Rate updated successfully.';
        } else {
            $rateId = DB::table('crop_rates')->insertGetId(
                array_merge($rateData, [
                    'created_at' => Carbon::now(),
                    'updated_at' => Carbon::now(),
                ])
            );
            $statusMsg = 'Rate submitted successfully.';
        }

        // Return updated averages
        $newAvgRow = DB::table('crop_rates')
            ->where('crop_id', $cropId)
            ->whereDate('date_and_time', $today)
            ->select(
                DB::raw('AVG(rate_per_kg_grade_a) as avg_a'),
                DB::raw('AVG(rate_per_kg_grade_b) as avg_b'),
                DB::raw('AVG(rate_per_kg_grade_c) as avg_c')
            )
            ->first();

        $totalSubmissions = DB::table('crop_rates')
            ->where('crop_id', $cropId)
            ->whereDate('date_and_time', $today)
            ->distinct('buyer_id')
            ->count('buyer_id');

        return response()->json([
            'success' => true,
            'message' => $statusMsg,
            'rate_id' => $rateId,
            'new_avg_rate_a' => $newAvgRow && $newAvgRow->avg_a ? round($newAvgRow->avg_a, 2) : null,
            'new_avg_rate_b' => $newAvgRow && $newAvgRow->avg_b ? round($newAvgRow->avg_b, 2) : null,
            'new_avg_rate_c' => $newAvgRow && $newAvgRow->avg_c ? round($newAvgRow->avg_c, 2) : null,
            'total_submissions' => $totalSubmissions,
        ], $existing ? 200 : 201);
    }
}
