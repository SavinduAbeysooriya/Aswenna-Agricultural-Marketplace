<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderReview extends Model
{
    use HasFactory;

    protected $table = 'retailer_customer_delivery_partner_reviews';

    protected $fillable = [
        'reviewed_to',
        'reviewed_by',
        'order_id',
        'feedback',
        'ratings',
    ];

    /**
     * Get the user being reviewed.
     */
    public function reviewedTo()
    {
        return $this->belongsTo(User::class, 'reviewed_to');
    }

    /**
     * Get the user who submitted the review.
     */
    public function reviewedBy()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    /**
     * Get the order associated with the review.
     */
    public function order()
    {
        return $this->belongsTo(CustomerOrder::class, 'order_id');
    }
}
