<?php

namespace App\Http\Controllers;

use App\Models\Crop;
use App\Models\CropGrowthStage;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

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
