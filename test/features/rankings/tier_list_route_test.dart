import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/tier_list_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/hero_ranking_screen.dart';

void main() {
  testWidgets('web tier list route opens the mobile tier tab', (tester) async {
    final router = createAppRouter();
    router.go('/tier-list');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async {
            return const [
              TierListEntry(
                heroId: 42,
                externalHeroId: '199',
                name: 'Lam',
                mainJob: '4',
                tier: 'T0',
                position: 1,
                score: 96.5,
                winRate: 0.55,
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tier'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('T0'), findsOneWidget);
    expect(find.text('Score 96.5'), findsOneWidget);
  });
}
