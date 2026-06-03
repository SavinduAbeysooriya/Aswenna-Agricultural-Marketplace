<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory;

    protected $table = 'order_items';

    protected $fillable = [
        'order_id',
        'retailer_product_id',
        'retailer_id',
        'quantity',
        'total_price',
        'discount_amount',
        'final_price',
        'grade',
    ];

    protected $casts = [
        'quantity' => 'decimal:2',
        'total_price' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'final_price' => 'decimal:2',
    ];

    /**
     * Get the order associated with this item.
     */
    public function order()
    {
        return $this->belongsTo(CustomerOrder::class, 'order_id');
    }

    /**
     * Get the retailer product associated with this item.
     */
    public function product()
    {
        return $this->belongsTo(RetailerProduct::class, 'retailer_product_id');
    }

    /**
     * Get the retailer seller of this order item.
     */
    public function retailer()
    {
        return $this->belongsTo(User::class, 'retailer_id');
    }
}
