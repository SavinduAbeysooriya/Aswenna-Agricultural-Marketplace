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
        Schema::create('crop_growth_stages', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // land_preparation, sowing_planting, germination, seedling, vegetative_early, vegetative_mid, vegetative_late, flowering_bud_formation, flowering_full_bloom, fruit_set, fruit_development, maturation_ripening, harvest_ongoing, harvest_complete, fallow
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('crop_growth_stages');
    }
};
