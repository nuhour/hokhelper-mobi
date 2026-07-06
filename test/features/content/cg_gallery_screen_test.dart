import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/content/data/content_repository.dart';
import 'package:hok_helper_mobile/src/features/content/domain/cg_detail.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/cg_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';

class _FakeContentRepository extends ContentRepository {
  _FakeContentRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  int? submittedCgId;
  String? submittedComment;
  int? viewedCgId;
  int? ratedCgId;
  double? submittedRating;
  final commentOrders = <String>[];

  @override
  Future<List<ContentItemSummary>> loadCgs(
    int regionId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return const [
      ContentItemSummary(
        id: 501,
        kind: ContentKind.cg,
        title: 'Lam Cinematic',
        heroName: 'Lam',
        imageUrl: 'https://example.test/lam-cover.jpg',
        subtitle: 'Playable video',
        rating: 4.8,
        ratingCount: 17,
        viewCount: 2300,
      ),
    ];
  }

  @override
  Future<CgDetail> loadCgDetail(int cgId) async {
    return const CgDetail(
      id: 501,
      title: 'Lam Cinematic',
      heroName: 'Lam',
      coverUrl: 'https://example.test/lam-cover.jpg',
      playUrl: 'https://example.test/lam.mp4',
      viewCount: 2300,
      rating: 4.8,
      ratingCount: 17,
    );
  }

  @override
  Future<List<CgCommentSummary>> loadCgComments(
    int cgId, {
    String order = 'desc',
  }) async {
    commentOrders.add(order);
    if (order == 'asc') {
      return const [
        CgCommentSummary(
          id: 8,
          authorName: 'oldest',
          authorAvatarUrl: '',
          content: 'First reaction.',
          createdAt: '2026-07-02T08:30:00Z',
        ),
      ];
    }
    return const [
      CgCommentSummary(
        id: 9,
        authorName: 'coach',
        authorAvatarUrl: '',
        content: 'Great cinematic.',
        createdAt: '2026-07-03T08:30:00Z',
      ),
    ];
  }

  @override
  Future<void> createCgComment(int cgId, String content) async {
    submittedCgId = cgId;
    submittedComment = content;
  }

  @override
  Future<int> recordCgView(int cgId) async {
    viewedCgId = cgId;
    return 2301;
  }

  @override
  Future<CgRatingResult> rateCg(int cgId, double rating) async {
    ratedCgId = cgId;
    submittedRating = rating;
    return const CgRatingResult(rating: 5, ratingCount: 18);
  }
}

void main() {
  testWidgets('renders cg gallery, filters, and opens cg detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cgGalleryProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 501,
                kind: ContentKind.cg,
                title: 'Lam Cinematic',
                heroName: 'Lam',
                imageUrl: 'https://example.test/lam-cover.jpg',
                subtitle: 'Playable video',
                rating: 4.8,
                ratingCount: 17,
                viewCount: 2300,
              ),
              ContentItemSummary(
                id: 502,
                kind: ContentKind.cg,
                title: 'Angela Trailer',
                heroName: 'Angela',
                imageUrl: '',
                subtitle: 'Playable video',
                rating: 3.9,
                ratingCount: 6,
                viewCount: 900,
              ),
            ];
          }),
          cgDetailProvider(501).overrideWith((ref) async {
            return const CgDetail(
              id: 501,
              title: 'Lam Cinematic',
              heroName: 'Lam',
              coverUrl: 'https://example.test/lam-cover.jpg',
              playUrl: 'https://example.test/lam.mp4',
              viewCount: 2300,
              rating: 4.8,
              ratingCount: 17,
            );
          }),
          cgCommentsProvider(const CgCommentsQuery(501)).overrideWith((
            ref,
          ) async {
            return const [
              CgCommentSummary(
                id: 9,
                authorName: 'coach',
                authorAvatarUrl: '',
                content: 'Great cinematic.',
                createdAt: '2026-07-03T08:30:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: CgGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CG Gallery'), findsOneWidget);
    expect(find.text('Lam Cinematic'), findsOneWidget);
    expect(find.text('Angela Trailer'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Lam');
    await tester.pumpAndSettle();

    expect(find.text('Lam Cinematic'), findsOneWidget);
    expect(find.text('Angela Trailer'), findsNothing);

    await tester.tap(find.text('Lam Cinematic'));
    await tester.pumpAndSettle();

    expect(find.text('CG Detail'), findsOneWidget);
    expect(find.text('https://example.test/lam.mp4'), findsOneWidget);
    expect(find.text('2,300 views'), findsOneWidget);
    expect(find.text('Great cinematic.'), findsOneWidget);
  });

  testWidgets('filters cgs from initial search query', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cgGalleryProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 501,
                kind: ContentKind.cg,
                title: 'Lam Cinematic',
                heroName: 'Lam',
                imageUrl: '',
                subtitle: 'Playable video',
                rating: 4.8,
                ratingCount: 17,
                viewCount: 2300,
              ),
              ContentItemSummary(
                id: 502,
                kind: ContentKind.cg,
                title: 'Angela Trailer',
                heroName: 'Angela',
                imageUrl: '',
                subtitle: 'Playable video',
                rating: 3.9,
                ratingCount: 6,
                viewCount: 900,
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CgGalleryScreen(initialSearchQuery: 'Lam')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Lam'), findsOneWidget);
    expect(find.text('Lam Cinematic'), findsOneWidget);
    expect(find.text('Angela Trailer'), findsNothing);
  });

  testWidgets('posts comments from the cg detail sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeContentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          cgGalleryProvider.overrideWith(
            (ref) =>
                ref.watch(contentRepositoryProvider).loadCgs(2, pageSize: 60),
          ),
          cgDetailProvider(501).overrideWith(
            (ref) => ref.watch(contentRepositoryProvider).loadCgDetail(501),
          ),
          cgCommentsProvider(const CgCommentsQuery(501)).overrideWith(
            (ref) => ref.watch(contentRepositoryProvider).loadCgComments(501),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CgGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lam Cinematic'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Write a comment'),
      'Fresh take.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Post comment'));
    await tester.pumpAndSettle();

    expect(repository.submittedCgId, 501);
    expect(repository.submittedComment, 'Fresh take.');
    expect(find.text('Comment posted'), findsOneWidget);
  });

  testWidgets('records views and rates cgs from the detail sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeContentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          cgGalleryProvider.overrideWith(
            (ref) =>
                ref.watch(contentRepositoryProvider).loadCgs(2, pageSize: 60),
          ),
          cgDetailProvider(501).overrideWith(
            (ref) => ref.watch(contentRepositoryProvider).loadCgDetail(501),
          ),
          cgCommentsProvider(const CgCommentsQuery(501)).overrideWith(
            (ref) => ref.watch(contentRepositoryProvider).loadCgComments(501),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CgGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lam Cinematic'));
    await tester.pumpAndSettle();

    expect(repository.viewedCgId, 501);

    await tester.tap(find.byTooltip('Rate 5 stars'));
    await tester.pumpAndSettle();

    expect(repository.ratedCgId, 501);
    expect(repository.submittedRating, 5);
    expect(find.text('Rating submitted'), findsOneWidget);
  });

  testWidgets('switches cg comments between newest and oldest order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeContentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          cgGalleryProvider.overrideWith(
            (ref) =>
                ref.watch(contentRepositoryProvider).loadCgs(2, pageSize: 60),
          ),
          cgDetailProvider(501).overrideWith(
            (ref) => ref.watch(contentRepositoryProvider).loadCgDetail(501),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CgGalleryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lam Cinematic'));
    await tester.pumpAndSettle();

    expect(repository.commentOrders, contains('desc'));
    expect(find.text('Great cinematic.'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Oldest first'));
    await tester.pumpAndSettle();

    expect(repository.commentOrders, contains('asc'));
    expect(find.text('First reaction.'), findsOneWidget);
  });
}
