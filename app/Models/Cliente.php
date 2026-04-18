<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Cliente extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'nombre',
        'documento',
        'telefono',
        'email',
        'direccion',
        'notas',
        'activo',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'activo' => 'boolean',
        ];
    }

    public function creador()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function cotizaciones()
    {
        return $this->hasMany(Cotizacion::class);
    }

    public function facturas()
    {
        return $this->hasMany(Factura::class);
    }
}
