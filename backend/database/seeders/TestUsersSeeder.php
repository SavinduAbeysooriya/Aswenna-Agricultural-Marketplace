<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class TestUsersSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = [
            [
                'full_name' => 'Saman Kumara (Farmer)',
                'phone_number' => '0711111111',
                'email' => 'farmer@aswenna.com',
                'role' => ['farmer'],
            ],
            [
                'full_name' => 'Keeri Samba Mills (Buyer)',
                'phone_number' => '0722222222',
                'email' => 'buyer@aswenna.com',
                'role' => ['buyer'],
            ],
            [
                'full_name' => 'Agro Retail (Retail Seller)',
                'phone_number' => '0733333333',
                'email' => 'retailer@aswenna.com',
                'role' => ['retail_seller'],
            ],
            [
                'full_name' => 'Nuwara Courier (Delivery Partner)',
                'phone_number' => '0744444444',
                'email' => 'delivery@aswenna.com',
                'role' => ['delivery_partner'],
            ],
            [
                'full_name' => 'Lakmal Perera (Customer)',
                'phone_number' => '0755555555',
                'email' => 'customer@aswenna.com',
                'role' => ['customer'],
            ],
        ];

        foreach ($users as $userData) {
            $user = User::firstOrCreate(
                ['phone_number' => $userData['phone_number']],
                [
                    'full_name' => $userData['full_name'],
                    'email' => $userData['email'],
                    'password' => Hash::make('password123'),
                    'role' => $userData['role'],
                    'is_verified' => true,
                    'is_active' => true,
                ]
            );

            // Create wallet if it doesn't exist
            $walletExists = DB::table('user_wallets')->where('user_id', $user->id)->exists();
            if (!$walletExists) {
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
            }
        }
    }
}
