import '../../../core/network/api_client.dart';
import '../domain/rank_fortune.dart';

class RankFortuneRepository {
  const RankFortuneRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<RankFortuneHistory> loadHistory({int days = 30}) async {
    final json = await apiClient.getJson(
      '/rank-fortune/history',
      query: {'days': days},
    );
    return RankFortuneHistory.fromJson(json['result'] ?? json);
  }

  Future<RankFortuneDraw> drawToday() async {
    final json = await apiClient.postJson('/rank-fortune/draw', body: {});
    return RankFortuneDraw.fromJson(json['result'] ?? json);
  }
}
