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

  Future<void> applyFriendLink({
    required String name,
    required String url,
    String description = '',
  }) async {
    final normalizedUrl = _normalizeUrl(url);
    final body = <String, String>{'name': name.trim(), 'url': normalizedUrl};
    final trimmedDescription = description.trim();
    if (trimmedDescription.isNotEmpty) {
      body['description'] = trimmedDescription;
    }

    await apiClient.postJson('/friendlink/apply', body: body);
  }
}

String _normalizeUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith(RegExp('https?://', caseSensitive: false))) {
    return trimmed;
  }
  return 'https://$trimmed';
}
