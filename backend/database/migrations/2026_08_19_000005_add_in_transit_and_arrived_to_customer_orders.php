<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations for DEL-003, DEL-004:
     * Change order_status to string column to support 'in_transit' and 'arrived'.
     */
    public function up(): void
    {
        DB::statement("ALTER TABLE customer_orders MODIFY COLUMN order_status VARCHAR(50) NOT NULL DEFAULT 'pending'");
        DB::statement("ALTER TABLE order_delivery_tracking MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'assigned'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No-op
    }
};
