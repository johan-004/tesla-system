<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CotizacionDetalle extends Model
{
    use HasFactory;

    protected $table = 'cotizacion_detalles';

    protected $fillable = [
        'cotizacion_id',
        'servicio_id',
        'producto_id',
        'categoria',
        'codigo',
        'descripcion',
        'unidad',
        'cantidad',
        'precio_unitario',
        'subtotal',
    ];

    // Relación: cada detalle pertenece a una cotización
    public function cotizacion()
    {
        return $this->belongsTo(Cotizacion::class);
    }

    public function servicio()
    {
        return $this->belongsTo(Servicio::class);
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }
}
