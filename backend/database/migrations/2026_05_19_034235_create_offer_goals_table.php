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
        Schema::create('offer_goals', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('goal_type', [
                'total_orders', 'total_spending', 'product_purchase_count', 
                'first_order', 'purchase_count', 'total_sales', 'total_earnings', 
                'total_products', 'rating_average', 'delivery_completed_orders', 
                'festival_campaign', 'seasonal_purchase', 'special_event_goal', 
                'total_referrals'
            ]);
            $table->decimal('target_value', 12, 2);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('offer_goals');
    }
};
