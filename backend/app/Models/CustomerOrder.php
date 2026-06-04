<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerOrder extends Model
{
    use HasFactory;

    protected $table = 'customer_orders';

    protected $fillable = [
        'order_number',
        'customer_id',
        'delivery_partner_id',
        'delivery_address',
        'delivery_latitude',
        'delivery_longitude',
        'customer_note',
        'retail_seller_note',
        'subtotal_amount',
        'discount_amount',
        'delivery_fee',
        'system_commission_amount',
        'tax_amount',
        'total_amount',
        'payment_status',
        'payment_id',
        'order_status',
        'placed_at',
        'confirmed_at',
        'picked_up_at',
        'delivered_at',
        'cancelled_at',
        'cancellation_reason',
        'expected_date_and_time',
    ];

    protected $casts = [
        'delivery_latitude' => 'decimal:8',
        'delivery_longitude' => 'decimal:8',
        'subtotal_amount' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'delivery_fee' => 'decimal:2',
        'system_commission_amount' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'placed_at' => 'datetime',
        'confirmed_at' => 'datetime',
        'picked_up_at' => 'datetime',
        'delivered_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'expected_date_and_time' => 'datetime',
    ];

    /**
     * Get the customer who placed the order.
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }



    /**
     * Get the delivery partner of this order.
     */
    public function deliveryPartner()
    {
        return $this->belongsTo(User::class, 'delivery_partner_id');
    }

    /**
     * Get the items in this order.
     */
    public function items()
    {
        return $this->hasMany(OrderItem::class, 'order_id');
    }

    /**
     * Get the retailers associated with this order.
     */
    public function retailers()
    {
        return $this->hasManyThrough(User::class, OrderItem::class, 'order_id', 'id', 'id', 'retailer_id');
    }

    /**
     * Get the reviews associated with this order.
     */
    public function reviews()
    {
        return $this->hasMany(OrderReview::class, 'order_id');
    }
}
