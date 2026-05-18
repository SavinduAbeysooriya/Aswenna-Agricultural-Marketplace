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
        Schema::create('chatbot_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farmer_id')->constrained('users')->cascadeOnDelete();
            $table->string('chat_title')->nullable();
            $table->text('farmer_quiz');
            $table->text('bot_answer');
            $table->timestamp('date_and_time');
            $table->integer('order')->default(1);
            $table->string('image_path')->nullable();
            $table->boolean('is_ended')->default(false);
            $table->integer('customer_rating')->nullable();
            $table->text('customer_feedback')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('chatbot_sessions');
    }
};
