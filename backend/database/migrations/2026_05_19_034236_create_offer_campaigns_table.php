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
        Schema::create('offer_campaigns', function (Blueprint $table) {
            $table->id();
            $table->foreignId('offer_goal_id')->constrained('offer_goals')->cascadeOnDelete();
            $table->string('title');
            $table->string('code')->unique();
            $table->text('description')->nullable();
            $table->enum('type', ['percentage', 'fixed_amount', 'free_shipping']);
            $table->decimal('discount_percentage', 5, 2)->nullable();
            $table->decimal('discount_amount', 10, 2)->nullable();
            $table->decimal('max_discount_amount', 10, 2)->nullable();
            $table->integer('minimum_completion_count')->default(1);
            $table->dateTime('valid_from');
            $table->dateTime('valid_until');
            $table->integer('usage_limit_per_user')->nullable();
            $table->integer('total_usage_limit')->nullable();
            $table->boolean('is_active')->default(true);
            $table->enum('applied_user_role', ['farmer', 'buyer', 'retail_seller', 'customer', 'delivery_partner']);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('offer_campaigns');
    }
};
