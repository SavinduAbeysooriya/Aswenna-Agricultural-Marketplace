<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OfferCampaign extends Model
{
    protected $fillable = [
        'offer_goal_id',
        'title',
        'code',
        'description',
        'type',
        'discount_percentage',
        'discount_amount',
        'max_discount_amount',
        'minimum_completion_count',
        'valid_from',
        'valid_until',
        'usage_limit_per_user',
        'total_usage_limit',
        'is_active',
        'applied_user_role',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'valid_from' => 'datetime',
        'valid_until' => 'datetime',
        'discount_percentage' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'max_discount_amount' => 'decimal:2',
        'minimum_completion_count' => 'integer',
        'usage_limit_per_user' => 'integer',
        'total_usage_limit' => 'integer',
    ];

    const TYPES = ['percentage', 'fixed_amount', 'free_shipping'];
    const APPLIED_USER_ROLES = ['farmer', 'buyer', 'retail_seller', 'customer', 'delivery_partner'];

    /**
     * Get the associated offer goal.
     */
    public function goal(): BelongsTo
    {
        return $this->belongsTo(OfferGoal::class, 'offer_goal_id');
    }
}
