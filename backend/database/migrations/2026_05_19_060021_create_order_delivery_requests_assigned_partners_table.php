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
        Schema::create('order_delivery_requests_assigned_partners', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_request_id');
            $table->unsignedBigInteger('delivery_partner_id');
            $table->enum('status', ['requested', 'accepted', 'rejected', 'cancelled', 'completed'])->default('requested');
            $table->dateTime('requested_at')->useCurrent();
            $table->dateTime('accepted_at')->nullable();
            $table->dateTime('rejected_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestamps();

            // Explicitly named constraints to avoid MySQL's 64-char identifier limit
            $table->foreign('delivery_request_id', 'odrap_req_id_fk')
                  ->references('id')
                  ->on('order_delivery_requests')
                  ->cascadeOnDelete();
            
            $table->foreign('delivery_partner_id', 'odrap_part_id_fk')
                  ->references('id')
                  ->on('users')
                  ->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_delivery_requests_assigned_partners');
    }
};
