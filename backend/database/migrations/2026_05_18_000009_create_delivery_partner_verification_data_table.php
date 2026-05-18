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
        Schema::create('delivery_partner_verification_data', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->date('driving_license_expiry_date')->nullable();
            $table->string('vehicle_type')->nullable(); // motorcycle, threewheeler, van, small_truck, medium_truck, large_truck
            $table->string('vehicle_make')->nullable();
            $table->string('model')->nullable();
            $table->integer('year')->nullable();
            $table->string('color')->nullable();
            $table->string('registration_number')->nullable();
            $table->string('insurance_image_path')->nullable();
            $table->string('revenue_license_image_path')->nullable();
            $table->date('insurance_expiry')->nullable();
            $table->date('revenue_license_expiry')->nullable();
            $table->string('vehicle_front_image')->nullable();
            $table->string('vehicle_back_image')->nullable();
            $table->json('vehicle_other_images')->nullable();
            $table->decimal('max_weight', 10, 2)->nullable();
            $table->string('status')->default('pending'); // pending, verified, rejected
            $table->text('rejected_reason')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delivery_partner_verification_data');
    }
};
