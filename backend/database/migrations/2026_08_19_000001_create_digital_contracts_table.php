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
        Schema::create('digital_contracts', function (Blueprint $table) {
            $table->id();
            $table->string('offer_code')->default('OFF-4412');
            $table->unsignedBigInteger('buyer_id');
            $table->unsignedBigInteger('farmer_id');
            $table->unsignedBigInteger('crop_id')->nullable();
            $table->string('crop_name')->default('Green Chilli');
            $table->decimal('quantity', 12, 2)->default(1000.00);
            $table->string('unit')->default('kg');
            $table->decimal('initial_price_per_unit', 10, 2)->default(350.00);
            $table->decimal('counter_offer_price_per_unit', 10, 2)->default(315.00);
            $table->decimal('total_contract_value', 12, 2)->default(315000.00);
            $table->decimal('escrow_deposit_percent', 5, 2)->default(20.00);
            $table->decimal('escrow_deposit_amount', 12, 2)->default(63000.00);
            $table->string('status')->default('counter_offer_received'); // counter_offer_received, contract_signed, completed
            $table->unsignedBigInteger('delivery_partner_id')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('digital_contracts');
    }
};
