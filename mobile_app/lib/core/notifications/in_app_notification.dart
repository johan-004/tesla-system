class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.event,
    required this.resourceType,
    required this.resourceId,
    required this.isRead,
    required this.createdAt,
    required this.codigo,
  });

  final int id;
  final String title;
  final String body;
  final String event;
  final String resourceType;
  final int? resourceId;
  final bool isRead;
  final DateTime? createdAt;
  final String codigo;

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return InAppNotification(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      resourceType: json['resource_type']?.toString() ?? '',
      resourceId: _parseNullableInt(json['resource_id']),
      isRead: (json['read_at']?.toString().trim().isNotEmpty ?? false),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      codigo: meta['codigo']?.toString() ?? '',
    );
  }
}

class NotificationFeed {
  const NotificationFeed({
    required this.items,
    required this.unreadCount,
  });

  final List<InAppNotification> items;
  final int unreadCount;
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _parseNullableInt(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed;
}

