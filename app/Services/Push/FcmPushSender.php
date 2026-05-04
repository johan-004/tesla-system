<?php

namespace App\Services\Push;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class FcmPushSender
{
    /**
     * @param list<string> $tokens
     * @param array<string, string> $data
     */
    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): void
    {
        $tokens = array_values(array_unique(array_filter(
            $tokens,
            static fn ($token) => is_string($token) && trim($token) !== ''
        )));

        if ($tokens === []) {
            return;
        }

        if (! (bool) config('push.enabled', true)) {
            return;
        }

        if ((string) config('push.driver', 'fcm') !== 'fcm') {
            return;
        }

        $data = $this->normalizeData($data);

        $serviceAccountPath = $this->resolveServiceAccountPath((string) config('push.fcm.service_account_json', ''));
        if ($serviceAccountPath !== '' && is_file($serviceAccountPath)) {
            $this->sendWithFcmV1(
                $tokens,
                $title,
                $body,
                $data,
                $serviceAccountPath
            );
            return;
        }

        // Compatibilidad con implementación legacy por server key.
        $serverKey = (string) config('push.fcm.server_key', '');
        if ($serverKey !== '') {
            $this->sendWithLegacyKey($tokens, $title, $body, $data, $serverKey);
            return;
        }

        Log::warning('Push FCM no configurado: falta credencial Admin SDK o FCM_SERVER_KEY.');
    }

    /**
     * @param list<string> $tokens
     * @param array<string, string> $data
     */
    private function sendWithFcmV1(
        array $tokens,
        string $title,
        string $body,
        array $data,
        string $serviceAccountPath
    ): void {
        $credentials = $this->loadServiceAccount($serviceAccountPath);

        $projectId = (string) config('push.fcm.project_id', '');
        if ($projectId === '') {
            $projectId = (string) ($credentials['project_id'] ?? '');
        }

        if ($projectId === '') {
            Log::warning('Push FCM v1 no configurado: falta project_id.');
            return;
        }

        $accessToken = $this->fetchAccessToken($credentials);
        $apiBase = rtrim((string) config('push.fcm.api_base', 'https://fcm.googleapis.com'), '/');
        $endpoint = $apiBase.'/v1/projects/'.$projectId.'/messages:send';

        foreach ($tokens as $token) {
            $response = Http::timeout(12)
                ->withToken($accessToken)
                ->post($endpoint, [
                    'message' => [
                        'token' => $token,
                        'notification' => [
                            'title' => $title,
                            'body' => $body,
                        ],
                        'data' => $data,
                        'android' => [
                            'priority' => 'high',
                            'notification' => [
                                'sound' => 'default',
                            ],
                        ],
                    ],
                ]);

            if (! $response->successful()) {
                Log::warning('Error enviando push por FCM v1.', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
            }
        }
    }

    /**
     * @param list<string> $tokens
     * @param array<string, string> $data
     */
    private function sendWithLegacyKey(
        array $tokens,
        string $title,
        string $body,
        array $data,
        string $serverKey
    ): void {
        $response = Http::timeout(12)
            ->withHeaders([
                'Authorization' => 'key='.$serverKey,
                'Content-Type' => 'application/json',
            ])
            ->post('https://fcm.googleapis.com/fcm/send', [
                'registration_ids' => $tokens,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                    'sound' => 'default',
                ],
                'data' => $data,
                'priority' => 'high',
            ]);

        if (! $response->successful()) {
            Log::warning('Error enviando push por FCM legacy.', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function loadServiceAccount(string $path): array
    {
        $raw = @file_get_contents($path);
        if ($raw === false) {
            throw new RuntimeException('No fue posible leer la credencial de Firebase Admin SDK.');
        }

        $json = json_decode($raw, true);
        if (! is_array($json)) {
            throw new RuntimeException('La credencial de Firebase Admin SDK no tiene JSON válido.');
        }

        if (! isset($json['client_email'], $json['private_key'])) {
            throw new RuntimeException('La credencial de Firebase Admin SDK está incompleta.');
        }

        return $json;
    }

    /**
     * @param array<string, mixed> $credentials
     */
    private function fetchAccessToken(array $credentials): string
    {
        $tokenUri = (string) config('push.fcm.oauth_token_uri', 'https://oauth2.googleapis.com/token');
        $jwt = $this->createJwtAssertion(
            (string) $credentials['client_email'],
            (string) $credentials['private_key'],
            $tokenUri
        );

        $response = Http::asForm()
            ->timeout(12)
            ->post($tokenUri, [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

        if (! $response->successful()) {
            throw new RuntimeException('No fue posible obtener access token de Firebase.');
        }

        $payload = $response->json();
        $token = is_array($payload) ? (string) ($payload['access_token'] ?? '') : '';
        if ($token === '') {
            throw new RuntimeException('Firebase no devolvió access_token.');
        }

        return $token;
    }

    private function createJwtAssertion(string $clientEmail, string $privateKey, string $audience): string
    {
        $now = time();

        $header = $this->base64UrlEncode(json_encode([
            'alg' => 'RS256',
            'typ' => 'JWT',
        ], JSON_UNESCAPED_SLASHES) ?: '{}');

        $claims = $this->base64UrlEncode(json_encode([
            'iss' => $clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => $audience,
            'iat' => $now,
            'exp' => $now + 3600,
        ], JSON_UNESCAPED_SLASHES) ?: '{}');

        $unsigned = $header.'.'.$claims;
        $signature = '';
        $signed = openssl_sign($unsigned, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        if (! $signed) {
            throw new RuntimeException('No fue posible firmar JWT para Firebase.');
        }

        return $unsigned.'.'.$this->base64UrlEncode($signature);
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function resolveServiceAccountPath(string $path): string
    {
        $path = trim($path);
        if ($path === '') {
            return '';
        }

        if (str_starts_with($path, DIRECTORY_SEPARATOR)) {
            return $path;
        }

        return base_path($path);
    }

    /**
     * @param array<string, mixed> $data
     * @return array<string, string>
     */
    private function normalizeData(array $data): array
    {
        $normalized = [];
        foreach ($data as $key => $value) {
            if (! is_string($key) || trim($key) === '') {
                continue;
            }
            $normalized[$key] = is_scalar($value)
                ? (string) $value
                : (json_encode($value) ?: '');
        }

        return $normalized;
    }
}
