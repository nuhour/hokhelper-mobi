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
