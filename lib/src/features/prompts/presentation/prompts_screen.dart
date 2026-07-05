import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/prompts_repository.dart';
import '../domain/prompt_summary.dart';

final promptsRepositoryProvider = Provider<PromptsRepository>((ref) {
  return PromptsRepository(apiClient: ref.watch(apiClientProvider));
});

final publicPromptsProvider = FutureProvider<List<PromptSummary>>((ref) {
  return ref.watch(promptListProvider(PromptListAction.explore).future);
});

final promptListProvider =
    FutureProvider.family<List<PromptSummary>, PromptListAction>((ref, action) {
      return ref.watch(promptsRepositoryProvider).loadPrompts(action: action);
    });

extension PromptListActionLabel on PromptListAction {
  String get label => switch (this) {
    PromptListAction.explore => 'Explore',
    PromptListAction.myPrompts => 'My Prompts',
    PromptListAction.favorites => 'Favorites',
  };
}

PromptListAction promptListActionFromRoute(String? value) {
  return switch ((value ?? '').trim()) {
    'myPrompts' => PromptListAction.myPrompts,
    'favorites' => PromptListAction.favorites,
    _ => PromptListAction.explore,
  };
}

class PromptsScreen extends ConsumerStatefulWidget {
  const PromptsScreen({
    super.key,
    this.initialAction = PromptListAction.explore,
    this.initialPromptId,
  });

  final PromptListAction initialAction;
  final String? initialPromptId;

  @override
  ConsumerState<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends ConsumerState<PromptsScreen> {
  late PromptListAction _action;

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction;
  }

  @override
  Widget build(BuildContext context) {
    final promptsValue = ref.watch(promptListProvider(_action));

    return AppAsyncView<List<PromptSummary>>(
      value: promptsValue,
      retry: () => ref.invalidate(promptListProvider(_action)),
      data: (prompts) {
        final visiblePrompts = _visiblePrompts(prompts);
        return RefreshIndicator(
          onRefresh: () => ref.refresh(promptListProvider(_action).future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(title: 'Prompts'),
                      const SizedBox(height: 8),
                      Text(
                        'Explore public AI prompt templates from the community.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<PromptListAction>(
                          segments: PromptListAction.values
                              .map(
                                (action) => ButtonSegment(
                                  value: action,
                                  label: Text(action.label),
                                ),
                              )
                              .toList(growable: false),
                          selected: {_action},
                          onSelectionChanged: (selection) {
                            setState(() => _action = selection.single);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (prompts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: 'No prompts found',
                    message: 'Pull to refresh and try again.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: visiblePrompts.length,
                    itemBuilder: (context, index) {
                      final prompt = visiblePrompts[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (prompt.id == widget.initialPromptId) ...[
                            const _SharedPromptBadge(),
                            const SizedBox(height: 8),
                          ],
                          _PromptCard(prompt: prompt),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<PromptSummary> _visiblePrompts(List<PromptSummary> prompts) {
    final initialPromptId = widget.initialPromptId?.trim();
    if (initialPromptId == null || initialPromptId.isEmpty) {
      return prompts;
    }

    final focusedIndex = prompts.indexWhere(
      (prompt) => prompt.id == initialPromptId,
    );
    if (focusedIndex < 0) {
      return prompts;
    }

    final focused = prompts[focusedIndex];
    final rest = prompts.where((prompt) => prompt.id != initialPromptId);
    return [focused, ...rest].toList(growable: false);
  }
}

class _SharedPromptBadge extends StatelessWidget {
  const _SharedPromptBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.32)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'Shared prompt',
          style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});

  final PromptSummary prompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppImage(
                  url: prompt.imageUrl,
                  width: 74,
                  height: 74,
                  borderRadius: 14,
                  semanticLabel: prompt.title,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              prompt.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PublicBadge(isPublic: prompt.isPublic),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prompt.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (prompt.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                prompt.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.35,
                ),
              ),
            ],
            if (prompt.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: prompt.tags.take(4).map(_TagChip.new).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.favorite_border,
                  value: prompt.likeCount,
                ),
                _MetricChip(
                  icon: Icons.bookmark_border,
                  value: prompt.favoriteCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicBadge extends StatelessWidget {
  const _PublicBadge({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: isPublic ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          isPublic ? 'Public' : 'Private',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.gold),
            const SizedBox(width: 5),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
