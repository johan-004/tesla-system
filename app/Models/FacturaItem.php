<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FacturaItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'factura_id',
        'producto_id',
        'orden',
        'descripcion',
        'unidad',
        'cantidad',
        'precio_unitario',
        'iva_porcentaje',
        'iva_valor',
        'subtotal_linea',
        'total_linea',
    ];

    protected function casts(): array
    {
        return [
            'cantidad' => 'decimal:2',
            'precio_unitario' => 'decimal:2',
            'iva_porcentaje' => 'decimal:2',
            'iva_valor' => 'decimal:2',
            'subtotal_linea' => 'decimal:2',
            'total_linea' => 'decimal:2',
        ];
    }

    public function factura()
    {
        return $this->belongsTo(Factura::class);
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }
}
