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
import '../data/builds_repository.dart';
import '../domain/build_scheme_summary.dart';

final buildsRepositoryProvider = Provider<BuildsRepository>((ref) {
  return BuildsRepository(apiClient: ref.watch(apiClientProvider));
});

final publicBuildSchemesProvider = FutureProvider<List<BuildSchemeSummary>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(buildsRepositoryProvider)
      .loadPublicSchemes(settings.region.regionId);
});

class BuildExplorerScreen extends ConsumerWidget {
  const BuildExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemesValue = ref.watch(publicBuildSchemesProvider);

    return AppAsyncView<List<BuildSchemeSummary>>(
      value: schemesValue,
      retry: () => ref.invalidate(publicBuildSchemesProvider),
      data: (schemes) {
        return RefreshIndicator(
          onRefresh: () => ref.refresh(publicBuildSchemesProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(title: 'Build Explorer'),
                      const SizedBox(height: 8),
                      Text(
                        'Browse public hero builds from the community.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              if (schemes.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.construction_outlined,
                    title: 'No public builds',
                    message: 'Pull to refresh or switch region in settings.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: schemes.length,
                    itemBuilder: (context, index) {
                      return BuildSchemeCard(scheme: schemes[index]);
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
}

class BuildSchemeCard extends ConsumerStatefulWidget {
  const BuildSchemeCard({required this.scheme, super.key});

  final BuildSchemeSummary scheme;

  @override
  ConsumerState<BuildSchemeCard> createState() => _BuildSchemeCardState();
}

class _BuildSchemeCardState extends ConsumerState<BuildSchemeCard> {
  late var _likeCount = widget.scheme.likeCount;
  late var _favoriteCount = widget.scheme.favoriteCount;
  var _likeSubmitting = false;
  var _favoriteSubmitting = false;
  var _cloneSubmitting = false;

  @override
  void didUpdateWidget(covariant BuildSchemeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheme.id != widget.scheme.id ||
        oldWidget.scheme.likeCount != widget.scheme.likeCount) {
      _likeCount = widget.scheme.likeCount;
      _likeSubmitting = false;
    }
    if (oldWidget.scheme.id != widget.scheme.id ||
        oldWidget.scheme.favoriteCount != widget.scheme.favoriteCount) {
      _favoriteCount = widget.scheme.favoriteCount;
      _favoriteSubmitting = false;
    }
    if (oldWidget.scheme.id != widget.scheme.id) {
      _cloneSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = widget.scheme;
    final heroName = scheme.heroName.isEmpty ? 'Any hero' : scheme.heroName;

    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/tools/build-sim?scheme=${scheme.id}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            scheme.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _BuildAuthorLine(
                            heroName: heroName,
                            authorName: scheme.authorName,
                            authorId: scheme.authorId,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PublicBadge(isPublic: scheme.isPublic),
                  ],
                ),
                const SizedBox(height: 14),
                _EquipmentStrip(icons: scheme.equipmentIcons),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      icon: Icons.thumb_up_outlined,
                      value: _likeCount,
                    ),
                    _MetricChip(
                      icon: Icons.star_border_rounded,
                      value: _favoriteCount,
                    ),
                    _MetricChip(
                      icon: Icons.copy_all_outlined,
                      value: scheme.cloneCount,
                    ),
                    OutlinedButton.icon(
                      onPressed: _likeSubmitting
                          ? null
                          : () => _likeScheme(context),
                      icon: const Icon(Icons.thumb_up_outlined, size: 16),
                      label: const Text('Like'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _favoriteSubmitting
                          ? null
                          : () => _favoriteScheme(context),
                      icon: const Icon(Icons.star_border_rounded, size: 16),
                      label: const Text('Favorite'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _cloneSubmitting
                          ? null
                          : () => _showCloneSheet(context),
                      icon: const Icon(Icons.copy_all_outlined, size: 16),
                      label: const Text('Clone'),
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

  Future<void> _likeScheme(BuildContext context) async {
    setState(() => _likeSubmitting = true);
    try {
      await ref
          .read(buildsRepositoryProvider)
          .likeBuildScheme(widget.scheme.id);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _likeCount += 1;
        _likeSubmitting = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Build liked')));
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _likeSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to like build')),
      );
    }
  }

  Future<void> _favoriteScheme(BuildContext context) async {
    setState(() => _favoriteSubmitting = true);
    try {
      await ref
          .read(buildsRepositoryProvider)
          .favoriteBuildScheme(widget.scheme.id);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _favoriteCount += 1;
        _favoriteSubmitting = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Build favorited')));
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _favoriteSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to favorite build')),
      );
    }
  }

  Future<void> _showCloneSheet(BuildContext context) async {
    final slotIndex = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppTheme.panel,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Clone build to slot',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              for (var slot = 1; slot <= 3; slot++) ...[
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(slot),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text('Slot $slot'),
                ),
                if (slot < 3) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
    if (slotIndex == null || !context.mounted) {
      return;
    }
    await _cloneScheme(context, slotIndex);
  }

  Future<void> _cloneScheme(BuildContext context, int slotIndex) async {
    setState(() => _cloneSubmitting = true);
    try {
      await ref.read(buildsRepositoryProvider).cloneBuildScheme(
            schemeId: widget.scheme.id,
            slotIndex: slotIndex,
          );
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _cloneSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Build cloned to Slot $slotIndex')),
      );
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _cloneSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to clone build')),
      );
    }
  }
}

class _BuildAuthorLine extends StatelessWidget {
  const _BuildAuthorLine({
    required this.heroName,
    required this.authorName,
    required this.authorId,
  });

  final String heroName;
  final String authorName;
  final int authorId;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted);
    final authorStyle = style?.copyWith(
      color: authorId > 0 ? AppTheme.gold : AppTheme.muted,
      fontWeight: authorId > 0 ? FontWeight.w800 : FontWeight.w400,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '$heroName · ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (authorId > 0)
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: authorStyle,
            ),
            onPressed: () => context.go('/profile/$authorId'),
            child: Text(
              authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: authorStyle,
            ),
          )
        else
          Flexible(
            child: Text(
              authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: authorStyle,
            ),
          ),
      ],
    );
  }
}

class _EquipmentStrip extends StatelessWidget {
  const _EquipmentStrip({required this.icons});

  final List<String> icons;

  @override
  Widget build(BuildContext context) {
    final visibleIcons = icons.take(6).toList(growable: false);
    if (visibleIcons.isEmpty) {
      return Text(
        'No equipment preview',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleIcons.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return AppImage(
            url: visibleIcons[index],
            width: 42,
            height: 42,
            borderRadius: 10,
            semanticLabel: 'Build equipment ${index + 1}',
          );
        },
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
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: isPublic ? 0.35 : 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          isPublic ? 'Public' : 'Private',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isPublic ? AppTheme.gold : AppTheme.muted,
            fontWeight: FontWeight.w800,
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
            Icon(icon, size: 16, color: AppTheme.muted),
            const SizedBox(width: 5),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
