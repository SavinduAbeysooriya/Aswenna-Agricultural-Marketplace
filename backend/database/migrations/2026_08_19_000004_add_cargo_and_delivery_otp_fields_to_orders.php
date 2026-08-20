<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations for DEL-003, DEL-004, DEL-005:
     * Cargo OTP verification, Cargo Photo, Delivery OTP, and Electronic Signature.
     */
    public function up(): void
    {
        Schema::table('customer_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('customer_orders', 'pickup_otp')) {
                $table->string('pickup_otp')->default('849201')->after('order_status');
            }
            if (!Schema::hasColumn('customer_orders', 'delivery_otp')) {
                $table->string('delivery_otp')->default('392014')->after('pickup_otp');
            }
            if (!Schema::hasColumn('customer_orders', 'cargo_photo_path')) {
                $table->string('cargo_photo_path')->nullable()->after('delivery_otp');
            }
            if (!Schema::hasColumn('customer_orders', 'recipient_signature_path')) {
                $table->text('recipient_signature_path')->nullable()->after('cargo_photo_path');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('customer_orders', function (Blueprint $table) {
            if (Schema::hasColumn('customer_orders', 'recipient_signature_path')) {
                $table->dropColumn('recipient_signature_path');
            }
            if (Schema::hasColumn('customer_orders', 'cargo_photo_path')) {
                $table->dropColumn('cargo_photo_path');
            }
            if (Schema::hasColumn('customer_orders', 'delivery_otp')) {
                $table->dropColumn('delivery_otp');
            }
            if (Schema::hasColumn('customer_orders', 'pickup_otp')) {
                $table->dropColumn('pickup_otp');
            }
        });
    }
};
