import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_image.dart';
import 'package:hok_helper_mobile/src/features/content/data/content_repository.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/domain/skin_detail.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/skin_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';

const _basicSkins = [
  ContentItemSummary(
    id: 1001,
    kind: ContentKind.skin,
    title: 'Crimson Hunter',
    heroName: 'Lam',
    imageUrl: 'https://example.test/portrait.jpg',
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
];

const _laneSkins = [
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
    rating: 4.2,
    ratingCount: 4,
    viewCount: 0,
    heroPosition: 1,
  ),
];

class _FakeSkinRepository extends ContentRepository {
  _FakeSkinRepository({this.skins = const [_defaultSkin]})
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  static const _defaultSkin = ContentItemSummary(
    id: 1001,
    kind: ContentKind.skin,
    title: 'Crimson Hunter',
    heroName: 'Lam',
    imageUrl: 'https://example.test/portrait.jpg',
    subtitle: 'Hunter Series',
    rating: 4.5,
    ratingCount: 12,
    viewCount: 0,
  );

  final List<ContentItemSummary> skins;
  int? ratedSkinId;
  double? submittedRating;
  String? requestedSkinSort;
  String? requestedSkinOrder;
  String? requestedSkinSearch;
  double? requestedMinRating;
  int? requestedLanePosition;

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
    requestedSkinSort = sort;
    requestedSkinOrder = order;
    requestedSkinSearch = search;
    requestedMinRating = minRating;
    requestedLanePosition = lanePosition;
    return skins;
  }

  @override
  Future<SkinDetail> loadSkinDetail(int skinId) async {
    return const SkinDetail(
      id: 1001,
      title: 'Crimson Hunter',
      heroName: 'Lam',
      portraitUrl: 'https://example.test/portrait.jpg',
      landscapeUrl: 'https://example.test/splash.jpg',
      seriesName: 'Hunter Series',
      regionName: 'Global',
      rating: 4.5,
      ratingCount: 12,
      linkUrl: 'https://example.test/skin/1001',
    );
  }

  @override
  Future<SkinRatingResult> rateSkin(int skinId, double rating) async {
    ratedSkinId = skinId;
    submittedRating = rating;
    return const SkinRatingResult(rating: 5, ratingCount: 13);
  }
}

class _PagedSkinRepository extends ContentRepository {
  _PagedSkinRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  final requestedPages = <int>[];

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
    requestedPages.add(page);
    final startId = (page - 1) * pageSize + 1;
    final count = page == 1 ? pageSize : 1;
    return List.generate(count, (index) {
      final id = startId + index;
      return ContentItemSummary(
        id: id,
        kind: ContentKind.skin,
        title: 'Paged Skin $id',
        heroName: 'Hero $id',
        imageUrl: '',
        subtitle: 'Paged Series',
        rating: 4,
        ratingCount: 1,
        viewCount: 0,
      );
    }, growable: false);
  }
}

void main() {
  testWidgets('renders skin gallery, filters, and opens skin detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            _FakeSkinRepository(skins: _basicSkins),
          ),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
          skinDetailProvider(1001).overrideWith((ref) async {
            return const SkinDetail(
              id: 1001,
              title: 'Crimson Hunter',
              heroName: 'Lam',
              portraitUrl: 'https://example.test/portrait.jpg',
              landscapeUrl: 'https://example.test/splash.jpg',
              seriesName: 'Hunter Series',
              regionName: 'Global',
              rating: 4.5,
              ratingCount: 12,
              linkUrl: 'https://example.test/skin/1001',
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Skin Gallery'), findsOneWidget);
    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Lam');
    await tester.pumpAndSettle();

    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsNothing);

    await tester.ensureVisible(find.text('Crimson Hunter'));
    expect(find.text('Crimson Hunter'), findsOneWidget);
    await tester.tap(
      find.ancestor(
        of: find.text('Crimson Hunter'),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Skin Detail'), findsOneWidget);
    expect(find.text('Hunter Series'), findsWidgets);
    expect(find.text('4.5'), findsWidgets);
    expect(find.text('12 ratings'), findsOneWidget);
  });

  testWidgets('filters skins from initial search query', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            _FakeSkinRepository(skins: _basicSkins),
          ),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SkinGalleryScreen(initialSearchQuery: 'Lam')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Lam'), findsOneWidget);
    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsNothing);
  });

  testWidgets('filters skins by hero lane position', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            _FakeSkinRepository(skins: _laneSkins),
          ),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('skin-lane-0')));
    await tester.pumpAndSettle();

    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('skin-lane-all')));
    await tester.pumpAndSettle();

    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsOneWidget);
  });

  testWidgets('filters skins from initial lane query', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            _FakeSkinRepository(
              skins: const [
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
              ],
            ),
          ),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SkinGalleryScreen(initialLanePosition: 0)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Focused skin filters'), findsOneWidget);
    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsNothing);
    expect(find.text('Low Rank Skin'), findsOneWidget);
  });

  testWidgets('requests skins with hokx-compatible sort params', (
    tester,
  ) async {
    final repository = _FakeSkinRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rating'));
    await tester.pumpAndSettle();

    expect(repository.requestedSkinSort, 'rating');
    expect(repository.requestedSkinOrder, 'desc');
  });

  testWidgets('requests skins with hokx-compatible search and filters', (
    tester,
  ) async {
    final repository = _FakeSkinRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Lam');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skin-lane-0')));
    await tester.pumpAndSettle();

    expect(repository.requestedSkinSearch, 'Lam');
    expect(repository.requestedMinRating, 0);
    expect(repository.requestedLanePosition, 0);
  });

  testWidgets('switches skin cards between poster and splash art', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinGalleryProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 1001,
                kind: ContentKind.skin,
                title: 'Crimson Hunter',
                heroName: 'Lam',
                imageUrl: 'https://example.test/portrait.jpg',
                landscapeImageUrl: 'https://example.test/splash.jpg',
                subtitle: 'Hunter Series',
                rating: 4.5,
                ratingCount: 12,
                viewCount: 0,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    AppImage cardImage() => tester.widget<AppImage>(find.byType(AppImage));

    expect(cardImage().url, 'https://example.test/portrait.jpg');

    await tester.tap(find.text('Splash'));
    await tester.pumpAndSettle();

    expect(cardImage().url, 'https://example.test/splash.jpg');
  });

  testWidgets('loads more skins after the first gallery page', (tester) async {
    final repository = _PagedSkinRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          skinGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paged Skin 1'), findsOneWidget);
    expect(find.text('Paged Skin 61'), findsNothing);

    final loadMoreButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Load more'),
    );
    await tester.runAsync(() async {
      loadMoreButton.onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(repository.requestedPages, [1, 2]);
    expect(find.text('Paged Skin 61'), findsOneWidget);
  });

  testWidgets('rates skins from the detail sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeSkinRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          skinGalleryProvider.overrideWith(
            (ref) =>
                ref.watch(contentRepositoryProvider).loadSkins(2, pageSize: 60),
          ),
          skinDetailProvider(1001).overrideWith(
            (ref) => ref.watch(contentRepositoryProvider).loadSkinDetail(1001),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crimson Hunter'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Rate skin 5 stars'));
    await tester.pumpAndSettle();

    expect(repository.ratedSkinId, 1001);
    expect(repository.submittedRating, 5);
    expect(find.text('Rating submitted'), findsOneWidget);
    expect(find.text('13 ratings'), findsOneWidget);
  });

  testWidgets('skin detail source links open through the mobile link route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter();
    router.go('/skin-gallery');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_FakeSkinRepository()),
          skinGalleryProvider.overrideWith(
            (ref) =>
                ref.watch(contentRepositoryProvider).loadSkins(2, pageSize: 60),
          ),
          skinDetailProvider(1001).overrideWith(
            (ref) => ref.watch(contentRepositoryProvider).loadSkinDetail(1001),
          ),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crimson Hunter'));
    await tester.pumpAndSettle();

    expect(find.text('Skin Detail'), findsOneWidget);
    expect(find.text('https://example.test/skin/1001'), findsOneWidget);
    final sourceButton = find.widgetWithText(
      FilledButton,
      'Open source',
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      sourceButton.last,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(sourceButton.last);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/external-link');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['url'],
      'https://example.test/skin/1001',
    );
  });

  testWidgets('rates skins directly from gallery cards', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeSkinRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          skinGalleryProvider.overrideWith(
            (ref) =>
                ref.watch(contentRepositoryProvider).loadSkins(2, pageSize: 60),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('skin-card-1001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rate Crimson Hunter 5 stars'));
    await tester.pumpAndSettle();

    expect(repository.ratedSkinId, 1001);
    expect(repository.submittedRating, 5);
    expect(find.text('Rating submitted'), findsOneWidget);
  });
}
