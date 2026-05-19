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
        Schema::create('retailer_customer_delivery_partner_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reviewed_to')->constrained('users')->cascadeOnDelete();
            $table->foreignId('reviewed_by')->constrained('users')->cascadeOnDelete();
            $table->foreignId('order_id')->constrained('customer_orders')->cascadeOnDelete();
            $table->text('feedback');
            $table->unsignedTinyInteger('ratings'); // 1-5 rating scale
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('retailer_customer_delivery_partner_reviews');
    }
};
