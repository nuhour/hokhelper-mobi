import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/content/data/content_repository.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/skin_gallery_screen.dart';

class _RouteSkinRepository extends ContentRepository {
  _RouteSkinRepository(this.skins)
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  final List<ContentItemSummary> skins;

  @override
  Future<List<ContentItemSummary>> loadSkins(
    int regionId, {
    int page = 1,
    int pageSize = 20,
    String sort = 'id',
    String order = 'desc',
    String search = '',
    double minRating = 0,
    int? lanePosition,
  }) async {
    return skins;
  }
}

void main() {
  testWidgets('web skin gallery route preserves search query', (tester) async {
    final router = createAppRouter();
    router.go('/skin-gallery?q=Lam');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            _RouteSkinRepository(const [
              ContentItemSummary(
                id: 1001,
                kind: ContentKind.skin,
                title: 'Crimson Hunter',
                heroName: 'Lam',
                imageUrl: '',
                subtitle: 'Hunter Series',
                rating: 4.5,
                ratingCount: 12,
                viewCount: 0,
              ),
              ContentItemSummary(
                id: 1002,
                kind: ContentKind.skin,
                title: 'Moonlight Tune',
                heroName: 'Angela',
                imageUrl: '',
                subtitle: 'Music Series',
                rating: 3.5,
                ratingCount: 4,
                viewCount: 0,
              ),
            ]),
          ),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/skin-gallery');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['q'],
      'Lam',
    );
    expect(find.widgetWithText(TextField, 'Lam'), findsOneWidget);
    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsNothing);
  });

  testWidgets('web skin gallery route preserves rating and lane filters', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/skin-gallery?min_rating=4&position=0');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            _RouteSkinRepository(const [
              ContentItemSummary(
                id: 1001,
                kind: ContentKind.skin,
                title: 'Crimson Hunter',
                heroName: 'Lam',
                imageUrl: '',
                subtitle: 'Hunter Series',
                rating: 4.5,
                ratingCount: 12,
                viewCount: 0,
                heroPosition: 0,
              ),
              ContentItemSummary(
                id: 1002,
                kind: ContentKind.skin,
                title: 'Moonlight Tune',
                heroName: 'Angela',
                imageUrl: '',
                subtitle: 'Music Series',
                rating: 4.6,
                ratingCount: 4,
                viewCount: 0,
                heroPosition: 1,
              ),
              ContentItemSummary(
                id: 1003,
                kind: ContentKind.skin,
                title: 'Low Rank Skin',
                heroName: 'Lam',
                imageUrl: '',
                subtitle: 'Classic Series',
                rating: 3.5,
                ratingCount: 2,
                viewCount: 0,
                heroPosition: 0,
              ),
            ]),
          ),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/skin-gallery');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['min_rating'],
      '4',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['position'],
      '0',
    );
    expect(find.text('Focused skin filters'), findsOneWidget);
    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsNothing);
    expect(find.text('Low Rank Skin'), findsNothing);
  });
}
