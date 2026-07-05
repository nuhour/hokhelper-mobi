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

  factory SearchResultItem.fromJson(Object? value) {
    final json = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};

    return SearchResultItem(
      id: _readString(json['id'] ?? json['pk']),
      title: _readString(
        json['title'] ?? json['name'] ?? json['heroName'] ?? json['label'],
        fallback: 'Untitled result',
      ),
      subtitle: _readString(
        json['subtitle'] ?? json['description'] ?? json['summary'],
      ),
      url: _readString(json['url'] ?? json['path'] ?? json['href']),
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
        .map(SearchResultItem.fromJson)
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
