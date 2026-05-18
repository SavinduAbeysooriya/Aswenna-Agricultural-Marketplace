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
        Schema::create('retail_seller_verification_data', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('br_number')->nullable();
            $table->string('br_image_path')->nullable();
            $table->date('br_issue_date')->nullable();
            $table->date('br_expiry_date')->nullable();
            $table->string('business_type')->nullable(); // sole_proprietorship, partnership, private_limited, cooperative
            $table->string('shop_address')->nullable();
            $table->json('shop_photos')->nullable();
            $table->string('postal_code')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('ownership_type')->nullable(); // owned, rental, leased
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
        Schema::dropIfExists('retail_seller_verification_data');
    }
};
