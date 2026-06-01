<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Crop extends Model
{
    use HasFactory;

    public const STATUSES = ['pending', 'rejected', 'approved'];

    protected $fillable = [
        'cropname',
        'image_path',
        'status',
        'added_by',
    ];

    public function addedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'added_by');
    }

    public function cropRates(): HasMany
    {
        return $this->hasMany(CropRate::class, 'crop_id');
    }
}
