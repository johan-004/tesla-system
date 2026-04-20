<?php

namespace App\Services\Sms;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class SmsSender
{
    public function send(string $phone, string $message): void
    {
        $driver = (string) config('sms.driver', 'log');

        if ($driver === 'twilio') {
            $this->sendWithTwilio($phone, $message);
            return;
        }

        Log::channel(config('sms.log_channel'))->info('SMS de recuperación', [
            'to' => $phone,
            'message' => $message,
        ]);
    }

    private function sendWithTwilio(string $phone, string $message): void
    {
        $sid = (string) config('sms.twilio.sid');
        $token = (string) config('sms.twilio.token');
        $from = (string) config('sms.twilio.from');

        if ($sid === '' || $token === '' || $from === '') {
            throw new RuntimeException('Twilio no está configurado correctamente.');
        }

        $response = Http::asForm()
            ->withBasicAuth($sid, $token)
            ->post("https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json", [
                'From' => $from,
                'To' => $phone,
                'Body' => $message,
            ]);

        if (! $response->successful()) {
            throw new RuntimeException('No fue posible enviar el SMS de recuperación.');
        }
    }
}
