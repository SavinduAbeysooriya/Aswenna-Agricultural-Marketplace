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
Route::get('/admin/crop-rates', [AdminWebController::class, 'cropRates'])->name('admin.crop-rates');
Route::get('/admin/crop-growth-stages', [AdminWebController::class, 'cropGrowthStages'])->name('admin.crop-growth-stages');
Route::get('/admin/offer-campaigns', [AdminWebController::class, 'offerCampaigns'])->name('admin.offer-campaigns');
Route::get('/admin/withdrawals', [AdminWebController::class, 'withdrawals'])->name('admin.withdrawals');
Route::get('/admin/users/roles', [AdminWebController::class, 'userRoles'])->name('admin.users.roles');
Route::get('/admin/users/{role}', [AdminWebController::class, 'usersList'])->name('admin.users.index');
Route::get('/admin/users/profile/{id}', [AdminWebController::class, 'userProfile'])->name('admin.users.profile');
Route::post('/admin/crop-rates/{id}/delete-from-profile', [AdminWebController::class, 'deleteCropRateFromProfile'])->name('admin.crop-rates.delete-from-profile');
Route::post('/admin/users/profile/{id}/approve', [AdminWebController::class, 'approveUserProfile'])->name('admin.users.profile.approve');
Route::post('/admin/users/profile/{id}/reject', [AdminWebController::class, 'rejectUserProfile'])->name('admin.users.profile.reject');
Route::post('/admin/users/profile/{id}/toggle-active', [AdminWebController::class, 'toggleUserActiveProfile'])->name('admin.users.profile.toggle-active');
Route::post('/admin/users/profile/{id}/verify-phone/{type}', [AdminWebController::class, 'verifyUserPhone'])->name('admin.users.profile.verify-phone');
Route::post('/admin/users/profile/document/{id}/approve', [AdminWebController::class, 'approveUserDocument'])->name('admin.users.profile.document.approve');
Route::post('/admin/users/profile/document/{id}/reject', [AdminWebController::class, 'rejectUserDocument'])->name('admin.users.profile.document.reject');
Route::post('/admin/users/profile/land/{id}/approve', [AdminWebController::class, 'approveUserLand'])->name('admin.users.profile.land.approve');
Route::post('/admin/users/profile/land/{id}/reject', [AdminWebController::class, 'rejectUserLand'])->name('admin.users.profile.land.reject');
Route::post('/admin/users/profile/harvest-listing/{id}/status', [AdminWebController::class, 'updateHarvestListingStatus'])->name('admin.harvest-listings.update-status');
Route::post('/admin/users/profile/{id}/retail-notes', [AdminWebController::class, 'updateRetailSellerNotes'])->name('admin.users.profile.retail-notes');
Route::post('/admin/users/profile/{id}/delivery-partner/approve', [AdminWebController::class, 'approveDeliveryPartnerVehicle'])->name('admin.users.profile.delivery-partner.approve');
Route::post('/admin/users/profile/{id}/delivery-partner/reject', [AdminWebController::class, 'rejectDeliveryPartnerVehicle'])->name('admin.users.profile.delivery-partner.reject');
Route::post('/admin/users/profile/{id}/delivery-partner/notes', [AdminWebController::class, 'updateDeliveryPartnerNotes'])->name('admin.users.profile.delivery-partner.notes');




// CSRF Protected Secure Session Termination
Route::post('/admin/logout', [AdminWebController::class, 'logout'])->name('admin.logout');

