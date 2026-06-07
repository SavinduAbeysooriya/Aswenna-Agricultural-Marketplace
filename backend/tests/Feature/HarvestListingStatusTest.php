<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Crop;
use App\Models\HarvestListing;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HarvestListingStatusTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_update_harvest_listing_status_to_active()
    {
        // 1. Setup Admin User
        $admin = User::factory()->create([
            'role' => json_encode(['admin']),
            'full_name' => 'Admin Test',
            'email' => 'admin@test.com',
        ]);

        // 2. Setup Farmer User
        $farmer = User::factory()->create([
            'role' => json_encode(['farmer']),
            'full_name' => 'Farmer Test',
        ]);

        // 3. Setup Crop
        $crop = Crop::create([
            'cropname' => 'Test Carrot',
            'scientificname' => 'Daucus carota',
            'category' => 'Vegetable',
            'status' => 'approved',
        ]);

        // 4. Setup Harvest Listing
        $listing = HarvestListing::create([
            'farmer_id' => $farmer->id,
            'crop_id' => $crop->id,
            'date_and_time' => now(),
            'notes' => 'Some notes',
            'grade' => 'A',
            'available_quantity' => 100,
            'unit' => 'kg',
            'minimum_order_quantity' => 10,
            'maximum_order_quantity' => 50,
            'price_per_unit' => 200,
            'harvest_date' => now()->subDays(2),
            'harvest_condition' => 'fresh',
            'available_from_date' => now(),
            'available_to_date' => now()->addDays(5),
            'status' => 'pending_approval',
        ]);

        // 5. Submit Status Update as Admin
        $response = $this->actingAs($admin)
            ->withSession([
                'admin_session' => [
                    'user_id' => $admin->id,
                    'username' => $admin->full_name,
                    'email' => $admin->email,
                    'logged_in_at' => now(),
                ]
            ])
            ->post(route('admin.harvest-listings.update-status', $listing->id), [
                'status' => 'active',
            ]);

        // 6. Assertions
        $response->assertRedirect();
        $response->assertSessionHas('status', 'Harvest listing status updated to Active successfully.');
        
        $this->assertDatabaseHas('harvest_listings', [
            'id' => $listing->id,
            'status' => 'active',
            'reject_reason' => null,
        ]);
    }

    public function test_admin_can_update_harvest_listing_status_to_rejected_with_reason()
    {
        $admin = User::factory()->create([
            'role' => json_encode(['admin']),
            'full_name' => 'Admin Test',
            'email' => 'admin@test.com',
        ]);

        $farmer = User::factory()->create([
            'role' => json_encode(['farmer']),
        ]);

        $crop = Crop::create([
            'cropname' => 'Test Potato',
            'scientificname' => 'Solanum tuberosum',
            'category' => 'Vegetable',
            'status' => 'approved',
        ]);

        $listing = HarvestListing::create([
            'farmer_id' => $farmer->id,
            'crop_id' => $crop->id,
            'date_and_time' => now(),
            'notes' => 'Some notes',
            'grade' => 'B',
            'available_quantity' => 200,
            'unit' => 'kg',
            'minimum_order_quantity' => 20,
            'maximum_order_quantity' => 100,
            'price_per_unit' => 150,
            'harvest_date' => now()->subDays(3),
            'harvest_condition' => 'fresh',
            'available_from_date' => now(),
            'available_to_date' => now()->addDays(6),
            'status' => 'active',
        ]);

        $response = $this->actingAs($admin)
            ->withSession([
                'admin_session' => [
                    'user_id' => $admin->id,
                    'username' => $admin->full_name,
                    'email' => $admin->email,
                    'logged_in_at' => now(),
                ]
            ])
            ->post(route('admin.harvest-listings.update-status', $listing->id), [
                'status' => 'rejected',
                'reject_reason' => 'Quality does not meet standard requirements.',
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('status', 'Harvest listing status updated to Rejected successfully.');

        $this->assertDatabaseHas('harvest_listings', [
            'id' => $listing->id,
            'status' => 'rejected',
            'reject_reason' => 'Quality does not meet standard requirements.',
        ]);
    }

    public function test_admin_can_view_profile_with_listings_bids_and_payments()
    {
        $admin = User::factory()->create([
            'role' => json_encode(['admin']),
            'full_name' => 'Admin User',
            'email' => 'admin@test.com',
        ]);

        $farmer = User::factory()->create([
            'role' => json_encode(['farmer']),
            'full_name' => 'Farmer Bob',
        ]);

        // Create farmer_verification_data so $farmerData is not null and tab loads
        \Illuminate\Support\Facades\DB::table('farmer_verification_data')->insert([
            'user_id' => $farmer->id,
            'total_lands' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $buyer = User::factory()->create([
            'role' => json_encode(['buyer']),
            'full_name' => 'Buyer Alice',
            'phone_number' => '0779998887',
        ]);

        $crop = Crop::create([
            'cropname' => 'Test Apple',
            'scientificname' => 'Malus domestica',
            'category' => 'Fruit',
            'status' => 'approved',
        ]);

        $listing = HarvestListing::create([
            'farmer_id' => $farmer->id,
            'crop_id' => $crop->id,
            'date_and_time' => now(),
            'notes' => 'Crisp red apples.',
            'grade' => 'A',
            'available_quantity' => 500,
            'unit' => 'kg',
            'minimum_order_quantity' => 50,
            'maximum_order_quantity' => 500,
            'price_per_unit' => 300,
            'harvest_date' => now()->subDays(1),
            'harvest_condition' => 'fresh',
            'available_from_date' => now(),
            'available_to_date' => now()->addDays(5),
            'status' => 'active',
        ]);

        // Insert Bid
        $bidId = \Illuminate\Support\Facades\DB::table('harvest_bids')->insertGetId([
            'buyer_id' => $buyer->id,
            'harvest_listing_id' => $listing->id,
            'bid_amount_per_unit' => 295.00,
            'bid_quantity_unit' => 500.00,
            'notes' => 'Bulk bid.',
            'status' => 'accepted',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Insert Confirmed Bid
        $confirmedBidId = \Illuminate\Support\Facades\DB::table('confirmed_bids')->insertGetId([
            'buyer_id' => $buyer->id,
            'harvest_listing_id' => $listing->id,
            'farmer_id' => $farmer->id,
            'bid_id' => $bidId,
            'notes' => 'Confirmed deal.',
            'total_amount' => 147500.00,
            'payment_status' => 'paid',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Insert Payment
        \Illuminate\Support\Facades\DB::table('confirmed_bids_payments')->insert([
            'buyer_id' => $buyer->id,
            'farmer_id' => $farmer->id,
            'confirmed_bid_id' => $confirmedBidId,
            'total_amount' => 147500.00,
            'system_commission' => 14750.00,
            'farmer_amount' => 132750.00,
            'payment_id' => 'PAYHERE-TEST-TRANSACTION-9921',
            'date_and_time' => now(),
            'payment_status' => 'paid',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->actingAs($admin)
            ->withSession([
                'admin_session' => [
                    'user_id' => $admin->id,
                    'username' => $admin->full_name,
                    'email' => $admin->email,
                    'logged_in_at' => now(),
                ]
            ])
            ->get(route('admin.users.profile', $farmer->id));

        $response->assertStatus(200);
        $response->assertSee('Buyer: Buyer Alice');
        $response->assertSee('0779998887');
        $response->assertSee('PAYHERE-TEST-TRANSACTION-9921');
        $response->assertSee('LKR 147,500.00');
        $response->assertSee('Commission (5%)');
        $response->assertSee('LKR 132,750.00');
    }

    public function test_admin_cannot_activate_sold_out_harvest_listing()
    {
        $admin = User::factory()->create([
            'role' => json_encode(['admin']),
            'full_name' => 'Admin Test',
            'email' => 'admin@test.com',
        ]);

        $farmer = User::factory()->create([
            'role' => json_encode(['farmer']),
        ]);

        $crop = Crop::create([
            'cropname' => 'Test Carrot',
            'scientificname' => 'Daucus carota',
            'category' => 'Vegetable',
            'status' => 'approved',
        ]);

        $listing = HarvestListing::create([
            'farmer_id' => $farmer->id,
            'crop_id' => $crop->id,
            'date_and_time' => now(),
            'notes' => 'Some notes',
            'grade' => 'A',
            'available_quantity' => 100,
            'unit' => 'kg',
            'minimum_order_quantity' => 10,
            'maximum_order_quantity' => 50,
            'price_per_unit' => 200,
            'harvest_date' => now()->subDays(2),
            'harvest_condition' => 'fresh',
            'available_from_date' => now(),
            'available_to_date' => now()->addDays(5),
            'status' => 'sold_out',
        ]);

        $response = $this->actingAs($admin)
            ->withSession([
                'admin_session' => [
                    'user_id' => $admin->id,
                    'username' => $admin->full_name,
                    'email' => $admin->email,
                    'logged_in_at' => now(),
                ]
            ])
            ->post(route('admin.harvest-listings.update-status', $listing->id), [
                'status' => 'active',
            ]);

        $response->assertSessionHasErrors(['error']);
        $this->assertDatabaseHas('harvest_listings', [
            'id' => $listing->id,
            'status' => 'sold_out',
        ]);
    }
}
