<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('harvest_listings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farmer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('crop_id')->constrained('crops')->cascadeOnDelete();
            $table->dateTime('date_and_time');
            $table->text('notes')->nullable();
            $table->enum('grade', ['A', 'B', 'C']);
            $table->decimal('available_quantity', 10, 2);
            $table->enum('unit', ['kg', 'g', 'ton', 'piece', 'bunch', 'dozen', 'liter']);
            $table->decimal('minimum_order_quantity', 10, 2);
            $table->decimal('maximum_order_quantity', 10, 2);
            $table->decimal('price_per_unit', 10, 2);
            $table->decimal('min_bid_price_per_unit', 10, 2)->nullable();
            $table->date('harvest_date');
            $table->string('harvest_condition'); // fresh, 1_day_old, 2, 3, etc.
            $table->string('storage_method')->nullable();
            $table->decimal('pickup_latitude', 10, 8)->nullable();
            $table->decimal('pickup_longitude', 11, 8)->nullable();
            $table->boolean('delivery_available')->default(false);
            $table->decimal('delivery_fee_per_km', 10, 2)->nullable();
            $table->decimal('max_delivery_distance', 8, 2)->nullable();
            $table->date('available_from_date');
            $table->date('available_to_date');
            $table->dateTime('bidding_start_date_and_time')->nullable();
            $table->dateTime('bidding_end_date_and_time')->nullable();
            $table->string('image_1')->nullable();
            $table->string('image_2')->nullable();
            $table->string('image_3')->nullable();
            $table->string('image_4')->nullable();
            $table->enum('status', [
                'draft', 'pending_approval', 'active', 'bidding_active', 
                'bidding_ended', 'sold_out', 'expired', 'cancelled', 
                'suspended', 'rejected'
            ])->default('draft');
            $table->text('reject_reason')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('harvest_listings');
    }
};
