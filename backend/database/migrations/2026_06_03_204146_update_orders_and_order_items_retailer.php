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
            $table->dropForeign(['retailer_seller_id']);
            $table->dropColumn('retailer_seller_id');
        });

        Schema::table('order_items', function (Blueprint $table) {
            $table->foreignId('retailer_id')->after('retailer_product_id')->constrained('users')->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            $table->dropForeign(['retailer_id']);
            $table->dropColumn('retailer_id');
        });

        Schema::table('customer_orders', function (Blueprint $table) {
            $table->foreignId('retailer_seller_id')->after('customer_id')->constrained('users')->cascadeOnDelete();
        });
    }
};
