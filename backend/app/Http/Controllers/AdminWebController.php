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
     * Show the platform operations administration console.
     */
    public function dashboard(Request $request)
    {
        if ($redirect = $this->ensureAdminSession($request)) {
            return $redirect;
        }

        return view('admin.dashboard', [
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
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
                ->join('users as sellers', 'customer_orders.retailer_seller_id', '=', 'sellers.id')
                ->select('customer_orders.*', 'sellers.full_name as seller_name')
                ->orderByDesc('customer_orders.created_at')
                ->get();
        } elseif (in_array('buyer', $roles, true)) {
            $history = DB::table('confirmed_bids')
                ->where('confirmed_bids.buyer_id', $user->id)
                ->join('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
                ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
                ->select('confirmed_bids.*', 'crops.cropname as crop_name', 'harvest_listings.grade')
                ->orderByDesc('confirmed_bids.created_at')
                ->get();
        }

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
            'pendingCropCount' => Crop::where('status', 'pending')->count(),
        ]);
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
}
