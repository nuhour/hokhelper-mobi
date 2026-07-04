import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/curiosity/data/curiosity_repository.dart';
import 'package:hok_helper_mobile/src/features/curiosity/domain/curiosity.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  String? getPath;
  Map<String, dynamic>? getQuery;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getPath = path;
    getQuery = query;
    return const {
      'success': true,
      'result': {
        'rows': [
          {
            'key': 'hero:199:skill:2',
            'name': 'Dimensional Shift',
            'type': 'hero_skill',
            'hero_id': 199,
            'hero_name': 'Kongming',
            'description': 'Dash through terrain.',
          },
        ],
        'total': 1,
        'verbs': [
          {
            'key': 'cross',
            'label_zh': '穿过',
            'label_en': 'cross',
            'label_id': 'melewati',
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    if (path == '/curiosity/query') {
      return const {
        'success': true,
        'result': {
          'id': 88,
          'source': {
            'key': 'hero:199:skill:2',
            'name': 'Dimensional Shift',
            'type': 'hero_skill',
          },
          'target': {
            'key': 'map:wall',
            'name': 'Terrain wall',
            'type': 'map_object',
          },
          'verb': {'key': 'cross', 'zh': '穿过', 'en': 'cross', 'id': 'melewati'},
          'result': 'yes',
          'result_label': {'zh': '可以', 'en': 'Yes', 'id': 'Ya'},
          'verdict_text': 'Can cross walls.',
          'reasoning': 'The dash checks terrain after the cast point.',
          'confidence_score': 86,
          'data_source': 'verified_submission',
          'videos': [
            {
              'id': 1,
              'video_url': 'https://example.test/replay.mp4',
              'experimenter_name': 'lab',
              'note': 'Training mode replay',
              'is_primary': true,
            },
          ],
          'updated_at': '2026-07-04T09:00:00Z',
          'allow_submission': true,
        },
      };
    }

    return const {
      'success': true,
      'result': {
        'query_id': 7,
        'query': 'Can Kongming dash through walls?',
        'lang': 'en',
        'region_id': 2,
        'matched': true,
        'answer': 'Yes, if the target point is valid.',
        'result': 'yes',
        'result_label': {'zh': '可以', 'en': 'Yes', 'id': 'Ya'},
        'summary': 'Kongming can cross many thin walls.',
        'reasoning': 'Verified submissions show repeatable wall crossing.',
        'conditions': [
          {'id': 'thin-wall', 'text': 'Works on thin walls.'},
        ],
        'evidence': [
          {
            'id': 'video-1',
            'title': 'Replay evidence',
            'source_type': 'verified_submission',
            'source_label': 'Verified',
            'date': '2026-07-04',
            'url': 'https://example.test/replay.mp4',
          },
        ],
        'confidence': {
          'score': 86,
          'level': 'high',
          'primary_source_type': 'verified_submission',
          'formula': {
            'base': 70,
            'evidence_bonus': 12,
            'recency_bonus': 4,
            'conflict_penalty': 0,
          },
        },
        'related_questions': ['Can the dash dodge projectiles?'],
        'allow_submission': true,
        'case_id': 88,
      },
    };
  }
}

void main() {
  test('asks curiosity questions with backend-compatible payload', () async {
    final apiClient = _FakeApiClient();
    final repository = CuriosityRepository(apiClient: apiClient);

    final answer = await repository.askQuestion(
      query: 'Can Kongming dash through walls?',
      regionId: 2,
      lang: 'en',
    );

    expect(apiClient.postPath, '/curiosity/ask');
    expect(apiClient.postBody, {
      'query': 'Can Kongming dash through walls?',
      'region_id': 2,
      'lang': 'en',
      'include_conditions': true,
    });
    expect(answer.answer, 'Yes, if the target point is valid.');
    expect(answer.resultLabel.en, 'Yes');
    expect(answer.evidence.single.title, 'Replay evidence');
  });

  test('loads entity options and verb choices', () async {
    final apiClient = _FakeApiClient();
    final repository = CuriosityRepository(apiClient: apiClient);

    final options = await repository.searchOptions(
      query: 'kongming',
      regionId: 2,
    );

    expect(apiClient.getPath, '/curiosity/options');
    expect(apiClient.getQuery, {'q': 'kongming', 'region_id': 2, 'limit': 18});
    expect(options.rows.single.name, 'Dimensional Shift');
    expect(options.verbs.single.key, 'cross');
  });

  test('queries a curiosity case with source target and verb', () async {
    final apiClient = _FakeApiClient();
    final repository = CuriosityRepository(apiClient: apiClient);

    final result = await repository.queryCase(
      source: const CuriosityEntity(
        key: 'hero:199:skill:2',
        name: 'Dimensional Shift',
        type: 'hero_skill',
      ),
      target: const CuriosityEntity(
        key: 'map:wall',
        name: 'Terrain wall',
        type: 'map_object',
      ),
      verb: 'cross',
      regionId: 2,
    );

    expect(apiClient.postPath, '/curiosity/query');
    expect(apiClient.postBody, {
      'source': {
        'key': 'hero:199:skill:2',
        'name': 'Dimensional Shift',
        'type': 'hero_skill',
        'hero_id': null,
        'hero_name': null,
        'icon_url': null,
        'description': null,
        'video_url': null,
      },
      'target': {
        'key': 'map:wall',
        'name': 'Terrain wall',
        'type': 'map_object',
        'hero_id': null,
        'hero_name': null,
        'icon_url': null,
        'description': null,
        'video_url': null,
      },
      'verb': 'cross',
      'region_id': 2,
    });
    expect(result.resultLabel.en, 'Yes');
    expect(result.videos.single.videoUrl, 'https://example.test/replay.mp4');
  });
}
