<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WithdrawRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'request_amount',
        'bank_name',
        'bank_branch',
        'bank_account_holder_name',
        'bank_account_number',
        'status',
        'reviewed_admin_id',
        'admin_note',
        'rejection_reason',
        'reviewed_at',
        'paid_at',
        'transaction_reference',
        'requested_ip',
    ];

    protected $casts = [
        'request_amount' => 'decimal:2',
        'reviewed_at' => 'datetime',
        'paid_at' => 'datetime',
    ];

    /**
     * Get the user who requested the withdrawal.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Get the administrator who reviewed the request.
     */
    public function reviewedAdmin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_admin_id');
    }
}
