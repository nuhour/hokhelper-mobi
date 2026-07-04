import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/curiosity/data/curiosity_repository.dart';
import 'package:hok_helper_mobile/src/features/curiosity/domain/curiosity.dart';
import 'package:hok_helper_mobile/src/features/curiosity/presentation/curiosity_lab_screen.dart';

class _FakeRepository extends CuriosityRepository {
  _FakeRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  String? askedQuery;
  String? queriedVerb;

  @override
  Future<CuriosityAskAnswer> askQuestion({
    required String query,
    required int regionId,
    required String lang,
  }) async {
    askedQuery = query;
    return const CuriosityAskAnswer(
      queryId: 7,
      query: 'Can Kongming dash through walls?',
      matched: true,
      answer: 'Yes, if the target point is valid.',
      result: 'yes',
      resultLabel: CuriosityLocalizedLabel(zh: '可以', en: 'Yes', id: 'Ya'),
      summary: 'Kongming can cross many thin walls.',
      reasoning: 'Verified submissions show repeatable wall crossing.',
      conditions: [
        CuriosityCondition(id: 'thin-wall', text: 'Works on thin walls.'),
      ],
      evidence: [
        CuriosityEvidence(
          id: 'video-1',
          title: 'Replay evidence',
          sourceLabel: 'Verified',
          url: 'https://example.test/replay.mp4',
        ),
      ],
      confidenceScore: 86,
      confidenceLevel: 'high',
      relatedQuestions: ['Can the dash dodge projectiles?'],
      allowSubmission: true,
      caseId: 88,
    );
  }

  @override
  Future<CuriosityOptionResult> searchOptions({
    required String query,
    required int regionId,
    int limit = 18,
  }) async {
    return const CuriosityOptionResult(
      rows: [
        CuriosityEntity(
          key: 'hero:199:skill:2',
          name: 'Dimensional Shift',
          type: 'hero_skill',
          heroName: 'Kongming',
          description: 'Dash through terrain.',
        ),
        CuriosityEntity(
          key: 'map:wall',
          name: 'Terrain wall',
          type: 'map_object',
          description: 'A map collision edge.',
        ),
      ],
      verbs: [
        CuriosityVerb(key: 'cross', zh: '穿过', en: 'cross', id: 'melewati'),
      ],
    );
  }

  @override
  Future<CuriosityCaseResult> queryCase({
    required CuriosityEntity source,
    required CuriosityEntity target,
    required String verb,
    required int regionId,
  }) async {
    queriedVerb = verb;
    return CuriosityCaseResult(
      id: 88,
      source: source,
      target: target,
      verb: const CuriosityVerb(
        key: 'cross',
        zh: '穿过',
        en: 'cross',
        id: 'melewati',
      ),
      result: 'yes',
      resultLabel: const CuriosityLocalizedLabel(zh: '可以', en: 'Yes', id: 'Ya'),
      verdictText: 'Can cross walls.',
      reasoning: 'The dash checks terrain after the cast point.',
      confidenceScore: 86,
      dataSource: 'verified_submission',
      videos: const [
        CuriosityVideo(
          id: '1',
          videoUrl: 'https://example.test/replay.mp4',
          experimenterName: 'lab',
          note: 'Training mode replay',
          isPrimary: true,
        ),
      ],
      allowSubmission: true,
    );
  }
}

void main() {
  testWidgets('asks a question and renders curiosity answer evidence', (
    tester,
  ) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curiosityRepositoryProvider.overrideWithValue(repository),
          curiosityOptionsProvider.overrideWith((ref) async {
            return repository.searchOptions(query: '', regionId: 1);
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: CuriosityLabScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Curiosity Lab'), findsOneWidget);
    expect(find.text('HOK Curiosity Lab'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'Can Kongming dash through walls?',
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();

    expect(repository.askedQuery, 'Can Kongming dash through walls?');
    expect(find.text('Conclusion'), findsWidgets);
    expect(find.text('Yes'), findsWidgets);
    expect(find.text('Yes, if the target point is valid.'), findsOneWidget);
    expect(find.text('Replay evidence'), findsOneWidget);
    expect(find.text('Works on thin walls.'), findsOneWidget);
  });

  testWidgets('runs an advanced interaction experiment', (tester) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curiosityRepositoryProvider.overrideWithValue(repository),
          curiosityOptionsProvider.overrideWith((ref) async {
            return repository.searchOptions(query: '', regionId: 1);
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: CuriosityLabScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Advanced Mode'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ChoiceChip, 'Dimensional Shift').first,
    );
    final scrollable = find.byType(Scrollable).first;
    final targetChip = find.widgetWithText(ChoiceChip, 'Terrain wall').last;
    await tester.scrollUntilVisible(targetChip, 120, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(targetChip);
    final runButton = find.text('Run Experiment');
    await tester.scrollUntilVisible(runButton, 120, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(runButton);
    await tester.pumpAndSettle();

    expect(repository.queriedVerb, 'cross');
    expect(
      find.text('The dash checks terrain after the cast point.'),
      findsOneWidget,
    );
    expect(find.text('Training mode replay'), findsOneWidget);
    expect(find.text('Submit Correction Video'), findsOneWidget);
  });
}
