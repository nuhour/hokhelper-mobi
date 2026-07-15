class FriendLinkSummary {
  const FriendLinkSummary({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.logoUrl,
  });

  final int id;
  final String name;
  final String url;
  final String description;
  final String logoUrl;

  factory FriendLinkSummary.fromJson(Object? value) {
    final json = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};

    return FriendLinkSummary(
      id: _readInt(json['id']),
      name: _readString(json['name']),
      url: _readString(json['url']),
      description: _readString(json['description']),
      logoUrl: _readString(json['logo']),
    );
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String _readString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}
