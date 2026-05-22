<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CropGrowthStage extends Model
{
    use HasFactory;

    protected $table = 'crop_growth_stages';

    protected $fillable = [
        'name',
    ];
}
