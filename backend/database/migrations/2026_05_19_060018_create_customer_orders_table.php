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
        Schema::create('customer_orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number')->unique();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('retailer_seller_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('delivery_partner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('delivery_address');
            $table->decimal('delivery_latitude', 10, 8)->nullable();
            $table->decimal('delivery_longitude', 11, 8)->nullable();
            $table->text('customer_note')->nullable();
            $table->text('retail_seller_note')->nullable();
            $table->decimal('subtotal_amount', 10, 2);
            $table->decimal('discount_amount', 10, 2)->default(0.00);
            $table->decimal('delivery_fee', 10, 2)->default(0.00);
            $table->decimal('system_commission_amount', 10, 2)->default(0.00);
            $table->decimal('tax_amount', 10, 2)->default(0.00);
            $table->decimal('total_amount', 10, 2);
            $table->enum('payment_status', ['pending', 'paid', 'failed', 'refunded'])->default('pending');
            $table->string('payment_id')->nullable(); // PayHere reference
            $table->enum('order_status', [
                'pending', 'confirmed', 'processing', 'ready_for_pickup',
                'delivery_requested', 'delivery_partner_assigned', 'picked_up',
                'on_the_way', 'delivered', 'completed', 'cancelled',
                'refund_requested', 'refunded'
            ])->default('pending');
            $table->timestamp('placed_at')->useCurrent();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('picked_up_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->dateTime('expected_date_and_time')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('customer_orders');
    }
};
