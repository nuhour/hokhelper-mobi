class TopicArticleSummary {
  const TopicArticleSummary({
    required this.id,
    required this.slug,
    required this.topicKey,
    required this.locale,
    required this.title,
    required this.excerpt,
    required this.seoDescription,
    required this.coverImageUrl,
    required this.tags,
    required this.sortOrder,
    required this.publishedAt,
    required this.updatedAt,
  });

  final int id;
  final String slug;
  final String topicKey;
  final String locale;
  final String title;
  final String excerpt;
  final String seoDescription;
  final String coverImageUrl;
  final List<String> tags;
  final int? sortOrder;
  final String publishedAt;
  final String updatedAt;

  factory TopicArticleSummary.fromJson(Object? value) {
    final json = _readMap(value);
    return TopicArticleSummary(
      id: _readInt(json['id']),
      slug: _readString(json['slug']),
      topicKey: _readString(json['topic_key']),
      locale: _readString(json['locale']),
      title: _readString(json['title'], fallback: 'Topic Article'),
      excerpt: _readString(json['excerpt']),
      seoDescription: _readString(json['seo_description']),
      coverImageUrl: _readString(json['cover_image_url']),
      tags: _readStringList(json['tags']),
      sortOrder: _readNullableInt(json['sort_order']),
      publishedAt: _readString(json['published_at']),
      updatedAt: _readString(json['updated_at']),
    );
  }
}

class TopicArticleDetail extends TopicArticleSummary {
  const TopicArticleDetail({
    required super.id,
    required super.slug,
    required super.topicKey,
    required super.locale,
    required super.title,
    required super.excerpt,
    required this.content,
    required this.seoTitle,
    required super.seoDescription,
    required super.coverImageUrl,
    required super.tags,
    required this.availableLocales,
    required super.publishedAt,
    required super.updatedAt,
  }) : super(sortOrder: null);

  final String content;
  final String seoTitle;
  final List<String> availableLocales;

  factory TopicArticleDetail.fromJson(Object? value) {
    final json = _readMap(value);
    return TopicArticleDetail(
      id: _readInt(json['id']),
      slug: _readString(json['slug']),
      topicKey: _readString(json['topic_key']),
      locale: _readString(json['locale']),
      title: _readString(json['title'], fallback: 'Topic Article'),
      excerpt: _readString(json['excerpt']),
      content: _readString(json['content']),
      seoTitle: _readString(json['seo_title']),
      seoDescription: _readString(json['seo_description']),
      coverImageUrl: _readString(json['cover_image_url']),
      tags: _readStringList(json['tags']),
      availableLocales: _readStringList(json['available_locales']),
      publishedAt: _readString(json['published_at']),
      updatedAt: _readString(json['updated_at']),
    );
  }
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

int _readInt(Object? value) => _readNullableInt(value) ?? 0;

int? _readNullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

String _readString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const [];
}
