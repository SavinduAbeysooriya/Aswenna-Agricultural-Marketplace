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
        Schema::create('daily_cultivation_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farmer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('land_id')->constrained('lands')->cascadeOnDelete();
            $table->date('log_date');
            $table->foreignId('growth_stage_id')->constrained('crop_growth_stages')->cascadeOnDelete();
            $table->text('leaf_appearance')->nullable();
            $table->boolean('disease_detected')->default(false);
            $table->boolean('pest_detected')->default(false);
            $table->text('disease_name_and_damage')->nullable();
            $table->text('pest_name_and_damage')->nullable();
            $table->boolean('pesticide_applied')->default(false);
            $table->string('pesticide_name')->nullable();
            $table->string('pesticide_type')->nullable(); // insecticide, fungicide, herbicide, bactericide, acaricide, nematicide
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('daily_cultivation_logs');
    }
};
