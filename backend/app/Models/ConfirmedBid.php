<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConfirmedBid extends Model
{
    use HasFactory;

    protected $table = 'confirmed_bids';

    protected $fillable = [
        'buyer_id',
        'farmer_id',
        'harvest_listing_id',
        'bid_id',
        'notes',
        'total_amount',
        'payment_status',
    ];

    protected function casts(): array
    {
        return [
            'total_amount' => 'decimal:2',
        ];
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function farmer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'farmer_id');
    }

    public function harvestListing(): BelongsTo
    {
        return $this->belongsTo(HarvestListing::class, 'harvest_listing_id');
    }

    public function bid(): BelongsTo
    {
        return $this->belongsTo(HarvestBid::class, 'bid_id');
    }
}
