<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CropController extends Controller
{
    public function index(Request $request)
    {
        $crops = DB::table('crops')
            ->where('status', 'approved')
            ->orderBy('cropname')
            ->get();

        return response()->json([
            'success' => true,
            'crops' => $crops,
        ], 200);
    }
}

