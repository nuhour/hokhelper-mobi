import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_image.dart';
import 'package:hok_helper_mobile/src/features/content/data/content_repository.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/domain/skin_detail.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/skin_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';

class _FakeSkinRepository extends ContentRepository {
  _FakeSkinRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  int? ratedSkinId;
  double? submittedRating;

  @override
  Future<List<ContentItemSummary>> loadSkins(
    int regionId, {
    int pageSize = 20,
  }) async {
    return const [
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
    ];
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
          skinGalleryProvider.overrideWith((ref) async {
            return const [
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
          }),
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
    await tester.tap(find.text('Crimson Hunter'));
    await tester.pumpAndSettle();

    expect(find.text('Skin Detail'), findsOneWidget);
    expect(find.text('Hunter Series'), findsWidgets);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('12 ratings'), findsOneWidget);
  });

  testWidgets('filters skins from initial search query', (tester) async {
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
            ];
          }),
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

  testWidgets('filters skins by minimum rating', (tester) async {
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
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '4+'));
    await tester.pumpAndSettle();

    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All ratings'));
    await tester.pumpAndSettle();

    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsOneWidget);
  });

  testWidgets('filters skins by hero lane position', (tester) async {
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
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: SkinGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Clash'));
    await tester.pumpAndSettle();

    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All lanes'));
    await tester.pumpAndSettle();

    expect(find.text('Crimson Hunter'), findsOneWidget);
    expect(find.text('Moonlight Tune'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Rate Crimson Hunter 5 stars'));
    await tester.pumpAndSettle();

    expect(repository.ratedSkinId, 1001);
    expect(repository.submittedRating, 5);
    expect(find.text('Rating submitted'), findsOneWidget);
  });
}
