import '../../../core/network/api_client.dart';
import '../domain/topic_article.dart';

class TopicRepository {
  const TopicRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<TopicArticleSummary>> loadArticles({
    required String topicKey,
    required String locale,
    int limit = 12,
  }) async {
    final json = await apiClient.getJson(
      '/topic/articles',
      query: {'topic_key': topicKey, 'locale': locale, 'limit': limit},
    );
    final rows = _readRows(json);
    return rows.map(TopicArticleSummary.fromJson).toList(growable: false);
  }

  Future<TopicArticleDetail> loadArticle({
    required String slug,
    required String locale,
  }) async {
    final json = await apiClient.getJson(
      '/topic/article',
      query: {'slug': slug, 'locale': locale},
    );
    return TopicArticleDetail.fromJson(_readResult(json));
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map && result['rows'] is List) {
      return List<Object?>.from(result['rows'] as List);
    }
    if (json['rows'] is List) {
      return List<Object?>.from(json['rows'] as List);
    }
    return const [];
  }

  Object? _readResult(Map<String, dynamic> json) {
    return json['result'] ?? json['data'] ?? json;
  }
}
