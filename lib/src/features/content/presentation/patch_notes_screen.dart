import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../domain/patch_note_summary.dart';
import 'content_screen.dart';

const _patchNotesPageSize = 120;

class PatchNotesScreen extends ConsumerStatefulWidget {
  const PatchNotesScreen({super.key});

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
                final allItems = [...items, ..._extraNotes];
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
                _HeroChangeWrap(changes: note.heroChanges),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatchDetailSheet extends StatelessWidget {
  const _PatchDetailSheet({required this.note});

  final PatchNoteSummary note;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return ListView(
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
                Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.text,
                    height: 1.45,
                  ),
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
          );
        },
      ),
    );
  }
}

class _HeroChangeWrap extends StatelessWidget {
  const _HeroChangeWrap({required this.changes});

  final List<PatchHeroChange> changes;

  @override
  Widget build(BuildContext context) {
    if (changes.isEmpty) {
      return const _ChangeChip(label: 'No hero changes', changeType: 'adjust');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final change in changes.take(6))
          _ChangeChip(label: change.heroName, changeType: change.changeType),
        if (changes.length > 6)
          _ChangeChip(label: '+${changes.length - 6}', changeType: 'adjust'),
      ],
    );
  }
}

class _HeroChangeRow extends StatelessWidget {
  const _HeroChangeRow({required this.change});

  final PatchHeroChange change;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
  const _ChangeChip({required this.label, required this.changeType});

  final String label;
  final String changeType;

  @override
  Widget build(BuildContext context) {
    final color = switch (changeType) {
      'buff' => const Color(0xFF4ADE80),
      'nerf' => const Color(0xFFFB7185),
      _ => AppTheme.gold,
    };

    return DecoratedBox(
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
  }
}
