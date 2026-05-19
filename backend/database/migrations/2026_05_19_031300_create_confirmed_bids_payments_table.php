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
        Schema::create('confirmed_bids_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('buyer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('farmer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('confirmed_bid_id')->constrained('confirmed_bids')->cascadeOnDelete();
            $table->decimal('total_amount', 10, 2);
            $table->decimal('system_commission', 10, 2);
            $table->decimal('farmer_amount', 10, 2);
            $table->string('payment_id')->nullable(); // from payhere
            $table->dateTime('date_and_time');
            $table->enum('payment_status', ['paid', 'unpaid'])->default('unpaid');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('confirmed_bids_payments');
    }
};
