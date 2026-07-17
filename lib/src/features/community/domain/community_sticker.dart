class CommunitySticker {
  const CommunitySticker({
    required this.id,
    required this.imageUrl,
    required this.name,
  });

  final String id;
  final String imageUrl;
  final String name;

  factory CommunitySticker.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return CommunitySticker(
      id: (map['id'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      name: (map['hero_name'] ?? map['name'] ?? 'Sticker').toString(),
    );
  }
}
