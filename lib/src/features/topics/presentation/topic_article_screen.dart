import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/topic_article.dart';
import 'topic_hub_screen.dart';

final topicArticleProvider = FutureProvider.family<TopicArticleDetail, String>((
  ref,
  slug,
) {
  final locale =
      ref.watch(appSettingsControllerProvider).valueOrNull?.languageCode ??
      'en';
  return ref
      .watch(topicRepositoryProvider)
      .loadArticle(slug: slug, locale: locale);
});

class TopicArticleScreen extends ConsumerWidget {
  const TopicArticleScreen({
    required this.topicKey,
    required this.slug,
    super.key,
  });

  final String topicKey;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleValue = ref.watch(topicArticleProvider(slug));
    final title = formatTopicTitle(topicKey);

    return Material(
      color: AppTheme.bg,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(topicArticleProvider(slug));
          await ref.read(topicArticleProvider(slug).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            AppAsyncView<TopicArticleDetail>(
              value: articleValue,
              retry: () => ref.invalidate(topicArticleProvider(slug)),
              data: (article) => _ArticleBody(
                topicTitle: title,
                topicKey: topicKey,
                article: article,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({
    required this.topicTitle,
    required this.topicKey,
    required this.article,
  });

  final String topicTitle;
  final String topicKey;
  final TopicArticleDetail article;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in article.tags) _ArticleTag(text: tag),
                if (article.availableLocales.isNotEmpty)
                  _ArticleTag(
                    text: article.availableLocales
                        .map((locale) => locale.toUpperCase())
                        .join(' / '),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            AppSectionHeader(title: article.title),
            if (article.excerpt.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                article.excerpt,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
              ),
            ],
            if (article.coverImageUrl.isNotEmpty) ...[
              const SizedBox(height: 18),
              AppImage(
                url: article.coverImageUrl,
                width: double.infinity,
                height: 190,
                borderRadius: 16,
                semanticLabel: article.title,
              ),
            ],
            const SizedBox(height: 22),
            ..._buildContentBlocks(context, article.content),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ArticleAction(
                  icon: Icons.link,
                  label: 'Back to $topicTitle Hub',
                  onTap: () => context.go('/$topicKey'),
                ),
                _ArticleAction(
                  icon: Icons.leaderboard_outlined,
                  label: 'View Tier List',
                  onTap: () => context.go('/tools/rankings'),
                ),
                _ArticleAction(
                  icon: Icons.insights_outlined,
                  label: 'Open Stats Dashboard',
                  onTap: () => context.go('/tools/stats'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContentBlocks(BuildContext context, String content) {
    final lines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return [
        Text(
          'No article content available.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
        ),
      ];
    }

    return [
      for (final line in lines) ...[
        if (line.startsWith('##'))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line.replaceFirst(RegExp(r'^#+\s*'), ''),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              line.replaceAll(RegExp(r'[*_`#]'), ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
                height: 1.55,
              ),
            ),
          ),
      ],
    ];
  }
}

class _ArticleTag extends StatelessWidget {
  const _ArticleTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.cyan,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ArticleAction extends StatelessWidget {
  const _ArticleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
