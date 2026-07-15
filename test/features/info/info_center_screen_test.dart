import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/info/data/info_repository.dart';
import 'package:hok_helper_mobile/src/features/info/domain/friend_link_summary.dart';
import 'package:hok_helper_mobile/src/features/info/presentation/info_center_screen.dart';

class _FakeInfoRepository extends InfoRepository {
  _FakeInfoRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  Object? submittedBody;
  var loadCount = 0;

  @override
  Future<List<FriendLinkSummary>> loadFriendLinks() async {
    loadCount += 1;
    return const [
      FriendLinkSummary(
        id: 7,
        name: 'HOK Lab',
        url: 'https://hoklab.example',
        description: 'Draft tools and hero research.',
        logoUrl: '',
      ),
    ];
  }

  @override
  Future<void> applyFriendLink({
    required String name,
    required String url,
    String description = '',
  }) async {
    submittedBody = {'name': name, 'url': url, 'description': description};
  }
}

void main() {
  testWidgets('renders info center static pages and friend links', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendLinksProvider.overrideWith((ref) async {
            return const [
              FriendLinkSummary(
                id: 7,
                name: 'HOK Lab',
                url: 'https://hoklab.example',
                description: 'Draft tools and hero research.',
                logoUrl: '',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: InfoCenterScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Info Center'), findsOneWidget);
    expect(find.text('About HOK Helper'), findsOneWidget);
    expect(find.text('FAQ'), findsWidgets);
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('Terms of Service'), findsWidgets);
    expect(find.text('Friend Links'), findsOneWidget);
    expect(find.text('HOK Lab'), findsOneWidget);
    expect(find.text('https://hoklab.example'), findsOneWidget);
  });

  testWidgets('submits a friend link application from the mobile links page', (
    tester,
  ) async {
    final repository = _FakeInfoRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          infoRepositoryProvider.overrideWithValue(repository),
          friendLinksProvider.overrideWith((ref) {
            return ref.watch(infoRepositoryProvider).loadFriendLinks();
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: InfoCenterScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Apply for link'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Apply for link'));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Site name'), 'New Lab');
    await tester.enterText(
      find.bySemanticsLabel('Portal URL'),
      'newlab.example',
    );
    await tester.enterText(
      find.bySemanticsLabel('Brief description'),
      'Meta tools.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send application'));
    await tester.pumpAndSettle();

    expect(repository.submittedBody, {
      'name': 'New Lab',
      'url': 'https://newlab.example',
      'description': 'Meta tools.',
    });
    expect(find.text('Friend link application submitted'), findsOneWidget);
  });
}
