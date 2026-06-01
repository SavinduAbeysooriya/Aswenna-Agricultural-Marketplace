<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LandController;
use App\Http\Controllers\Api\CropController;
use App\Http\Controllers\Api\DailyCultivationLogController;
use App\Http\Controllers\Api\CropGrowthStageController;
use App\Http\Controllers\Api\ChatbotController;

use App\Http\Controllers\Api\CropRateController;
use App\Http\Controllers\Api\HarvestListingController;
use App\Http\Controllers\Api\HarvestBidController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/google-register', [AuthController::class, 'googleRegister']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/login/verify-otp', [AuthController::class, 'loginVerifyOtp']);
Route::post('/login/send-otp', [AuthController::class, 'sendLoginOtp']);
Route::post('/send-otp', [AuthController::class, 'sendOtp']);
Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
Route::post('/google-login', [AuthController::class, 'googleLogin']);
Route::post('/google-authenticate', [AuthController::class, 'googleAuthenticate']);
Route::post('/forgot-password/send-otp', [AuthController::class, 'forgotPasswordSendOtp']);
Route::post('/forgot-password/reset', [AuthController::class, 'forgotPasswordReset']);
Route::middleware('auth:sanctum')->get('/farmer/profile', [AuthController::class, 'farmerProfile']);
Route::middleware('auth:sanctum')->put('/farmer/profile', [AuthController::class, 'updateFarmerProfile']);
Route::middleware('auth:sanctum')->get('/buyer/profile', [AuthController::class, 'buyerProfile']);
Route::middleware('auth:sanctum')->post('/buyer/profile', [AuthController::class, 'updateBuyerProfile']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/crops', [CropController::class, 'index']);
    Route::get('/crop-growth-stages', [CropGrowthStageController::class, 'index']);
    Route::get('/farmer/lands', [LandController::class, 'index']);
    Route::post('/farmer/lands', [LandController::class, 'store']);
    Route::get('/farmer/lands/{id}', [LandController::class, 'show']);
    Route::put('/farmer/lands/{id}', [LandController::class, 'update']);

    Route::get('/farmer/cultivation-logs', [DailyCultivationLogController::class, 'index']);
    Route::post('/farmer/cultivation-logs', [DailyCultivationLogController::class, 'store']);
    Route::put('/farmer/cultivation-logs/{id}', [DailyCultivationLogController::class, 'update']);
    Route::delete('/farmer/cultivation-logs/{id}', [DailyCultivationLogController::class, 'destroy']);
    Route::post('/chat/send', [ChatbotController::class, 'sendMessage']);
    Route::get('/chat/session/{session_id}', [ChatbotController::class, 'getSessionMessages']);
    Route::post('/chat/session', [ChatbotController::class, 'createSession']);

    // Crop Market Rates
    Route::get('/crop-rates', [CropRateController::class, 'index']);
    Route::get('/crop-rates/{crop_id}', [CropRateController::class, 'show']);
    Route::post('/crop-rates', [CropRateController::class, 'store']);

    // Farmer Harvest Listings
    Route::get('/farmer/harvest-listings', [HarvestListingController::class, 'index']);
    Route::post('/farmer/harvest-listings', [HarvestListingController::class, 'store']);
    Route::get('/farmer/harvest-listings/{id}', [HarvestListingController::class, 'show']);
    Route::post('/farmer/harvest-listings/{id}', [HarvestListingController::class, 'update']);

    // Buyer Harvest Listings Feed
    Route::get('/buyer/harvest-listings', [HarvestListingController::class, 'buyerIndex']);

    // Bidding Engine
    Route::post('/harvest-listings/{id}/bids', [HarvestBidController::class, 'placeBid']);
    Route::get('/farmer/bids', [HarvestBidController::class, 'indexFarmerBids']);
    Route::post('/farmer/bids/{id}/accept', [HarvestBidController::class, 'acceptBid']);
    Route::post('/farmer/bids/{id}/reject', [HarvestBidController::class, 'rejectBid']);
});

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
