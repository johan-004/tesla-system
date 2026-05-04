<?php

namespace App\Services\Alerts;

use App\Models\Cotizacion;
use App\Models\Factura;
use App\Models\Producto;
use App\Models\User;
use App\Models\UserNotification;
use App\Models\UserPushDevice;
use App\Services\Push\FcmPushSender;
use Illuminate\Support\Facades\Log;

class AdminBusinessPushNotifier
{
    public function __construct(
        private readonly FcmPushSender $fcmPushSender,
    ) {
    }

    public function notifyCotizacionCreatedBySeller(Cotizacion $cotizacion, ?User $actor): void
    {
        if (! $actor?->isVendedor()) {
            return;
        }

        $tokens = $this->adminTokens();
        Log::info('Push cotización: tokens admin encontrados', [
            'tokens_count' => count($tokens),
            'actor_id' => $actor->id,
            'cotizacion_id' => $cotizacion->id,
        ]);
        if ($tokens === []) {
            return;
        }

        $this->fcmPushSender->sendToTokens(
            $tokens,
            'Nueva cotización creada',
            sprintf(
                '%s creó %s para %s.',
                $actor->name ?: 'Un vendedor',
                $cotizacion->codigo ?: ('#'.$cotizacion->id),
                $cotizacion->cliente_nombre ?: 'cliente'
            ),
            [
                'event' => 'cotizacion.created',
                'cotizacion_id' => (string) $cotizacion->id,
                'codigo' => (string) ($cotizacion->codigo ?? ''),
            ],
        );

        $this->storeAdminNotifications(
            title: 'Nueva cotización creada',
            body: sprintf(
                '%s creó %s para %s.',
                $actor->name ?: 'Un vendedor',
                $cotizacion->codigo ?: ('#'.$cotizacion->id),
                $cotizacion->cliente_nombre ?: 'cliente'
            ),
            event: 'cotizacion.created',
            resourceType: 'cotizacion',
            resourceId: (int) $cotizacion->id,
            meta: [
                'codigo' => (string) ($cotizacion->codigo ?? ''),
            ],
        );
    }

    public function notifyFacturaCreatedBySeller(Factura $factura, ?User $actor): void
    {
        if (! $actor?->isVendedor()) {
            return;
        }

        $tokens = $this->adminTokens();
        Log::info('Push factura: tokens admin encontrados', [
            'tokens_count' => count($tokens),
            'actor_id' => $actor->id,
            'factura_id' => $factura->id,
        ]);
        if ($tokens === []) {
            return;
        }

        $this->fcmPushSender->sendToTokens(
            $tokens,
            'Nueva factura creada',
            sprintf(
                '%s creó %s para %s.',
                $actor->name ?: 'Un vendedor',
                $factura->codigo ?: ('#'.$factura->id),
                $factura->cliente_nombre ?: 'cliente'
            ),
            [
                'event' => 'factura.created',
                'factura_id' => (string) $factura->id,
                'codigo' => (string) ($factura->codigo ?? ''),
            ],
        );

        $this->storeAdminNotifications(
            title: 'Nueva factura creada',
            body: sprintf(
                '%s creó %s para %s.',
                $actor->name ?: 'Un vendedor',
                $factura->codigo ?: ('#'.$factura->id),
                $factura->cliente_nombre ?: 'cliente'
            ),
            event: 'factura.created',
            resourceType: 'factura',
            resourceId: (int) $factura->id,
            meta: [
                'codigo' => (string) ($factura->codigo ?? ''),
            ],
        );
    }

    public function notifyProductoOutOfStock(Producto $producto, Factura $factura, ?User $actor): void
    {
        $tokens = $this->adminTokens();
        $title = 'Producto sin stock';
        $body = sprintf(
            '%s (%s) quedó en 0 unidades tras emitir %s.',
            $producto->nombre ?: 'Producto',
            $producto->codigo ?: ('#'.$producto->id),
            $factura->codigo ?: ('#'.$factura->id)
        );

        if ($tokens !== []) {
            $this->fcmPushSender->sendToTokens(
                $tokens,
                $title,
                $body,
                [
                    'event' => 'producto.stock_zero',
                    'producto_id' => (string) $producto->id,
                    'factura_id' => (string) $factura->id,
                    'codigo' => (string) ($producto->codigo ?? ''),
                    'stock' => (string) ((int) $producto->stock),
                ],
            );
        }

        $this->storeAdminNotifications(
            title: $title,
            body: $body,
            event: 'producto.stock_zero',
            resourceType: 'producto',
            resourceId: (int) $producto->id,
            meta: [
                'codigo' => (string) ($producto->codigo ?? ''),
                'stock' => (int) $producto->stock,
                'factura_codigo' => (string) ($factura->codigo ?? ''),
                'factura_id' => (int) $factura->id,
                'actor_id' => (int) ($actor?->id ?? 0),
            ],
        );
    }

    /**
     * @return list<string>
     */
    private function adminTokens(): array
    {
        return UserPushDevice::query()
            ->join('users', 'users.id', '=', 'user_push_devices.user_id')
            ->whereIn('users.role', [User::ROLE_ADMINISTRADOR, User::LEGACY_ROLE_ADMINISTRADORA])
            ->pluck('user_push_devices.token')
            ->filter(fn ($token) => is_string($token) && trim($token) !== '')
            ->map(fn ($token) => (string) $token)
            ->unique()
            ->values()
            ->all();
    }

    /**
     * @return list<int>
     */
    private function adminUserIds(): array
    {
        return User::query()
            ->whereIn('role', [User::ROLE_ADMINISTRADOR, User::LEGACY_ROLE_ADMINISTRADORA])
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values()
            ->all();
    }

    private function storeAdminNotifications(
        string $title,
        string $body,
        string $event,
        string $resourceType,
        int $resourceId,
        array $meta = [],
    ): void {
        $userIds = $this->adminUserIds();
        if ($userIds === []) {
            return;
        }

        $now = now();
        $metaJson = json_encode($meta, JSON_UNESCAPED_UNICODE);
        if (! is_string($metaJson) || $metaJson === '') {
            $metaJson = '{}';
        }

        $rows = array_map(
            fn (int $userId) => [
                'user_id' => $userId,
                'title' => $title,
                'body' => $body,
                'event' => $event,
                'resource_type' => $resourceType,
                'resource_id' => $resourceId,
                'meta' => $metaJson,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            $userIds,
        );

        UserNotification::query()->insert($rows);
    }
}
