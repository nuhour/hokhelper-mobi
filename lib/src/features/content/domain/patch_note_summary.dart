class PatchNoteSummary {
  const PatchNoteSummary({
    required this.id,
    required this.version,
    required this.title,
    required this.date,
    required this.preview,
    required this.changeCount,
    required this.tags,
    this.content = '',
    this.heroChanges = const [],
  });

  final int id;
  final String version;
  final String title;
  final String date;
  final String preview;
  final int changeCount;
  final List<String> tags;
  final String content;
  final List<PatchHeroChange> heroChanges;

  factory PatchNoteSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final title = _readString(map['title'], fallback: 'Patch Note');
    final tags = _readStringList(map['tags']);
    final preview = _readString(map['content_preview'] ?? map['content']);
    final heroChanges = _readHeroChanges(map['hero_histories']);

    return PatchNoteSummary(
      id: _readInt(map['id']),
      version: _deriveVersion(title),
      title: title,
      date: _readString(
        map['date'],
        fallback: _readString(map['created_at']).split('T').first,
      ),
      preview: preview,
      changeCount: heroChanges.length,
      tags: tags,
      content: _readString(map['content'], fallback: preview),
      heroChanges: heroChanges,
    );
  }
}

class PatchHeroChange {
  const PatchHeroChange({
    required this.heroId,
    required this.heroName,
    required this.avatarUrl,
    required this.changeType,
  });

  final int heroId;
  final String heroName;
  final String avatarUrl;
  final String changeType;

  factory PatchHeroChange.fromJson(Object? json, int index) {
    final map = json is Map ? json : const <String, Object?>{};
    final heroId = _readInt(map['hero_id'] ?? map['heroId']);

    return PatchHeroChange(
      heroId: heroId,
      heroName: _readString(
        map['hero_name'] ?? map['heroName'],
        fallback: heroId > 0 ? 'Unknown Hero ${index + 1}' : 'Unknown Hero',
      ),
      avatarUrl: _readString(map['avatar_url'] ?? map['avatarUrl']),
      changeType: _normalizeChangeType(map['change_type'] ?? map['changeType']),
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

List<PatchHeroChange> _readHeroChanges(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (var index = 0; index < value.length; index += 1)
      PatchHeroChange.fromJson(value[index], index),
  ];
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

String _normalizeChangeType(Object? value) {
  final normalized = value?.toString().toLowerCase() ?? '';
  if (normalized.contains('buff')) {
    return 'buff';
  }
  if (normalized.contains('nerf')) {
    return 'nerf';
  }
  return 'adjust';
}
