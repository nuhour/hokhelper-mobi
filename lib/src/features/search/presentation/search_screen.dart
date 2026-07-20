import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/regions.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/portal_link.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/search_repository.dart';
import '../domain/search_result.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(apiClient: ref.watch(apiClientProvider));
});

Future<void> showPortalSearchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.66),
    builder: (context) => const _PortalSearchSheet(),
  );
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({this.initialQuery, super.key});

  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.hokTheme.backgroundDeep,
      child: _SearchContent(initialQuery: initialQuery),
    );
  }
}

class _PortalSearchSheet extends StatelessWidget {
  const _PortalSearchSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.hokTheme.surfaceSlate,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.hokTheme.onSurfaceMuted.withValues(
                      alpha: 0.48,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Global Search',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceStrong,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close search',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: context.hokTheme.onSurfaceMuted,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.hokTheme.outlineSoft),
                Expanded(
                  child: _SearchContent(
                    scrollController: scrollController,
                    compact: true,
                    autofocus: true,
                    closeBeforeOpening: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchContent extends ConsumerStatefulWidget {
  const _SearchContent({
    this.initialQuery,
    this.scrollController,
    this.compact = false,
    this.autofocus = false,
    this.closeBeforeOpening = false,
  });

  final String? initialQuery;
  final ScrollController? scrollController;
  final bool compact;
  final bool autofocus;
  final bool closeBeforeOpening;

  @override
  ConsumerState<_SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends ConsumerState<_SearchContent> {
  final _controller = TextEditingController();
  Future<List<SearchResultGroup>>? _searchFuture;
  String _lastQuery = '';
  var _didRunInitialQuery = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _controller.text = initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }

    final settings = ref.read(appSettingsControllerProvider).valueOrNull;
    final regionId = settings?.region.id ?? 2;
    setState(() {
      _lastQuery = query;
      _searchFuture = ref
          .read(searchRepositoryProvider)
          .search(query, regionId)
          .then(parseSearchResultGroups);
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialQuery = widget.initialQuery?.trim() ?? '';
    if (!_didRunInitialQuery && initialQuery.isNotEmpty) {
      _didRunInitialQuery = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _submit();
        }
      });
    }

    return ListView(
      controller: widget.scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: widget.compact
          ? const EdgeInsets.fromLTRB(18, 12, 18, 28)
          : const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        if (!widget.compact) ...[
          const AppSectionHeader(title: 'Global Search'),
          const SizedBox(height: 8),
          Text(
            'Search heroes, builds, guides, and community content from the HOK portal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.hokTheme.onSurfaceMuted,
            ),
          ),
        ] else
          Text(
            'Search heroes, builds, guides, and community content.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.hokTheme.onSurfaceMuted,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          style: TextStyle(color: context.hokTheme.onSurfaceStrong),
          decoration: InputDecoration(
            hintText: 'Search HOK Helper',
            prefixIcon: Icon(
              Icons.search,
              color: context.hokTheme.onSurfaceMuted,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward, color: AppTheme.gold),
              onPressed: _submit,
              tooltip: 'Search',
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_searchFuture == null)
          const AppEmptyState(
            icon: Icons.manage_search_outlined,
            title: 'Search the portal',
            message:
                'Enter a hero, build, guide, player, or community keyword.',
          )
        else
          FutureBuilder<List<SearchResultGroup>>(
            future: _searchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Search failed',
                  message: snapshot.error.toString(),
                );
              }

              final groups = snapshot.data ?? const [];
              if (groups.isEmpty) {
                return AppEmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'No results found',
                  message: 'No portal content matched "$_lastQuery".',
                );
              }

              return Column(
                children: [
                  for (final group in groups) ...[
                    _SearchGroupCard(
                      group: group,
                      closeBeforeOpening: widget.closeBeforeOpening,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SearchGroupCard extends StatelessWidget {
  const _SearchGroupCard({
    required this.group,
    this.closeBeforeOpening = false,
  });

  final SearchResultGroup group;
  final bool closeBeforeOpening;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hokTheme.outlineSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.title} (${group.items.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.hokTheme.onSurfaceStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in group.items) ...[
              _SearchResultTile(
                item: item,
                closeBeforeOpening: closeBeforeOpening,
              ),
              if (item != group.items.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    this.closeBeforeOpening = false,
  });

  final SearchResultItem item;
  final bool closeBeforeOpening;

  void _open(BuildContext context, String url) {
    if (!closeBeforeOpening) {
      _openSearchResult(context, url);
      return;
    }

    final router = GoRouter.of(context);
    Navigator.of(context, rootNavigator: true).pop();
    _openSearchResultWithRouter(router, url);
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = item.url.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canOpen ? () => _open(context, item.url) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl.isNotEmpty)
                AppImage(
                  url: item.imageUrl,
                  width: 40,
                  height: 40,
                  borderRadius: 10,
                  semanticLabel: item.title,
                )
              else
                const Icon(Icons.chevron_right, color: AppTheme.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.hokTheme.onSurfaceStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.hokTheme.onSurfaceMuted,
                        ),
                      ),
                    ],
                    if (item.actions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final action in item.actions)
                            OutlinedButton(
                              onPressed: () => _open(context, action.url),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                foregroundColor: AppTheme.gold,
                                side: BorderSide(
                                  color: AppTheme.gold.withValues(alpha: 0.35),
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              child: Text(action.label),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (canOpen) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.open_in_new,
                  color: context.hokTheme.onSurfaceMuted,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _openSearchResult(BuildContext context, String url) {
  _openSearchResultWithRouter(GoRouter.of(context), url);
}

void _openSearchResultWithRouter(GoRouter router, String url) {
  final target = normalizePortalLinkTarget(url);
  if (target.startsWith('/')) {
    router.go(target);
    return;
  }

  router.push(externalLinkRoute(target));
}
