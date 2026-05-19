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
        Schema::create('order_delivery_tracking', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('customer_orders')->cascadeOnDelete();
            $table->foreignId('delivery_partner_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', [
                'assigned', 'heading_to_pickup', 'arrived_pickup', 
                'picked_up', 'on_the_way', 'arrived_destination', 'delivered'
            ]);
            $table->decimal('current_latitude', 10, 8);
            $table->decimal('current_longitude', 11, 8);
            $table->text('tracking_note')->nullable();
            $table->timestamp('tracked_at')->useCurrent();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_delivery_tracking');
    }
};
