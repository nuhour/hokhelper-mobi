import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/build_editor_asset.dart';
import '../domain/build_scheme_summary.dart';

class BuildsRepository {
  const BuildsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<BuildSchemeSummary>> loadPublicSchemes(int regionId) async {
    final json = await apiClient.getJson(
      '/build/schemes',
      query: {
        'action': 'explore',
        'page': 1,
        'pageSize': 20,
        'filterRules': jsonEncode([
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );
    return _readRows(
      json,
    ).map(BuildSchemeSummary.fromJson).toList(growable: false);
  }

  Future<List<BuildSchemeSummary?>> loadUserHeroSlots({
    required int heroId,
    required int regionId,
  }) async {
    final json = await apiClient.getJson(
      '/build/schemes',
      query: {
        'action': 'mySchemes',
        'page': 1,
        'pageSize': 3,
        'filterRules': jsonEncode([
          {'field': 'hero__heroId', 'op': 'eq', 'value': heroId},
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
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
        'pageSize': 100,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
          {'field': 'level', 'op': 'eq', 'value': 5},
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

  Future<void> favoriteBuildScheme(int schemeId) async {
    await apiClient.postJson(
      '/build/schemes/favorite',
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
