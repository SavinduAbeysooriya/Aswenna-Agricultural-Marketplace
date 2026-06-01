<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CropRate extends Model
{
    use HasFactory;

    protected $fillable = [
        'buyer_id',
        'crop_id',
        'date_and_time',
        'rate_per_kg_grade_a',
        'rate_per_kg_grade_b',
        'rate_per_kg_grade_c',
        'min_qty_required',
        'accepted_grade',
        'max_qty_required',
    ];

    protected function casts(): array
    {
        return [
            'date_and_time' => 'datetime',
            'rate_per_kg_grade_a' => 'decimal:2',
            'rate_per_kg_grade_b' => 'decimal:2',
            'rate_per_kg_grade_c' => 'decimal:2',
            'min_qty_required' => 'decimal:2',
            'max_qty_required' => 'decimal:2',
        ];
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function crop(): BelongsTo
    {
        return $this->belongsTo(Crop::class, 'crop_id');
    }
}
