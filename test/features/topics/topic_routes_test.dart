import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';
import 'package:hok_helper_mobile/src/features/topics/domain/topic_article.dart';
import 'package:hok_helper_mobile/src/features/topics/presentation/topic_article_screen.dart';
import 'package:hok_helper_mobile/src/features/topics/presentation/topic_hub_screen.dart';

void main() {
  testWidgets('topics namespace opens a generic topic hub', (tester) async {
    final router = createAppRouter();
    router.go('/topics/hok-world');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async => _emptyHomeStats),
          topicArticlesProvider(('hok-world', 12)).overrideWith((ref) async {
            return const [
              TopicArticleSummary(
                id: 11,
                slug: 'hok-world-tier-list',
                topicKey: 'hok-world',
                locale: 'en',
                title: 'HOK World Tier List',
                excerpt: 'A starter guide for HOK World rankings.',
                seoDescription: 'Ranked context for HOK World.',
                coverImageUrl: '',
                tags: ['Guide', 'Meta'],
                sortOrder: 1,
                publishedAt: '2026-07-01 10:00:00',
                updatedAt: '',
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hok World'), findsOneWidget);
    expect(find.text('HOK World Tier List'), findsOneWidget);
  });

  testWidgets('topics namespace opens a generic topic article detail', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/topics/hok-world/hok-world-tier-list');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async => _emptyHomeStats),
          topicArticleProvider('hok-world-tier-list').overrideWith((ref) async {
            return const TopicArticleDetail(
              id: 11,
              slug: 'hok-world-tier-list',
              topicKey: 'hok-world',
              locale: 'en',
              title: 'HOK World Tier List',
              excerpt: 'A starter guide for HOK World rankings.',
              content: '## Why it matters\nUse hero roles and stats together.',
              seoTitle: 'HOK World Tier List | HOK Helper',
              seoDescription: 'Ranked context for HOK World.',
              coverImageUrl: '',
              tags: ['Guide', 'Meta'],
              availableLocales: ['en', 'zh'],
              publishedAt: '2026-07-01 10:00:00',
              updatedAt: '2026-07-02 10:00:00',
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Why it matters'), findsOneWidget);
    expect(find.text('Use hero roles and stats together.'), findsOneWidget);
    expect(find.text('HOK World'), findsWidgets);
    expect(find.text('HOK Tier List'), findsOneWidget);
    expect(find.text('HOK Hero Stats'), findsOneWidget);
  });

  testWidgets('legacy topics slug route opens the hok world article detail', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/topics/hok-world-tier-list');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async => _emptyHomeStats),
          topicArticlesProvider((
            'hok-world-tier-list',
            12,
          )).overrideWith((ref) async => const []),
          topicArticleProvider('hok-world-tier-list').overrideWith((ref) async {
            return const TopicArticleDetail(
              id: 11,
              slug: 'hok-world-tier-list',
              topicKey: 'hok-world',
              locale: 'en',
              title: 'HOK World Tier List',
              excerpt: 'A starter guide for HOK World rankings.',
              content: '## Why it matters\nUse hero roles and stats together.',
              seoTitle: 'HOK World Tier List | HOK Helper',
              seoDescription: 'Ranked context for HOK World.',
              coverImageUrl: '',
              tags: ['Guide', 'Meta'],
              availableLocales: ['en', 'zh'],
              publishedAt: '2026-07-01 10:00:00',
              updatedAt: '2026-07-02 10:00:00',
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Why it matters'), findsOneWidget);
    expect(find.text('HOK World'), findsWidgets);
  });

  testWidgets('hok world hub opens a topic article detail', (tester) async {
    final router = createAppRouter();
    router.go('/hok-world');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async => _emptyHomeStats),
          topicArticlesProvider(('hok-world', 12)).overrideWith((ref) async {
            return const [
              TopicArticleSummary(
                id: 11,
                slug: 'hok-world-tier-list',
                topicKey: 'hok-world',
                locale: 'en',
                title: 'HOK World Tier List',
                excerpt: 'A starter guide for HOK World rankings.',
                seoDescription: 'Ranked context for HOK World.',
                coverImageUrl: '',
                tags: ['Guide', 'Meta'],
                sortOrder: 1,
                publishedAt: '2026-07-01 10:00:00',
                updatedAt: '',
              ),
            ];
          }),
          topicArticleProvider('hok-world-tier-list').overrideWith((ref) async {
            return const TopicArticleDetail(
              id: 11,
              slug: 'hok-world-tier-list',
              topicKey: 'hok-world',
              locale: 'en',
              title: 'HOK World Tier List',
              excerpt: 'A starter guide for HOK World rankings.',
              content: '## Why it matters\nUse hero roles and stats together.',
              seoTitle: 'HOK World Tier List | HOK Helper',
              seoDescription: 'Ranked context for HOK World.',
              coverImageUrl: '',
              tags: ['Guide', 'Meta'],
              availableLocales: ['en', 'zh'],
              publishedAt: '2026-07-01 10:00:00',
              updatedAt: '2026-07-02 10:00:00',
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HOK World'), findsWidgets);
    expect(find.text('HOK World Tier List'), findsOneWidget);
    expect(
      find.text('A starter guide for HOK World rankings.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open article'));
    await tester.pumpAndSettle();

    expect(find.text('Why it matters'), findsOneWidget);
    expect(find.text('Use hero roles and stats together.'), findsOneWidget);
    expect(find.text('HOK World'), findsWidgets);
    expect(find.text('HOK Tier List'), findsOneWidget);
    expect(find.text('HOK Hero Stats'), findsOneWidget);
  });

  testWidgets('top-level topic routes mirror hokx generic topics', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/pro-guides');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async => _emptyHomeStats),
          topicArticlesProvider(('pro-guides', 12)).overrideWith((ref) async {
            return const [
              TopicArticleSummary(
                id: 21,
                slug: 'draft-guide',
                topicKey: 'pro-guides',
                locale: 'en',
                title: 'Draft Guide',
                excerpt: 'Pick order notes for ranked play.',
                seoDescription: 'Drafting for mobile players.',
                coverImageUrl: '',
                tags: ['Guide'],
                sortOrder: 1,
                publishedAt: '2026-07-05 10:00:00',
                updatedAt: '',
              ),
            ];
          }),
          topicArticleProvider('draft-guide').overrideWith((ref) async {
            return const TopicArticleDetail(
              id: 21,
              slug: 'draft-guide',
              topicKey: 'pro-guides',
              locale: 'en',
              title: 'Draft Guide',
              excerpt: 'Pick order notes for ranked play.',
              content: '## First rotation\nSecure flexible heroes first.',
              seoTitle: 'Draft Guide | HOK Helper',
              seoDescription: 'Drafting for mobile players.',
              coverImageUrl: '',
              tags: ['Guide'],
              availableLocales: ['en'],
              publishedAt: '2026-07-05 10:00:00',
              updatedAt: '',
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pro Guides'), findsOneWidget);
    expect(find.text('Draft Guide'), findsOneWidget);

    router.go('/pro-guides/draft-guide');
    await tester.pumpAndSettle();

    expect(find.text('First rotation'), findsOneWidget);
    expect(find.text('Secure flexible heroes first.'), findsOneWidget);
    expect(find.text('Back to Pro Guides Hub'), findsOneWidget);
  });
}

const _emptyHomeStats = HomeStats(success: true, message: 'Ready', result: {});
