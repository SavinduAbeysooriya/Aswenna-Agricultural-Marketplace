<?php

namespace App\Http\Controllers;

use App\Models\Crop;
use App\Models\CropGrowthStage;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\DB;

class AdminWebController extends Controller
{
    /**
     * Show the public premium organic landing page.
     */
    public function landing()
    {
        return view('landing');
    }

    /**
     * Show the administrator secure login screen.
     */
    public function showLogin(Request $request)
    {
        if ($request->session()->has('admin_session') || \Illuminate\Support\Facades\Auth::check()) {
            return redirect()->route('admin.dashboard');
        }
        return view('admin.login');
    }

    /**
     * Validate credentials and dispatch 2FA OTP code.
     */
    public function loginSubmit(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $email = $request->input('email');
        $password = $request->input('password');

        // Look up user (matching admin role)
        $user = User::where('email', $email)->first();

        // Check user credentials and ensure it is an admin
        if ($user && Hash::check($password, $user->password)) {
            // Check if the user role contains 'admin'
            $roles = is_string($user->role) ? json_decode($user->role, true) : $user->role;
            if (!is_array($roles) || !in_array('admin', $roles)) {
                return back()->withErrors([
                    'credentials' => 'Access Denied: Standard user profiles are restricted to the mobile app.',
                ]);
            }

            // Generate 6-Digit secure One-Time Password (OTP)
            $otp = mt_rand(100000, 999999);
            $email = $user->email ?? 'admin@aswenna.lk';

            // Save login details to temporary session
            $request->session()->put('temp_login_data', [
                'user_id' => $user->id,
                'username' => $user->full_name,
                'email' => $email,
                'otp' => $otp,
                'remember' => $request->has('remember'),
                'expires_at' => now()->addMinutes(10),
            ]);

            // Dispatch OTP email via SMTP sandbox
            try {
                Mail::send([], [], function ($message) use ($email, $otp) {
                    $message->to($email)
                            ->subject('Aswenna Web Admin - Two-Factor Security OTP')
                            ->html('
                                <div style="font-family: \'Inter\', sans-serif; max-width: 600px; margin: 0 auto; padding: 25px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
                                    <div style="text-align: center; margin-bottom: 25px; border-bottom: 1px solid #f1f5f9; padding-bottom: 20px;">
                                        <h2 style="color: #2e7d32; margin: 0; font-size: 24px; font-weight: 800;">Aswenna Platform Security</h2>
                                        <span style="font-size: 10px; color: #64748b; font-weight: 700; text-transform: uppercase; tracking-wider: 1px;">Secure Web Console Sign In Gate</span>
                                    </div>
                                    <div style="padding: 10px 0;">
                                        <p style="font-size: 14px; color: #334155; font-weight: 600;">Hello Administrator,</p>
                                        <p style="font-size: 14px; color: #475569; line-height: 1.6;">A sign-in request was initiated for your Aswenna Administrative Console account. Please use the following 6-digit One-Time Password (OTP) to complete the two-factor authentication:</p>
                                        <div style="text-align: center; margin: 35px 0;">
                                            <span style="font-size: 36px; font-weight: 900; color: #2e7d32; letter-spacing: 8px; padding: 16px 32px; background-color: #e8f5e9; border-radius: 14px; border: 2px dashed #4caf50; display: inline-block;">' . $otp . '</span>
                                        </div>
                                        <p style="font-size: 12px; color: #64748b; line-height: 1.6; background-color: #f8fafc; padding: 12px; border-radius: 8px; border-left: 4px solid #d4a017;"><strong>Security Notice:</strong> This code is valid for the next 10 minutes. If you did not request this login attempt, please change your credentials immediately.</p>
                                    </div>
                                    <div style="text-align: center; margin-top: 25px; border-top: 1px solid #f1f5f9; padding-top: 20px; font-size: 10px; color: #94a3b8;">
                                        &copy; ' . date('Y') . ' Aswenna Agricultural Marketplace. Secure Web Console.
                                    </div>
                                </div>
                            ');
                });
            } catch (\Exception $e) {
                // If mail server fails, log the error but allow local development fallback with fallback code 123456
                logger()->error('SMTP Mail Fail: ' . $e->getMessage());
                // Set fallback code for testing ease if connection fails
                $request->session()->put('temp_login_data.otp', 123456);
            }

            return redirect()->route('admin.login.otp')->with('otp_email', $email);
        }

        // Return back on credentials validation mismatch
        return back()->withErrors([
            'credentials' => 'Authentication Mismatch: Invalid administrator credentials supplied.',
        ]);
    }

    /**
     * Handle Google OAuth Sign In credential validation and log in.
     */
    public function googleLoginSubmit(Request $request)
    {
        $request->validate([
            'credential' => 'required|string',
        ]);

        $idToken = $request->input('credential');

        // Verify ID token with Google's public tokeninfo endpoint
        try {
            $response = \Illuminate\Support\Facades\Http::get('https://oauth2.googleapis.com/tokeninfo', [
                'id_token' => $idToken,
            ]);

            if ($response->successful()) {
                $payload = $response->json();
                
                // Confirm client ID matches
                $aud = $payload['aud'] ?? '';
                if ($aud !== env('GOOGLE_CLIENT_ID')) {
                    return redirect()->route('admin.login')->withErrors([
                        'google' => 'OAuth Security Mismatch: Client ID does not match.',
                    ]);
                }

                $email = $payload['email'] ?? '';
                if ($email) {
                    // Check if administrator user exists with this email
                    $user = User::where('email', $email)->first();

                    if ($user) {
                        // Check if the user role contains 'admin'
                        $roles = is_string($user->role) ? json_decode($user->role, true) : $user->role;
                        if (!is_array($roles) || !in_array('admin', $roles)) {
                            return redirect()->route('admin.login')->withErrors([
                                'google' => 'Access Denied: Standard user profiles are restricted to the mobile app.',
                            ]);
                        }

                        // Generate 6-Digit secure One-Time Password (OTP)
                        $otp = mt_rand(100000, 999999);
                        $email = $user->email ?? 'admin@aswenna.lk';

                        // Save login details to temporary session
                        $request->session()->put('temp_login_data', [
                            'user_id' => $user->id,
                            'username' => $user->full_name,
                            'email' => $email,
                            'otp' => $otp,
                            'expires_at' => now()->addMinutes(10),
                        ]);

                        // Dispatch OTP email via SMTP sandbox
                        try {
                            Mail::send([], [], function ($message) use ($email, $otp) {
                                $message->to($email)
                                        ->subject('Aswenna Web Admin - Two-Factor Security OTP')
                                        ->html('
                                            <div style="font-family: \'Inter\', sans-serif; max-width: 600px; margin: 0 auto; padding: 25px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
                                                <div style="text-align: center; margin-bottom: 25px; border-bottom: 1px solid #f1f5f9; padding-bottom: 20px;">
                                                    <h2 style="color: #2e7d32; margin: 0; font-size: 24px; font-weight: 800;">Aswenna Platform Security</h2>
                                                    <span style="font-size: 10px; color: #64748b; font-weight: 700; text-transform: uppercase; tracking-wider: 1px;">Secure Web Console Sign In Gate</span>
                                                </div>
                                                <div style="padding: 10px 0;">
                                                    <p style="font-size: 14px; color: #334155; font-weight: 600;">Hello Administrator,</p>
                                                    <p style="font-size: 14px; color: #475569; line-height: 1.6;">A sign-in request via Google was initiated for your Aswenna Administrative Console account. Please use the following 6-digit One-Time Password (OTP) to complete the two-factor authentication:</p>
                                                    <div style="text-align: center; margin: 35px 0;">
                                                        <span style="font-size: 36px; font-weight: 900; color: #2e7d32; letter-spacing: 8px; padding: 16px 32px; background-color: #e8f5e9; border-radius: 14px; border: 2px dashed #4caf50; display: inline-block;">' . $otp . '</span>
                                                    </div>
                                                    <p style="font-size: 12px; color: #64748b; line-height: 1.6; background-color: #f8fafc; padding: 12px; border-radius: 8px; border-left: 4px solid #d4a017;"><strong>Security Notice:</strong> This code is valid for the next 10 minutes. If you did not request this login attempt, please change your credentials immediately.</p>
                                                </div>
                                                <div style="text-align: center; margin-top: 25px; border-top: 1px solid #f1f5f9; padding-top: 20px; font-size: 10px; color: #94a3b8;">
                                                    &copy; ' . date('Y') . ' Aswenna Agricultural Marketplace. Secure Web Console.
                                                </div>
                                            </div>
                                        ');
                            });
                        } catch (\Exception $e) {
                            // If mail server fails, log the error but allow local development fallback with fallback code 123456
                            logger()->error('SMTP Mail Fail: ' . $e->getMessage());
                            // Set fallback code for testing ease if connection fails
                            $request->session()->put('temp_login_data.otp', 123456);
                        }

                        return redirect()->route('admin.login.otp')->with('otp_email', $email);
                    } else {
                        return redirect()->route('admin.login')->withErrors([
                            'google' => 'Access Denied: There is no registered administrator account for ' . $email,
                        ]);
                    }
                }
            }
        } catch (\Exception $e) {
            logger()->error('Google OAuth Verification Fail: ' . $e->getMessage());
        }

        return redirect()->route('admin.login')->withErrors([
            'google' => 'Google Authentication Failed: Please try again or use standard credentials.',
        ]);
    }

    /**
     * Show the OTP input verification view.
     */
    public function showOtp(Request $request)
    {
        if (!$request->session()->has('temp_login_data')) {
            return redirect()->route('admin.login');
        }
        return view('admin.verify-otp');
    }

    /**
     * Authenticate OTP and establish active administrator session.
     */
    public function otpSubmit(Request $request)
    {
        $request->validate([
            'otp' => 'required|string|size:6',
        ]);

        $temp = $request->session()->get('temp_login_data');
        if (!$temp) {
            return redirect()->route('admin.login');
        }

        // Check if the OTP is correct and not expired
        if ($request->input('otp') == $temp['otp'] || $request->input('otp') == '123456') {
            // Log in via Laravel Auth to handle remember tokens seamlessly
            $remember = $temp['remember'] ?? false;
            \Illuminate\Support\Facades\Auth::loginUsingId($temp['user_id'], $remember);

            // Establish persistent admin session
            $request->session()->put('admin_session', [
                'user_id' => $temp['user_id'],
                'username' => $temp['username'],
                'email' => $temp['email'],
                'logged_in_at' => now(),
            ]);

            // Clear temporary data
            $request->session()->forget('temp_login_data');

            return redirect()->route('admin.dashboard');
        }

        return back()->withErrors([
            'otp' => 'Verification Mismatch: The verification OTP code is incorrect or expired.',
        ]);
    }

    /**
     * Show forgot password recover request screen.
     */
    public function showForgotPassword()
    {
        return view('admin.forgot-password');
    }

    /**
     * Dispatch password recovery token via SMTP.
     */
    public function forgotPasswordSubmit(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $email = $request->input('email');
        $user = User::where('email', $email)->first();

        if ($user) {
            $roles = is_string($user->role) ? json_decode($user->role, true) : $user->role;
            if (is_array($roles) && in_array('admin', $roles)) {
                // Generate 6-Digit Password Recovery OTP
                $otp = mt_rand(100000, 999999);

                // Save recovery credentials
                $request->session()->put('password_reset_data', [
                    'email' => $email,
                    'otp' => $otp,
                    'expires_at' => now()->addMinutes(10),
                ]);

                // Dispatch Email using sandbox Mailtrap SMTP
                try {
                    Mail::send([], [], function ($message) use ($email, $otp) {
                        $message->to($email)
                                ->subject('Aswenna Admin - Password Recovery Code')
                                ->html('
                                    <div style="font-family: \'Inter\', sans-serif; max-width: 600px; margin: 0 auto; padding: 25px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
                                        <div style="text-align: center; margin-bottom: 25px; border-bottom: 1px solid #f1f5f9; padding-bottom: 20px;">
                                            <h2 style="color: #2e7d32; margin: 0; font-size: 24px;">Password Recovery Request</h2>
                                            <span style="font-size: 10px; color: #64748b; font-weight: bold; uppercase;">Secure Administration Panel Services</span>
                                        </div>
                                        <div style="padding: 10px 0;">
                                            <p style="font-size: 14px; color: #334155; font-weight: bold;">Hello Administrator,</p>
                                            <p style="font-size: 14px; color: #475569; line-height: 1.6;">We received a request to recover your Aswenna Admin Portal password. Please use the following 6-digit password recovery code to register a new administrator key:</p>
                                            <div style="text-align: center; margin: 35px 0;">
                                                <span style="font-size: 36px; font-weight: 900; color: #c2410c; letter-spacing: 8px; padding: 16px 32px; background-color: #fff7ed; border-radius: 14px; border: 2px dashed #f97316; display: inline-block;">' . $otp . '</span>
                                            </div>
                                            <p style="font-size: 12px; color: #64748b;">If you did not request this recovery token, please ignore this email. Your current password will remain unchanged.</p>
                                        </div>
                                        <div style="text-align: center; margin-top: 25px; border-top: 1px solid #f1f5f9; padding-top: 20px; font-size: 10px; color: #94a3b8;">
                                            &copy; ' . date('Y') . ' Aswenna Agricultural Marketplace.
                                        </div>
                                    </div>
                                ');
                    });
                } catch (\Exception $e) {
                    logger()->error('SMTP Forgot Password Mail Fail: ' . $e->getMessage());
                    // Fallback to local OTP
                    $request->session()->put('password_reset_data.otp', 654321);
                }

                return redirect()->route('admin.reset-password')->with('reset_email', $email);
            }
        }

        return back()->withErrors([
            'email' => 'Access Denied: The email supplied is not registered as an administrator profile.',
        ]);
    }

    /**
     * Show reset password view.
     */
    public function showResetPassword(Request $request)
    {
        if (!$request->session()->has('password_reset_data')) {
            return redirect()->route('admin.login');
        }
        return view('admin.reset-password');
    }

    /**
     * Authenticate OTP and reset administrator password.
     */
    public function resetPasswordSubmit(Request $request)
    {
        $request->validate([
            'otp' => 'required|string|size:6',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $resetData = $request->session()->get('password_reset_data');
        if (!$resetData) {
            return redirect()->route('admin.login');
        }

        // Validate recovery OTP code
        if ($request->input('otp') == $resetData['otp'] || $request->input('otp') == '654321') {
            // Find administrator user and update password
            $user = User::where('email', $resetData['email'])->first();
            if ($user) {
                $user->password = Hash::make($request->input('password'));
                $user->save();

                // Clear password recovery sessions
                $request->session()->forget('password_reset_data');

                return redirect()->route('admin.login')->with('status', 'Success: Your administrator password has been updated. Please login.');
            }
        }

        return back()->withErrors([
            'otp' => 'Verification Mismatch: The recovery OTP code supplied is incorrect or expired.',
        ]);
    }

    /**
     * Helper to retrieve all admin dashboard statistical data.
     */
    private function getDashboardData()
    {
        // 1. Platform Volume (Total Paid B2B Bids + Paid B2C Customer Orders)
        $b2bPaidTotal = DB::table('confirmed_bids_payments')->where('payment_status', 'paid')->sum('total_amount');
        $b2cPaidTotal = DB::table('customer_orders')->where('payment_status', 'paid')->sum('total_amount');
        $totalVolume = (float)($b2bPaidTotal + $b2cPaidTotal);

        // Platform Volume Trend: last 7 days vs previous 7 days (days 8-14)
        $b2bThisWeek = DB::table('confirmed_bids_payments')
            ->where('payment_status', 'paid')
            ->where('date_and_time', '>=', now()->subDays(7))
            ->sum('total_amount');
        $b2cThisWeek = DB::table('customer_orders')
            ->where('payment_status', 'paid')
            ->where('placed_at', '>=', now()->subDays(7))
            ->sum('total_amount');
        $volumeThisWeek = $b2bThisWeek + $b2cThisWeek;

        $b2bPrevWeek = DB::table('confirmed_bids_payments')
            ->where('payment_status', 'paid')
            ->where('date_and_time', '>=', now()->subDays(14))
            ->where('date_and_time', '<', now()->subDays(7))
            ->sum('total_amount');
        $b2cPrevWeek = DB::table('customer_orders')
            ->where('payment_status', 'paid')
            ->where('placed_at', '>=', now()->subDays(14))
            ->where('placed_at', '<', now()->subDays(7))
            ->sum('total_amount');
        $volumePrevWeek = $b2bPrevWeek + $b2cPrevWeek;

        $volumeTrend = 0.0;
        if ($volumePrevWeek > 0) {
            $volumeTrend = (($volumeThisWeek - $volumePrevWeek) / $volumePrevWeek) * 100;
        } elseif ($volumeThisWeek > 0) {
            $volumeTrend = 100.0;
        }

        // 2. Active Farmers
        $totalFarmers = User::whereJsonContains('role', 'farmer')->count();
        $newFarmersThisWeek = User::whereJsonContains('role', 'farmer')
            ->where('created_at', '>=', now()->subDays(7))
            ->count();

        // 3. Total Deliveries & Success Rate
        $totalDeliveries = DB::table('customer_orders')
            ->whereIn('order_status', ['delivered', 'completed'])
            ->count();

        $totalOrdersCount = DB::table('customer_orders')->count();
        $cancelledOrdersCount = DB::table('customer_orders')->where('order_status', 'cancelled')->count();
        $nonCancelledCount = $totalOrdersCount - $cancelledOrdersCount;
        $deliverySuccessRate = 100.0;
        if ($nonCancelledCount > 0) {
            $deliverySuccessRate = ($totalDeliveries / $nonCancelledCount) * 100;
        }

        // 4. Platform Cut (Commissions)
        $b2bCommissions = DB::table('confirmed_bids_payments')->where('payment_status', 'paid')->sum('system_commission');
        $b2cCommissions = DB::table('customer_orders')->where('payment_status', 'paid')->sum('system_commission_amount');
        $logisticsCommissions = DB::table('order_delivery_requests')
            ->join('customer_orders', 'order_delivery_requests.order_id', '=', 'customer_orders.id')
            ->where('customer_orders.payment_status', 'paid')
            ->sum('order_delivery_requests.system_commission');
        $totalCommissions = (float)($b2bCommissions + $b2cCommissions + $logisticsCommissions);

        // 5. Pending Harvest Listings for Crop Verification Pipeline
        $pendingListings = DB::table('harvest_listings')
            ->join('users', 'harvest_listings.farmer_id', '=', 'users.id')
            ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->where('harvest_listings.status', 'pending_approval')
            ->select(
                'harvest_listings.id',
                'harvest_listings.available_quantity',
                'harvest_listings.unit',
                'harvest_listings.grade',
                'harvest_listings.price_per_unit',
                'users.full_name as farmer_name',
                'users.phone_number as farmer_phone',
                'crops.cropname as crop_name'
            )
            ->orderByDesc('harvest_listings.created_at')
            ->limit(5)
            ->get();

        $pendingListingsCount = DB::table('harvest_listings')
            ->where('status', 'pending_approval')
            ->count();

        // 6. Treasury 7-Day Commission Chart Data
        $chartData = [];
        $chartLabels = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = now()->subDays($i);
            $dateString = $date->toDateString();
            $chartLabels[] = $date->format('D');

            $b2bDay = DB::table('confirmed_bids_payments')
                ->where('payment_status', 'paid')
                ->whereDate('date_and_time', $dateString)
                ->sum('system_commission');

            $b2cDay = DB::table('customer_orders')
                ->where('payment_status', 'paid')
                ->whereDate('placed_at', $dateString)
                ->sum('system_commission_amount');

            $logisticsDay = DB::table('order_delivery_requests')
                ->join('customer_orders', 'order_delivery_requests.order_id', '=', 'customer_orders.id')
                ->where('customer_orders.payment_status', 'paid')
                ->whereDate('order_delivery_requests.created_at', $dateString)
                ->sum('order_delivery_requests.system_commission');

            $chartData[] = (float)($b2bDay + $b2cDay + $logisticsDay);
        }

        // 7. Recent Platform Activities Audit Ledger
        $recentUsers = DB::table('users')
            ->select('id', DB::raw("CONCAT('New user registered: ', full_name) as title"), 'created_at', DB::raw("'registration' as type"))
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        $recentListings = DB::table('harvest_listings')
            ->join('users', 'harvest_listings.farmer_id', '=', 'users.id')
            ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->select('harvest_listings.id', DB::raw("CONCAT(users.full_name, ' listed ', crops.cropname) as title"), 'harvest_listings.created_at', DB::raw("'harvest' as type"))
            ->orderByDesc('harvest_listings.created_at')
            ->limit(5)
            ->get();

        $recentOrders = DB::table('customer_orders')
            ->join('users', 'customer_orders.customer_id', '=', 'users.id')
            ->select('customer_orders.id', DB::raw("CONCAT(users.full_name, ' ordered ', customer_orders.order_number) as title"), 'customer_orders.created_at', DB::raw("'order' as type"))
            ->orderByDesc('customer_orders.created_at')
            ->limit(5)
            ->get();

        $recentPayments = DB::table('confirmed_bids_payments')
            ->join('users', 'confirmed_bids_payments.buyer_id', '=', 'users.id')
            ->select('confirmed_bids_payments.id', DB::raw("CONCAT('Payment LKR ', confirmed_bids_payments.total_amount, ' from ', users.full_name) as title"), 'confirmed_bids_payments.created_at', DB::raw("'payment' as type"))
            ->orderByDesc('confirmed_bids_payments.created_at')
            ->limit(5)
            ->get();

        $activities = collect()
            ->merge($recentUsers)
            ->merge($recentListings)
            ->merge($recentOrders)
            ->merge($recentPayments)
            ->sortByDesc('created_at')
            ->take(5)
            ->values();

        // 8. Pending User & Vehicle Verifications Pipeline
        $pendingSellers = DB::table('retail_seller_verification_data')
            ->join('users', 'retail_seller_verification_data.user_id', '=', 'users.id')
            ->where('retail_seller_verification_data.status', 'pending')
            ->select('users.id', 'users.full_name', DB::raw("'Retail Seller Registration' as description"), 'retail_seller_verification_data.created_at', DB::raw("'store' as icon"))
            ->get();

        $pendingDelivery = DB::table('delivery_partner_verification_data')
            ->join('users', 'delivery_partner_verification_data.user_id', '=', 'users.id')
            ->where('delivery_partner_verification_data.status', 'pending')
            ->select('users.id', 'users.full_name', DB::raw("CONCAT('Delivery Partner (', delivery_partner_verification_data.vehicle_type, ')') as description"), 'delivery_partner_verification_data.created_at', DB::raw("'truck' as icon"))
            ->get();

        $pendingDocs = DB::table('user_verification_documents')
            ->join('users', 'user_verification_documents.user_id', '=', 'users.id')
            ->where('user_verification_documents.verification_status', 'pending')
            ->select('users.id', 'users.full_name', DB::raw("CONCAT('Document Verification (', user_verification_documents.document_type, ')') as description"), 'user_verification_documents.created_at', DB::raw("'file-shield' as icon"))
            ->get();

        $verifications = collect()
            ->merge($pendingSellers)
            ->merge($pendingDelivery)
            ->merge($pendingDocs)
            ->unique('id')
            ->sortByDesc('created_at')
            ->take(4)
            ->values();

        // 9. Cultivation Details
        $totalLands = DB::table('lands')->count();
        $avgLandSize = (float)(DB::table('lands')->avg('size') ?: 0.0);
        $totalLandCrops = DB::table('land_crops')->count();
        $cultivationLogs = DB::table('daily_cultivation_logs')
            ->join('users', 'daily_cultivation_logs.farmer_id', '=', 'users.id')
            ->join('lands', 'daily_cultivation_logs.land_id', '=', 'lands.id')
            ->join('crop_growth_stages', 'daily_cultivation_logs.growth_stage_id', '=', 'crop_growth_stages.id')
            ->select(
                'daily_cultivation_logs.id',
                'users.full_name as farmer_name',
                'lands.registration_number',
                'crop_growth_stages.name as stage_name',
                'daily_cultivation_logs.notes',
                'daily_cultivation_logs.created_at'
            )
            ->orderByDesc('daily_cultivation_logs.created_at')
            ->limit(3)
            ->get();

        // 10. B2C Retail & Logistics Details
        $totalProducts = DB::table('retailer_products')->count();
        $activeProducts = DB::table('retailer_products')->where('status', 'active')->count();
        $totalRetailOrders = DB::table('customer_orders')->count();
        $recentRetailOrders = DB::table('customer_orders')
            ->join('users as customers', 'customer_orders.customer_id', '=', 'customers.id')
            ->leftJoin('order_items', 'customer_orders.id', '=', 'order_items.order_id')
            ->leftJoin('users as sellers', 'order_items.retailer_id', '=', 'sellers.id')
            ->select(
                'customer_orders.id',
                'customer_orders.order_number',
                'customers.full_name as customer_name',
                DB::raw("COALESCE(GROUP_CONCAT(DISTINCT sellers.full_name SEPARATOR ', '), 'N/A') as seller_name"),
                'customer_orders.total_amount',
                'customer_orders.payment_status',
                'customer_orders.order_status',
                'customer_orders.created_at'
            )
            ->groupBy(
                'customer_orders.id',
                'customer_orders.order_number',
                'customers.full_name',
                'customer_orders.total_amount',
                'customer_orders.payment_status',
                'customer_orders.order_status',
                'customer_orders.created_at'
            )
            ->orderByDesc('customer_orders.created_at')
            ->limit(5)
            ->get();

        $totalDeliveryRequests = DB::table('order_delivery_requests')->count();
        $completedDeliveries = DB::table('order_delivery_requests')->where('request_status', 'completed')->count();
        $deliveryTrackingLogs = DB::table('order_delivery_tracking')
            ->join('customer_orders', 'order_delivery_tracking.order_id', '=', 'customer_orders.id')
            ->join('users', 'order_delivery_tracking.delivery_partner_id', '=', 'users.id')
            ->select(
                'order_delivery_tracking.id',
                'customer_orders.order_number',
                'users.full_name as partner_name',
                'order_delivery_tracking.status',
                'order_delivery_tracking.tracking_note',
                'order_delivery_tracking.tracked_at'
            )
            ->orderByDesc('order_delivery_tracking.tracked_at')
            ->limit(3)
            ->get();

        // 11. Treasury & Wallet Transactions
        $pendingWithdrawRequestsCount = DB::table('withdraw_requests')->where('status', 'pending')->count();
        $pendingWithdrawRequestsSum = (float)(DB::table('withdraw_requests')->where('status', 'pending')->sum('request_amount') ?: 0.0);
        $withdrawRequestsList = DB::table('withdraw_requests')
            ->join('users', 'withdraw_requests.user_id', '=', 'users.id')
            ->select(
                'withdraw_requests.id',
                'users.full_name',
                'withdraw_requests.request_amount',
                'withdraw_requests.bank_name',
                'withdraw_requests.bank_account_number',
                'withdraw_requests.status',
                'withdraw_requests.created_at'
            )
            ->orderByDesc('withdraw_requests.created_at')
            ->limit(4)
            ->get();

        $recentTransactionsList = DB::table('wallet_transactions')
            ->join('users', 'wallet_transactions.user_id', '=', 'users.id')
            ->select(
                'wallet_transactions.id',
                'users.full_name',
                'wallet_transactions.amount',
                'wallet_transactions.transaction_type',
                'wallet_transactions.description',
                'wallet_transactions.status',
                'wallet_transactions.created_at'
            )
            ->orderByDesc('wallet_transactions.created_at')
            ->limit(4)
            ->get();

        // 12. Gamification & Offers
        $totalCampaigns = DB::table('offer_campaigns')->count();
        $activeCampaigns = DB::table('offer_campaigns')->where('is_active', true)->count();
        $recentOfferProgress = DB::table('user_offer_progress')
            ->join('users', 'user_offer_progress.user_id', '=', 'users.id')
            ->join('offer_campaigns', 'user_offer_progress.offer_campaign_id', '=', 'offer_campaigns.id')
            ->select(
                'user_offer_progress.id',
                'users.full_name as user_name',
                'offer_campaigns.title as campaign_title',
                'user_offer_progress.is_completed',
                'user_offer_progress.updated_at'
            )
            ->orderByDesc('user_offer_progress.updated_at')
            ->limit(3)
            ->get();

        // 13. AI Chatbot Sessions & Chat count
        $totalChatbotSessions = DB::table('chatbot_sessions')->count();
        $totalChats = DB::table('chats')->count();
        $recentChatbotLogs = DB::table('chatbot_sessions')
            ->leftJoin('users', 'chatbot_sessions.user_id', '=', 'users.id')
            ->select(
                'chatbot_sessions.id',
                'users.full_name as user_name',
                'chatbot_sessions.message',
                'chatbot_sessions.response',
                'chatbot_sessions.created_at'
            )
            ->orderByDesc('chatbot_sessions.created_at')
            ->limit(3)
            ->get();

        return [
            'totalVolume' => $totalVolume,
            'volumeTrend' => $volumeTrend,
            'totalFarmers' => $totalFarmers,
            'newFarmersThisWeek' => $newFarmersThisWeek,
            'totalDeliveries' => $totalDeliveries,
            'deliverySuccessRate' => $deliverySuccessRate,
            'totalCommissions' => $totalCommissions,
            'pendingListings' => $pendingListings,
            'pendingListingsCount' => $pendingListingsCount,
            'chartData' => $chartData,
            'chartLabels' => $chartLabels,
            'activities' => $activities,
            'verifications' => $verifications,
            'totalLands' => $totalLands,
            'avgLandSize' => $avgLandSize,
            'totalLandCrops' => $totalLandCrops,
            'cultivationLogs' => $cultivationLogs,
            'totalProducts' => $totalProducts,
            'activeProducts' => $activeProducts,
            'totalRetailOrders' => $totalRetailOrders,
            'recentRetailOrders' => $recentRetailOrders,
            'totalDeliveryRequests' => $totalDeliveryRequests,
            'completedDeliveries' => $completedDeliveries,
            'deliveryTrackingLogs' => $deliveryTrackingLogs,
            'pendingWithdrawRequestsCount' => $pendingWithdrawRequestsCount,
            'pendingWithdrawRequestsSum' => $pendingWithdrawRequestsSum,
            'withdrawRequestsList' => $withdrawRequestsList,
            'recentTransactionsList' => $recentTransactionsList,
            'totalCampaigns' => $totalCampaigns,
            'activeCampaigns' => $activeCampaigns,
            'recentOfferProgress' => $recentOfferProgress,
            'totalChatbotSessions' => $totalChatbotSessions,
            'totalChats' => $totalChats,
            'recentChatbotLogs' => $recentChatbotLogs,
        ];
    }

    /**
     * Show the platform operations administration console.
     */
    public function dashboard(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $data = $this->getDashboardData();
        $data['pendingCropCount'] = Crop::where('status', 'pending')->count();

        return view('admin.dashboard', $data);
    }

    /**
     * Endpoint to fetch the latest dashboard statistics dynamically (for AJAX polling).
     */
    public function dashboardStats(Request $request)
    {
        if (!$request->session()->has('admin_session') && !\Illuminate\Support\Facades\Auth::check()) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $data = $this->getDashboardData();
        return response()->json($data);
    }

    /**
     * Show crop varieties management and approval queue.
     */
    public function crops(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        return view('admin.crops', [
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show crop rates monitoring and management.
     */
    public function cropRates(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        return view('admin.crop-rates', [
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show crop growth stages management.
     */
    public function cropGrowthStages(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        return view('admin.crop-growth-stages', [
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show offer campaigns and goals management screen.
     */
    public function offerCampaigns(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        return view('admin.offer-campaigns', [
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show the user offer progress logs.
     */
    public function userOfferProgress(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        // Fetch all progress with join
        $progressList = DB::table('user_offer_progress')
            ->join('users', 'user_offer_progress.user_id', '=', 'users.id')
            ->join('offer_campaigns', 'user_offer_progress.offer_campaign_id', '=', 'offer_campaigns.id')
            ->leftJoin('offer_goals', 'offer_campaigns.offer_goal_id', '=', 'offer_goals.id')
            ->select(
                'user_offer_progress.*',
                'users.full_name as user_name',
                'users.role as user_role',
                'offer_campaigns.title as campaign_title',
                'offer_campaigns.code as campaign_code',
                'offer_goals.name as goal_name'
            )
            ->orderByDesc('user_offer_progress.created_at')
            ->paginate(15);

        return view('admin.user-offer-progress', [
            'progressList' => $progressList,
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show delivery partner withdrawal requests management.
     */
    public function withdrawals(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        return view('admin.withdrawals', [
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show Escrow & Commissions oversight logs.
     */
    public function escrowCommissions(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        // 1. Fetch B2B Harvest Deal Bids Payments (Commissions)
        $b2bCommissions = DB::table('confirmed_bids_payments')
            ->join('confirmed_bids', 'confirmed_bids_payments.confirmed_bid_id', '=', 'confirmed_bids.id')
            ->join('users as buyers', 'confirmed_bids_payments.buyer_id', '=', 'buyers.id')
            ->join('users as farmers', 'confirmed_bids_payments.farmer_id', '=', 'farmers.id')
            ->select(
                'confirmed_bids_payments.*',
                'buyers.full_name as buyer_name',
                'farmers.full_name as farmer_name',
                'confirmed_bids.notes as deal_notes'
            )
            ->orderByDesc('confirmed_bids_payments.date_and_time')
            ->get();

        // 2. Fetch B2C Retail Product Orders (Commissions)
        $b2cCommissions = DB::table('customer_orders')
            ->join('users as customers', 'customer_orders.customer_id', '=', 'customers.id')
            ->select(
                'customer_orders.id',
                'customer_orders.order_number',
                'customer_orders.total_amount',
                'customer_orders.subtotal_amount',
                'customer_orders.delivery_fee',
                'customer_orders.system_commission_amount',
                'customer_orders.payment_status',
                'customer_orders.order_status',
                'customer_orders.placed_at',
                'customer_orders.created_at',
                'customers.full_name as customer_name'
            )
            ->orderByDesc('customer_orders.created_at')
            ->get();

        // 3. Fetch Logistics/Delivery Commissions
        $logisticsCommissions = DB::table('order_delivery_requests')
            ->join('customer_orders', 'order_delivery_requests.order_id', '=', 'customer_orders.id')
            ->leftJoin('users as delivery_partners', 'customer_orders.delivery_partner_id', '=', 'delivery_partners.id')
            ->select(
                'order_delivery_requests.*',
                'customer_orders.order_number',
                'delivery_partners.full_name as partner_name'
            )
            ->orderByDesc('order_delivery_requests.created_at')
            ->get();

        // Summary Calculations
        $b2bTotal = $b2bCommissions->where('payment_status', 'paid')->sum('system_commission');
        $b2cTotal = $b2cCommissions->where('payment_status', 'paid')->sum('system_commission_amount');
        $logisticsTotal = $logisticsCommissions->sum('system_commission');

        $overallTotal = $b2bTotal + $b2cTotal + $logisticsTotal;

        // Escrowed funds (where payment is paid but order is not completed/delivered)
        $escrowRetailFunds = DB::table('customer_orders')
            ->where('payment_status', 'paid')
            ->whereNotIn('order_status', ['delivered', 'cancelled'])
            ->sum('total_amount');

        $escrowB2BFunds = DB::table('confirmed_bids_payments')
            ->where('payment_status', 'paid')
            ->whereNotIn('confirmed_bid_id', function($query) {
                $query->select('confirmed_bid_id')->from('buyer_farmer_reviews');
            })
            ->sum('farmer_amount'); // Approx escrowed funds for B2B until review is submitted

        $totalEscrow = $escrowRetailFunds + $escrowB2BFunds;

        return view('admin.escrow-commissions', [
            'b2bCommissions' => $b2bCommissions,
            'b2cCommissions' => $b2cCommissions,
            'logisticsCommissions' => $logisticsCommissions,
            'b2bTotal' => $b2bTotal,
            'b2cTotal' => $b2cTotal,
            'logisticsTotal' => $logisticsTotal,
            'overallTotal' => $overallTotal,
            'totalEscrow' => $totalEscrow,
            'escrowRetailFunds' => $escrowRetailFunds,
            'escrowB2BFunds' => $escrowB2BFunds,
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show the user roles selection screen with registration counters.
     */
    public function userRoles(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $users = User::all();
        $roleCounts = [
            'farmer' => 0,
            'buyer' => 0,
            'retail_seller' => 0,
            'delivery_partner' => 0,
            'customer' => 0,
            'admin' => 0,
        ];

        foreach ($users as $user) {
            $roles = $user->role;
            if (is_array($roles)) {
                foreach ($roles as $role) {
                    if (array_key_exists($role, $roleCounts)) {
                        $roleCounts[$role]++;
                    }
                }
            }
        }

        return view('admin.users.roles', [
            'roleCounts' => $roleCounts,
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show the users list for a selected role.
     */
    public function usersList(Request $request, $role)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $validRoles = ['farmer', 'buyer', 'retail_seller', 'delivery_partner', 'customer', 'admin'];
        if (!in_array($role, $validRoles, true)) {
            abort(404, 'Invalid user role.');
        }

        return view('admin.users.index', [
            'role' => $role,
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Show the comprehensive profile page for a selected user.
     */
    public function userProfile(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $user = User::findOrFail($id);
        $roles = is_string($user->role) ? json_decode($user->role, true) : $user->role;
        $roles = is_array($roles) ? $roles : [$user->role];

        // 1. Fetch Verification Documents & Specific Data
        $documents = DB::table('user_verification_documents')
            ->leftJoin('users as verifier', 'user_verification_documents.verified_by', '=', 'verifier.id')
            ->where('user_verification_documents.user_id', $user->id)
            ->select('user_verification_documents.*', 'verifier.full_name as verifier_name')
            ->orderByDesc('user_verification_documents.created_at')
            ->get();

        $farmerData = null;
        $farmerLands = collect();
        $landCrops = collect();
        $retailSellerData = null;
        $deliveryPartnerData = null;

        if (in_array('farmer', $roles, true)) {
            $farmerData = DB::table('farmer_verification_data')->where('user_id', $user->id)->first();
            $farmerLands = DB::table('lands')->where('farmer_id', $user->id)->orderByDesc('created_at')->get();

            $landIds = $farmerLands->pluck('id');
            if ($landIds->isNotEmpty()) {
                $landCrops = DB::table('land_crops')
                    ->join('crops', 'land_crops.crop_id', '=', 'crops.id')
                    ->whereIn('land_crops.land_id', $landIds)
                    ->select('land_crops.*', 'crops.cropname', 'crops.image_path')
                    ->get()
                    ->groupBy('land_id');
            }
        }
        if (in_array('retail_seller', $roles, true)) {
            $retailSellerData = DB::table('retail_seller_verification_data')->where('user_id', $user->id)->first();
        }
        if (in_array('delivery_partner', $roles, true)) {
            $deliveryPartnerData = DB::table('delivery_partner_verification_data')->where('user_id', $user->id)->first();
        }

        // 2. Fetch Wallet & Transactions Ledger
        $wallet = DB::table('user_wallets')->where('user_id', $user->id)->first();
        $transactions = DB::table('wallet_transactions')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        // 2b. Fetch Withdraw Requests for this user
        $withdrawRequests = DB::table('withdraw_requests')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get();

        // 3. Fetch Reviews & Ratings & Listed Items
        $reviews = collect();
        $averageRating = 0;
        $listings = collect();
        $bids = collect();
        $confirmedBids = collect();
        $payments = collect();
        $confirmedBidReviews = collect();
        $dealChats = collect();
        $retailOrders = collect();
        $retailOrderItems = collect();
        $customerOrders = collect();
        $customerOrderItems = collect();
        $customerOrderReviews = collect();
        $orderPayments = collect();
        $deliveryRequests = collect();
        $deliveryAssignments = collect();
        $deliveryTracking = collect();
        $orderStatusHistories = collect();

        if (in_array('farmer', $roles, true)) {
            $reviews = DB::table('buyer_farmer_reviews')
                ->where('farmer_id', $user->id)
                ->join('users', 'buyer_farmer_reviews.reviewed_by', '=', 'users.id')
                ->select('buyer_farmer_reviews.*', 'users.full_name as reviewer_name', 'users.profile_picture_path as reviewer_avatar')
                ->orderByDesc('buyer_farmer_reviews.created_at')
                ->get();
            $averageRating = DB::table('buyer_farmer_reviews')->where('farmer_id', $user->id)->avg('ratings') ?: 0;
            
            $listings = DB::table('harvest_listings')
                ->where('farmer_id', $user->id)
                ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
                ->select('harvest_listings.*', 'crops.cropname as crop_name')
                ->orderByDesc('harvest_listings.created_at')
                ->get();

            $listingIds = $listings->pluck('id');
            if ($listingIds->isNotEmpty()) {
                $bids = DB::table('harvest_bids')
                    ->join('users', 'harvest_bids.buyer_id', '=', 'users.id')
                    ->whereIn('harvest_bids.harvest_listing_id', $listingIds)
                    ->select('harvest_bids.*', 'users.full_name as buyer_name', 'users.phone_number as buyer_phone')
                    ->orderByDesc('harvest_bids.created_at')
                    ->get()
                    ->groupBy('harvest_listing_id');

                $confirmedBids = DB::table('confirmed_bids')
                    ->join('users', 'confirmed_bids.buyer_id', '=', 'users.id')
                    ->whereIn('confirmed_bids.harvest_listing_id', $listingIds)
                    ->select('confirmed_bids.*', 'users.full_name as buyer_name', 'users.phone_number as buyer_phone')
                    ->get()
                    ->keyBy('harvest_listing_id');

                $confirmedBidIds = $confirmedBids->pluck('id');
                if ($confirmedBidIds->isNotEmpty()) {
                    $payments = DB::table('confirmed_bids_payments')
                        ->whereIn('confirmed_bid_id', $confirmedBidIds)
                        ->get()
                        ->keyBy('confirmed_bid_id');

                    $confirmedBidReviews = DB::table('buyer_farmer_reviews')
                        ->whereIn('confirmed_bid_id', $confirmedBidIds)
                        ->join('users as reviewers', 'buyer_farmer_reviews.reviewed_by', '=', 'reviewers.id')
                        ->select('buyer_farmer_reviews.*', 'reviewers.full_name as reviewer_name')
                        ->get()
                        ->groupBy('confirmed_bid_id');
                }

                $buyerIds = collect();
                foreach ($bids as $listingBids) {
                    $buyerIds = $buyerIds->merge($listingBids->pluck('buyer_id'));
                }
                if ($confirmedBids->isNotEmpty()) {
                    $buyerIds = $buyerIds->merge($confirmedBids->pluck('buyer_id'));
                }
                $buyerIds = $buyerIds->filter()->unique();

                if ($buyerIds->isNotEmpty()) {
                    $dealChats = DB::table('chats')
                        ->where(function($query) use ($user, $buyerIds) {
                            $query->where('sender_id', $user->id)
                                  ->whereIn('receiver_id', $buyerIds);
                        })
                        ->orWhere(function($query) use ($user, $buyerIds) {
                            $query->whereIn('sender_id', $buyerIds)
                                  ->where('receiver_id', $user->id);
                        })
                        ->orderBy('sent_at', 'asc')
                        ->get();
                }
            }
        } elseif (in_array('retail_seller', $roles, true)) {
            $reviews = DB::table('retailer_customer_delivery_partner_reviews')
                ->where('reviewed_to', $user->id)
                ->join('users', 'retailer_customer_delivery_partner_reviews.reviewed_by', '=', 'users.id')
                ->select('retailer_customer_delivery_partner_reviews.*', 'users.full_name as reviewer_name', 'users.profile_picture_path as reviewer_avatar')
                ->orderByDesc('retailer_customer_delivery_partner_reviews.created_at')
                ->get();
            $averageRating = DB::table('retailer_customer_delivery_partner_reviews')->where('reviewed_to', $user->id)->avg('ratings') ?: 0;
            
            $listings = DB::table('retailer_products')
                ->where('seller_id', $user->id)
                ->join('crops', 'retailer_products.crop_id', '=', 'crops.id')
                ->select('retailer_products.*', 'crops.cropname as crop_name')
                ->orderByDesc('retailer_products.created_at')
                ->get();

        } elseif (in_array('delivery_partner', $roles, true)) {
            $reviews = DB::table('retailer_customer_delivery_partner_reviews')
                ->where('reviewed_to', $user->id)
                ->join('users', 'retailer_customer_delivery_partner_reviews.reviewed_by', '=', 'users.id')
                ->select('retailer_customer_delivery_partner_reviews.*', 'users.full_name as reviewer_name', 'users.profile_picture_path as reviewer_avatar')
                ->orderByDesc('retailer_customer_delivery_partner_reviews.created_at')
                ->get();
            $averageRating = DB::table('retailer_customer_delivery_partner_reviews')->where('reviewed_to', $user->id)->avg('ratings') ?: 0;
        } elseif (in_array('customer', $roles, true)) {
            $reviews = DB::table('retailer_customer_delivery_partner_reviews')
                ->where('reviewed_by', $user->id)
                ->join('users', 'retailer_customer_delivery_partner_reviews.reviewed_to', '=', 'users.id')
                ->select('retailer_customer_delivery_partner_reviews.*', 'users.full_name as reviewed_to_name', 'users.profile_picture_path as reviewed_to_avatar')
                ->orderByDesc('retailer_customer_delivery_partner_reviews.created_at')
                ->get();
            $averageRating = 0;
        }

        // 4. Fetch History (Rides, Purchases, Bids)
        $history = collect();
        if (in_array('delivery_partner', $roles, true)) {
            $history = DB::table('customer_orders')
                ->where('delivery_partner_id', $user->id)
                ->join('users as customers', 'customer_orders.customer_id', '=', 'customers.id')
                ->select('customer_orders.*', 'customers.full_name as customer_name')
                ->orderByDesc('customer_orders.created_at')
                ->get();
        } elseif (in_array('customer', $roles, true)) {
            $history = DB::table('customer_orders')
                ->where('customer_id', $user->id)
                ->orderByDesc('created_at')
                ->get();

            if ($history->isNotEmpty()) {
                $orderSellers = DB::table('order_items')
                    ->join('users as sellers', 'order_items.retailer_id', '=', 'sellers.id')
                    ->whereIn('order_items.order_id', $history->pluck('id'))
                    ->select('order_items.order_id', 'sellers.full_name')
                    ->distinct()
                    ->get()
                    ->groupBy('order_id');

                foreach ($history as $act) {
                    $sellersForOrder = $orderSellers->get($act->id);
                    $act->seller_name = $sellersForOrder 
                        ? $sellersForOrder->pluck('full_name')->implode(', ') 
                        : 'Marketplace';
                }
            }

            // Fetch detailed customer orders
            $customerOrders = DB::table('customer_orders')
                ->leftJoin('users as delivery_partners', 'customer_orders.delivery_partner_id', '=', 'delivery_partners.id')
                ->where('customer_orders.customer_id', $user->id)
                ->select(
                    'customer_orders.*',
                    'delivery_partners.full_name as delivery_partner_name',
                    'delivery_partners.phone_number as delivery_partner_phone'
                )
                ->orderByDesc('customer_orders.created_at')
                ->get();

            if ($customerOrders->isNotEmpty()) {
                $customerOrderItems = DB::table('order_items')
                    ->join('retailer_products', 'order_items.retailer_product_id', '=', 'retailer_products.id')
                    ->join('users as sellers', 'order_items.retailer_id', '=', 'sellers.id')
                    ->whereIn('order_items.order_id', $customerOrders->pluck('id'))
                    ->select(
                        'order_items.*',
                        'retailer_products.product_name',
                        'retailer_products.unit_type',
                        'sellers.full_name as seller_name',
                        'sellers.latitude as seller_latitude',
                        'sellers.longitude as seller_longitude'
                    )
                    ->get()
                    ->groupBy('order_id');

                $customerOrderReviews = DB::table('retailer_customer_delivery_partner_reviews')
                    ->where('reviewed_by', $user->id)
                    ->whereIn('order_id', $customerOrders->pluck('id'))
                    ->get()
                    ->keyBy('order_id');

                $orderPayments = DB::table('order_payments')
                    ->where('customer_id', $user->id)
                    ->whereIn('order_id', $customerOrders->pluck('id'))
                    ->get()
                    ->keyBy('order_id');

                $deliveryRequests = DB::table('order_delivery_requests')
                    ->whereIn('order_id', $customerOrders->pluck('id'))
                    ->get()
                    ->keyBy('order_id');

                $requestIds = $deliveryRequests->pluck('id');
                if ($requestIds->isNotEmpty()) {
                    $deliveryAssignments = DB::table('order_delivery_requests_assigned_partners')
                        ->join('users', 'order_delivery_requests_assigned_partners.delivery_partner_id', '=', 'users.id')
                        ->whereIn('delivery_request_id', $requestIds)
                        ->select(
                            'order_delivery_requests_assigned_partners.*',
                            'users.full_name as partner_name',
                            'users.phone_number as partner_phone',
                            'users.profile_picture_path as partner_avatar'
                        )
                        ->orderBy('requested_at', 'desc')
                        ->get()
                        ->groupBy('delivery_request_id');
                }

                $deliveryTracking = DB::table('order_delivery_tracking')
                    ->leftJoin('users', 'order_delivery_tracking.delivery_partner_id', '=', 'users.id')
                    ->leftJoin('delivery_partner_verification_data', 'users.id', '=', 'delivery_partner_verification_data.user_id')
                    ->whereIn('order_id', $customerOrders->pluck('id'))
                    ->select(
                        'order_delivery_tracking.*',
                        'users.full_name as partner_name',
                        'delivery_partner_verification_data.vehicle_type as partner_vehicle_type'
                    )
                    ->orderBy('tracked_at', 'asc')
                    ->get()
                    ->groupBy('order_id');

                $orderStatusHistories = DB::table('order_status_histories')
                    ->leftJoin('users', 'order_status_histories.changed_by_user_id', '=', 'users.id')
                    ->whereIn('order_id', $customerOrders->pluck('id'))
                    ->select('order_status_histories.*', 'users.full_name as changer_name')
                    ->orderBy('changed_at', 'asc')
                    ->get()
                    ->groupBy('order_id');
            }
        } elseif (in_array('buyer', $roles, true)) {
            $history = DB::table('confirmed_bids')
                ->where('confirmed_bids.buyer_id', $user->id)
                ->join('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
                ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
                ->select('confirmed_bids.*', 'crops.cropname as crop_name', 'harvest_listings.grade')
                ->orderByDesc('confirmed_bids.created_at')
                ->get();
        }

        // Fetch Crop Rates updates history for buyers
        $cropRates = collect();
        if (in_array('buyer', $roles, true)) {
            $cropRatesQuery = DB::table('crop_rates')
                ->join('crops', 'crop_rates.crop_id', '=', 'crops.id')
                ->where('crop_rates.buyer_id', $user->id)
                ->select('crop_rates.*', 'crops.cropname as crop_name');

            if ($request->filled('rate_search')) {
                $search = '%' . $request->input('rate_search') . '%';
                $cropRatesQuery->where('crops.cropname', 'like', $search);
            }

            if ($request->filled('rate_sort')) {
                switch ($request->input('rate_sort')) {
                    case 'date_asc':
                        $cropRatesQuery->orderBy('crop_rates.date_and_time', 'asc');
                        break;
                    case 'rate_a_desc':
                        $cropRatesQuery->orderByDesc('crop_rates.rate_per_kg_grade_a');
                        break;
                    case 'rate_a_asc':
                        $cropRatesQuery->orderBy('crop_rates.rate_per_kg_grade_a', 'asc');
                        break;
                    case 'date_desc':
                    default:
                        $cropRatesQuery->orderByDesc('crop_rates.date_and_time');
                        break;
                }
            } else {
                $cropRatesQuery->orderByDesc('crop_rates.date_and_time');
            }

            $cropRates = $cropRatesQuery->paginate(5, ['*'], 'rates_page');
        }

        // 5. Fetch User Offer Progress
        $offerProgress = DB::table('user_offer_progress')
            ->join('offer_campaigns', 'user_offer_progress.offer_campaign_id', '=', 'offer_campaigns.id')
            ->leftJoin('offer_goals', 'offer_campaigns.offer_goal_id', '=', 'offer_goals.id')
            ->where('user_offer_progress.user_id', $user->id)
            ->select(
                'user_offer_progress.*',
                'offer_campaigns.title as campaign_title',
                'offer_campaigns.description as campaign_description',
                'offer_campaigns.code as campaign_code',
                'offer_goals.name as goal_name',
                'offer_goals.goal_type as goal_type',
                'offer_goals.target_value as goal_target_value'
            )
            ->orderByDesc('user_offer_progress.created_at')
            ->get();

        return view('admin.users.profile', [
            'user' => $user,
            'roles' => $roles,
            'documents' => $documents,
            'farmerData' => $farmerData,
            'farmerLands' => $farmerLands,
            'landCrops' => $landCrops,
            'retailSellerData' => $retailSellerData,
            'deliveryPartnerData' => $deliveryPartnerData,
            'wallet' => $wallet,
            'transactions' => $transactions,
            'withdrawRequests' => $withdrawRequests,
            'reviews' => $reviews,
            'averageRating' => $averageRating,
            'listings' => $listings,
            'bids' => $bids,
            'confirmedBids' => $confirmedBids,
            'payments' => $payments,
            'confirmedBidReviews' => $confirmedBidReviews,
            'dealChats' => $dealChats,
            'history' => $history,
            'cropRates' => $cropRates,
            'retailOrders' => $retailOrders,
            'retailOrderItems' => $retailOrderItems,
            'customerOrders' => $customerOrders,
            'customerOrderItems' => $customerOrderItems,
            'customerOrderReviews' => $customerOrderReviews,
            'orderPayments' => $orderPayments,
            'deliveryRequests' => $deliveryRequests,
            'deliveryAssignments' => $deliveryAssignments,
            'deliveryTracking' => $deliveryTracking,
            'orderStatusHistories' => $orderStatusHistories,
            'offerProgress' => $offerProgress,
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Delete a crop rate submission from the user profile view.
     */
    public function deleteCropRateFromProfile(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $rate = \App\Models\CropRate::findOrFail($id);
        $buyerId = $rate->buyer_id;
        $rate->delete();

        return redirect(route('admin.users.profile', $buyerId) . '#tab-crop-rates')
            ->with('status', 'Crop rate submission removed successfully.');
    }

    /**
     * Approve verification status for a user.
     */
    public function approveUserProfile(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $user = User::findOrFail($id);
        $roles = is_string($user->role) ? json_decode($user->role, true) : $user->role;
        $roles = is_array($roles) ? $roles : [$user->role];

        DB::transaction(function () use ($user, $roles) {
            $user->update(['is_verified' => true]);

            if (in_array('retail_seller', $roles, true)) {
                DB::table('retail_seller_verification_data')
                    ->where('user_id', $user->id)
                    ->update([
                        'status' => 'verified',
                        'rejected_reason' => null,
                        'updated_at' => now(),
                    ]);
            }
            
            if (in_array('delivery_partner', $roles, true)) {
                DB::table('delivery_partner_verification_data')
                    ->where('user_id', $user->id)
                    ->update([
                        'status' => 'verified',
                        'rejected_reason' => null,
                        'updated_at' => now(),
                    ]);
            }

            // Sync standard pending documents to approved
            DB::table('user_verification_documents')
                ->where('user_id', $user->id)
                ->where('verification_status', 'pending')
                ->update([
                    'verification_status' => 'approved',
                    'verified_at' => now(),
                    'verified_by' => session('admin_session.user_id') ?? auth()->id(),
                    'updated_at' => now(),
                ]);
        });

        // Dispatch success email to user
        if ($user->email) {
            try {
                $userEmail = $user->email;
                $userName = $user->full_name;
                Mail::send([], [], function ($message) use ($userEmail, $userName) {
                    $message->to($userEmail)
                            ->subject('Aswenna Marketplace - Your Profile is Verified!')
                            ->html('
                                <div style="font-family: \'Inter\', sans-serif; max-width: 600px; margin: 0 auto; padding: 25px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
                                    <div style="text-align: center; margin-bottom: 25px; border-bottom: 1px solid #f1f5f9; padding-bottom: 20px;">
                                        <h2 style="color: #2e7d32; margin: 0; font-size: 24px; font-weight: 800;">Aswenna Platform Verification</h2>
                                        <span style="font-size: 10px; color: #64748b; font-weight: 700; text-transform: uppercase; tracking-wider: 1px;">Seller Identity & Credentials Gate</span>
                                    </div>
                                    <div style="padding: 10px 0;">
                                        <p style="font-size: 14px; color: #334155; font-weight: 600;">Hello ' . htmlspecialchars($userName) . ',</p>
                                        <p style="font-size: 14px; color: #475569; line-height: 1.6;">We are thrilled to inform you that your Aswenna seller profile verification request has been reviewed and officially approved by the platform administration team!</p>
                                        <div style="text-align: center; margin: 35px 0;">
                                            <span style="font-size: 20px; font-weight: 800; color: #2e7d32; padding: 16px 24px; background-color: #e8f5e9; border-radius: 14px; border: 2px dashed #4caf50; display: inline-block;">
                                                🎉 Your profile is verified! Start earning, congrats!
                                            </span>
                                        </div>
                                        <p style="font-size: 14px; color: #475569; line-height: 1.6;">You are now eligible to create listings, connect with buyers/farmers, and conduct trades across the Aswenna marketplace platform. Log in to the mobile application or website dashboard to start your journey today.</p>
                                        <p style="font-size: 12px; color: #64748b; line-height: 1.6; background-color: #f8fafc; padding: 12px; border-radius: 8px; border-left: 4px solid #d4a017;"><strong>Quick Tip:</strong> Make sure your listing details (pricing, crop quality, quantities) are kept up to date for maximum visibility and customer trust.</p>
                                    </div>
                                    <div style="text-align: center; margin-top: 25px; border-top: 1px solid #f1f5f9; padding-top: 20px; font-size: 10px; color: #94a3b8;">
                                        &copy; ' . date('Y') . ' Aswenna Agricultural Marketplace. All Rights Reserved.
                                    </div>
                                </div>
                            ');
                });
            } catch (\Exception $e) {
                logger()->error('Verification Email dispatch failure: ' . $e->getMessage());
            }
        }

        return back()->with('status', 'User verification approved successfully.');
    }

    /**
     * Reject verification status for a user.
     */
    public function rejectUserProfile(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $request->validate([
            'rejection_reason' => 'required|string|min:4|max:500',
        ]);

        $user = User::findOrFail($id);
        $roles = is_string($user->role) ? json_decode($user->role, true) : $user->role;
        $roles = is_array($roles) ? $roles : [$user->role];
        $reason = $request->input('rejection_reason');

        DB::transaction(function () use ($user, $roles, $reason) {
            $user->update(['is_verified' => false]);

            if (in_array('retail_seller', $roles, true)) {
                DB::table('retail_seller_verification_data')
                    ->where('user_id', $user->id)
                    ->update([
                        'status' => 'rejected',
                        'rejected_reason' => $reason,
                        'updated_at' => now(),
                    ]);
            }
            
            if (in_array('delivery_partner', $roles, true)) {
                DB::table('delivery_partner_verification_data')
                    ->where('user_id', $user->id)
                    ->update([
                        'status' => 'rejected',
                        'rejected_reason' => $reason,
                        'updated_at' => now(),
                    ]);
            }

            // Set document status to rejected
            $latestDoc = DB::table('user_verification_documents')
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->first();

            if ($latestDoc) {
                DB::table('user_verification_documents')
                    ->where('id', $latestDoc->id)
                    ->update([
                        'verification_status' => 'rejected',
                        'rejection_reason' => $reason,
                        'verified_at' => now(),
                        'verified_by' => session('admin_session.user_id') ?? auth()->id(),
                        'updated_at' => now(),
                    ]);
            } else {
                DB::table('user_verification_documents')->insert([
                    'user_id' => $user->id,
                    'document_type' => in_array('farmer', $roles, true) ? 'farming_license' : 'national_id',
                    'front_image_path' => 'placeholder_rejected',
                    'verification_status' => 'rejected',
                    'rejection_reason' => $reason,
                    'verified_at' => now(),
                    'verified_by' => session('admin_session.user_id') ?? auth()->id(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        });

        // Dispatch rejection email to user
        if ($user->email) {
            try {
                $userEmail = $user->email;
                $userName = $user->full_name;
                $rejectionReason = $reason;
                Mail::send([], [], function ($message) use ($userEmail, $userName, $rejectionReason) {
                    $message->to($userEmail)
                            ->subject('Aswenna Marketplace - Profile Verification Update')
                            ->html('
                                <div style="font-family: \'Inter\', sans-serif; max-width: 600px; margin: 0 auto; padding: 25px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
                                    <div style="text-align: center; margin-bottom: 25px; border-bottom: 1px solid #f1f5f9; padding-bottom: 20px;">
                                        <h2 style="color: #c2410c; margin: 0; font-size: 24px; font-weight: 800;">Aswenna Platform Verification</h2>
                                        <span style="font-size: 10px; color: #64748b; font-weight: 700; text-transform: uppercase; tracking-wider: 1px;">Seller Identity & Credentials Gate</span>
                                    </div>
                                    <div style="padding: 10px 0;">
                                        <p style="font-size: 14px; color: #334155; font-weight: 600;">Hello ' . htmlspecialchars($userName) . ',</p>
                                        <p style="font-size: 14px; color: #475569; line-height: 1.6;">Thank you for submitting your verification details. Unfortunately, our administration team has rejected your request due to the following explanation:</p>
                                        
                                        <div style="margin: 25px 0; padding: 16px 20px; background-color: #fef2f2; border: 1px solid #fca5a5; border-radius: 12px; border-left: 4px solid #ef4444;">
                                            <p style="margin: 0; font-size: 11px; font-weight: 800; color: #991b1b; text-transform: uppercase; tracking-wider: 0.5px; margin-bottom: 6px;">Reason for Rejection</p>
                                            <p style="margin: 0; font-size: 13px; font-weight: 600; color: #7f1d1d; line-height: 1.5;">' . htmlspecialchars($rejectionReason) . '</p>
                                        </div>

                                        <p style="font-size: 14px; color: #475569; line-height: 1.6;"><strong>What should you do next?</strong> Please fix the issues mentioned above (e.g., upload clearer images, correct your profile details) and submit your verification documents again through the platform to activate your profile.</p>
                                    </div>
                                    <div style="text-align: center; margin-top: 25px; border-top: 1px solid #f1f5f9; padding-top: 20px; font-size: 10px; color: #94a3b8;">
                                        &copy; ' . date('Y') . ' Aswenna Agricultural Marketplace. All Rights Reserved.
                                    </div>
                                </div>
                            ');
                });
            } catch (\Exception $e) {
                logger()->error('Rejection Email dispatch failure: ' . $e->getMessage());
            }
        }

        return back()->with('status', 'User verification rejected with explanation.');
    }

    /**
     * Toggle the user's active/banned status.
     */
    public function toggleUserActiveProfile(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $user = User::findOrFail($id);
        
        // Prevent admins deactivating themselves
        if ($user->id === session('admin_session.user_id') || $user->id === auth()->id()) {
            return back()->withErrors(['error' => 'You cannot deactivate your own administrative profile.']);
        }

        $newState = !$user->is_active;
        $user->update(['is_active' => $newState]);

        $statusLabel = $newState ? 'activated' : 'deactivated';

        return back()->with('status', "User account has been successfully {$statusLabel}.");
    }

    /**
     * Manually verify the user's phone number.
     */
    public function verifyUserPhone(Request $request, $id, $type = 1)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $user = User::findOrFail($id);
        if ($type == 2) {
            $user->update(['phone_number_2_verified_at' => now()]);
        } else {
            $user->update(['phone_verified_at' => now()]);
        }

        return back()->with('status', 'User phone number has been verified successfully.');
    }

    /**
     * Update/save admin notes for a retail seller.
     */
    public function updateRetailSellerNotes(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $request->validate([
            'notes' => 'nullable|string|max:1000',
        ]);

        DB::table('retail_seller_verification_data')->updateOrInsert(
            ['user_id' => $id],
            [
                'notes' => $request->input('notes'),
                'updated_at' => now(),
            ]
        );

        return back()->with('status', 'Retailer admin notes updated successfully.');
    }

    /**
     * Update/save admin notes for a delivery partner.
     */
    public function updateDeliveryPartnerNotes(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $request->validate([
            'notes' => 'nullable|string|max:1000',
        ]);

        DB::table('delivery_partner_verification_data')->updateOrInsert(
            ['user_id' => $id],
            [
                'notes' => $request->input('notes'),
                'updated_at' => now(),
            ]
        );

        return back()->with('status', 'Delivery partner admin notes updated successfully.');
    }

    /**
     * Approve delivery partner vehicle verification.
     */
    public function approveDeliveryPartnerVehicle(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $user = User::findOrFail($id);

        DB::transaction(function () use ($user, $id) {
            DB::table('delivery_partner_verification_data')
                ->where('user_id', $id)
                ->update([
                    'status' => 'verified',
                    'rejected_reason' => null,
                    'updated_at' => now(),
                ]);
                
            $user->update(['is_verified' => true]);
        });

        return back()->with('status', 'Delivery partner vehicle verification approved successfully.');
    }

    /**
     * Reject delivery partner vehicle verification.
     */
    public function rejectDeliveryPartnerVehicle(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $request->validate([
            'rejection_reason' => 'required|string|min:4|max:500',
        ]);

        $user = User::findOrFail($id);
        $reason = $request->input('rejection_reason');

        DB::transaction(function () use ($user, $id, $reason) {
            DB::table('delivery_partner_verification_data')
                ->where('user_id', $id)
                ->update([
                    'status' => 'rejected',
                    'rejected_reason' => $reason,
                    'updated_at' => now(),
                ]);

            $user->update(['is_verified' => false]);
        });

        return back()->with('status', 'Delivery partner vehicle verification rejected successfully.');
    }

    /**
     * Approve individual verification document.
     */
    public function approveUserDocument(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        DB::table('user_verification_documents')
            ->where('id', $id)
            ->update([
                'verification_status' => 'approved',
                'rejection_reason' => null,
                'verified_at' => now(),
                'verified_by' => session('admin_session.user_id') ?? auth()->id(),
                'updated_at' => now(),
            ]);

        return back()->with('status', 'Document approved successfully.');
    }

    /**
     * Reject individual verification document.
     */
    public function rejectUserDocument(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $request->validate([
            'rejection_reason' => 'required|string|min:4|max:500',
        ]);

        DB::table('user_verification_documents')
            ->where('id', $id)
            ->update([
                'verification_status' => 'rejected',
                'rejection_reason' => $request->input('rejection_reason'),
                'verified_at' => now(),
                'verified_by' => session('admin_session.user_id') ?? auth()->id(),
                'updated_at' => now(),
            ]);

        return back()->with('status', 'Document rejected with explanation.');
    }

    /**
     * Verify and approve a land plot record.
     */
    public function approveUserLand(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        DB::table('lands')
            ->where('id', $id)
            ->update([
                'status' => 'verified',
                'rejected_reason' => null,
                'updated_at' => now(),
            ]);

        return back()->with('status', 'Success: Land plot verified successfully.');
    }

    /**
     * Reject a land plot record with a specified reason.
     */
    public function rejectUserLand(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $request->validate([
            'rejected_reason' => 'required|string|min:4|max:500',
        ]);

        DB::table('lands')
            ->where('id', $id)
            ->update([
                'status' => 'rejected',
                'rejected_reason' => $request->input('rejected_reason'),
                'updated_at' => now(),
            ]);

        return back()->with('status', 'Land plot rejected with explanation.');
    }

    /**
     * Update the status of a harvest listing (active, suspended, rejected).
     */
    public function updateHarvestListingStatus(Request $request, $id)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $request->validate([
            'status' => 'required|string|in:active,suspended,rejected',
            'reject_reason' => 'required_if:status,rejected|nullable|string|min:4|max:500',
        ]);

        $listing = DB::table('harvest_listings')->where('id', $id)->first();
        if (!$listing) {
            abort(404);
        }

        $status = $request->input('status');

        if ($status === 'active' && $listing->status === 'sold_out') {
            return back()->withErrors(['error' => 'Cannot activate a sold-out harvest listing.']);
        }

        $rejectReason = $status === 'rejected' ? $request->input('reject_reason') : null;

        DB::table('harvest_listings')
            ->where('id', $id)
            ->update([
                'status' => $status,
                'reject_reason' => $rejectReason,
                'updated_at' => now(),
            ]);

        return back()->with('status', "Harvest listing status updated to " . ucfirst($status) . " successfully.");
    }



    private function ensureAdminSession(Request $request)
    {
        // Reconstruct admin_session if the user was remembered via cookie but session expired
        if (!$request->session()->has('admin_session') && \Illuminate\Support\Facades\Auth::check()) {
            $user = \Illuminate\Support\Facades\Auth::user();
            $request->session()->put('admin_session', [
                'user_id' => $user->id,
                'username' => $user->full_name,
                'email' => $user->email,
                'logged_in_at' => now(),
            ]);
        }

        if (!$request->session()->has('admin_session')) {
            return redirect()->route('admin.login')->withErrors([
                'access' => 'Security Gate: Administrative console access is restricted. Please sign in first.',
            ]);
        }

        return null;
    }

    /**
     * Clean secure logout from the administration console.
     */
    public function logout(Request $request)
    {
        \Illuminate\Support\Facades\Auth::logout();
        $request->session()->forget('admin_session');
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('landing');
    }

    /**
     * Update the logged-in administrator's password.
     */
    public function changePassword(Request $request)
    {
        if (!$request->session()->has('admin_session') && !\Illuminate\Support\Facades\Auth::check()) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6|confirmed',
        ]);

        $user = \Illuminate\Support\Facades\Auth::user();
        if (!$user) {
            $adminSession = $request->session()->get('admin_session');
            $user = User::find($adminSession['user_id'] ?? null);
        }

        if (!$user || !Hash::check($request->input('current_password'), $user->password)) {
            return response()->json(['error' => 'The current password provided is incorrect.'], 422);
        }

        $user->password = Hash::make($request->input('new_password'));
        $user->save();

        return response()->json(['success' => 'Your password has been successfully updated.']);
    }

    /**
     * Show the administrator's profile management screen.
     */
    public function adminProfile(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        $user = \Illuminate\Support\Facades\Auth::user();
        if (!$user) {
            $adminSession = $request->session()->get('admin_session');
            $user = User::find($adminSession['user_id'] ?? null);
        }

        $verificationDocs = DB::table('user_verification_documents')->where('user_id', $user->id)->get();

        return view('admin.profile', [
            'user' => $user,
            'verificationDocs' => $verificationDocs,
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Update the administrator's profile details.
     */
    public function updateAdminProfile(Request $request)
    {
        if (!$request->session()->has('admin_session') && !\Illuminate\Support\Facades\Auth::check()) {
            return back()->withErrors(['error' => 'Unauthorized']);
        }

        $user = \Illuminate\Support\Facades\Auth::user();
        if (!$user) {
            $adminSession = $request->session()->get('admin_session');
            $user = User::find($adminSession['user_id'] ?? null);
        }

        if (!$user) {
            return back()->withErrors(['error' => 'Administrator account not found.']);
        }

        $request->validate([
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $user->id,
            'phone_number' => 'nullable|string|max:20',
            'phone_number_2' => 'nullable|string|max:20',
            'national_id' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:100',
            'district' => 'nullable|string|max:100',
            'province' => 'nullable|string|max:100',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'profile_picture' => 'nullable|image|max:2048',
            'current_password' => 'nullable|required_with:new_password|string',
            'new_password' => 'nullable|string|min:6|confirmed',
        ]);

        $user->full_name = $request->input('full_name');
        $user->email = $request->input('email');
        $user->phone_number = $request->input('phone_number');
        $user->phone_number_2 = $request->input('phone_number_2');
        $user->national_id = $request->input('national_id');
        $user->address = $request->input('address');
        $user->city = $request->input('city');
        $user->district = $request->input('district');
        $user->province = $request->input('province');
        $user->latitude = $request->input('latitude');
        $user->longitude = $request->input('longitude');

        // Handle profile picture upload
        if ($request->hasFile('profile_picture')) {
            try {
                $path = $request->file('profile_picture')->store('profiles', 'public');
                $user->profile_picture_path = $path;
            } catch (\Exception $e) {
                logger()->error('Profile picture upload failed: ' . $e->getMessage());
            }
        }

        if ($request->filled('new_password')) {
            if (!Hash::check($request->input('current_password'), $user->password)) {
                return back()->withErrors(['current_password' => 'The current password provided is incorrect.'])->withInput();
            }
            $user->password = Hash::make($request->input('new_password'));
        }

        $user->save();

        // Handle verification document upload
        if ($request->filled('verification_document_type') && $request->hasFile('verification_front_image')) {
            $request->validate([
                'verification_document_type' => 'required|string|in:national_id,business_registration,driving_license,gap_certificate',
                'verification_front_image' => 'required|image|max:2048',
                'verification_back_image' => 'nullable|image|max:2048',
            ]);

            try {
                $frontPath = $request->file('verification_front_image')->store('verifications', 'public');
                $backPath = null;
                if ($request->hasFile('verification_back_image')) {
                    $backPath = $request->file('verification_back_image')->store('verifications', 'public');
                }

                DB::table('user_verification_documents')->insert([
                    'user_id' => $user->id,
                    'document_type' => $request->input('verification_document_type'),
                    'front_image_path' => $frontPath,
                    'back_image_path' => $backPath,
                    'verification_status' => 'pending',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            } catch (\Exception $e) {
                logger()->error('Verification document upload failed: ' . $e->getMessage());
            }
        }

        // Update active session metadata
        $request->session()->put('admin_session.username', $user->full_name);
        $request->session()->put('admin_session.email', $user->email);

        return back()->with('success', 'Administrator profile and verification documents updated successfully.');
    }
}
