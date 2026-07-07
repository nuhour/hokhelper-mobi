import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/activity/data/event_assistance_repository.dart';
import 'package:hok_helper_mobile/src/features/activity/domain/event_assistance_record.dart';
import 'package:hok_helper_mobile/src/features/activity/presentation/event_assistance_screen.dart';

class _FakeRepository extends EventAssistanceRepository {
  _FakeRepository({this.throwOnSubmit = false})
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  final bool throwOnSubmit;
  String? submittedText;
  int? submittedRegionId;
  String? reportedRecordId;

  @override
  Future<EventAssistanceRecord> submitText({
    required String text,
    required int regionId,
  }) async {
    if (throwOnSubmit) {
      throw StateError('submit failed');
    }
    submittedText = text;
    submittedRegionId = regionId;
    return EventAssistanceRecord(
      id: '78',
      regionId: regionId,
      content: text,
      eventTime: '2026-07-04T09:00:00Z',
      isReported: false,
      rawText: text,
      sharedBy: 'me',
      createdAt: '2026-07-04T09:00:00Z',
      updatedAt: '2026-07-04T09:00:00Z',
    );
  }

  @override
  Future<void> reportRecord(String recordId) async {
    reportedRecordId = recordId;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('renders event assistance records and submits text', (
    tester,
  ) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventAssistanceRepositoryProvider.overrideWithValue(repository),
          eventAssistanceRecordsProvider.overrideWith((ref) async {
            return const [
              EventAssistanceRecord(
                id: '77',
                regionId: 1,
                content: 'Need one player for Friday event team.',
                eventTime: '2026-07-03T12:00:00Z',
                isReported: false,
                rawText: 'Need one player for Friday event team.',
                sharedBy: 'captain',
                createdAt: '2026-07-03T12:00:00Z',
                updatedAt: '2026-07-03T12:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EventAssistanceScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Event Assistance'), findsOneWidget);
    expect(find.text('Need one player for Friday event team.'), findsOneWidget);
    expect(find.text('captain'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.text('Share Text'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Join my activity code ABCD.',
    );
    final submitButton = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repository.submittedText, 'Join my activity code ABCD.');
    expect(repository.submittedRegionId, 1);
  });

  testWidgets('cancels the share sheet without publishing', (tester) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventAssistanceRepositoryProvider.overrideWithValue(repository),
          eventAssistanceRecordsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: EventAssistanceScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share Text'));
    await tester.pumpAndSettle();
    expect(find.text('Share Assistance Text'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Share Assistance Text'), findsNothing);
    expect(repository.submittedText, isNull);
  });

  testWidgets('keeps share sheet open and shows feedback on submit failure', (
    tester,
  ) async {
    final repository = _FakeRepository(throwOnSubmit: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventAssistanceRepositoryProvider.overrideWithValue(repository),
          eventAssistanceRecordsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: EventAssistanceScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share Text'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Join failed activity.');
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Share Assistance Text'), findsOneWidget);
    expect(find.text('Failed to submit assistance text'), findsOneWidget);
  });

  testWidgets('copies and reports event assistance records', (tester) async {
    final repository = _FakeRepository();
    MethodCall? clipboardCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCall = call;
          }
          return null;
        });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventAssistanceRepositoryProvider.overrideWithValue(repository),
          eventAssistanceRecordsProvider.overrideWith((ref) async {
            return const [
              EventAssistanceRecord(
                id: '77',
                regionId: 1,
                content: 'Need one player for Friday event team.',
                eventTime: '2026-07-03T12:00:00Z',
                isReported: false,
                rawText: 'Need one player for Friday event team.',
                sharedBy: 'captain',
                createdAt: '2026-07-03T12:00:00Z',
                updatedAt: '2026-07-03T12:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EventAssistanceScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Copy'));
    await tester.pumpAndSettle();

    expect(clipboardCall?.arguments, {
      'text': 'Need one player for Friday event team.',
    });
    expect(find.text('Copied to clipboard'), findsOneWidget);

    await tester.tap(find.byTooltip('Report'));
    await tester.pumpAndSettle();

    expect(repository.reportedRecordId, '77');
    expect(find.text('Reported'), findsOneWidget);
    expect(find.text('Record reported'), findsOneWidget);
  });

  testWidgets('renders event times as relative labels like the hokx portal', (
    tester,
  ) async {
    final recentTime = DateTime.now()
        .subtract(const Duration(hours: 2, minutes: 5))
        .toUtc()
        .toIso8601String();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventAssistanceRecordsProvider.overrideWith((ref) async {
            return [
              EventAssistanceRecord(
                id: '88',
                regionId: 1,
                content: 'Need help finishing the weekly task.',
                eventTime: recentTime,
                isReported: false,
                rawText: 'Need help finishing the weekly task.',
                sharedBy: 'teammate',
                createdAt: recentTime,
                updatedAt: recentTime,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EventAssistanceScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 hr ago'), findsOneWidget);
    expect(find.text(recentTime), findsNothing);
  });
}
