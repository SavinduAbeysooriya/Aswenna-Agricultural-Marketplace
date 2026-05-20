<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Exception;

class AuthController extends Controller
{
    /**
     * Handle user registration.
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'full_name' => 'required|string|max:255',
            'phone_number' => 'required|string|unique:users,phone_number',
            'email' => 'nullable|email|unique:users,email',
            'password' => 'required|string|min:6',
            'province' => 'nullable|string|max:100',
            'district' => 'nullable|string|max:100',
            'role' => 'required|string', // 'farmer', 'buyer', 'retail_seller', 'delivery_partner', 'customer'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors occurred.',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();

        try {
            // Create base User
            $user = User::create([
                'full_name' => $request->full_name,
                'phone_number' => $request->phone_number,
                'email' => $request->email,
                'password' => $request->password, // automatically hashed by the User cast in Laravel 11/10
                'province' => $request->province,
                'district' => $request->district,
                'role' => [$request->role],
                'is_verified' => false,
                'is_active' => true,
            ]);

            // Save specialized profile verification info
            $role = $request->role;
            if ($role === 'farmer') {
                DB::table('farmer_verification_data')->insert([
                    'user_id' => $user->id,
                    'farming_license_number' => $request->farming_license_number ?? null,
                    'total_lands' => $request->total_lands ?? 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            } elseif ($role === 'retail_seller') {
                DB::table('retail_seller_verification_data')->insert([
                    'user_id' => $user->id,
                    'br_number' => $request->br_number ?? null,
                    'shop_address' => $request->shop_address ?? null,
                    'status' => 'pending',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            } elseif ($role === 'delivery_partner') {
                DB::table('delivery_partner_verification_data')->insert([
                    'user_id' => $user->id,
                    'vehicle_type' => $request->vehicle_type ?? null,
                    'status' => 'pending',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Create user wallet
            DB::table('user_wallets')->insert([
                'user_id' => $user->id,
                'available_balance' => 0.00,
                'pending_balance' => 0.00,
                'total_earned' => 0.00,
                'total_withdrawn' => 0.00,
                'last_updated_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::commit();

            // Generate personal access token
            $token = $user->createToken('aswenna_auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'User registered successfully!',
                'token' => $token,
                'user' => $user
            ], 201);

        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to create user account.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Handle user login.
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|string',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::where('phone_number', $request->phone_number)
            ->orWhere('email', $request->phone_number)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials.'
            ], 401);
        }

        // Update last login
        $user->update([
            'last_login_at' => now()
        ]);

        $token = $user->createToken('aswenna_auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful!',
            'token' => $token,
            'user' => $user
        ], 200);
    }

    /**
     * Handle Google OAuth registration flow from mobile.
     */
    public function googleRegister(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'role' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        try {
            // Generate a dummy phone number and extract a name since they aren't provided in this flow
            $dummyPhone = 'G-' . time() . rand(1000, 9999);
            $extractedName = explode('@', $request->email)[0];

            $user = User::create([
                'full_name' => ucwords(str_replace(['.', '_', '-'], ' ', $extractedName)),
                'email' => $request->email,
                'phone_number' => $dummyPhone,
                'password' => $request->password, // automatically hashed
                'role' => [$request->role],
                'is_verified' => false,
                'is_active' => true,
            ]);

            // Save specialized profile verification info based on role
            $role = $request->role;
            if ($role === 'farmer') {
                DB::table('farmer_verification_data')->insert([
                    'user_id' => $user->id,
                    'total_lands' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            } elseif ($role === 'retail_seller') {
                DB::table('retail_seller_verification_data')->insert([
                    'user_id' => $user->id,
                    'status' => 'pending',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            } elseif ($role === 'delivery_partner') {
                DB::table('delivery_partner_verification_data')->insert([
                    'user_id' => $user->id,
                    'status' => 'pending',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Create user wallet
            DB::table('user_wallets')->insert([
                'user_id' => $user->id,
                'available_balance' => 0.00,
                'pending_balance' => 0.00,
                'total_earned' => 0.00,
                'total_withdrawn' => 0.00,
                'last_updated_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::commit();

            $token = $user->createToken('aswenna_auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Google registration successful!',
                'token' => $token,
                'user' => $user
            ], 201);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to complete Google registration.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
