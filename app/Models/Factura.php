<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Factura extends Model
{
    use HasFactory;

    public const ESTADO_PENDIENTE = 'pendiente';
    public const ESTADO_BORRADOR = 'borrador'; // Legacy
    public const ESTADO_EMITIDA = 'emitida';
    public const ESTADO_ANULADA = 'anulada';

    public const ESTADOS = [
        self::ESTADO_PENDIENTE,
        self::ESTADO_EMITIDA,
        self::ESTADO_ANULADA,
    ];

    public const ESTADO_ALIASES = [
        self::ESTADO_BORRADOR => self::ESTADO_PENDIENTE,
    ];

    protected $fillable = [
        'codigo',
        'numero',
        'fecha',
        'ciudad_expedicion',
        'cliente_id',
        'cliente_nombre',
        'cliente_nit',
        'cliente_contacto',
        'cliente_direccion',
        'cliente_ciudad',
        'observaciones',
        'firma_path',
        'firma_nombre',
        'firma_cargo',
        'firma_empresa',
        'subtotal',
        'iva_total',
        'impuestos',
        'total',
        'estado',
        'created_by',
        'updated_by',
        'emitida_at',
        'emitida_by',
        'anulada_at',
        'anulada_by',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'fecha' => 'date',
            'subtotal' => 'decimal:2',
            'iva_total' => 'decimal:2',
            'impuestos' => 'decimal:2',
            'total' => 'decimal:2',
            'emitida_at' => 'datetime',
            'anulada_at' => 'datetime',
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
                ->orWhere('numero', 'like', "%{$buscar}%")
                ->orWhere('cliente_nombre', 'like', "%{$buscar}%")
                ->orWhere('cliente_nit', 'like', "%{$buscar}%");
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

    public function scopeVisibleFlow(Builder $query): Builder
    {
        return $query->whereIn('estado', [
            self::ESTADO_PENDIENTE,
            self::ESTADO_BORRADOR, // Legacy
            self::ESTADO_EMITIDA,
            self::ESTADO_ANULADA,
        ]);
    }

    public function scopePendiente(Builder $query): Builder
    {
        return $query->whereIn('estado', [
            self::ESTADO_PENDIENTE,
            self::ESTADO_BORRADOR, // Legacy
        ]);
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

    public function canBeUpdated(): bool
    {
        return in_array($this->estado, [self::ESTADO_PENDIENTE, self::ESTADO_BORRADOR], true);
    }

    public function canBeEmitted(): bool
    {
        return in_array($this->estado, [self::ESTADO_PENDIENTE, self::ESTADO_BORRADOR], true);
    }

    public function canBeAnnulled(): bool
    {
        return in_array($this->estado, [self::ESTADO_PENDIENTE, self::ESTADO_BORRADOR], true);
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

    public function emitter()
    {
        return $this->belongsTo(User::class, 'emitida_by');
    }

    public function annuller()
    {
        return $this->belongsTo(User::class, 'anulada_by');
    }

    public function items()
    {
        return $this->hasMany(FacturaItem::class)->orderBy('orden');
    }
}
