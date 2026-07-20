import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/topic_repository.dart';
import '../domain/topic_article.dart';

typedef TopicArticlesArgs = (String topicKey, int limit);

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository(apiClient: ref.watch(apiClientProvider));
});

final topicArticlesProvider =
    FutureProvider.family<List<TopicArticleSummary>, TopicArticlesArgs>((
      ref,
      args,
    ) {
      final locale =
          ref.watch(appSettingsControllerProvider).valueOrNull?.languageCode ??
          'en';
      return ref
          .watch(topicRepositoryProvider)
          .loadArticles(topicKey: args.$1, locale: locale, limit: args.$2);
    });

class TopicHubScreen extends ConsumerWidget {
  const TopicHubScreen({required this.topicKey, super.key});

  final String topicKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedTopicKey = _normalizeTopicKey(topicKey);
    final articlesValue = ref.watch(
      topicArticlesProvider((normalizedTopicKey, 12)),
    );
    final title = formatTopicTitle(normalizedTopicKey);

    return Material(
      color: context.hokTheme.backgroundDeep,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(topicArticlesProvider((normalizedTopicKey, 12)));
          await ref.read(
            topicArticlesProvider((normalizedTopicKey, 12)).future,
          );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            AppSectionHeader(title: title),
            const SizedBox(height: 10),
            Text(
              'Browse $title topic content from the HOK portal.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.hokTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 20),
            AppAsyncView<List<TopicArticleSummary>>(
              value: articlesValue,
              retry: () => ref.invalidate(
                topicArticlesProvider((normalizedTopicKey, 12)),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.article_outlined,
                    title: 'No content published yet',
                    message: 'Pull to refresh once topic articles are live.',
                  );
                }

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return _TopicArticleCard(
                      topicKey: normalizedTopicKey,
                      article: articles[index],
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemCount: articles.length,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicArticleCard extends StatelessWidget {
  const _TopicArticleCard({required this.topicKey, required this.article});

  final String topicKey;
  final TopicArticleSummary article;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.hokTheme.outlineSoft),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.go('/$topicKey/${article.slug}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.coverImageUrl.isNotEmpty) ...[
                  AppImage(
                    url: article.coverImageUrl,
                    width: double.infinity,
                    height: 150,
                    borderRadius: 14,
                    semanticLabel: article.title,
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _TopicPill(text: 'Latest articles'),
                    if (article.sortOrder != null)
                      _TopicPill(text: '#${article.sortOrder}'),
                    for (final tag in article.tags.take(3))
                      _TopicPill(text: tag),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.hokTheme.onSurfaceStrong,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (article.excerpt.isNotEmpty ||
                    article.seoDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    article.excerpt.isNotEmpty
                        ? article.excerpt
                        : article.seoDescription,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.hokTheme.onSurfaceMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open article',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.gold,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicPill extends StatelessWidget {
  const _TopicPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

String formatTopicTitle(String topicKey) {
  final words = _normalizeTopicKey(topicKey)
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}');
  return words.isEmpty ? 'Topic' : words.join(' ');
}

String _normalizeTopicKey(String topicKey) {
  final normalized = topicKey.trim().toLowerCase();
  return normalized.isEmpty ? 'hok-world' : normalized;
}
