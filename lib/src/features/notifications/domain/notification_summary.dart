class NotificationPage {
  const NotificationPage({required this.total, required this.rows});

  final int total;
  final List<NotificationSummary> rows;
}

class NotificationSummary {
  const NotificationSummary({
    required this.id,
    required this.type,
    required this.targetType,
    required this.title,
    required this.content,
    required this.link,
    required this.isRead,
    required this.createdAt,
    required this.actorName,
    required this.actorAvatar,
  });

  final int id;
  final String type;
  final String targetType;
  final String title;
  final String content;
  final String link;
  final bool isRead;
  final String createdAt;
  final String actorName;
  final String actorAvatar;

  factory NotificationSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final actor = map['actor'];
    final actorMap = actor is Map ? actor : const <String, Object?>{};
    final firstName = _readString(actorMap['first_name']);
    final username = _readString(actorMap['username']);

    return NotificationSummary(
      id: _readInt(map['id']),
      type: _readString(map['type'], fallback: 'system'),
      targetType: _readString(map['target_type'] ?? map['targetType']),
      title: _readString(map['title'], fallback: 'Notification'),
      content: _readString(map['content']),
      link: _readString(map['link']),
      isRead: _readBool(map['is_read'] ?? map['isRead']),
      createdAt: _readString(map['created_at'] ?? map['createdAt']),
      actorName: firstName.isNotEmpty ? firstName : username,
      actorAvatar: _readString(actorMap['avatar'] ?? actorMap['avatar_url']),
    );
  }

  NotificationSummary copyWith({bool? isRead}) {
    return NotificationSummary(
      id: id,
      type: type,
      targetType: targetType,
      title: title,
      content: content,
      link: link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actorName: actorName,
      actorAvatar: actorAvatar,
    );
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
