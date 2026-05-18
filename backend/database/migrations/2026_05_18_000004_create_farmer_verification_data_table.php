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
        Schema::create('farmer_verification_data', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('farming_license_number')->nullable();
            $table->string('farming_license_path')->nullable();
            $table->string('organic_certificate_number')->nullable();
            $table->string('organic_certificate_path')->nullable();
            $table->date('organic_certificate_expiry')->nullable();
            $table->string('gap_certificate_number')->nullable();
            $table->string('gap_certificate_path')->nullable();
            $table->date('gap_certificate_expiry')->nullable();
            $table->json('other_certificates_titles_and_paths')->nullable();
            $table->integer('total_lands')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('farmer_verification_data');
    }
};
