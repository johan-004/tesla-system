import '../api/api_client.dart';
import 'in_app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<NotificationFeed> fetchNotifications({int limit = 20}) async {
    final response = await _apiClient.get('/notificaciones?limit=$limit');
    final data = response['data'] as List<dynamic>? ?? const [];
    final meta = response['meta'] as Map<String, dynamic>? ?? const {};

    return NotificationFeed(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(InAppNotification.fromJson)
          .toList(),
      unreadCount: _parseInt(meta['unread_count']),
    );
  }

  Future<void> markRead(int id) async {
    await _apiClient.patch('/notificaciones/$id/leer', {});
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

