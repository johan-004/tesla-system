<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserPushDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PushDeviceController extends Controller
{
    public function upsert(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'token' => ['required', 'string', 'max:255'],
            'platform' => ['nullable', 'string', 'in:android,ios,web,unknown'],
            'device_name' => ['nullable', 'string', 'max:80'],
        ]);

        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'No autenticado.'], 401);
        }

        UserPushDevice::query()->updateOrCreate(
            ['token' => trim((string) $payload['token'])],
            [
                'user_id' => $user->id,
                'platform' => trim((string) ($payload['platform'] ?? 'unknown')) ?: 'unknown',
                'device_name' => trim((string) ($payload['device_name'] ?? '')) ?: null,
                'last_seen_at' => now(),
            ],
        );

        return response()->json([
            'message' => 'Dispositivo de notificaciones actualizado.',
        ]);
    }

    public function delete(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'token' => ['required', 'string', 'max:255'],
        ]);

        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'No autenticado.'], 401);
        }

        UserPushDevice::query()
            ->where('user_id', $user->id)
            ->where('token', trim((string) $payload['token']))
            ->delete();

        return response()->json([
            'message' => 'Dispositivo eliminado.',
        ]);
    }
}

