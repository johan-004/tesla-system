<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class Producto extends Model
{
    use HasFactory;

    protected $fillable = [
        'codigo',
        'nombre',
        'descripcion',
        'precio_compra',
        'precio_venta',
        'iva_porcentaje',
        'stock',
        'unidad_medida',
        'categoria_id',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'precio_compra' => 'decimal:2',
            'precio_venta' => 'decimal:2',
            'iva_porcentaje' => 'decimal:2',
            'activo' => 'boolean',
        ];
    }

    public function scopeBuscar(Builder $query, string $buscar): Builder
    {
        $buscar = trim($buscar);

        if ($buscar === '') {
            return $query;
        }

        return $query->where(function (Builder $subQuery) use ($buscar) {
            $subQuery->where('codigo', 'like', "%{$buscar}%")
                ->orWhere('nombre', 'like', "%{$buscar}%")
                ->orWhereHas('categoria', function (Builder $relationQuery) use ($buscar) {
                    $relationQuery->where('nombre', 'like', "%{$buscar}%");
                });
        });
    }

    public function scopeSugerencias(Builder $query, string $buscar, int $limite = 6): Builder
    {
        $buscar = trim($buscar);
        $limite = max(1, min($limite, 10));

        return $query
            ->buscar($buscar)
            ->orderByRaw('CASE WHEN codigo LIKE ? THEN 0 ELSE 1 END', ["{$buscar}%"])
            ->orderByRaw('CASE WHEN nombre LIKE ? THEN 0 ELSE 1 END', ["{$buscar}%"])
            ->orderBy('nombre')
            ->limit($limite);
    }

    public function categoria()
    {
        return $this->belongsTo(ProductoCategoria::class, 'categoria_id');
    }
}
