import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/activity/presentation/event_assistance_screen.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';
import 'package:hok_helper_mobile/src/features/content/domain/skin_detail.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/skin_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/hero_ranking_screen.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/stats_dashboard.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/hero_trends_screen.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/stats_screen.dart';

void main() {
  testWidgets('web portal paths redirect to mobile route equivalents', (
    tester,
  ) async {
    final aliases =
        <String, ({String path, String? tab, String? entry, String? equipId})>{
          '/hero-gallery': (
            path: '/heroes',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/hero-gallery?hero_id=101': (
            path: '/heroes/101',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/skin-gallery?skin_id=1001': (
            path: '/skin-gallery/1001',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/community': (
            path: '/content/community',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/community?view=my': (
            path: '/content/community',
            tab: 'my',
            entry: null,
            equipId: null,
          ),
          '/community/leaks': (
            path: '/content/community',
            tab: 'leaks',
            entry: null,
            equipId: null,
          ),
          '/leaks': (
            path: '/content/community',
            tab: 'leaks',
            entry: null,
            equipId: null,
          ),
          '/skin-leaks': (
            path: '/content/community',
            tab: 'leaks',
            entry: null,
            equipId: null,
          ),
          '/event-assistance': (
            path: '/content/event-assistance',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/patch-notes': (
            path: '/content/patch-notes',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/versions': (
            path: '/content/patch-notes',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/stats': (
            path: '/tools/stats',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/stats?entry=hero_trend': (
            path: '/trends',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/stats?entry=equip_rank&equip_id=88': (
            path: '/tools/stats',
            tab: null,
            entry: 'equip_rank',
            equipId: '88',
          ),
          '/builds': (
            path: '/tools/builds',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/build-sim?hero_id=101&scheme=22': (
            path: '/tools/build-sim',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/bp-simulator': (
            path: '/tools/bp-simulator',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/rankings': (
            path: '/tools/rankings',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/game-assistant': (
            path: '/tools/game-assistant',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/rank-fortune': (
            path: '/tools/rank-fortune',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/curiosity-lab': (
            path: '/tools/curiosity-lab',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/team-builder': (
            path: '/tools/team-builder',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/prompts?tab=favorites': (
            path: '/tools/prompts',
            tab: 'favorites',
            entry: null,
            equipId: null,
          ),
          '/en/hero-gallery?hero_id=101': (
            path: '/heroes/101',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/zh/tools/build-sim?hero_id=101&scheme=22': (
            path: '/tools/build-sim',
            tab: null,
            entry: null,
            equipId: null,
          ),
          '/id/community/leaks': (
            path: '/content/community',
            tab: 'leaks',
            entry: null,
            equipId: null,
          ),
          '/en/prompts?tab=favorites': (
            path: '/tools/prompts',
            tab: 'favorites',
            entry: null,
            equipId: null,
          ),
        };

    for (final entry in aliases.entries) {
      final router = createAppRouter()..go(entry.key);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heroGalleryProvider.overrideWith((ref) async => const []),
            selectedRegionHeroDetailProvider.overrideWith(
              (ref, heroId) async => {'id': heroId},
            ),
            skinGalleryProvider.overrideWith((ref) async => const []),
            skinDetailProvider(1001).overrideWith(
              (ref) async => const SkinDetail(
                id: 1001,
                title: 'Crimson Hunter',
                heroName: 'Lam',
                portraitUrl: '',
                landscapeUrl: '',
                seriesName: 'Hunter Series',
                regionName: 'Global',
                rating: 4.5,
                ratingCount: 12,
                linkUrl: '',
              ),
            ),
            communityPostsProvider.overrideWith((ref) async => const []),
            leakPostsProvider.overrideWith((ref) async => const []),
            eventAssistanceRecordsProvider.overrideWith(
              (ref) async => const [],
            ),
            patchNotesProvider.overrideWith((ref) async => const []),
            statsDashboardProvider.overrideWith(
              (ref) async => const StatsDashboard(),
            ),
            heroTrendsProvider.overrideWith((ref) async => const []),
            heroRankingProvider.overrideWith((ref) async => const []),
            playerRankingProvider.overrideWith((ref) async => const []),
            equipRankingProvider.overrideWith((ref) async => const []),
            tierRankingProvider.overrideWith((ref) async => const []),
          ],
          child: HokHelperApp(router: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        router.routeInformationProvider.value.uri.path,
        entry.value.path,
        reason: '${entry.key} should open ${entry.value.path}',
      );
      expect(
        router.routeInformationProvider.value.uri.queryParameters['tab'],
        entry.value.tab,
        reason: '${entry.key} should preserve the mobile tab target',
      );
      expect(
        router.routeInformationProvider.value.uri.queryParameters['entry'],
        entry.value.entry,
        reason: '${entry.key} should preserve the stats entry target',
      );
      expect(
        router.routeInformationProvider.value.uri.queryParameters['equip_id'],
        entry.value.equipId,
        reason: '${entry.key} should preserve the focused equipment target',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
