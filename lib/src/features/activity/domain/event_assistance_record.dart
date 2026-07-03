class EventAssistanceRecord {
  const EventAssistanceRecord({
    required this.id,
    required this.regionId,
    required this.content,
    required this.eventTime,
    required this.isReported,
    required this.rawText,
    required this.sharedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int regionId;
  final String content;
  final String eventTime;
  final bool isReported;
  final String rawText;
  final String sharedBy;
  final String createdAt;
  final String updatedAt;

  String get reportedLabel => isReported ? 'Reported' : 'Active';

  factory EventAssistanceRecord.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return EventAssistanceRecord(
      id: _readString(map['id']),
      regionId: _readInt(map['region_id']),
      content: _readString(map['content']),
      eventTime: _readString(map['event_time']),
      isReported: _readBool(map['is_reported']),
      rawText: _readString(map['raw_text']),
      sharedBy: _readString(map['shared_by'], fallback: 'anonymous'),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().toLowerCase() ?? '';
  return text == 'true' || text == '1';
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
