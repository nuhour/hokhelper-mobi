class PatchNoteSummary {
  const PatchNoteSummary({
    required this.id,
    required this.version,
    required this.title,
    required this.date,
    required this.preview,
    required this.changeCount,
    required this.tags,
  });

  final int id;
  final String version;
  final String title;
  final String date;
  final String preview;
  final int changeCount;
  final List<String> tags;

  factory PatchNoteSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final title = _readString(map['title'], fallback: 'Patch Note');
    final tags = _readStringList(map['tags']);

    return PatchNoteSummary(
      id: _readInt(map['id']),
      version: _deriveVersion(title),
      title: title,
      date: _readString(
        map['date'],
        fallback: _readString(map['created_at']).split('T').first,
      ),
      preview: _readString(map['content_preview'] ?? map['content']),
      changeCount: _readListLength(map['hero_histories']),
      tags: tags,
    );
  }
}

bool isPatchNotePost(Object? json) {
  final map = json is Map ? json : const <String, Object?>{};
  final tags = _readStringList(map['tags']);
  return tags.any((tag) {
    final normalized = tag.toLowerCase();
    return normalized == 'update' ||
        normalized == 'patch notes' ||
        normalized == 'catatan patch' ||
        tag == '更新公告';
  });
}

String _deriveVersion(String title) {
  final match = RegExp(
    r'v?\d+(?:\.\d+){1,3}',
    caseSensitive: false,
  ).firstMatch(title);
  if (match == null) {
    return '-';
  }
  return match.group(0)!.replaceFirst(RegExp('^v', caseSensitive: false), '');
}

int _readListLength(Object? value) {
  return value is List ? value.length : 0;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
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
