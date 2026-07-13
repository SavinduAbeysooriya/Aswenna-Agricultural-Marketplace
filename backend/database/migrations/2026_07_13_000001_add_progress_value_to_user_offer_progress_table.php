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
        Schema::table('user_offer_progress', function (Blueprint $table) {
            $table->decimal('progress_value', 12, 2)->default(0.00)->after('user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_offer_progress', function (Blueprint $table) {
            $table->dropColumn('progress_value');
        });
    }
};
