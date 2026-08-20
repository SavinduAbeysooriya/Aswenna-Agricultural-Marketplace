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
        Schema::table('customer_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('customer_orders', 'pickup_slot')) {
                $table->string('pickup_slot')->nullable()->after('order_status');
            }
            if (!Schema::hasColumn('customer_orders', 'pickup_barcode')) {
                $table->string('pickup_barcode')->nullable()->after('pickup_slot');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('customer_orders', function (Blueprint $table) {
            if (Schema::hasColumn('customer_orders', 'pickup_barcode')) {
                $table->dropColumn('pickup_barcode');
            }
            if (Schema::hasColumn('customer_orders', 'pickup_slot')) {
                $table->dropColumn('pickup_slot');
            }
        });
    }
};
