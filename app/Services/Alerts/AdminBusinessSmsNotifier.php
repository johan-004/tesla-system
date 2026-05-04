<?php

namespace App\Services\Alerts;

use App\Models\Cotizacion;
use App\Models\Factura;
use App\Models\User;
use App\Services\Sms\SmsSender;
use Illuminate\Support\Facades\Log;
use Throwable;

class AdminBusinessSmsNotifier
{
    public function __construct(
        private readonly SmsSender $smsSender,
    ) {
    }

    public function notifyCotizacionCreatedBySeller(Cotizacion $cotizacion, ?User $actor): void
    {
        if (! $actor?->isVendedor()) {
            return;
        }

        $phones = $this->adminPhones();
        if ($phones === []) {
            return;
        }

        $message = sprintf(
            'Tesla: nueva cotizacion %s creada por %s para %s. Total: $%s.',
            $cotizacion->codigo ?: ('#'.$cotizacion->id),
            $actor->name ?: 'vendedor',
            $cotizacion->cliente_nombre ?: 'cliente',
            number_format((float) $cotizacion->total, 0, ',', '.')
        );

        $this->sendToPhones($phones, $message, 'cotizacion');
    }

    public function notifyFacturaCreatedBySeller(Factura $factura, ?User $actor): void
    {
        if (! $actor?->isVendedor()) {
            return;
        }

        $phones = $this->adminPhones();
        if ($phones === []) {
            return;
        }

        $message = sprintf(
            'Tesla: nueva factura %s creada por %s para %s. Total: $%s.',
            $factura->codigo ?: ('#'.$factura->id),
            $actor->name ?: 'vendedor',
            $factura->cliente_nombre ?: 'cliente',
            number_format((float) $factura->total, 0, ',', '.')
        );

        $this->sendToPhones($phones, $message, 'factura');
    }

    /**
     * @return list<string>
     */
    private function adminPhones(): array
    {
        return User::query()
            ->whereIn('role', [User::ROLE_ADMINISTRADOR, User::LEGACY_ROLE_ADMINISTRADORA])
            ->whereNotNull('phone')
            ->where('phone', '<>', '')
            ->pluck('phone')
            ->filter(fn ($phone) => is_string($phone) && trim($phone) !== '')
            ->map(fn ($phone) => (string) $phone)
            ->unique()
            ->values()
            ->all();
    }

    /**
     * @param list<string> $phones
     */
    private function sendToPhones(array $phones, string $message, string $context): void
    {
        foreach ($phones as $phone) {
            try {
                $this->smsSender->send($phone, $message);
            } catch (Throwable $exception) {
                Log::warning('No fue posible enviar SMS de alerta de negocio.', [
                    'contexto' => $context,
                    'to' => $phone,
                    'error' => $exception->getMessage(),
                ]);
            }
        }
    }
}

