<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Crop;
use App\Models\HarvestListing;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HarvestListingCreationTest extends TestCase
{
    use RefreshDatabase;

    public function test_creating_harvest_listing_auto_populates_bidding_dates_if_null()
    {
        $farmer = User::factory()->create([
            'role' => json_encode(['farmer']),
            'full_name' => 'Farmer Bob',
        ]);

        $crop = Crop::create([
            'cropname' => 'Carrots',
            'scientificname' => 'Daucus carota',
            'category' => 'Vegetable',
            'status' => 'approved',
        ]);

        $response = $this->actingAs($farmer)
            ->postJson('/api/farmer/harvest-listings', [
                'crop_id' => $crop->id,
                'notes' => 'Fresh carrots from the farm',
                'grade' => 'A',
                'available_quantity' => 100,
                'unit' => 'kg',
                'minimum_order_quantity' => 10,
                'maximum_order_quantity' => 50,
                'price_per_unit' => 200,
                'min_bid_price_per_unit' => 150,
                'harvest_date' => '2026-06-07',
                'harvest_condition' => 'fresh',
                'available_from_date' => '2026-06-07',
                'available_to_date' => '2026-06-14',
                // bidding_start_date_and_time and bidding_end_date_and_time are omitted/null
            ]);

        $response->assertStatus(201);

        $listing = HarvestListing::first();
        $this->assertNotNull($listing);

        // Assert start is at start of available_from_date
        $expectedStart = Carbon::parse('2026-06-07')->startOfDay();
        $this->assertEquals($expectedStart->toDateTimeString(), $listing->bidding_start_date_and_time->toDateTimeString());

        // Assert end is at end of available_to_date
        $expectedEnd = Carbon::parse('2026-06-14')->endOfDay();
        $this->assertEquals($expectedEnd->toDateTimeString(), $listing->bidding_end_date_and_time->toDateTimeString());
    }

    public function test_updating_harvest_listing_auto_populates_bidding_dates_if_null()
    {
        $farmer = User::factory()->create([
            'role' => json_encode(['farmer']),
        ]);

        $crop = Crop::create([
            'cropname' => 'Potatoes',
            'scientificname' => 'Solanum tuberosum',
            'category' => 'Vegetable',
            'status' => 'approved',
        ]);

        $listing = HarvestListing::create([
            'farmer_id' => $farmer->id,
            'crop_id' => $crop->id,
            'date_and_time' => now(),
            'notes' => 'Old notes',
            'grade' => 'B',
            'available_quantity' => 200,
            'unit' => 'kg',
            'minimum_order_quantity' => 20,
            'maximum_order_quantity' => 100,
            'price_per_unit' => 150,
            'harvest_date' => '2026-06-07',
            'harvest_condition' => 'fresh',
            'available_from_date' => '2026-06-07',
            'available_to_date' => '2026-06-14',
            'bidding_start_date_and_time' => null,
            'bidding_end_date_and_time' => null,
        ]);

        $response = $this->actingAs($farmer)
            ->postJson("/api/farmer/harvest-listings/{$listing->id}", [
                'crop_id' => $crop->id,
                'notes' => 'Updated notes',
                'grade' => 'B',
                'available_quantity' => 200,
                'unit' => 'kg',
                'minimum_order_quantity' => 20,
                'maximum_order_quantity' => 100,
                'price_per_unit' => 150,
                'harvest_date' => '2026-06-07',
                'harvest_condition' => 'fresh',
                'available_from_date' => '2026-06-07',
                'available_to_date' => '2026-06-14',
                'bidding_start_date_and_time' => null,
                'bidding_end_date_and_time' => null,
            ]);

        $response->assertStatus(200);

        $listing->refresh();

        $expectedStart = Carbon::parse('2026-06-07')->startOfDay();
        $this->assertEquals($expectedStart->toDateTimeString(), $listing->bidding_start_date_and_time->toDateTimeString());

        $expectedEnd = Carbon::parse('2026-06-14')->endOfDay();
        $this->assertEquals($expectedEnd->toDateTimeString(), $listing->bidding_end_date_and_time->toDateTimeString());
    }
}
