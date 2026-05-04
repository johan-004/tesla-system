<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserNotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $limit = max(1, min((int) $request->get('limit', 20), 50));

        $query = UserNotification::query()
            ->where('user_id', $user->id);

        $items = (clone $query)
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get()
            ->map(fn (UserNotification $notification) => $this->mapNotification($notification))
            ->values()
            ->all();

        $unreadCount = (clone $query)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'message' => 'Notificaciones obtenidas correctamente.',
            'data' => $items,
            'meta' => [
                'unread_count' => (int) $unreadCount,
            ],
        ]);
    }

    public function markRead(Request $request, UserNotification $notification): JsonResponse
    {
        $user = $request->user();
        if ((int) $notification->user_id !== (int) $user->id) {
            return response()->json([
                'message' => 'No tienes permisos para esta notificación.',
            ], 403);
        }

        if ($notification->read_at === null) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json([
            'message' => 'Notificación marcada como leída.',
            'data' => $this->mapNotification($notification->fresh()),
        ]);
    }

    private function mapNotification(UserNotification $notification): array
    {
        return [
            'id' => $notification->id,
            'title' => (string) $notification->title,
            'body' => (string) ($notification->body ?? ''),
            'event' => (string) ($notification->event ?? ''),
            'resource_type' => (string) ($notification->resource_type ?? ''),
            'resource_id' => $notification->resource_id === null ? null : (int) $notification->resource_id,
            'meta' => $notification->meta ?? [],
            'read_at' => optional($notification->read_at)->toDateTimeString(),
            'created_at' => optional($notification->created_at)->toDateTimeString(),
        ];
    }
}

