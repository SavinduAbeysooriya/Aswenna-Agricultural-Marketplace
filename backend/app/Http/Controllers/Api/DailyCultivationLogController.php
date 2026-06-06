<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Exception;

class DailyCultivationLogController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $logs = DB::table('daily_cultivation_logs')
            ->join('lands', 'daily_cultivation_logs.land_id', '=', 'lands.id')
            ->join('crop_growth_stages', 'daily_cultivation_logs.growth_stage_id', '=', 'crop_growth_stages.id')
            ->where('daily_cultivation_logs.farmer_id', $user->id)
            ->orderByDesc('daily_cultivation_logs.log_date')
            ->orderByDesc('daily_cultivation_logs.id')
            ->select(
                'daily_cultivation_logs.*',
                'lands.size as land_size',
                'lands.ownership_type as land_ownership_type',
                'lands.registration_number as land_registration_number',
                'crop_growth_stages.name as growth_stage_name'
            )
            ->get();

        return response()->json(['success' => true, 'logs' => $logs], 200);
    }

    public function store(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'land_id' => [
                'required',
                'integer',
                Rule::exists('lands', 'id')->where('farmer_id', $user->id),
            ],
            'log_date' => 'required|date',
            'growth_stage_id' => 'required|integer|exists:crop_growth_stages,id',
            'leaf_appearance' => 'nullable|string',
            'disease_detected' => 'nullable|boolean',
            'pest_detected' => 'nullable|boolean',
            'disease_name_and_damage' => 'nullable',
            'pest_name_and_damage' => 'nullable',
            'pesticide_applied' => 'nullable|boolean',
            'pesticide_name' => 'nullable|string|max:255',
            'pesticide_type' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $diseaseData = $request->disease_name_and_damage;
        if (is_array($diseaseData) || is_object($diseaseData)) {
            $diseaseData = json_encode($diseaseData);
        }

        $pestData = $request->pest_name_and_damage;
        if (is_array($pestData) || is_object($pestData)) {
            $pestData = json_encode($pestData);
        }

        DB::beginTransaction();
        try {
            $id = DB::table('daily_cultivation_logs')->insertGetId([
                'farmer_id' => $user->id,
                'land_id' => $request->land_id,
                'log_date' => $request->log_date,
                'growth_stage_id' => $request->growth_stage_id,
                'leaf_appearance' => $request->leaf_appearance,
                'disease_detected' => (bool) $request->input('disease_detected', false),
                'pest_detected' => (bool) $request->input('pest_detected', false),
                'disease_name_and_damage' => $diseaseData,
                'pest_name_and_damage' => $pestData,
                'pesticide_applied' => (bool) $request->input('pesticide_applied', false),
                'pesticide_name' => $request->pesticide_name,
                'pesticide_type' => $request->pesticide_type,
                'notes' => $request->notes,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::commit();

            $log = DB::table('daily_cultivation_logs')->where('id', $id)->first();
            return response()->json(['success' => true, 'log' => $log], 201);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to create cultivation log.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, int $id)
    {
        $user = $request->user();

        $existing = DB::table('daily_cultivation_logs')
            ->where('id', $id)
            ->where('farmer_id', $user->id)
            ->first();

        if (!$existing) {
            return response()->json(['success' => false, 'message' => 'Log not found.'], 404);
        }

        $validator = Validator::make($request->all(), [
            'land_id' => [
                'required',
                'integer',
                Rule::exists('lands', 'id')->where('farmer_id', $user->id),
            ],
            'log_date' => 'required|date',
            'growth_stage_id' => 'required|integer|exists:crop_growth_stages,id',
            'leaf_appearance' => 'nullable|string',
            'disease_detected' => 'nullable|boolean',
            'pest_detected' => 'nullable|boolean',
            'disease_name_and_damage' => 'nullable',
            'pest_name_and_damage' => 'nullable',
            'pesticide_applied' => 'nullable|boolean',
            'pesticide_name' => 'nullable|string|max:255',
            'pesticide_type' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $diseaseData = $request->disease_name_and_damage;
        if (is_array($diseaseData) || is_object($diseaseData)) {
            $diseaseData = json_encode($diseaseData);
        }

        $pestData = $request->pest_name_and_damage;
        if (is_array($pestData) || is_object($pestData)) {
            $pestData = json_encode($pestData);
        }

        try {
            DB::table('daily_cultivation_logs')
                ->where('id', $id)
                ->update([
                    'land_id' => $request->land_id,
                    'log_date' => $request->log_date,
                    'growth_stage_id' => $request->growth_stage_id,
                    'leaf_appearance' => $request->leaf_appearance,
                    'disease_detected' => (bool) $request->input('disease_detected', false),
                    'pest_detected' => (bool) $request->input('pest_detected', false),
                    'disease_name_and_damage' => $diseaseData,
                    'pest_name_and_damage' => $pestData,
                    'pesticide_applied' => (bool) $request->input('pesticide_applied', false),
                    'pesticide_name' => $request->pesticide_name,
                    'pesticide_type' => $request->pesticide_type,
                    'notes' => $request->notes,
                    'updated_at' => now(),
                ]);

            $log = DB::table('daily_cultivation_logs')->where('id', $id)->first();
            return response()->json(['success' => true, 'log' => $log], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update cultivation log.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(Request $request, int $id)
    {
        $user = $request->user();

        $existing = DB::table('daily_cultivation_logs')
            ->where('id', $id)
            ->where('farmer_id', $user->id)
            ->first();

        if (!$existing) {
            return response()->json(['success' => false, 'message' => 'Log not found.'], 404);
        }

        DB::table('daily_cultivation_logs')->where('id', $id)->delete();
        return response()->json(['success' => true, 'message' => 'Log deleted.'], 200);
    }
}

