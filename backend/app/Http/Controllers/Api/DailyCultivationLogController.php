<?php

namespace App\Http\Controllers\Api;
 
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Http;
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

    public function analyzeLogs(Request $request)
    {
        $request->validate([
            'prompt' => 'required|string',
            'land_id' => 'nullable|integer',
        ]);

        $groqKey = env('GROQ_API_KEY');
        if (empty($groqKey)) {
            return response()->json([
                'success' => false,
                'message' => 'Groq API Key is not configured on the server.',
            ], 500);
        }

        $landId = $request->input('land_id');
        $landSize = 1.0;
        $cropName = 'Rice';
        $district = 'Hambantota';

        if ($landId) {
            $land = DB::table('lands')
                ->where('id', $landId)
                ->first();
            if ($land) {
                $landSize = (float) $land->size;

                // Get crop name
                $landCrop = DB::table('land_crops')
                    ->join('crops', 'land_crops.crop_id', '=', 'crops.id')
                    ->where('land_crops.land_id', $landId)
                    ->select('crops.cropname')
                    ->first();
                if ($landCrop) {
                    $cropName = $landCrop->cropname;
                }

                // Get farmer district
                $farmer = DB::table('users')->where('id', $land->farmer_id)->first();
                if ($farmer && !empty($farmer->district)) {
                    $district = $farmer->district;
                }
            }
        }

        // Typical defaults based on crop name (rice, tomato, potato, banana, chili, carrot)
        $nitrogen = 50; $phosphorus = 50; $potassium = 50;
        $temp = 28.0; $humidity = 75.0; $ph = 6.5; $rainfall = 1000.0;
        $soilMoisture = 45; $soilType = 'Loamy';

        $cropLower = strtolower($cropName);
        if (str_contains($cropLower, 'rice') || str_contains($cropLower, 'paddy')) {
            $nitrogen = 80; $phosphorus = 40; $potassium = 40;
            $temp = 27.0; $humidity = 80.0; $ph = 6.0; $rainfall = 1200.0;
            $soilMoisture = 60; $soilType = 'Clayey';
        } elseif (str_contains($cropLower, 'tomato')) {
            $nitrogen = 60; $phosphorus = 50; $potassium = 80;
            $temp = 24.0; $humidity = 65.0; $ph = 6.2; $rainfall = 800.0;
            $soilMoisture = 45; $soilType = 'Loamy';
        } elseif (str_contains($cropLower, 'potato')) {
            $nitrogen = 50; $phosphorus = 60; $potassium = 100;
            $temp = 18.0; $humidity = 70.0; $ph = 5.5; $rainfall = 900.0;
            $soilMoisture = 50; $soilType = 'Sandy';
        } elseif (str_contains($cropLower, 'banana')) {
            $nitrogen = 100; $phosphorus = 30; $potassium = 200;
            $temp = 28.0; $humidity = 80.0; $ph = 6.5; $rainfall = 1500.0;
            $soilMoisture = 55; $soilType = 'Loamy';
        } elseif (str_contains($cropLower, 'carrot')) {
            $nitrogen = 40; $phosphorus = 50; $potassium = 120;
            $temp = 17.0; $humidity = 75.0; $ph = 6.0; $rainfall = 1000.0;
            $soilMoisture = 40; $soilType = 'Sandy';
        }

        $predictionData = [];
        try {
            $predictResponse = Http::timeout(5)->post('http://127.0.0.1:8000/predict', [
                'nitrogen' => $nitrogen,
                'phosphorus' => $phosphorus,
                'potassium' => $potassium,
                'temperature' => $temp,
                'humidity' => $humidity,
                'ph' => $ph,
                'rainfall' => $rainfall,
                'area_name' => 'Sri Lanka',
                'crop_name' => $cropName,
                'year' => 2026,
                'pesticide_tonnes' => 8.0,
                'land_size' => $landSize,
                'soil_moisture' => $soilMoisture,
                'soil_temperature' => $temp - 2.0,
                'soil_type' => $soilType
            ]);

            if ($predictResponse->successful()) {
                $predictionData = $predictResponse->json();
            }
        } catch (\Exception $e) {
            // Silently handle fallback if predict fails
        }

        $predictContext = "";
        if (!empty($predictionData)) {
            $predictContext = "\n\n--- TABULAR AI PREDICTIONS FOR THIS LAND ---\n";
            $predictContext .= "- Cultivated Crop: " . $cropName . "\n";
            $predictContext .= "- Land Size: " . $landSize . " Acres\n";
            if (isset($predictionData['yield_forecast'])) {
                $yf = $predictionData['yield_forecast'];
                $predictContext .= "- Expected Yield: " . number_format($yf['yield_kg_acre'], 1) . " kg per Acre (Total predicted yield for this land size: " . number_format($yf['total_expected_yield_kg'], 1) . " kg)\n";
            }
            if (isset($predictionData['recommended_fertilizer'])) {
                $predictContext .= "- AI Recommended Fertilizer: " . $predictionData['recommended_fertilizer'] . "\n";
            }
            if (isset($predictionData['recommended_crop'])) {
                $predictContext .= "- AI Recommended Alternative Crop: " . $predictionData['recommended_crop'] . " (based on current NPK/Climate properties)\n";
            }
            $predictContext .= "--------------------------------------------\n\n";
            $predictContext .= "Instructions to AI: Incorporate these Tabular ML model yield forecasts and fertilizer/crop recommendations into your final report to show data-backed analysis.";
        }

        $models = ['openai/gpt-oss-120b', 'openai/gpt-oss-20b', 'qwen/qwen3.6-27b'];
        $lastError = null;
        $content = null;

        foreach ($models as $model) {
            try {
                $response = Http::withHeaders([
                    'Content-Type' => 'application/json',
                    'Authorization' => 'Bearer ' . $groqKey,
                ])->timeout(30)->post('https://api.groq.com/openai/v1/chat/completions', [
                    'model' => $model,
                    'messages' => [
                        ['role' => 'user', 'content' => $request->input('prompt') . $predictContext],
                    ],
                    'temperature' => 0.7,
                ]);

                if ($response->successful()) {
                    $content = $response->json('choices.0.message.content');
                    // Remove <think>...</think> tag if present
                    if (str_contains($content, '<think>')) {
                        $content = preg_replace('/<think>[\s\S]*?<\/think>/', '', $content);
                    }
                    $content = trim($content);
                    break;
                } else {
                    $lastError = $response->body();
                }
            } catch (\Exception $e) {
                $lastError = $e->getMessage();
            }
        }

        if ($content !== null) {
            return response()->json([
                'success' => true,
                'content' => $content,
            ]);
        } else {
            return response()->json([
                'success' => false,
                'message' => 'Failed to obtain AI advice: ' . $lastError,
            ], 500);
        }
    }
}

