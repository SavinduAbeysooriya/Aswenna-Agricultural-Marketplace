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
        Schema::table('offer_campaigns', function (Blueprint $table) {
            if (!Schema::hasColumn('offer_campaigns', 'retailer_id')) {
                $table->unsignedBigInteger('retailer_id')->nullable()->after('id');
            }
            if (!Schema::hasColumn('offer_campaigns', 'status')) {
                $table->string('status')->default('pending_admin_approval')->after('is_active');
            }
            if (!Schema::hasColumn('offer_campaigns', 'target_category')) {
                $table->string('target_category')->nullable()->after('status');
            }
            if (!Schema::hasColumn('offer_campaigns', 'banner_image')) {
                $table->string('banner_image')->nullable()->after('target_category');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('offer_campaigns', function (Blueprint $table) {
            $table->dropColumn(['retailer_id', 'status', 'target_category', 'banner_image']);
        });
    }
};
