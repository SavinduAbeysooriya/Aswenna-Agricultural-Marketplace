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
        Schema::create('crop_rates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('buyer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('crop_id')->constrained('crops')->cascadeOnDelete();
            $table->timestamp('date_and_time');
            $table->decimal('rate_per_kg_grade_a', 10, 2)->nullable();
            $table->decimal('rate_per_kg_grade_b', 10, 2)->nullable();
            $table->decimal('rate_per_kg_grade_c', 10, 2)->nullable();
            $table->decimal('min_qty_required', 10, 2)->nullable();
            $table->string('accepted_grade')->nullable(); // A, B, C, All
            $table->decimal('max_qty_required', 10, 2)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('crop_rates');
    }
};
