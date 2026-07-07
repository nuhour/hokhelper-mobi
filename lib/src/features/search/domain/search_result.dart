class SearchResultGroup {
  const SearchResultGroup({required this.key, required this.items});

  final String key;
  final List<SearchResultItem> items;

  String get title {
    final words = key
        .replaceAll('_', '-')
        .split('-')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}');
    return words.isEmpty ? 'Results' : words.join(' ');
  }
}

class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String id;
  final String title;
  final String subtitle;
  final String url;

  factory SearchResultItem.fromJson(Object? value, {String groupKey = ''}) {
    final json = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};

    return SearchResultItem(
      id: _readString(json['id'] ?? json['pk']),
      title: _readString(
        json['title'] ??
            json['name'] ??
            json['heroName'] ??
            json['hero_name'] ??
            json['player_name'] ??
            json['label'],
        fallback: 'Untitled result',
      ),
      subtitle: _readSubtitle(json, groupKey),
      url: _readUrl(json, groupKey),
    );
  }
}

List<SearchResultGroup> parseSearchResultGroups(Map<String, dynamic> json) {
  final result = json['result'];
  final data = result is Map ? result['data'] : json['data'];
  final groupedData = data is Map
      ? data
      : result is Map
      ? result
      : json;
  final groups = <SearchResultGroup>[];

  for (final entry in groupedData.entries) {
    final value = entry.value;
    if (value is! List) {
      continue;
    }

    final items = value
        .map(
          (item) =>
              SearchResultItem.fromJson(item, groupKey: entry.key.toString()),
        )
        .where((item) => item.title.isNotEmpty)
        .toList(growable: false);
    if (items.isEmpty) {
      continue;
    }

    groups.add(SearchResultGroup(key: entry.key.toString(), items: items));
  }

  return groups;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.trim().isEmpty ? fallback : text.trim();
}

String _readSubtitle(Map<String, dynamic> json, String groupKey) {
  final explicit = _readString(
    json['subtitle'] ??
        json['description'] ??
        json['summary'] ??
        json['content_preview'],
  );
  if (explicit.isNotEmpty) {
    return explicit;
  }

  final parts = switch (groupKey) {
    'pro_players' => [
      _readString(json['team_name']),
      _readString(json['position'] ?? json['role']),
    ],
    'players' => [
      _readString(json['rank_type']),
      _readString(json['area'] ?? json['server_name']),
    ],
    'skins' => [_readString(json['hero_name']), _readString(json['rating'])],
    'equips' => [_readString(json['equip_id']), _readString(json['price'])],
    _ => const <String>[],
  };
  return parts.where((part) => part.isNotEmpty).join(' · ');
}

String _readUrl(Map<String, dynamic> json, String groupKey) {
  final explicitUrl = _readString(json['url'] ?? json['path'] ?? json['href']);
  if (explicitUrl.isNotEmpty) {
    return explicitUrl;
  }

  return switch (groupKey) {
    'heroes' => _idPath('/hero-gallery', json['id'] ?? json['hero_id']),
    'skins' => _idPath('/skin-gallery', json['id'] ?? json['skin_id']),
    'equips' => _equipStatsPath(json['equip_id'] ?? json['id']),
    'posts' => _idPath('/community/post', json['id'] ?? json['post_id']),
    'teams' => _idPath('/esports/teams', json['id'] ?? json['team_id']),
    'pro_players' => _idPath(
      '/esports/players',
      json['player_id'] ?? json['id'],
      encode: true,
    ),
    'leaks' => _readString(json['source_url'] ?? json['sourceUrl']),
    _ => '',
  };
}

String _idPath(String prefix, Object? id, {bool encode = false}) {
  final value = _readString(id);
  if (value.isEmpty) {
    return '';
  }
  return '$prefix/${encode ? Uri.encodeComponent(value) : value}';
}

String _equipStatsPath(Object? equipId) {
  final value = _readString(equipId);
  if (value.isEmpty) {
    return '';
  }
  return Uri(
    path: '/stats',
    queryParameters: {'entry': 'equip_rank', 'equip_id': value},
  ).toString();
}
