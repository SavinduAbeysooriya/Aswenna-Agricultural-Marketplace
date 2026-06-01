<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HarvestBid extends Model
{
    use HasFactory;

    protected $table = 'harvest_bids';

    protected $fillable = [
        'buyer_id',
        'harvest_listing_id',
        'bid_amount_per_unit',
        'bid_quantity_unit',
        'notes',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'bid_amount_per_unit' => 'decimal:2',
            'bid_quantity_unit' => 'decimal:2',
        ];
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function harvestListing(): BelongsTo
    {
        return $this->belongsTo(HarvestListing::class, 'harvest_listing_id');
    }
}
