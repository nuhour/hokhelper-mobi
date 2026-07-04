import '../../../core/network/api_client.dart';
import '../domain/notification_summary.dart';

class NotificationsRepository {
  const NotificationsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<NotificationPage> loadNotifications({
    int page = 1,
    int pageSize = 50,
    String type = '',
    bool unreadOnly = false,
  }) async {
    final json = await apiClient.getJson(
      '/notifications',
      query: {
        'page': page,
        'pageSize': pageSize,
        if (type.isNotEmpty) 'type': type,
        if (unreadOnly) 'unreadOnly': true,
      },
    );
    final result = json['result'];
    final resultMap = result is Map ? result : const <String, Object?>{};
    final rows = resultMap['rows'];

    return NotificationPage(
      total: _readInt(resultMap['total']),
      rows: rows is List
          ? rows.map(NotificationSummary.fromJson).toList(growable: false)
          : const [],
    );
  }

  Future<int> loadUnreadCount() async {
    final json = await apiClient.getJson('/notifications/unread-count');
    final result = json['result'];
    final resultMap = result is Map ? result : const <String, Object?>{};
    return _readInt(resultMap['unread_count'] ?? resultMap['unreadCount']);
  }

  Future<int> markRead(List<int> ids) async {
    final json = await apiClient.postJson(
      '/notifications/read',
      body: {'ids': ids},
    );
    return _readUpdated(json);
  }

  Future<int> markAllRead() async {
    final json = await apiClient.postJson('/notifications/read-all', body: {});
    return _readUpdated(json);
  }

  int _readUpdated(Map<String, dynamic> json) {
    final result = json['result'];
    final resultMap = result is Map ? result : const <String, Object?>{};
    return _readInt(resultMap['updated']);
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
