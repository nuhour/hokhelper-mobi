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

enum PromptListSort {
  hot('-hot'),
  latest('-updated_at');

  const PromptListSort(this.backendValue);

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
    String search = '',
    PromptListSort sort = PromptListSort.hot,
  }) async {
    final searchValue = search.trim();
    final json = await apiClient.getJson(
      '/prompt',
      query: {
        'action': action.backendValue,
        'page': 1,
        'pageSize': 30,
        if (searchValue.isNotEmpty) 'search': searchValue,
        'sort': sort.backendValue,
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

  Future<PromptSummary> updatePrompt(String promptId, PromptDraft draft) async {
    final json = await apiClient.postJson(
      '/prompt/$promptId/update',
      body: draft.toJson(),
    );
    final result = json['result'];
    final map = result is Map ? result : json;
    final prompt = map['prompt'];
    return PromptSummary.fromJson(prompt ?? map);
  }

  Future<void> deletePrompt(String promptId) async {
    await apiClient.postJson('/prompt/$promptId/delete', body: {});
  }

  Future<PromptGenerationQuota> loadGenerationQuota() async {
    final json = await apiClient.getJson('/prompt/quota');
    final result = json['result'];
    final map = result is Map ? result : const <String, Object?>{};
    return PromptGenerationQuota.fromJson(map);
  }

  Future<bool> loadGenerationEnabled() async {
    final json = await apiClient.getJson('/prompt/generate/config');
    final result = json['result'];
    final map = result is Map ? result : const <String, Object?>{};
    return _readBool(map['enabled']);
  }

  Future<PromptGenerateResult> generateImages({
    required String promptId,
    int count = 1,
    String? customContent,
  }) async {
    final body = <String, Object?>{
      'prompt_id': promptId,
      'mode': 'text',
      'count': count,
    };
    final content = customContent?.trim();
    if (content != null && content.isNotEmpty) {
      body['custom_content'] = content;
    }
    final json = await apiClient.postJson('/prompt/generate', body: body);
    final result = json['result'];
    final map = result is Map ? result : const <String, Object?>{};
    return PromptGenerateResult.fromJson(map);
  }

  Future<PromptSummary> setPromptImage({
    required String promptId,
    required String imageData,
  }) async {
    final json = await apiClient.postJson(
      '/prompt/$promptId/set-image',
      body: {'image_data': imageData},
    );
    final result = json['result'];
    final map = result is Map ? result : json;
    final prompt = map['prompt'];
    return PromptSummary.fromJson(prompt ?? map);
  }

  Future<PromptRechargeResult> rechargeGenerationQuota({
    required String planId,
    String paymentMethod = 'card',
  }) async {
    final json = await apiClient.postJson(
      '/prompt/recharge',
      body: {'plan_id': planId, 'payment_method': paymentMethod},
    );
    final result = json['result'];
    final map = result is Map ? result : const <String, Object?>{};
    return PromptRechargeResult.fromJson(map);
  }
}

class PromptGenerationQuota {
  const PromptGenerationQuota({required this.used, required this.total});

  final int used;
  final int total;

  int get remaining => (total - used).clamp(0, 1 << 31);

  factory PromptGenerationQuota.fromJson(Map<dynamic, dynamic> json) {
    return PromptGenerationQuota(
      used: _readInt(json['quota_used'] ?? json['used']),
      total: _readInt(json['quota_total'] ?? json['total'], fallback: 5),
    );
  }
}

class PromptGenerateResult {
  const PromptGenerateResult({required this.images, required this.quota});

  final List<String> images;
  final PromptGenerationQuota quota;

  factory PromptGenerateResult.fromJson(Map<dynamic, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages
              .map((image) {
                if (image is Map) {
                  return image['generated'] ?? image['url'] ?? image['image'];
                }
                return image;
              })
              .map((image) => image?.toString() ?? '')
              .where((image) => image.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    return PromptGenerateResult(
      images: images,
      quota: PromptGenerationQuota.fromJson(json),
    );
  }
}

class PromptRechargeResult {
  const PromptRechargeResult({required this.quota, required this.added});

  final PromptGenerationQuota quota;
  final int added;

  factory PromptRechargeResult.fromJson(Map<dynamic, dynamic> json) {
    return PromptRechargeResult(
      quota: PromptGenerationQuota.fromJson(json),
      added: _readInt(json['added']),
    );
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

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
