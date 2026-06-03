<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RetailerProduct extends Model
{
    use HasFactory;

    protected $table = 'retailer_products';

    protected $fillable = [
        'seller_id',
        'crop_id',
        'product_name',
        'description',
        'price_per_unit',
        'discount_price_per_unit',
        'stock_quantity',
        'unit_type',
        'grade',
        'status',
        'thumbnail_path',
        'image_paths',
    ];

    protected $casts = [
        'price_per_unit' => 'decimal:2',
        'discount_price_per_unit' => 'decimal:2',
        'stock_quantity' => 'decimal:2',
        'image_paths' => 'array',
    ];

    /**
     * Get the seller user that owns this product.
     */
    public function seller()
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    /**
     * Get the crop associated with this product.
     */
    public function crop()
    {
        return $this->belongsTo(Crop::class, 'crop_id');
    }
}
