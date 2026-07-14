import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_markdown_content.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../heroes/data/heroes_repository.dart';
import '../domain/patch_note_summary.dart';
import 'content_screen.dart';

const _patchNotesPageSize = 120;

final _patchHeroesRepositoryProvider = Provider<HeroesRepository>((ref) {
  return HeroesRepository(apiClient: ref.watch(apiClientProvider));
});

final patchHeroDirectoryProvider = FutureProvider<Map<int, PatchHeroIdentity>>((
  ref,
) async {
  final regionId = await ref.watch(patchNotesRegionProvider.future);
  final heroes = await ref
      .watch(_patchHeroesRepositoryProvider)
      .loadHeroes(regionId, pageSize: 300);
  final directory = <int, PatchHeroIdentity>{};
  for (final hero in heroes) {
    final identity = PatchHeroIdentity(name: hero.name, avatarUrl: hero.avatar);
    _addHeroIdentity(directory, hero.id, identity);
    _addHeroIdentity(directory, hero.heroId, identity);
  }
  return directory;
});

class PatchNotesScreen extends ConsumerStatefulWidget {
  const PatchNotesScreen({this.initialNoteId, super.key});

  final int? initialNoteId;

  @override
  ConsumerState<PatchNotesScreen> createState() => _PatchNotesScreenState();
}

class _PatchNotesScreenState extends ConsumerState<PatchNotesScreen> {
  final _heroFilterController = TextEditingController();
  final _extraNotes = <PatchNoteSummary>[];
  String _heroFilter = '';
  var _nextPage = 2;
  var _hasMoreNotes = true;
  var _isLoadingMoreNotes = false;
  var _hasOpenedInitialNote = false;

  @override
  void dispose() {
    _heroFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patchNotesValue = ref.watch(patchNotesProvider);

    return Material(
      color: AppTheme.bg,
      child: RefreshIndicator(
        onRefresh: () async {
          _resetLoadedPages();
          ref.invalidate(patchNotesProvider);
          await ref.read(patchNotesProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const AppSectionHeader(title: 'Patch Notes'),
            const SizedBox(height: 12),
            Text(
              'Version timelines and hero balance adjustments from the HOK portal.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _heroFilterController,
              onChanged: (value) => setState(() => _heroFilter = value),
              style: const TextStyle(color: AppTheme.text),
              decoration: InputDecoration(
                hintText: 'Filter by hero',
                prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                suffixIcon: _heroFilter.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _heroFilterController.clear();
                          setState(() => _heroFilter = '');
                        },
                        icon: const Icon(Icons.close, color: AppTheme.muted),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            AppAsyncView<List<PatchNoteSummary>>(
              value: patchNotesValue,
              retry: () => ref.invalidate(patchNotesProvider),
              data: (items) {
                final rawItems = [...items, ..._extraNotes];
                final needsHeroDirectory = rawItems.any(
                  (note) => note.heroChanges.any(
                    (change) => change.needsIdentityResolution,
                  ),
                );
                final heroDirectory = needsHeroDirectory
                    ? ref.watch(patchHeroDirectoryProvider).valueOrNull ??
                          const <int, PatchHeroIdentity>{}
                    : const <int, PatchHeroIdentity>{};
                final allItems = _resolvePatchHeroes(rawItems, heroDirectory);
                _openInitialNoteIfNeeded(allItems);
                final filteredItems = _filterByHero(allItems, _heroFilter);
                if (filteredItems.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.newspaper_outlined,
                    title: _heroFilter.trim().isEmpty
                        ? 'No Patch Notes found'
                        : 'No hero updates found',
                    message: _heroFilter.trim().isEmpty
                        ? 'Pull to refresh or switch region in settings.'
                        : 'Try another hero name.',
                  );
                }

                return Column(
                  children: [
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _PatchTimelineCard(
                          note: filteredItems[index],
                          onTap: () =>
                              _showPatchDetail(context, filteredItems[index]),
                        );
                      },
                    ),
                    if (_hasMoreNotes && items.length >= _patchNotesPageSize)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FilledButton.icon(
                          onPressed: _isLoadingMoreNotes
                              ? null
                              : _loadMorePatchNotes,
                          icon: _isLoadingMoreNotes
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            _isLoadingMoreNotes ? 'Loading...' : 'Load more',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<PatchNoteSummary> _filterByHero(
    List<PatchNoteSummary> items,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return items;
    }

    return items
        .where(
          (note) => note.heroChanges.any(
            (change) => change.heroName.toLowerCase().contains(normalizedQuery),
          ),
        )
        .toList(growable: false);
  }

  void _showPatchDetail(BuildContext context, PatchNoteSummary note) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PatchDetailSheet(note: note);
      },
    );
  }

  void _openInitialNoteIfNeeded(List<PatchNoteSummary> items) {
    final initialNoteId = widget.initialNoteId;
    if (_hasOpenedInitialNote || initialNoteId == null) {
      return;
    }
    for (final note in items) {
      if (note.id == initialNoteId) {
        _hasOpenedInitialNote = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showPatchDetail(context, note);
          }
        });
        return;
      }
    }
  }

  void _resetLoadedPages() {
    _extraNotes.clear();
    _nextPage = 2;
    _hasMoreNotes = true;
    _isLoadingMoreNotes = false;
  }

  Future<void> _loadMorePatchNotes() async {
    if (_isLoadingMoreNotes || !_hasMoreNotes) {
      return;
    }

    setState(() => _isLoadingMoreNotes = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final regionId = await ref.read(patchNotesRegionProvider.future);
      final nextItems = await ref
          .read(contentRepositoryProvider)
          .loadPatchNotes(
            regionId,
            page: _nextPage,
            pageSize: _patchNotesPageSize,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _nextPage += 1;
        _extraNotes.addAll(nextItems);
        _hasMoreNotes = nextItems.length >= _patchNotesPageSize;
        _isLoadingMoreNotes = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMoreNotes = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to load more patch notes: $error')),
      );
    }
  }
}

void _addHeroIdentity(
  Map<int, PatchHeroIdentity> directory,
  String id,
  PatchHeroIdentity identity,
) {
  final parsedId = int.tryParse(id);
  if (parsedId != null && parsedId > 0) {
    directory.putIfAbsent(parsedId, () => identity);
  }
}

List<PatchNoteSummary> _resolvePatchHeroes(
  List<PatchNoteSummary> notes,
  Map<int, PatchHeroIdentity> directory,
) {
  if (directory.isEmpty) {
    return notes;
  }
  return notes
      .map((note) => note.resolveHeroes(directory))
      .toList(growable: false);
}

class _PatchTimelineCard extends StatelessWidget {
  const _PatchTimelineCard({required this.note, required this.onTap});

  final PatchNoteSummary note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _VersionPill(version: note.version),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.muted),
                  ],
                ),
                if (note.preview.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    note.preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                ],
                const SizedBox(height: 14),
                _HeroChangeRail(changes: note.heroChanges),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatchDetailSheet extends ConsumerStatefulWidget {
  const _PatchDetailSheet({required this.note});

  final PatchNoteSummary note;

  @override
  ConsumerState<_PatchDetailSheet> createState() => _PatchDetailSheetState();
}

class _PatchDetailSheetState extends ConsumerState<_PatchDetailSheet> {
  PatchNoteSummary? _detailNote;
  var _isLoadingDetail = false;
  var _detailFailed = false;

  PatchNoteSummary get _visibleNote => _detailNote ?? widget.note;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _detailFailed = false;
    });
    try {
      final regionId = await ref.read(patchNotesRegionProvider.future);
      final detail = await ref
          .read(contentRepositoryProvider)
          .loadPatchNoteDetail(widget.note.id, regionId: regionId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detailNote = detail;
        _isLoadingDetail = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingDetail = false;
        _detailFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawNote = _visibleNote;
    final needsHeroDirectory = rawNote.heroChanges.any(
      (change) => change.needsIdentityResolution,
    );
    final heroDirectory = needsHeroDirectory
        ? ref.watch(patchHeroDirectoryProvider).valueOrNull ??
              const <int, PatchHeroIdentity>{}
        : const <int, PatchHeroIdentity>{};
    final note = rawNote.resolveHeroes(heroDirectory);
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            interactive: true,
            thickness: 4,
            radius: const Radius.circular(99),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _VersionPill(version: note.version),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        note.date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppMarkdownContent(content: note.content),
                ],
                if (_isLoadingDetail) ...[
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading full patch details...',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ],
                if (_detailFailed) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load full patch details.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Hero Adjustments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (note.heroChanges.isEmpty)
                  const Text(
                    'No hero-specific adjustments attached.',
                    style: TextStyle(color: AppTheme.muted),
                  )
                else
                  ...note.heroChanges.map(
                    (change) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HeroChangeRow(change: change),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroChangeRail extends StatelessWidget {
  const _HeroChangeRail({required this.changes});

  final List<PatchHeroChange> changes;

  @override
  Widget build(BuildContext context) {
    if (changes.isEmpty) {
      return const _ChangeChip(label: 'No hero changes', changeType: 'adjust');
    }

    return SizedBox(
      height: 46,
      child: Scrollbar(
        thumbVisibility: changes.length > 6,
        thickness: 3,
        radius: const Radius.circular(99),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: changes.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) =>
              _HeroChangeAvatar(change: changes[index]),
        ),
      ),
    );
  }
}

class _HeroChangeAvatar extends StatelessWidget {
  const _HeroChangeAvatar({required this.change});

  final PatchHeroChange change;

  @override
  Widget build(BuildContext context) {
    final route = change.heroId > 0
        ? '/heroes/${change.heroId}?tab=history'
        : null;
    final child = Tooltip(
      message: '${change.heroName} (${change.changeType})',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppImage(
            url: change.avatarUrl,
            width: 38,
            height: 38,
            borderRadius: 19,
            semanticLabel: change.heroName,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: _ChangeDirectionBadge(changeType: change.changeType),
          ),
        ],
      ),
    );
    if (route == null) {
      return child;
    }
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => context.go(route),
      child: child,
    );
  }
}

class _ChangeDirectionBadge extends StatelessWidget {
  const _ChangeDirectionBadge({required this.changeType});

  final String changeType;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (changeType) {
      'buff' => (Icons.arrow_upward_rounded, AppTheme.success),
      'nerf' => (Icons.arrow_downward_rounded, AppTheme.error),
      _ => (Icons.remove_rounded, AppTheme.muted),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }
}

class _HeroChangeRow extends StatelessWidget {
  const _HeroChangeRow({required this.change});

  final PatchHeroChange change;

  @override
  Widget build(BuildContext context) {
    final route = change.heroId > 0
        ? '/heroes/${change.heroId}?tab=history'
        : null;
    final row = DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AppImage(
              url: change.avatarUrl,
              width: 40,
              height: 40,
              borderRadius: 12,
              semanticLabel: change.heroName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                change.heroName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ChangeChip(
              label: change.changeType,
              changeType: change.changeType,
            ),
          ],
        ),
      ),
    );

    if (route == null) {
      return row;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(route),
        child: row,
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          version == '-' ? 'Version' : 'V$version',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({
    required this.label,
    required this.changeType,
    this.route,
  });

  final String label;
  final String changeType;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final color = switch (changeType) {
      'buff' => const Color(0xFF4ADE80),
      'nerf' => const Color(0xFFFB7185),
      _ => AppTheme.gold,
    };

    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    final destination = route;
    if (destination == null) {
      return chip;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go(destination),
      child: chip,
    );
  }
}
