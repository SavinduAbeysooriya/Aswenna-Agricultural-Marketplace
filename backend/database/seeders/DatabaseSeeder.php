<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Seed Super Administrator User
        User::updateOrCreate(
            ['phone_number' => '0771234567'],
            [
                'full_name' => 'Super Administrator',
                'email' => 'admin@aswenna.lk',
                'password' => Hash::make('adminpassword'),
                'role' => ['admin'],
                'is_verified' => true,
                'is_active' => true,
            ]
        );

        // 2. Seed Test Farmer User
        User::updateOrCreate(
            ['phone_number' => '0777123456'],
            [
                'full_name' => 'Saman Kumara',
                'email' => 'saman@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['farmer'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '124, Nuwara Eliya Rd',
                'city' => 'Nuwara Eliya',
                'district' => 'Nuwara Eliya',
                'province' => 'Central',
            ]
        );

        // 3. Seed Test Bulk Buyer User
        User::updateOrCreate(
            ['phone_number' => '0777234567'],
            [
                'full_name' => 'Keeri Samba Mills Ltd',
                'email' => 'buyer@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['buyer'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '45, Industrial Zone',
                'city' => 'Polonnaruwa',
                'district' => 'Polonnaruwa',
                'province' => 'North Central',
            ]
        );

        // 4. Seed Test Retail Store Seller User
        User::updateOrCreate(
            ['phone_number' => '0777345678'],
            [
                'full_name' => 'Agro Retail Mart',
                'email' => 'retail@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['retail_seller'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '78, High Level Road',
                'city' => 'Maharagama',
                'district' => 'Colombo',
                'province' => 'Western',
            ]
        );

        // 5. Seed Test Delivery Partner User
        User::updateOrCreate(
            ['phone_number' => '0777456789'],
            [
                'full_name' => 'Nuwara Courier Express',
                'email' => 'delivery@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['delivery_partner'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '22, Main Street',
                'city' => 'Kandy',
                'district' => 'Kandy',
                'province' => 'Central',
            ]
        );

        // 6. Seed Test Standard Customer User
        User::updateOrCreate(
            ['phone_number' => '0777567890'],
            [
                'full_name' => 'Lakmal Perera',
                'email' => 'customer@aswenna.lk',
                'password' => Hash::make('password123'),
                'role' => ['customer'],
                'is_verified' => true,
                'is_active' => true,
                'address' => '99/A, Galle Road',
                'city' => 'Colombo 03',
                'district' => 'Colombo',
                'province' => 'Western',
            ]
        );
    }
}
