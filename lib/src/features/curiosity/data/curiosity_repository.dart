import '../../../core/network/api_client.dart';
import '../domain/curiosity.dart';

class CuriosityRepository {
  const CuriosityRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<CuriosityAskAnswer> askQuestion({
    required String query,
    required int regionId,
    required String lang,
  }) async {
    final json = await apiClient.postJson(
      '/curiosity/ask',
      body: {
        'query': query,
        'region_id': regionId,
        'lang': lang,
        'include_conditions': true,
      },
    );
    return CuriosityAskAnswer.fromJson(json['result'] ?? json);
  }

  Future<CuriosityOptionResult> searchOptions({
    required String query,
    required int regionId,
    int limit = 18,
  }) async {
    final json = await apiClient.getJson(
      '/curiosity/options',
      query: {'q': query, 'region_id': regionId, 'limit': limit},
    );
    return CuriosityOptionResult.fromJson(json['result'] ?? json);
  }

  Future<CuriosityCaseResult> queryCase({
    required CuriosityEntity source,
    required CuriosityEntity target,
    required String verb,
    required int regionId,
  }) async {
    final json = await apiClient.postJson(
      '/curiosity/query',
      body: {
        'source': source.toJson(),
        'target': target.toJson(),
        'verb': verb,
        'region_id': regionId,
      },
    );
    return CuriosityCaseResult.fromJson(json['result'] ?? json);
  }
}
