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
        Schema::create('user_offer_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('offer_campaign_id')->constrained('offer_campaigns')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->boolean('is_completed')->default(false);
            $table->dateTime('completed_at')->nullable();
            $table->boolean('reward_claimed')->default(false);
            $table->dateTime('reward_claimed_at')->nullable();
            // Polymorphic relation to trace the associated activity (orders, deliveries, sales, etc.)
            $table->nullableMorphs('reward_claimed_activity', 'reward_activity'); 
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_offer_progress');
    }
};
