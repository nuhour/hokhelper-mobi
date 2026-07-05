import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/regions.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/search_repository.dart';
import '../domain/search_result.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(apiClient: ref.watch(apiClientProvider));
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Future<List<SearchResultGroup>>? _searchFuture;
  String _lastQuery = '';

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
    return Material(
      color: AppTheme.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const AppSectionHeader(title: 'Global Search'),
          const SizedBox(height: 8),
          Text(
            'Search heroes, builds, guides, and community content from the HOK portal.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(color: AppTheme.text),
            decoration: InputDecoration(
              hintText: 'Search HOK Helper',
              prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
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
                      _SearchGroupCard(group: group),
                      const SizedBox(height: 14),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SearchGroupCard extends StatelessWidget {
  const _SearchGroupCard({required this.group});

  final SearchResultGroup group;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in group.items) ...[
              _SearchResultTile(item: item),
              if (item != group.items.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.chevron_right, color: AppTheme.gold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (item.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
