import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/prompt_summary.dart';

enum PromptListAction {
  explore('explore'),
  myPrompts('myPrompts'),
  favorites('favorites');

  const PromptListAction(this.backendValue);

  final String backendValue;
}

class PromptsRepository {
  const PromptsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PromptSummary>> loadExplorePrompts() {
    return loadPrompts(action: PromptListAction.explore);
  }

  Future<List<PromptSummary>> loadPrompts({
    required PromptListAction action,
  }) async {
    final json = await apiClient.getJson(
      '/prompt',
      query: {
        'action': action.backendValue,
        'page': 1,
        'pageSize': 20,
        'sort': '-hot',
        'order': 'desc',
        'filterRules': jsonEncode([
          {'field': 'is_public', 'op': 'eq', 'value': true},
        ]),
      },
    );
    final result = json['result'];
    final rows = result is Map ? result['prompts'] : json['prompts'];
    if (rows is! List) {
      return const [];
    }

    return rows.map(PromptSummary.fromJson).toList(growable: false);
  }

  Future<PromptFavoriteResult> toggleFavorite(String promptId) async {
    final json = await apiClient.postJson(
      '/prompt/$promptId/favorite',
      body: {},
    );
    final result = json['result'];
    final map = result is Map ? result : const <String, Object?>{};
    return PromptFavoriteResult.fromJson(map);
  }
}

class PromptFavoriteResult {
  const PromptFavoriteResult({
    required this.isFavorited,
    required this.favoriteCount,
  });

  final bool isFavorited;
  final int favoriteCount;

  factory PromptFavoriteResult.fromJson(Map<dynamic, dynamic> json) {
    return PromptFavoriteResult(
      isFavorited: _readBool(json['is_favorited']),
      favoriteCount: _readInt(json['favorites'] ?? json['favorite_count']),
    );
  }
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().toLowerCase() ?? '';
  return text == 'true' || text == '1';
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
