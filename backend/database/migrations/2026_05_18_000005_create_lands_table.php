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
        Schema::create('lands', function (Blueprint $table) {
            $table->id();
            $table->decimal('size', 10, 2);
            $table->foreignId('farmer_id')->constrained('users')->cascadeOnDelete();
            $table->string('ownership_type'); // owned, license, lease, government, other
            $table->string('registration_number')->nullable();
            $table->json('land_documents_paths_and_document_titles')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->json('land_images')->nullable();
            $table->string('status')->default('pending'); // pending, verified, rejected
            $table->text('rejected_reason')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('lands');
    }
};
