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
        Schema::table('crops', function (Blueprint $table) {
            if (!Schema::hasColumn('crops', 'status')) {
                $table->enum('status', ['pending', 'rejected', 'approved'])->default('pending')->index()->after('image_path');
            }

            if (!Schema::hasColumn('crops', 'added_by')) {
                $table->foreignId('added_by')->nullable()->after('status')->constrained('users')->nullOnDelete();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('crops', function (Blueprint $table) {
            if (Schema::hasColumn('crops', 'added_by')) {
                $table->dropConstrainedForeignId('added_by');
            }

            if (Schema::hasColumn('crops', 'status')) {
                $table->dropColumn('status');
            }
        });
    }
};
