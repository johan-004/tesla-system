<?php

namespace App\Services\Security;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class SecurityAlertService
{
    public function onFailedLogin(Request $request, string $email): void
    {
        $ip = (string) $request->ip();
        $windowSeconds = 10 * 60;
        $threshold = 8;

        $count = $this->incrementCounter("sec:failed_login:{$ip}", $windowSeconds);
        if ($count < $threshold) {
            return;
        }

        $this->dispatchAlert(
            key: "sec:alert:failed_login:{$ip}",
            cooldownSeconds: 30 * 60,
            event: 'suspicious_failed_logins',
            payload: [
                'ip' => $ip,
                'email' => $email,
                'count_window_10m' => $count,
                'user_agent' => substr((string) $request->userAgent(), 0, 255),
            ],
        );
    }

    public function onRateLimitExceeded(string $limiter, Request $request): void
    {
        $ip = (string) $request->ip();

        $this->dispatchAlert(
            key: "sec:alert:ratelimit:{$limiter}:{$ip}",
            cooldownSeconds: 15 * 60,
            event: 'rate_limit_exceeded',
            payload: [
                'limiter' => $limiter,
                'ip' => $ip,
                'path' => '/'.ltrim($request->path(), '/'),
                'user_agent' => substr((string) $request->userAgent(), 0, 255),
            ],
        );
    }

    private function incrementCounter(string $key, int $ttlSeconds): int
    {
        if (! Cache::has($key)) {
            Cache::put($key, 0, now()->addSeconds($ttlSeconds));
        }

        return (int) Cache::increment($key);
    }

    /**
     * @param array<string,mixed> $payload
     */
    private function dispatchAlert(
        string $key,
        int $cooldownSeconds,
        string $event,
        array $payload
    ): void {
        if (Cache::has($key)) {
            return;
        }

        Cache::put($key, true, now()->addSeconds($cooldownSeconds));

        Log::channel('security')->critical($event, $payload);

        $recipients = $this->getRecipients();
        if ($recipients === []) {
            return;
        }

        $subject = '[Tesla System] Alerta de seguridad';
        $message = $this->buildMailBody($event, $payload);

        try {
            Mail::raw($message, function ($mail) use ($recipients, $subject): void {
                $mail->to($recipients)->subject($subject);
            });
        } catch (\Throwable $e) {
            Log::channel('security')->error('security_alert_email_failed', [
                'event' => $event,
                'error' => $e->getMessage(),
            ]);
        }

        $this->sendTelegramAlerts($event, $payload);
    }

    /**
     * @return array<int,string>
     */
    private function getRecipients(): array
    {
        $raw = (string) env('SECURITY_ALERT_RECIPIENTS', '');
        $emails = array_values(array_filter(array_map('trim', explode(',', $raw))));

        return array_values(array_filter($emails, static fn (string $email): bool => filter_var($email, FILTER_VALIDATE_EMAIL) !== false));
    }

    /**
     * @param array<string,mixed> $payload
     */
    private function buildMailBody(string $event, array $payload): string
    {
        $lines = [
            'Se detectó un evento de seguridad en Tesla System.',
            "Evento: {$event}",
            'Fecha: '.now()->toDateTimeString(),
            '',
            'Detalles:',
        ];

        foreach ($payload as $key => $value) {
            $lines[] = "- {$key}: ".(is_scalar($value) ? (string) $value : json_encode($value));
        }

        $lines[] = '';
        $lines[] = 'Acción recomendada: revisar logs de seguridad y bloquear IP si aplica.';

        return implode(PHP_EOL, $lines);
    }

    /**
     * @param array<string,mixed> $payload
     */
    private function sendTelegramAlerts(string $event, array $payload): void
    {
        $botToken = trim((string) env('TELEGRAM_BOT_TOKEN', ''));
        $chatIds = $this->getTelegramChatIds();

        if ($botToken === '' || $chatIds === []) {
            return;
        }

        $message = $this->buildTelegramBody($event, $payload);

        foreach ($chatIds as $chatId) {
            try {
                Http::timeout(8)->asForm()->post(
                    "https://api.telegram.org/bot{$botToken}/sendMessage",
                    [
                        'chat_id' => $chatId,
                        'text' => $message,
                        'disable_web_page_preview' => 'true',
                    ]
                );
            } catch (\Throwable $e) {
                Log::channel('security')->error('security_alert_telegram_failed', [
                    'event' => $event,
                    'chat_id' => $chatId,
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }

    /**
     * @return array<int,string>
     */
    private function getTelegramChatIds(): array
    {
        $raw = (string) env('TELEGRAM_CHAT_IDS', '');
        $chatIds = array_values(array_filter(array_map('trim', explode(',', $raw))));

        return array_values(array_filter($chatIds, static fn (string $chatId): bool => $chatId !== ''));
    }

    /**
     * @param array<string,mixed> $payload
     */
    private function buildTelegramBody(string $event, array $payload): string
    {
        $parts = [
            '[Tesla System] Alerta de seguridad',
            "Evento: {$event}",
        ];

        if (isset($payload['ip'])) {
            $parts[] = 'IP: '.(string) $payload['ip'];
        }

        if (isset($payload['path'])) {
            $parts[] = 'Ruta: '.(string) $payload['path'];
        }

        if (isset($payload['count_window_10m'])) {
            $parts[] = 'Intentos (10m): '.(string) $payload['count_window_10m'];
        }

        $parts[] = 'Revisa logs de seguridad y bloquea la IP si aplica.';

        return implode(' | ', $parts);
    }
}
