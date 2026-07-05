import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/activity/presentation/event_assistance_screen.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/hero_ranking_screen.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/stats_dashboard.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/stats_screen.dart';

void main() {
  testWidgets('web portal paths redirect to mobile route equivalents', (
    tester,
  ) async {
    final aliases = <String, String>{
      '/hero-gallery': '/heroes',
      '/community': '/content/community',
      '/community/leaks': '/content/community',
      '/event-assistance': '/content/event-assistance',
      '/patch-notes': '/content/patch-notes',
      '/versions': '/content/patch-notes',
      '/stats': '/tools/stats',
      '/tier-list': '/tools/rankings',
    };

    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async => const []),
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsProvider.overrideWith((ref) async => const []),
          eventAssistanceRecordsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async => const []),
          statsDashboardProvider.overrideWith(
            (ref) async => const StatsDashboard(),
          ),
          heroRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async => const []),
        ],
        child: HokHelperApp(router: router),
      ),
    );

    for (final entry in aliases.entries) {
      router.go(entry.key);
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        entry.value,
        reason: '${entry.key} should open ${entry.value}',
      );
    }
  });
}
