<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OfferGoal extends Model
{
    protected $fillable = [
        'name',
        'description',
        'goal_type',
        'target_value',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'target_value' => 'decimal:2',
    ];

    const GOAL_TYPES = [
        'total_orders',
        'total_spending',
        'product_purchase_count',
        'first_order',
        'purchase_count',
        'total_sales',
        'total_earnings',
        'total_products',
        'rating_average',
        'delivery_completed_orders',
        'festival_campaign',
        'seasonal_purchase',
        'special_event_goal',
        'total_referrals'
    ];

    /**
     * Get the campaigns associated with this goal.
     */
    public function campaigns(): HasMany
    {
        return $this->hasMany(OfferCampaign::class);
    }
}
