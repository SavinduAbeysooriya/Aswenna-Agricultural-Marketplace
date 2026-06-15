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

    public function test_admin_can_view_placed_orders_and_received_orders_tabs()
    {
        $admin = User::factory()->create([
            'role' => json_encode(['admin']),
            'full_name' => 'Admin User',
            'email' => 'admin@test.com',
        ]);

        $customer = User::factory()->create([
            'role' => json_encode(['customer']),
            'full_name' => 'Lakmal Perera',
            'phone_number' => '0777567890',
        ]);

        $retailSeller = User::factory()->create([
            'role' => json_encode(['retail_seller']),
            'full_name' => 'Agro Retail Mart',
            'latitude' => 6.84000000,
            'longitude' => 79.90000000,
        ]);

        $crop = Crop::create([
            'cropname' => 'Test Potato',
            'scientificname' => 'Solanum tuberosum',
            'category' => 'Vegetable',
            'status' => 'approved',
        ]);

        // Create a Retailer Product
        $prodPotato = \Illuminate\Support\Facades\DB::table('retailer_products')->insertGetId([
            'seller_id' => $retailSeller->id,
            'crop_id' => $crop->id,
            'product_name' => 'Nuwara Eliya Red Potatoes',
            'price_per_unit' => 290.00,
            'discount_price_per_unit' => 275.00,
            'unit_type' => 'kg',
            'stock_quantity' => 450.00,
            'grade' => 'A',
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Create a Customer Order
        $orderId = \Illuminate\Support\Facades\DB::table('customer_orders')->insertGetId([
            'order_number' => 'ORD-RETAIL-4482-17182918',
            'customer_id' => $customer->id,
            'delivery_address' => '99/A, Galle Road, Colombo 03',
            'subtotal_amount' => 930.00,
            'discount_amount' => 30.00,
            'delivery_fee' => 380.00,
            'system_commission_amount' => 46.50,
            'tax_amount' => 0.00,
            'total_amount' => 1310.00,
            'payment_status' => 'paid',
            'order_status' => 'delivered',
            'placed_at' => now()->subDays(1),
            'created_at' => now()->subDays(1),
            'updated_at' => now()->subDays(1),
        ]);

        // Create an Order Payment Record
        \Illuminate\Support\Facades\DB::table('order_payments')->insert([
            'order_id' => $orderId,
            'customer_id' => $customer->id,
            'transaction_reference' => 'PAYHERE-TEST-REF-998822',
            'paid_amount' => 1310.00,
            'payment_status' => 'paid',
            'paid_at' => \Carbon\Carbon::parse('2026-06-14 12:00:00'),
            'created_at' => now()->subDays(1),
            'updated_at' => now()->subDays(1),
        ]);

        $deliveryPartner = User::factory()->create([
            'role' => json_encode(['delivery_partner']),
            'full_name' => 'Samantha Kumara',
            'phone_number' => '0711223344',
        ]);

        $requestId = \Illuminate\Support\Facades\DB::table('order_delivery_requests')->insertGetId([
            'order_id' => $orderId,
            'request_status' => 'assigned',
            'pickup_address' => 'Colombo Market',
            'pickup_latitude' => 6.9271,
            'pickup_longitude' => 79.8612,
            'delivery_address' => '99/A, Galle Road, Colombo 03',
            'delivery_latitude' => 6.9150,
            'delivery_longitude' => 79.8500,
            'delivery_fee' => 380.00,
            'system_commission' => 19.00,
            'estimated_distance_km' => 5.2,
            'estimated_distance_minutes' => 18,
            'expires_at' => now()->addHours(2),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \Illuminate\Support\Facades\DB::table('order_delivery_requests_assigned_partners')->insert([
            'delivery_request_id' => $requestId,
            'delivery_partner_id' => $deliveryPartner->id,
            'status' => 'accepted',
            'requested_at' => now()->subMinutes(15),
            'accepted_at' => now()->subMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \Illuminate\Support\Facades\DB::table('order_delivery_tracking')->insert([
            'order_id' => $orderId,
            'delivery_partner_id' => $deliveryPartner->id,
            'status' => 'on_the_way',
            'current_latitude' => 6.9200,
            'current_longitude' => 79.8550,
            'tracking_note' => 'Heading past Galle Face, almost at destination.',
            'tracked_at' => now()->subMinutes(5),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \Illuminate\Support\Facades\DB::table('order_status_histories')->insert([
            'order_id' => $orderId,
            'changed_by_user_id' => $deliveryPartner->id,
            'old_status' => 'confirmed',
            'new_status' => 'picked_up',
            'status_note' => 'Picked up all items from Agro Retail Mart.',
            'changed_at' => now()->subMinutes(12),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Create Order Item
        \Illuminate\Support\Facades\DB::table('order_items')->insert([
            'order_id' => $orderId,
            'retailer_product_id' => $prodPotato,
            'retailer_id' => $retailSeller->id,
            'quantity' => 2.00,
            'total_price' => 580.00,
            'discount_amount' => 30.00,
            'final_price' => 550.00,
            'grade' => 'A',
            'created_at' => now()->subDays(1),
            'updated_at' => now()->subDays(1),
        ]);

        // Request Customer Profile Page
        $responseCustomer = $this->actingAs($admin)
            ->withSession([
                'admin_session' => [
                    'user_id' => $admin->id,
                    'username' => $admin->full_name,
                    'email' => $admin->email,
                    'logged_in_at' => now(),
                ]
            ])
            ->get(route('admin.users.profile', $customer->id));

        $responseCustomer->assertStatus(200);
        $responseCustomer->assertSee('Placed Customer Orders');
        $responseCustomer->assertSee('ORD-RETAIL-4482-17182918');
        $responseCustomer->assertSee('Nuwara Eliya Red Potatoes');
        $responseCustomer->assertSee('Seller: Agro Retail Mart');
        $responseCustomer->assertSee('LKR 1,310.00');
        $responseCustomer->assertSee('PAYHERE-TEST-REF-998822');
        $responseCustomer->assertSee('Amount: LKR 1,310.00');
        $responseCustomer->assertSee('Paid: Jun 14, 2026 12:00 PM');
        $responseCustomer->assertSee('Delivery Logistics & Request Status');
        $responseCustomer->assertSee('Colombo Market');
        $responseCustomer->assertSee('Samantha Kumara');
        $responseCustomer->assertSee('0711223344');
        $responseCustomer->assertSee('Heading past Galle Face');
        $responseCustomer->assertSee('Picked up all items from Agro Retail Mart');

        // Request Retail Seller Profile Page
        $responseRetailer = $this->actingAs($admin)
            ->withSession([
                'admin_session' => [
                    'user_id' => $admin->id,
                    'username' => $admin->full_name,
                    'email' => $admin->email,
                    'logged_in_at' => now(),
                ]
            ])
            ->get(route('admin.users.profile', $retailSeller->id));

        $responseRetailer->assertStatus(200);
        $responseRetailer->assertSee('Retailer Store Catalog');
        $responseRetailer->assertSee('Nuwara Eliya Red Potatoes');
        $responseRetailer->assertDontSee('Received Customer Orders');
    }
}
