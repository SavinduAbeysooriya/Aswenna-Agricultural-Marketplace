<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminWebController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

// Public Organic Landing Page
Route::get('/', [AdminWebController::class, 'landing'])->name('landing');

// Secure Administration Portal Authentication & 2FA Gates
Route::get('/admin/login', [AdminWebController::class, 'showLogin'])->name('admin.login');
Route::post('/admin/login', [AdminWebController::class, 'loginSubmit'])->name('admin.login.submit');
Route::post('/admin/login/google', [AdminWebController::class, 'googleLoginSubmit'])->name('admin.google.callback');

// Secure Two-Factor Authentication OTP Verification
Route::get('/admin/login/otp', [AdminWebController::class, 'showOtp'])->name('admin.login.otp');
Route::post('/admin/login/otp', [AdminWebController::class, 'otpSubmit'])->name('admin.login.otp.submit');

// Password Recovery SMTP Services
Route::get('/admin/forgot-password', [AdminWebController::class, 'showForgotPassword'])->name('admin.forgot-password');
Route::post('/admin/forgot-password', [AdminWebController::class, 'forgotPasswordSubmit'])->name('admin.forgot-password.submit');

// Password Reset Gateways
Route::get('/admin/reset-password', [AdminWebController::class, 'showResetPassword'])->name('admin.reset-password');
Route::post('/admin/reset-password', [AdminWebController::class, 'resetPasswordSubmit'])->name('admin.reset-password.submit');

// Secure Platform Oversight Dashboard Panel
Route::get('/admin/dashboard', [AdminWebController::class, 'dashboard'])->name('admin.dashboard');
Route::get('/admin/crops', [AdminWebController::class, 'crops'])->name('admin.crops');
Route::get('/admin/crop-growth-stages', [AdminWebController::class, 'cropGrowthStages'])->name('admin.crop-growth-stages');

// CSRF Protected Secure Session Termination
Route::post('/admin/logout', [AdminWebController::class, 'logout'])->name('admin.logout');
