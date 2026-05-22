<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CropGrowthStageController extends Controller
{
    public function index(Request $request)
    {
        $stages = DB::table('crop_growth_stages')
            ->orderBy('id')
            ->get();

        return response()->json([
            'success' => true,
            'stages' => $stages,
        ], 200);
    }
}

