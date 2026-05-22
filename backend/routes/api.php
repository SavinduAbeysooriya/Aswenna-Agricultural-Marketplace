<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LandController;

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

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/farmer/lands', [LandController::class, 'index']);
    Route::post('/farmer/lands', [LandController::class, 'store']);
    Route::get('/farmer/lands/{id}', [LandController::class, 'show']);
    Route::put('/farmer/lands/{id}', [LandController::class, 'update']);
});

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
