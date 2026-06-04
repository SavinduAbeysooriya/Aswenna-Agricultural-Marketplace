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
use App\Http\Controllers\Api\ConfirmedBidController;
use App\Http\Controllers\Api\ChatMessageController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\RetailerProductController;
use App\Http\Controllers\Api\CustomerProductController;
use App\Http\Controllers\Api\CustomerOrderController;
use App\Http\Controllers\Api\DeliveryPartnerController;

// ─── Public Auth Routes ────────────────────────────────────────────────────────
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

// PayHere server-to-server notify (unauthenticated)
Route::post('/payment/notify', [PaymentController::class, 'notifyPayment']);
Route::get('/payment/return', fn() => response('OK', 200));
Route::get('/payment/cancel', fn() => response('CANCELLED', 200));

// ─── Authenticated Routes ──────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->get('/farmer/profile', [AuthController::class, 'farmerProfile']);
Route::middleware('auth:sanctum')->put('/farmer/profile', [AuthController::class, 'updateFarmerProfile']);
Route::middleware('auth:sanctum')->get('/buyer/profile', [AuthController::class, 'buyerProfile']);
Route::middleware('auth:sanctum')->post('/buyer/profile', [AuthController::class, 'updateBuyerProfile']);
Route::middleware('auth:sanctum')->get('/retail-seller/profile', [AuthController::class, 'retailSellerProfile']);
Route::middleware('auth:sanctum')->post('/retail-seller/profile', [AuthController::class, 'updateRetailSellerProfile']);
Route::middleware('auth:sanctum')->get('/delivery/profile', [AuthController::class, 'deliveryPartnerProfile']);
Route::middleware('auth:sanctum')->post('/delivery/profile', [AuthController::class, 'updateDeliveryPartnerProfile']);
Route::middleware('auth:sanctum')->post('/user/add-role', [AuthController::class, 'addRole']);

Route::middleware('auth:sanctum')->group(function () {

    // Crops & Lands
    Route::get('/crops', [CropController::class, 'index']);
    Route::get('/crop-growth-stages', [CropGrowthStageController::class, 'index']);
    Route::get('/farmer/lands', [LandController::class, 'index']);
    Route::post('/farmer/lands', [LandController::class, 'store']);
    Route::get('/farmer/lands/{id}', [LandController::class, 'show']);
    Route::put('/farmer/lands/{id}', [LandController::class, 'update']);

    // Cultivation Logs
    Route::get('/farmer/cultivation-logs', [DailyCultivationLogController::class, 'index']);
    Route::post('/farmer/cultivation-logs', [DailyCultivationLogController::class, 'store']);
    Route::put('/farmer/cultivation-logs/{id}', [DailyCultivationLogController::class, 'update']);
    Route::delete('/farmer/cultivation-logs/{id}', [DailyCultivationLogController::class, 'destroy']);

    // AI Chatbot
    Route::post('/chat/send', [ChatbotController::class, 'sendMessage']);
    Route::get('/chat/session/{session_id}', [ChatbotController::class, 'getSessionMessages']);
    Route::post('/chat/session', [ChatbotController::class, 'createSession']);

    // Crop Market Rates
    Route::get('/crop-rates', [CropRateController::class, 'index']);
    Route::get('/crop-rates/{crop_id}', [CropRateController::class, 'show']);
    Route::post('/crop-rates', [CropRateController::class, 'store']);

    // ── Harvest Listings ──────────────────────────────────────────────────────
    Route::get('/farmer/harvest-listings', [HarvestListingController::class, 'index']);
    Route::post('/farmer/harvest-listings', [HarvestListingController::class, 'store']);
    Route::get('/farmer/harvest-listings/{id}', [HarvestListingController::class, 'show']);
    Route::post('/farmer/harvest-listings/{id}', [HarvestListingController::class, 'update']);

    // Buyer Harvest Feed
    Route::get('/buyer/harvest-listings', [HarvestListingController::class, 'buyerIndex']);

    // ── Bidding Engine ────────────────────────────────────────────────────────
    Route::post('/harvest-listings/{id}/bids', [HarvestBidController::class, 'placeBid']);
    Route::get('/farmer/bids', [HarvestBidController::class, 'indexFarmerBids']);
    Route::post('/farmer/bids/{id}/accept', [HarvestBidController::class, 'acceptBid']);
    Route::post('/farmer/bids/{id}/reject', [HarvestBidController::class, 'rejectBid']);

    // ── Confirmed Bids ────────────────────────────────────────────────────────
    Route::post('/farmer/confirmed-bids/{bidId}/confirm', [ConfirmedBidController::class, 'confirmBid']);
    Route::get('/farmer/confirmed-bids', [ConfirmedBidController::class, 'getFarmerConfirmedBids']);
    Route::get('/buyer/confirmed-bids', [ConfirmedBidController::class, 'getBuyerConfirmedBids']);

    // ── Messaging (Harvest Deal Chat) ─────────────────────────────────────────
    Route::get('/chats/{otherUserId}', [ChatMessageController::class, 'getConversation']);
    Route::post('/chats/send', [ChatMessageController::class, 'sendMessage']);
    Route::get('/chats', [ChatMessageController::class, 'getConversations']);

    // ── Payments ──────────────────────────────────────────────────────────────
    Route::post('/buyer/confirmed-bids/{confirmedBidId}/initiate-payment', [PaymentController::class, 'initiatePayment']);
    Route::post('/customer/orders/{orderId}/initiate-payment', [PaymentController::class, 'initiateRetailOrderPayment']);
    Route::get('/user/wallet', [PaymentController::class, 'getWalletDetails']);
    Route::post('/payment/debug-simulate-success', [PaymentController::class, 'debugSimulateSuccess']);
    Route::post('/payment/debug-simulate-retail-order-success', [PaymentController::class, 'debugSimulateRetailOrderSuccess']);

    // ─── Reviews ───────────────────────────────────────────────────────────────
    Route::post('/confirmed-bids/{confirmedBidId}/reviews', [ReviewController::class, 'submitReview']);
    Route::get('/farmers/{farmerId}/reviews', [ReviewController::class, 'getFarmerReviews']);
    Route::post('/orders/{orderId}/reviews', [ReviewController::class, 'submitOrderReview']);
    Route::get('/orders/{orderId}/reviews', [ReviewController::class, 'getOrderReviews']);

    // ─── Retailer Products CRUD ──────────────────────────────────────────────────
    Route::get('/retailer/products/rate-limit/{cropId}/{grade}', [RetailerProductController::class, 'rateLimitInfo']);
    Route::post('/retailer/products/{id}', [RetailerProductController::class, 'update']); // Support multipart/form-data for updates
    Route::apiResource('/retailer/products', RetailerProductController::class)->except(['update']);
    Route::get('/retailer/orders', [CustomerOrderController::class, 'getRetailerOrders']);

    // ─── Customer Shop & Checkout ───────────────────────────────────────────────
    Route::get('/customer/products', [CustomerProductController::class, 'index']);
    Route::post('/customer/orders/calculate-delivery', [CustomerOrderController::class, 'calculateDelivery']);
    Route::post('/customer/orders', [CustomerOrderController::class, 'store']);
    Route::get('/customer/orders', [CustomerOrderController::class, 'index']);
    Route::get('/customer/orders/{id}', [CustomerOrderController::class, 'show']);

    // ─── Customer Order Tracking ─────────────────────────────────────────────────
    Route::get('/customer/orders/{orderId}/track', [DeliveryPartnerController::class, 'trackOrder']);

    // ─── Delivery Partner Routes ──────────────────────────────────────────────────
    // Live location update
    Route::post('/delivery/location', [DeliveryPartnerController::class, 'updateLocation']);
    // Get nearby open delivery requests
    Route::get('/delivery/nearby-orders', [DeliveryPartnerController::class, 'getNearbyOrders']);
    // Accept a delivery request
    Route::post('/delivery/requests/{requestId}/accept', [DeliveryPartnerController::class, 'acceptDeliveryRequest']);
    // Reject a delivery request
    Route::post('/delivery/requests/{requestId}/reject', [DeliveryPartnerController::class, 'rejectDeliveryRequest']);
    // Get my active deliveries
    Route::get('/delivery/my-deliveries', [DeliveryPartnerController::class, 'getMyDeliveries']);
    // Update delivery status + location
    Route::post('/delivery/orders/{orderId}/update-status', [DeliveryPartnerController::class, 'updateDeliveryStatus']);
    // Get delivery earnings
    Route::get('/delivery/earnings', [DeliveryPartnerController::class, 'getEarnings']);
    // Request a wallet withdrawal
    Route::post('/delivery/withdraw', [DeliveryPartnerController::class, 'requestWithdrawal']);
    // Get past and pending withdrawal requests
    Route::get('/delivery/withdrawals', [DeliveryPartnerController::class, 'getMyWithdrawals']);
    // 🧪 DEBUG: Create a test delivery request (for testing the delivery dashboard)
    Route::post('/delivery/debug-create-test-request', [DeliveryPartnerController::class, 'debugCreateTestRequest']);
});

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
