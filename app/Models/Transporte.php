<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transporte extends Model
{
    public function cotizacion()
    {
        return $this->belongsTo(Cotizacion::class);
    }
}
