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
    this.imageUrl = '',
    this.actions = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String url;
  final String imageUrl;
  final List<SearchResultAction> actions;

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
      imageUrl: _readImageUrl(json),
      actions: _readActions(json, groupKey),
    );
  }
}

class SearchResultAction {
  const SearchResultAction({required this.label, required this.url});

  final String label;
  final String url;
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
    'teams' => _teamSubtitleParts(json),
    'pro_players' => _proPlayerSubtitleParts(json),
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

List<String> _teamSubtitleParts(Map<String, dynamic> json) {
  final schedule = _readMap(json['schedule']);
  return [
    _readString(json['league_name']),
    _recordText(json['wins'], json['losses']),
    _opponentText(schedule),
  ];
}

List<String> _proPlayerSubtitleParts(Map<String, dynamic> json) {
  final schedule = _readMap(json['schedule']);
  return [
    _readString(json['team_name']),
    _readString(json['position'] ?? json['role']),
    _opponentText(schedule),
  ];
}

Map<String, dynamic> _readMap(Object? value) {
  return value is Map<String, dynamic>
      ? value
      : value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};
}

String _recordText(Object? wins, Object? losses) {
  final winText = _readString(wins);
  final lossText = _readString(losses);
  if (winText.isEmpty || lossText.isEmpty) {
    return '';
  }
  return '$winText-$lossText';
}

String _opponentText(Map<String, dynamic> schedule) {
  final opponent = _readString(schedule['opponent_name']);
  if (opponent.isEmpty) {
    return '';
  }
  return 'VS $opponent';
}

String _readImageUrl(Map<String, dynamic> json) {
  return _readString(
    json['avatar_url'] ??
        json['hero_icon'] ??
        json['icon_url'] ??
        json['image_url'] ??
        json['additional_image_url'] ??
        json['logo_url'] ??
        json['player_avatar'] ??
        json['team_logo_url'],
  );
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

List<SearchResultAction> _readActions(
  Map<String, dynamic> json,
  String groupKey,
) {
  return switch (groupKey) {
    'heroes' => _heroActions(json),
    'skins' => _singleAction(
      label: 'Gallery',
      url: _idPath('/skin-gallery', json['id'] ?? json['skin_id']),
    ),
    'equips' => _singleAction(
      label: 'Equip Rank',
      url: _equipStatsPath(json['equip_id'] ?? json['id']),
    ),
    'teams' => _singleAction(
      label: 'Team',
      url: _idPath('/esports/teams', json['id'] ?? json['team_id']),
    ),
    'pro_players' => _singleAction(
      label: 'Player',
      url: _idPath(
        '/esports/players',
        json['player_id'] ?? json['id'],
        encode: true,
      ),
    ),
    _ => const [],
  };
}

List<SearchResultAction> _heroActions(Map<String, dynamic> json) {
  final heroId = _readString(json['id'] ?? json['hero_id']);
  if (heroId.isEmpty) {
    return const [];
  }

  final heroName = _readString(
    json['name'] ?? json['heroName'] ?? json['hero_name'],
  );
  return [
    SearchResultAction(label: 'Atlas', url: '/hero-gallery/$heroId'),
    SearchResultAction(label: 'Trend', url: '/trends?hero_id=$heroId'),
    const SearchResultAction(label: 'Tier', url: '/stats?entry=tier_rank'),
    const SearchResultAction(label: 'Power', url: '/stats?entry=power_rank'),
    SearchResultAction(
      label: 'Build Sim',
      url: '/tools/build-sim?hero_id=$heroId',
    ),
    if (heroName.isNotEmpty)
      SearchResultAction(
        label: 'Leaks',
        url: '/community/leaks?q=${Uri.encodeComponent(heroName)}',
      ),
  ];
}

List<SearchResultAction> _singleAction({
  required String label,
  required String url,
}) {
  if (url.isEmpty) {
    return const [];
  }
  return [SearchResultAction(label: label, url: url)];
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
