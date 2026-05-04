<?php

namespace App\Services\Sms;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Throwable;

class SmsSender
{
    public function send(string $phone, string $message): void
    {
        $driver = (string) config('sms.driver', 'log');
        $isProduction = app()->environment('production');

        if ($driver === 'twilio') {
            $this->sendWithTwilio($phone, $message);
            return;
        }

        if ($isProduction) {
            throw new RuntimeException('SMS driver inseguro para producción. Configura un proveedor real (ej. Twilio).');
        }

        Log::channel(config('sms.log_channel'))->info('SMS de recuperación', [
            'to' => $this->maskPhone($phone),
            'message' => '[REDACTED]',
        ]);
    }

    private function sendWithTwilio(string $phone, string $message): void
    {
        $sid = (string) config('sms.twilio.sid');
        $token = (string) config('sms.twilio.token');
        $from = $this->normalizeTwilioPhone((string) config('sms.twilio.from'));
        $to = $this->normalizeTwilioPhone($phone);

        if ($sid === '' || $token === '' || $from === '') {
            throw new RuntimeException('Twilio no está configurado correctamente.');
        }

        $response = Http::asForm()
            ->withBasicAuth($sid, $token)
            ->post("https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json", [
                'From' => $from,
                'To' => $to,
                'Body' => $message,
            ]);

        if (! $response->successful()) {
            $detail = $this->extractTwilioErrorDetail($response->json());

            Log::warning('Twilio rechazó el SMS', [
                'to' => $this->maskPhone($to),
                'status' => $response->status(),
                'detail' => $detail,
            ]);

            throw new RuntimeException('No fue posible enviar el SMS de recuperación: '.$detail);
        }
    }

    private function normalizeTwilioPhone(string $phone): string
    {
        $trimmed = trim($phone);
        if ($trimmed === '') {
            return '';
        }

        $digits = preg_replace('/\D+/', '', $trimmed) ?? '';
        if ($digits === '') {
            return $trimmed;
        }

        if (str_starts_with($trimmed, '+')) {
            return '+'.$digits;
        }

        // Entrada local colombiana (10 dígitos) desde el formulario.
        if (strlen($digits) === 10) {
            return '+57'.$digits;
        }

        // Si ya viene con indicativo sin prefijo "+", lo forzamos a E.164.
        return '+'.$digits;
    }

    /**
     * @param mixed $payload
     */
    private function extractTwilioErrorDetail($payload): string
    {
        try {
            if (! is_array($payload)) {
                return 'respuesta no detallada de Twilio';
            }

            $message = isset($payload['message']) && is_string($payload['message'])
                ? trim($payload['message'])
                : 'error desconocido';
            $code = isset($payload['code']) ? (string) $payload['code'] : 'N/A';

            return "Twilio code {$code}: {$message}";
        } catch (Throwable) {
            return 'error no parseable de Twilio';
        }
    }

    private function maskPhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if ($digits === '') {
            return '***';
        }

        if (strlen($digits) <= 4) {
            return str_repeat('*', strlen($digits));
        }

        return str_repeat('*', strlen($digits) - 4).substr($digits, -4);
    }
}
