<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class Servicio extends Model
{
    use HasFactory;

    public const CATEGORIAS_SUGERIDAS = [
        'residencial',
        'comercial',
        'industrial',
        'mantenimiento y emergencias',
    ];

    protected $fillable = [
        'categoria_servicio_id',
        'codigo',
        'nombre',
        'descripcion',
        'categoria',
        'unidad',
        'precio_unitario',
        'iva',
        'precio_con_iva',
        'observaciones',
        'precio_base',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'precio_unitario' => 'decimal:2',
            'iva' => 'decimal:2',
            'precio_con_iva' => 'decimal:2',
            'precio_base' => 'decimal:2',
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
                ->orWhere('descripcion', 'like', "%{$buscar}%")
                ->orWhere('categoria', 'like', "%{$buscar}%")
                ->orWhereHas('categoria', function (Builder $relationQuery) use ($buscar) {
                    $relationQuery->where('nombre', 'like', "%{$buscar}%");
                });
        });
    }

    public function scopeCategoria(Builder $query, ?string $categoria): Builder
    {
        $categoria = self::normalizeCategoria($categoria);

        if ($categoria === null) {
            return $query;
        }

        return $query->where(function (Builder $subQuery) use ($categoria) {
            $subQuery->whereRaw('LOWER(TRIM(categoria)) = ?', [$categoria])
                ->orWhereHas('categoria', function (Builder $relationQuery) use ($categoria) {
                    $relationQuery->whereRaw('LOWER(TRIM(nombre)) = ?', [$categoria]);
                });
        });
    }

    public static function normalizeCategoria(?string $categoria): ?string
    {
        if ($categoria === null) {
            return null;
        }

        $normalized = mb_strtolower(trim($categoria));

        if ($normalized === 'instalaciones') {
            return 'residencial';
        }

        return $normalized === '' ? null : $normalized;
    }

    public function categoria()
    {
        return $this->belongsTo(CategoriaServicio::class, 'categoria_servicio_id');
    }
}
