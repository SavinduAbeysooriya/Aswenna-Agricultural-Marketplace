<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class UserOfferProgress extends Model
{
    protected $table = 'user_offer_progress';

    protected $fillable = [
        'offer_campaign_id',
        'user_id',
        'is_completed',
        'completed_at',
        'reward_claimed',
        'reward_claimed_at',
        'reward_claimed_activity_type',
        'reward_claimed_activity_id',
        'notes',
    ];

    protected $casts = [
        'is_completed' => 'boolean',
        'completed_at' => 'datetime',
        'reward_claimed' => 'boolean',
        'reward_claimed_at' => 'datetime',
    ];

    /**
     * Get the campaign that owns the progress.
     */
    public function campaign(): BelongsTo
    {
        return $this->belongsTo(OfferCampaign::class, 'offer_campaign_id');
    }

    /**
     * Get the user that owns the progress.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Get the parent reward claimed activity model.
     */
    public function rewardActivity(): MorphTo
    {
        return $this->morphTo('reward_activity', 'reward_claimed_activity_type', 'reward_claimed_activity_id');
    }
}
