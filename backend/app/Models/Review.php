<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    use HasFactory;

    protected $table = 'buyer_farmer_reviews';

    protected $fillable = [
        'buyer_id',
        'farmer_id',
        'confirmed_bid_id',
        'feedback',
        'ratings',
        'reviewed_by',
    ];

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function farmer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'farmer_id');
    }

    public function confirmedBid(): BelongsTo
    {
        return $this->belongsTo(ConfirmedBid::class, 'confirmed_bid_id');
    }
}
