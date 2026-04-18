<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    public const ROLE_ADMINISTRADOR = 'administrador';
    public const ROLE_VENDEDOR = 'vendedor';
    public const LEGACY_ROLE_ADMINISTRADORA = 'administradora';
    public const LEGACY_ROLE_VENDEDORA = 'vendedora';

    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'firma_path_default',
        'firma_nombre_default',
        'firma_cargo_default',
        'firma_empresa_default',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function clientes()
    {
        return $this->hasMany(Cliente::class, 'created_by');
    }

    public function cotizaciones()
    {
        return $this->hasMany(Cotizacion::class);
    }

    public function facturas()
    {
        return $this->hasMany(Factura::class);
    }

    public function normalizedRole(): ?string
    {
        return self::normalizeRoleValue($this->role);
    }

    public function isAdministrador(): bool
    {
        return $this->normalizedRole() === self::ROLE_ADMINISTRADOR;
    }

    public function isVendedor(): bool
    {
        return $this->normalizedRole() === self::ROLE_VENDEDOR;
    }

    public function permissions(): array
    {
        return match ($this->normalizedRole()) {
            self::ROLE_ADMINISTRADOR => [
                'productos.view',
                'productos.create',
                'productos.update',
                'productos.toggle',
                'productos.delete',
                'servicios.view',
                'servicios.create',
                'servicios.update',
                'servicios.toggle',
                'servicios.delete',
                'clientes.view',
                'clientes.create',
                'clientes.update',
                'clientes.delete',
                'categorias_servicio.view',
                'categorias_servicio.create',
                'categorias_servicio.update',
                'categorias_servicio.delete',
                'cotizaciones.view',
                'cotizaciones.create',
                'cotizaciones.update',
                'cotizaciones.delete',
                'facturacion.view',
                'facturacion.create',
                'facturacion.update',
                'facturacion.delete',
                'usuarios.view',
                'usuarios.create',
                'usuarios.update',
                'usuarios.delete',
            ],
            self::ROLE_VENDEDOR => [
                'productos.view',
                'servicios.view',
                'clientes.view',
                'categorias_servicio.view',
                'cotizaciones.view',
                'cotizaciones.create',
                'cotizaciones.update',
                'facturacion.view',
                'facturacion.create',
                'facturacion.update',
            ],
            default => [],
        };
    }

    public function hasPermission(string $permission): bool
    {
        return in_array($permission, $this->permissions(), true);
    }

    public static function normalizeRoleValue(?string $role): ?string
    {
        return match ($role) {
            self::LEGACY_ROLE_ADMINISTRADORA => self::ROLE_ADMINISTRADOR,
            self::LEGACY_ROLE_VENDEDORA => self::ROLE_VENDEDOR,
            default => $role,
        };
    }

    public function setRoleAttribute(?string $value): void
    {
        $this->attributes['role'] = self::normalizeRoleValue($value);
    }
}
