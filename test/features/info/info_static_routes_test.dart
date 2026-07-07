import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';
import 'package:hok_helper_mobile/src/features/info/domain/friend_link_summary.dart';
import 'package:hok_helper_mobile/src/features/info/presentation/info_center_screen.dart';

void main() {
  testWidgets('app router exposes hokx static information routes', (
    tester,
  ) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith(
            (ref) async => const HomeStats(
              success: true,
              message: 'Ready',
              result: {'heroes': 128},
            ),
          ),
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
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/about');
    await tester.pumpAndSettle();
    expect(find.text('About HOK Helper'), findsOneWidget);
    expect(find.text('Global Community Intel'), findsOneWidget);
    expect(find.text('Heroes Tracked'), findsOneWidget);
    expect(find.text('Data Accuracy'), findsOneWidget);
    expect(find.text('Update Cycle'), findsOneWidget);
    expect(find.text('Regions'), findsOneWidget);
    expect(find.text('Our Mission'), findsOneWidget);
    expect(find.text('Beginner Friendly'), findsOneWidget);
    expect(find.text('Explore Heroes'), findsOneWidget);
    expect(find.text('Plan Builds'), findsOneWidget);
    expect(find.text('Practice Drafts'), findsOneWidget);
    expect(find.text('Share & Improve'), findsOneWidget);
    expect(find.text('Hero Analytics'), findsOneWidget);
    expect(find.text('Tier Lists'), findsOneWidget);
    expect(find.text('BP Simulator'), findsOneWidget);
    expect(find.text('Build Simulator'), findsOneWidget);
    expect(find.text('AI Prompts'), findsOneWidget);
    expect(find.text('Team Builder'), findsOneWidget);

    router.go('/about?section=community');
    await tester.pumpAndSettle();
    expect(find.text('Community channel focus'), findsOneWidget);
    expect(find.text('Open Community'), findsOneWidget);

    router.go('/faq');
    await tester.pumpAndSettle();
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Where does hero data come from?'), findsOneWidget);

    router.go('/privacy');
    await tester.pumpAndSettle();
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Data use'), findsOneWidget);

    router.go('/terms');
    await tester.pumpAndSettle();
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Community conduct'), findsOneWidget);

    router.go('/links');
    await tester.pumpAndSettle();
    expect(find.text('Friend Links'), findsOneWidget);
    expect(find.text('HOK Lab'), findsOneWidget);

    router.go(
      Uri(
        path: '/external-link',
        queryParameters: {'url': 'https://example.test/event?id=9'},
      ).toString(),
    );
    await tester.pumpAndSettle();
    expect(find.text('External Link'), findsWidgets);
    expect(find.text('https://example.test/event?id=9'), findsOneWidget);
  });

  testWidgets('info center opens each static information page', (tester) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith(
            (ref) async => const HomeStats(
              success: true,
              message: 'Ready',
              result: {'heroes': 128},
            ),
          ),
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
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/content/info');
    await tester.pumpAndSettle();
    await tester.tap(find.text('About HOK Helper'));
    await tester.pumpAndSettle();
    expect(find.text('Global Community Intel'), findsOneWidget);

    router.go('/content/info');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Privacy Policy'));
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.text('Data use'), findsOneWidget);
  });
}
