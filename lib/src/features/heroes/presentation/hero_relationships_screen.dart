import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/hero_relationship.dart';
import 'hero_gallery_screen.dart';

final heroRelationshipsProvider = FutureProvider<List<HeroRelationship>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(heroesRepositoryProvider)
      .loadHeroRelationships(settings.region.regionId);
});

class HeroRelationshipsScreen extends ConsumerStatefulWidget {
  const HeroRelationshipsScreen({super.key});

  @override
  ConsumerState<HeroRelationshipsScreen> createState() =>
      _HeroRelationshipsScreenState();
}

class _HeroRelationshipsScreenState
    extends ConsumerState<HeroRelationshipsScreen> {
  String _query = '';
  String _focusedHero = '';

  @override
  Widget build(BuildContext context) {
    final relationshipsValue = ref.watch(heroRelationshipsProvider);

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<List<HeroRelationship>>(
        value: relationshipsValue,
        retry: () => ref.invalidate(heroRelationshipsProvider),
        data: (relationships) {
          final heroNames = _collectHeroNames(relationships);
          final visibleRelationships = _filterRelationships(relationships);

          return RefreshIndicator(
            onRefresh: () => ref.refresh(heroRelationshipsProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(title: 'Hero Relationships'),
                        const SizedBox(height: 8),
                        Text(
                          'Explore lore links, rivalries, and ally networks.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                              _focusedHero = '';
                            });
                          },
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search heroes or relationship titles',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RelationshipSummary(
                          total: relationships.length,
                          visible: visibleRelationships.length,
                          focusedHero: _focusedHero,
                        ),
                        if (heroNames.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _HeroFocusRail(
                            heroNames: heroNames,
                            focusedHero: _focusedHero,
                            onSelected: (name) {
                              setState(() {
                                _focusedHero = _focusedHero == name ? '' : name;
                                _query = '';
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (relationships.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.hub_outlined,
                      title: 'No relationships found',
                      message:
                          'Pull to refresh and load the hero network again.',
                    ),
                  )
                else if (visibleRelationships.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No matching links',
                      message: 'Try a different hero name or clear the focus.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: visibleRelationships.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _RelationshipCard(
                          relationship: visibleRelationships[index],
                          focusedHero: _focusedHero,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<HeroRelationship> _filterRelationships(
    List<HeroRelationship> relationships,
  ) {
    final query = _query.trim().toLowerCase();

    return relationships
        .where((relationship) {
          if (_focusedHero.isNotEmpty && !relationship.involves(_focusedHero)) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          final haystack = [
            relationship.sourceHeroName,
            relationship.targetHeroName,
            relationship.title,
            relationship.description,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  List<String> _collectHeroNames(List<HeroRelationship> relationships) {
    final names = <String>{};
    for (final relationship in relationships) {
      if (relationship.sourceHeroName.isNotEmpty) {
        names.add(relationship.sourceHeroName);
      }
      if (relationship.targetHeroName.isNotEmpty) {
        names.add(relationship.targetHeroName);
      }
    }

    return names.toList()..sort();
  }
}

class _RelationshipSummary extends StatelessWidget {
  const _RelationshipSummary({
    required this.total,
    required this.visible,
    required this.focusedHero,
  });

  final int total;
  final int visible;
  final String focusedHero;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.muted.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$total links',
            style: textTheme.titleMedium?.copyWith(
              color: AppTheme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            focusedHero.isEmpty
                ? '$visible currently visible'
                : 'Focused: $focusedHero',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _HeroFocusRail extends StatelessWidget {
  const _HeroFocusRail({
    required this.heroNames,
    required this.focusedHero,
    required this.onSelected,
  });

  final List<String> heroNames;
  final String focusedHero;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: heroNames.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final heroName = heroNames[index];
          final selected = heroName == focusedHero;

          return ChoiceChip(
            label: Text(heroName),
            selected: selected,
            onSelected: (_) => onSelected(heroName),
          );
        },
      ),
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({
    required this.relationship,
    required this.focusedHero,
  });

  final HeroRelationship relationship;
  final String focusedHero;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = relationship.title.isEmpty
        ? 'Relationship #${relationship.id}'
        : relationship.title;
    final counterpart = focusedHero.isEmpty
        ? null
        : relationship.otherHeroName(focusedHero);

    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _WeightBadge(weight: relationship.weight),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _HeroNamePill(
                  name: relationship.sourceHeroName,
                  heroId: relationship.sourceHeroId,
                ),
                const Icon(Icons.sync_alt, color: AppTheme.muted, size: 18),
                _HeroNamePill(
                  name: relationship.targetHeroName,
                  heroId: relationship.targetHeroId,
                ),
              ],
            ),
            if (counterpart != null && counterpart.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Connected with $counterpart',
                style: textTheme.bodySmall?.copyWith(color: AppTheme.cyan),
              ),
            ],
            if (relationship.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                relationship.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroNamePill extends StatelessWidget {
  const _HeroNamePill({required this.name, required this.heroId});

  final String name;
  final String heroId;

  @override
  Widget build(BuildContext context) {
    final trimmedHeroId = heroId.trim();
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name.isEmpty ? 'Unknown hero' : name,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.cyan,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (trimmedHeroId.isEmpty) {
      return pill;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.go('/heroes/$trimmedHeroId'),
        child: pill,
      ),
    );
  }
}

class _WeightBadge extends StatelessWidget {
  const _WeightBadge({required this.weight});

  final int weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        weight <= 0 ? 'Link' : '$weight',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.gold,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
