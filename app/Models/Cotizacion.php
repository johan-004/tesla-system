<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cotizacion extends Model
{
    use HasFactory;

    protected $table = 'cotizaciones';

    public const ESTADO_PENDIENTE = 'pendiente';
    public const ESTADO_VISTO = 'visto';
    public const ESTADO_REALIZADA = 'realizada';
    public const ESTADO_NULA = 'nula';

    public const ESTADOS = [
        self::ESTADO_PENDIENTE,
        self::ESTADO_VISTO,
        self::ESTADO_REALIZADA,
        self::ESTADO_NULA,
    ];

    public const ESTADO_ALIASES = [
        'borrador' => self::ESTADO_PENDIENTE,
        'revisada' => self::ESTADO_VISTO,
        'aprobada' => self::ESTADO_REALIZADA,
        'anulada' => self::ESTADO_NULA,
    ];

    protected $fillable = [
        'numero',
        'ciudad',
        'cliente_nombre',
        'cliente_nit',
        'cliente_contacto',
        'cliente_cargo',
        'cliente_ciudad',
        'cliente_direccion',
        'referencia',
        'created_by',
        'updated_by',
        'cliente_id',
        'user_id',
        'codigo',
        'fecha',
        'estado',
        'observaciones',
        'alcance_items',
        'oferta_dias_totales',
        'oferta_dias_ejecucion',
        'oferta_dias_tramitologia',
        'oferta_pago_1_pct',
        'oferta_pago_2_pct',
        'oferta_pago_3_pct',
        'oferta_garantia_meses',
        'firma_path',
        'firma_nombre',
        'firma_cargo',
        'firma_empresa',
        'subtotal',
        'impuestos',
        'total',
        'item',
        'obra',
        'descripcion',
        'unidad',
        'factor_zona',
        'aiu',
        'total_costo_directo',
        'total_costo_unitario',
    ];

    protected function casts(): array
    {
        return [
            'fecha' => 'date',
            'alcance_items' => 'array',
            'oferta_dias_totales' => 'integer',
            'oferta_dias_ejecucion' => 'integer',
            'oferta_dias_tramitologia' => 'integer',
            'oferta_pago_1_pct' => 'decimal:2',
            'oferta_pago_2_pct' => 'decimal:2',
            'oferta_pago_3_pct' => 'decimal:2',
            'oferta_garantia_meses' => 'integer',
            'subtotal' => 'decimal:2',
            'impuestos' => 'decimal:2',
            'total' => 'decimal:2',
            'factor_zona' => 'decimal:2',
            'aiu' => 'decimal:2',
            'total_costo_directo' => 'decimal:2',
            'total_costo_unitario' => 'decimal:2',
        ];
    }

    public function scopeBuscar(Builder $query, string $buscar): Builder
    {
        $buscar = trim($buscar);

        if ($buscar === '') {
            return $query;
        }

        return $query->where(function (Builder $subQuery) use ($buscar) {
            $subQuery->where('numero', 'like', "%{$buscar}%")
                ->orWhere('codigo', 'like', "%{$buscar}%")
                ->orWhere('cliente_nombre', 'like', "%{$buscar}%")
                ->orWhere('ciudad', 'like', "%{$buscar}%")
                ->orWhere('referencia', 'like', "%{$buscar}%");
        });
    }

    public function scopeEstado(Builder $query, ?string $estado): Builder
    {
        $estado = self::normalizeEstado($estado);

        if ($estado === null) {
            return $query;
        }

        return $query->where('estado', $estado);
    }

    public static function normalizeEstado(?string $estado): ?string
    {
        if ($estado === null) {
            return null;
        }

        $normalized = mb_strtolower(trim($estado));
        if (isset(self::ESTADO_ALIASES[$normalized])) {
            return self::ESTADO_ALIASES[$normalized];
        }

        return in_array($normalized, self::ESTADOS, true) ? $normalized : null;
    }

    public function canBeMarkedAsVista(): bool
    {
        return $this->estado === self::ESTADO_PENDIENTE;
    }

    public function canBeMarkedAsRealizada(): bool
    {
        return $this->estado === self::ESTADO_VISTO;
    }

    public function canBeMarkedAsNula(): bool
    {
        return in_array($this->estado, [self::ESTADO_PENDIENTE, self::ESTADO_VISTO], true);
    }

    public function cliente()
    {
        return $this->belongsTo(Cliente::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function detalles()
    {
        return $this->hasMany(CotizacionDetalle::class);
    }

    public function equipos()
    {
        return $this->hasMany(Equipo::class);
    }

    public function transportes()
    {
        return $this->hasMany(Transporte::class);
    }

    public function manoObras()
    {
        return $this->hasMany(ManoObra::class);
    }
}
