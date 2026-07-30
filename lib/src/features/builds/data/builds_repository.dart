import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/build_editor_asset.dart';
import '../domain/build_scheme_summary.dart';

enum BuildSchemeSort {
  popular('-hot'),
  latest('-updated_at');

  const BuildSchemeSort(this.backendValue);

  final String backendValue;
}

/// 方案列表的单页结果；`total` 缺失时 [hasMore] 退化为整页启发式判断。
class BuildSchemePage {
  const BuildSchemePage({
    required this.schemes,
    required this.hasMore,
    this.total,
  });

  final List<BuildSchemeSummary> schemes;
  final bool hasMore;
  final int? total;
}

class BuildsRepository {
  const BuildsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<BuildSchemeSummary>> loadPublicSchemes(
    int regionId, {
    BuildSchemeSort sort = BuildSchemeSort.popular,
    int? heroId,
  }) async {
    final page = await loadPublicSchemesPage(
      regionId,
      sort: sort,
      heroId: heroId,
    );
    return page.schemes;
  }

  Future<BuildSchemePage> loadPublicSchemesPage(
    int regionId, {
    BuildSchemeSort sort = BuildSchemeSort.popular,
    int? heroId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final filterRules = [
      {'field': 'region_id', 'op': 'eq', 'value': regionId},
      if (heroId != null && heroId > 0)
        {'field': 'hero__heroId', 'op': 'eq', 'value': heroId},
    ];
    final json = await apiClient.getJson(
      '/build/schemes',
      query: {
        'action': 'explore',
        'page': page,
        'pageSize': pageSize,
        'sort': sort.backendValue,
        'order': 'desc',
        'filterRules': jsonEncode(filterRules),
      },
    );
    return _readSchemePage(json, page: page, pageSize: pageSize);
  }

  Future<List<BuildSchemeSummary>> loadFavoriteSchemes() async {
    final page = await loadFavoriteSchemesPage();
    return page.schemes;
  }

  Future<BuildSchemePage> loadFavoriteSchemesPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await apiClient.postJson(
      '/build/schemes/my-favorites',
      body: {'page': page, 'pageSize': pageSize},
    );
    return _readSchemePage(json, page: page, pageSize: pageSize);
  }

  Future<List<BuildSchemeSummary?>> loadUserHeroSlots({
    required int heroId,
    required int regionId,
  }) async {
    final json = await apiClient.postJson(
      '/build/schemes/user-slots',
      body: {'hero_id': heroId.toString()},
    );
    final slots = <BuildSchemeSummary?>[null, null, null];
    for (final scheme in _readRows(json).map(BuildSchemeSummary.fromJson)) {
      final index = scheme.slotIndex;
      if (index >= 1 && index <= 3) {
        slots[index - 1] = scheme;
      }
    }
    return slots;
  }

  Future<List<BuildEquipSummary>> loadTopEquips(int regionId) async {
    final json = await apiClient.postJson(
      '/build/equips',
      body: {
        'page': 1,
        'pageSize': 100,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
          {'field': 'is_top_equip', 'op': 'eq', 'value': true},
        ],
      },
    );
    return _readRows(
      json,
    ).map(BuildEquipSummary.fromJson).toList(growable: false);
  }

  Future<List<BuildSummonerSkillSummary>> loadSummonerSkills(
    int regionId,
  ) async {
    final json = await apiClient.postJson(
      '/build/summoner-skills',
      body: {
        'page': 1,
        'pageSize': 100,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ],
      },
    );
    return _readRows(
      json,
    ).map(BuildSummonerSkillSummary.fromJson).toList(growable: false);
  }

  Future<List<BuildRuneSummary>> loadRunes(int regionId) async {
    final json = await apiClient.postJson(
      '/build/runes',
      body: {
        'page': 1,
        'pageSize': 1000,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ],
      },
    );
    return _readRows(
      json,
    ).map(BuildRuneSummary.fromJson).toList(growable: false);
  }

  Future<void> saveBuildScheme(BuildSchemeDraft draft) async {
    final schemeId = draft.schemeId;
    final path = schemeId == null
        ? '/build/schemes'
        : '/build/schemes/$schemeId/update';
    await apiClient.postJson(path, body: draft.toJson());
  }

  Future<void> likeBuildScheme(int schemeId) async {
    await apiClient.postJson(
      '/build/schemes/like',
      body: {'scheme_id': schemeId.toString()},
    );
  }

  Future<void> unlikeBuildScheme(int schemeId) async {
    await apiClient.postJson(
      '/build/schemes/unlike',
      body: {'scheme_id': schemeId.toString()},
    );
  }

  Future<void> favoriteBuildScheme(int schemeId) async {
    await apiClient.postJson(
      '/build/schemes/favorite',
      body: {'scheme_id': schemeId.toString()},
    );
  }

  Future<void> unfavoriteBuildScheme(int schemeId) async {
    await apiClient.postJson(
      '/build/schemes/unfavorite',
      body: {'scheme_id': schemeId.toString()},
    );
  }

  Future<void> cloneBuildScheme({
    required int schemeId,
    required int slotIndex,
    String? name,
  }) async {
    await apiClient.postJson(
      '/build/schemes/clone',
      body: {
        'scheme_id': schemeId.toString(),
        'slot_index': slotIndex,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );
  }

  BuildSchemePage _readSchemePage(
    Map<String, dynamic> json, {
    required int page,
    required int pageSize,
  }) {
    final schemes = _readRows(
      json,
    ).map(BuildSchemeSummary.fromJson).toList(growable: false);
    final total = _readTotal(json);
    return BuildSchemePage(
      schemes: schemes,
      total: total,
      hasMore: total != null
          ? page * pageSize < total
          : schemes.length >= pageSize,
    );
  }

  int? _readTotal(Map<String, dynamic> json) {
    final result = json['result'];
    final total = result is Map ? result['total'] : json['total'];
    if (total is num) {
      return total.toInt();
    }
    return null;
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is List) {
      return result;
    }
    if (result is Map) {
      final data = result['data'];
      if (data is List) {
        return data;
      }
      final schemes = result['schemes'];
      if (schemes is List) {
        return schemes;
      }
      final rows = result['rows'];
      if (rows is List) {
        return rows;
      }
      final slots = result['slots'];
      if (slots is List) {
        return slots;
      }
      final equips = result['equips'];
      if (equips is List) {
        return equips;
      }
      final skills = result['skills'];
      if (skills is List) {
        return skills;
      }
      final runes = result['runes'];
      if (runes is List) {
        return runes;
      }
    }
    final data = json['data'];
    if (data is List) {
      return data;
    }
    final schemes = json['schemes'];
    if (schemes is List) {
      return schemes;
    }
    return const [];
  }
}
