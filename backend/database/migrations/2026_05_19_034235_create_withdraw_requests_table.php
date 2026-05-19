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
        Schema::create('withdraw_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('request_amount', 12, 2);
            $table->string('bank_name');
            $table->string('bank_branch');
            $table->string('bank_account_holder_name');
            $table->string('bank_account_number');
            $table->enum('status', ['pending', 'approved', 'rejected', 'processing', 'paid', 'cancelled'])->default('pending');
            $table->foreignId('reviewed_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('admin_note')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->string('transaction_reference')->nullable(); // bank transfer invoice ref
            $table->string('requested_ip')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('withdraw_requests');
    }
};
