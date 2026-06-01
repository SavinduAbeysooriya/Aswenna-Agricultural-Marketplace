<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HarvestListing extends Model
{
    use HasFactory;

    protected $fillable = [
        'farmer_id',
        'crop_id',
        'date_and_time',
        'notes',
        'grade',
        'available_quantity',
        'unit',
        'minimum_order_quantity',
        'maximum_order_quantity',
        'price_per_unit',
        'min_bid_price_per_unit',
        'harvest_date',
        'harvest_condition',
        'storage_method',
        'pickup_latitude',
        'pickup_longitude',
        'delivery_available',
        'delivery_fee_per_km',
        'max_delivery_distance',
        'available_from_date',
        'available_to_date',
        'bidding_start_date_and_time',
        'bidding_end_date_and_time',
        'image_1',
        'image_2',
        'image_3',
        'image_4',
        'status',
        'reject_reason',
    ];

    protected function casts(): array
    {
        return [
            'date_and_time' => 'datetime',
            'available_quantity' => 'decimal:2',
            'minimum_order_quantity' => 'decimal:2',
            'maximum_order_quantity' => 'decimal:2',
            'price_per_unit' => 'decimal:2',
            'min_bid_price_per_unit' => 'decimal:2',
            'harvest_date' => 'date',
            'pickup_latitude' => 'decimal:8',
            'pickup_longitude' => 'decimal:8',
            'delivery_available' => 'boolean',
            'delivery_fee_per_km' => 'decimal:2',
            'max_delivery_distance' => 'decimal:2',
            'available_from_date' => 'date',
            'available_to_date' => 'date',
            'bidding_start_date_and_time' => 'datetime',
            'bidding_end_date_and_time' => 'datetime',
        ];
    }

    public function farmer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'farmer_id');
    }

    public function crop(): BelongsTo
    {
        return $this->belongsTo(Crop::class, 'crop_id');
    }
}
