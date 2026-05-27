<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatbotSession extends Model
{
    protected $fillable = [
        'farmer_id',
        'chat_title',
        'farmer_quiz',
        'bot_answer',
        'date_and_time',
        'order',
        'image_path',
        'is_ended',
        'customer_rating',
        'customer_feedback',
    ];

    protected $casts = [
        'date_and_time' => 'datetime',
        'is_ended' => 'boolean',
    ];

    public function farmer()
    {
        return $this->belongsTo(User::class, 'farmer_id');
    }
}
