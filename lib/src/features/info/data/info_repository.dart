import '../../../core/network/api_client.dart';
import '../domain/friend_link_summary.dart';

class InfoRepository {
  const InfoRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<FriendLinkSummary>> loadFriendLinks() async {
    final json = await apiClient.getJson('/friendlink/list');
    final rows = json['rows'];
    if (rows is List) {
      return rows.map(FriendLinkSummary.fromJson).toList(growable: false);
    }

    final data = json['data'];
    if (data is Map && data['rows'] is List) {
      return (data['rows'] as List)
          .map(FriendLinkSummary.fromJson)
          .toList(growable: false);
    }

    final result = json['result'];
    if (result is Map && result['rows'] is List) {
      return (result['rows'] as List)
          .map(FriendLinkSummary.fromJson)
          .toList(growable: false);
    }

    return const [];
  }
}
