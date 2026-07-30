import 'package:flutter/material.dart';
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

    router.go('/about#community');
    await tester.pumpAndSettle();
    expect(find.text('Community channel focus'), findsOneWidget);
    expect(find.text('Open Community'), findsOneWidget);

    router.go('/faq');
    await tester.pumpAndSettle();
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Where does hero data come from?'), findsOneWidget);
    expect(
      find.text('Where does the hero data and win rate statistics come from?'),
      findsOneWidget,
    );
    expect(
      find.text("Why isn't my favorite hero appearing in T0 or T1?"),
      findsOneWidget,
    );
    expect(
      find.text('Is the BP Simulator synced with the actual game?'),
      findsOneWidget,
    );
    expect(find.text('How does the AI Prompt Library work?'), findsOneWidget);
    expect(
      find.text('Can I use the builds provided here in pro tournaments?'),
      findsOneWidget,
    );
    expect(
      find.text('Is HOK Helper an official product of Level Infinite?'),
      findsOneWidget,
    );
    expect(
      find.text('How can I report a bug or incorrect data?'),
      findsOneWidget,
    );
    expect(find.text('Still have questions?'), findsOneWidget);
    expect(find.text('Contact Support'), findsOneWidget);
    expect(find.text('Join Community'), findsOneWidget);

    router.go('/privacy');
    await tester.pumpAndSettle();
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Effective July 31, 2026.'), findsOneWidget);
    expect(find.text('1. Information we collect'), findsOneWidget);
    expect(find.text('2. How we use information'), findsOneWidget);
    expect(find.text('3. Public content and community safety'), findsOneWidget);
    expect(find.text('4. Service providers and disclosures'), findsOneWidget);
    expect(find.text('6. Your choices and rights'), findsOneWidget);
    expect(
      find.text('Delete your HOK Helper account and associated data'),
      findsOneWidget,
    );

    router.go('/terms');
    await tester.pumpAndSettle();
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Effective July 31, 2026.'), findsOneWidget);
    expect(find.text('1. Acceptance and eligibility'), findsOneWidget);
    expect(find.text('2. Acceptable use'), findsOneWidget);
    expect(find.text('3. User-generated content'), findsOneWidget);
    expect(find.text('6. Digital features and store billing'), findsOneWidget);

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
    await tester.ensureVisible(find.text('Privacy Policy').first);
    await tester.tap(find.text('Privacy Policy').first);
    await tester.pumpAndSettle();
    expect(find.text('1. Information we collect'), findsOneWidget);
  });

  testWidgets('info center exposes hokx footer portal directory', (
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

    router.go('/content/info');
    await tester.pumpAndSettle();

    final mainScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Portal Directory'),
      240,
      scrollable: mainScroll,
    );

    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('Hero Gallery'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Hero Tier List'), findsOneWidget);
    expect(find.text('Community'), findsWidgets);
    expect(find.text('Community Leaks'), findsOneWidget);
    expect(find.text('Tools'), findsWidgets);
    expect(find.text('BP Simulator'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('About Us'), findsOneWidget);
    expect(find.text('Links'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, '/tools/stats');
  });
}
