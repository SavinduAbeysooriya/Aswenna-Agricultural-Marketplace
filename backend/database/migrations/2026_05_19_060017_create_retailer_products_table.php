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
        Schema::create('retailer_products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('crop_id')->constrained('crops')->cascadeOnDelete();
            $table->text('description')->nullable();
            $table->string('thumbnail_path')->nullable();
            $table->string('product_name');
            $table->decimal('price_per_unit', 10, 2);
            $table->decimal('discount_price_per_unit', 10, 2)->nullable();
            $table->decimal('stock_quantity', 10, 2);
            $table->enum('unit_type', ['kg', 'g', 'liter', 'ml']);
            $table->enum('grade', ['A', 'B', 'C']);
            $table->enum('status', ['active', 'inactive', 'out_of_stock'])->default('active');
            $table->json('image_paths')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('retailer_products');
    }
};
