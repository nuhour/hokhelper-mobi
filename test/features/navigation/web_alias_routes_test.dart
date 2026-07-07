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
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/public_profile_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/hero_ranking_screen.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/stats_dashboard.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/hero_trends_screen.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/stats_screen.dart';

void main() {
  testWidgets('web portal paths redirect to mobile route equivalents', (
    tester,
  ) async {
    final aliases =
        <
          String,
          ({
            String path,
            String? tab,
            String? entry,
            String? equipId,
            String? postId,
            String? userId,
          })
        >{
          '/hero-gallery': (
            path: '/heroes',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/hero-gallery?hero_id=101': (
            path: '/heroes/101',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/skin-gallery?skin_id=1001': (
            path: '/skin-gallery/1001',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/community': (
            path: '/content/community',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/community?view=my': (
            path: '/content/community',
            tab: 'my',
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/community/leaks': (
            path: '/content/community',
            tab: 'leaks',
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/leaks': (
            path: '/content/community',
            tab: 'leaks',
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/skin-leaks': (
            path: '/content/community',
            tab: 'leaks',
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/event-assistance': (
            path: '/content/event-assistance',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/patch-notes': (
            path: '/content/patch-notes',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/patch-notes?post_id=31': (
            path: '/content/patch-notes',
            tab: null,
            entry: null,
            equipId: null,
            postId: '31',
            userId: null,
          ),
          '/versions': (
            path: '/content/patch-notes',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/profile?user_id=42&tab=followers': (
            path: '/profile/42',
            tab: 'followers',
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/stats': (
            path: '/tools/stats',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/stats?entry=home_core': (
            path: '/tools/stats',
            tab: null,
            entry: 'home_core',
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/stats?entry=hero_trend': (
            path: '/trends',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/stats?entry=equip_rank&equip_id=88': (
            path: '/tools/stats',
            tab: null,
            entry: 'equip_rank',
            equipId: '88',
            postId: null,
            userId: null,
          ),
          '/builds': (
            path: '/tools/builds',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/build-sim?hero_id=101&scheme=22': (
            path: '/tools/build-sim',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/bp-simulator': (
            path: '/tools/bp-simulator',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/rankings': (
            path: '/tools/rankings',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/game-assistant': (
            path: '/tools/game-assistant',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/rank-fortune': (
            path: '/tools/rank-fortune',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/curiosity-lab': (
            path: '/tools/curiosity-lab',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/team-builder': (
            path: '/tools/team-builder',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/prompts?tab=favorites': (
            path: '/tools/prompts',
            tab: 'favorites',
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/en/hero-gallery?hero_id=101': (
            path: '/heroes/101',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/zh/tools/build-sim?hero_id=101&scheme=22': (
            path: '/tools/build-sim',
            tab: null,
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/id/community/leaks': (
            path: '/content/community',
            tab: 'leaks',
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
          ),
          '/en/prompts?tab=favorites': (
            path: '/tools/prompts',
            tab: 'favorites',
            entry: null,
            equipId: null,
            postId: null,
            userId: null,
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
            publicUserProfileProvider(42).overrideWith((ref) async {
              return const UserProfile(
                id: 42,
                username: 'lam',
                displayName: 'Lam',
                email: 'lam@example.test',
                avatar: '',
                level: 7,
                points: 1200,
                xpTotal: 1400,
                xpCurrentLevel: 260,
                xpToNextLevel: 740,
                levelProgress: 26,
                levelCap: false,
                bio: 'Jungle main',
                socialLinks: {},
                stats: ProfileStats(
                  posts: 3,
                  following: 4,
                  followers: 5,
                  likes: 6,
                ),
                isFollowing: false,
                isLiked: false,
                isSelf: false,
              );
            }),
            statsDashboardProvider.overrideWith(
              (ref, entry) async => const StatsDashboard(),
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
      expect(
        router.routeInformationProvider.value.uri.queryParameters['post_id'],
        entry.value.postId,
        reason: '${entry.key} should preserve the focused portal post target',
      );
      expect(
        router.routeInformationProvider.value.uri.queryParameters['user_id'],
        entry.value.userId,
        reason: '${entry.key} should move focused profile users into the path',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
