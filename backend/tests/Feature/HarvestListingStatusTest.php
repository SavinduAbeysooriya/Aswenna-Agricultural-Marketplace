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
}
