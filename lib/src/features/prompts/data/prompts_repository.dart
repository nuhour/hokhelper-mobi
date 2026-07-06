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

  Future<PromptLikeResult> toggleLike(String promptId) async {
    final json = await apiClient.postJson('/prompt/$promptId/like', body: {});
    final result = json['result'];
    final map = result is Map ? result : const <String, Object?>{};
    return PromptLikeResult.fromJson(map);
  }

  Future<PromptSummary> createPrompt(PromptDraft draft) async {
    final json = await apiClient.postJson('/prompt', body: draft.toJson());
    final result = json['result'];
    final map = result is Map ? result : json;
    final prompt = map['prompt'];
    return PromptSummary.fromJson(prompt ?? map);
  }
}

class PromptDraft {
  const PromptDraft({
    required this.title,
    required this.content,
    required this.tags,
    required this.isPublic,
    this.language = 'en',
    this.sourceImageUrl = '',
    this.effectImageUrl = '',
  });

  final String title;
  final String content;
  final List<String> tags;
  final bool isPublic;
  final String language;
  final String sourceImageUrl;
  final String effectImageUrl;

  Map<String, Object?> toJson() {
    final normalizedTags = <String>{
      ...tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty),
    };
    final lang = language.trim();
    if (lang.isNotEmpty) {
      normalizedTags.add('Lang:$lang');
    }
    return {
      'title': title.trim(),
      'content': content.trim(),
      'tags': normalizedTags.toList(growable: false),
      'is_public': isPublic,
      'source_image_url': sourceImageUrl.trim(),
      'effect_image_url': effectImageUrl.trim(),
      'language': lang,
    };
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

class PromptLikeResult {
  const PromptLikeResult({required this.isLiked, required this.likeCount});

  final bool isLiked;
  final int likeCount;

  factory PromptLikeResult.fromJson(Map<dynamic, dynamic> json) {
    return PromptLikeResult(
      isLiked: _readBool(json['is_liked']),
      likeCount: _readInt(json['likes'] ?? json['like_count']),
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
