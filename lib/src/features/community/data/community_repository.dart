import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/community_post_detail.dart';
import '../domain/community_post_summary.dart';
import '../domain/leak_post_summary.dart';

class CommunityRepository {
  const CommunityRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<CommunityPostSummary>> loadPosts(int regionId) async {
    final json = await apiClient.getJson(
      '/community/posts',
      query: {
        'page': 1,
        'pageSize': 30,
        'sort': 'hot',
        'filterRules': jsonEncode([
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );

    return _readRows(json).map(CommunityPostSummary.fromJson).toList();
  }

  Future<List<LeakPostSummary>> loadLeaks(int regionId) async {
    final json = await apiClient.getJson(
      '/leak/posts',
      query: {
        'page': 1,
        'pageSize': 30,
        'region_id': regionId,
        'category': 'all',
      },
    );

    return _readRows(json).map(LeakPostSummary.fromJson).toList();
  }

  Future<CommunityPostDetail> loadPostDetail(
    String postId, {
    required int regionId,
  }) async {
    final json = await apiClient.getJson(
      '/community/posts/$postId',
      query: {'region_id': regionId},
    );
    final result = json['result'];
    return CommunityPostDetail.fromJson(result);
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];
    final rows = result is Map
        ? result['rows'] ?? result['data']
        : json['rows'] ?? json['data'];
    if (rows is! List) {
      return const [];
    }
    return rows;
  }
}
