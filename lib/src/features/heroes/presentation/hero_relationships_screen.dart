import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/hero_relationship.dart';
import '../domain/hero_summary.dart';
import 'hero_gallery_screen.dart';

final heroRelationshipsProvider = FutureProvider<List<HeroRelationship>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(heroesRepositoryProvider)
      .loadHeroRelationships(settings.region.regionId);
});

final relationshipGraphHeroesProvider = FutureProvider<List<HeroSummary>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(heroesRepositoryProvider)
      .loadHeroes(settings.region.regionId, pageSize: 200);
});

class HeroRelationshipsScreen extends ConsumerStatefulWidget {
  const HeroRelationshipsScreen({
    this.initialHeroId,
    this.initialHeroName,
    super.key,
  });

  final String? initialHeroId;
  final String? initialHeroName;

  @override
  ConsumerState<HeroRelationshipsScreen> createState() =>
      _HeroRelationshipsScreenState();
}

class _HeroRelationshipsScreenState
    extends ConsumerState<HeroRelationshipsScreen> {
  String _query = '';
  String _focusedHero = '';
  bool _didResolveInitialFocus = false;

  @override
  void didUpdateWidget(covariant HeroRelationshipsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHeroId != widget.initialHeroId ||
        oldWidget.initialHeroName != widget.initialHeroName) {
      _didResolveInitialFocus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final relationshipsValue = ref.watch(heroRelationshipsProvider);
    final graphHeroes =
        ref.watch(relationshipGraphHeroesProvider).valueOrNull ??
        const <HeroSummary>[];

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<List<HeroRelationship>>(
        value: relationshipsValue,
        retry: () => ref.invalidate(heroRelationshipsProvider),
        data: (rawRelationships) {
          final relationships = _withHeroNames(rawRelationships, graphHeroes);
          _resolveInitialFocus(relationships);
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
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _RelationshipChainBoard(
                            relationships: visibleRelationships,
                            heroes: graphHeroes,
                            focusedHero: _focusedHero,
                            onHeroSelected: (heroName) {
                              setState(() {
                                _focusedHero = heroName;
                                _query = '';
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          ...visibleRelationships.map(
                            (relationship) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RelationshipCard(
                                relationship: relationship,
                                focusedHero: _focusedHero,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  List<HeroRelationship> _withHeroNames(
    List<HeroRelationship> relationships,
    List<HeroSummary> heroes,
  ) {
    if (heroes.isEmpty) {
      return relationships;
    }

    final heroesById = <String, HeroSummary>{
      for (final hero in heroes) ...{
        hero.id: hero,
        if (hero.heroId.isNotEmpty) hero.heroId: hero,
      },
    };
    return relationships
        .map(
          (relationship) => relationship.withHeroNames(
            sourceHeroName:
                heroesById[relationship.sourceHeroId]?.name.isNotEmpty == true
                ? heroesById[relationship.sourceHeroId]?.name
                : null,
            targetHeroName:
                heroesById[relationship.targetHeroId]?.name.isNotEmpty == true
                ? heroesById[relationship.targetHeroId]?.name
                : null,
          ),
        )
        .toList(growable: false);
  }

  void _resolveInitialFocus(List<HeroRelationship> relationships) {
    if (_didResolveInitialFocus || relationships.isEmpty) {
      return;
    }

    final heroId = widget.initialHeroId?.trim();
    final heroName = widget.initialHeroName?.trim();
    String focusedHero = '';

    if (heroId != null && heroId.isNotEmpty) {
      for (final relationship in relationships) {
        if (relationship.sourceHeroId == heroId) {
          focusedHero = relationship.sourceHeroName;
          break;
        }
        if (relationship.targetHeroId == heroId) {
          focusedHero = relationship.targetHeroName;
          break;
        }
      }
    }

    if (focusedHero.isEmpty && heroName != null && heroName.isNotEmpty) {
      for (final relationship in relationships) {
        if (relationship.sourceHeroName.toLowerCase() ==
            heroName.toLowerCase()) {
          focusedHero = relationship.sourceHeroName;
          break;
        }
        if (relationship.targetHeroName.toLowerCase() ==
            heroName.toLowerCase()) {
          focusedHero = relationship.targetHeroName;
          break;
        }
      }
    }

    _didResolveInitialFocus = true;
    if (focusedHero.isNotEmpty) {
      _focusedHero = focusedHero;
      _query = '';
    }
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

class _RelationshipChainBoard extends StatelessWidget {
  const _RelationshipChainBoard({
    required this.relationships,
    required this.heroes,
    required this.focusedHero,
    required this.onHeroSelected,
  });

  final List<HeroRelationship> relationships;
  final List<HeroSummary> heroes;
  final String focusedHero;
  final ValueChanged<String> onHeroSelected;

  @override
  Widget build(BuildContext context) {
    final focus = focusedHero.isNotEmpty
        ? focusedHero
        : relationships.first.sourceHeroName.isNotEmpty
        ? relationships.first.sourceHeroName
        : relationships.first.sourceHeroId;
    final directLinks = relationships
        .where((relationship) => relationship.involves(focus))
        .toList(growable: false);
    final displayLinks = (directLinks.isNotEmpty ? directLinks : relationships)
        .take(6)
        .toList(growable: false);
    final heroesByName = <String, HeroSummary>{
      for (final hero in heroes) hero.name.toLowerCase(): hero,
    };
    final centerHero = heroesByName[focus.toLowerCase()];
    final nodes = displayLinks
        .map((link) => _ChainNode.fromRelationship(link, focus, heroesByName))
        .where((node) => node.name.isNotEmpty)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, color: AppTheme.cyan),
              const SizedBox(width: 8),
              Text(
                'Relationship Chain',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                'Linked heroes: ${nodes.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 276,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, 276);
                final center = Offset(size.width / 2, 138);
                final radius = math.min(size.width * 0.36, 98.0);
                final positions = <Offset>[
                  for (var index = 0; index < nodes.length; index++)
                    Offset(
                      center.dx +
                          math.cos(
                                -math.pi / 2 +
                                    index * (math.pi * 2 / nodes.length),
                              ) *
                              radius,
                      center.dy +
                          math.sin(
                                -math.pi / 2 +
                                    index * (math.pi * 2 / nodes.length),
                              ) *
                              radius,
                    ),
                ];

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RelationshipChainPainter(
                          center: center,
                          nodes: positions,
                          colors: [for (final node in nodes) node.color],
                        ),
                      ),
                    ),
                    for (var index = 0; index < nodes.length; index++)
                      Positioned(
                        left: positions[index].dx - 35,
                        top: positions[index].dy - 42,
                        child: _RelationshipAvatarNode(
                          node: nodes[index],
                          compact: true,
                          onTap: () => onHeroSelected(nodes[index].name),
                        ),
                      ),
                    Positioned(
                      left: center.dx - 48,
                      top: center.dy - 54,
                      child: _RelationshipAvatarNode(
                        node: _ChainNode(
                          name: focus,
                          avatar: centerHero?.avatar ?? '',
                          color: AppTheme.cyan,
                        ),
                        onTap: () => onHeroSelected(focus),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainNode {
  const _ChainNode({
    required this.name,
    required this.avatar,
    required this.color,
  });

  final String name;
  final String avatar;
  final Color color;

  factory _ChainNode.fromRelationship(
    HeroRelationship relationship,
    String focus,
    Map<String, HeroSummary> heroesByName,
  ) {
    final name = relationship.involves(focus)
        ? relationship.otherHeroName(focus)
        : relationship.targetHeroName.isNotEmpty
        ? relationship.targetHeroName
        : relationship.targetHeroId;
    return _ChainNode(
      name: name,
      avatar: heroesByName[name.toLowerCase()]?.avatar ?? '',
      color: _relationshipColor(relationship.title),
    );
  }
}

Color _relationshipColor(String title) {
  final value = title.toLowerCase();
  if (value.contains('enemy') || value.contains('rival')) return AppTheme.error;
  if (value.contains('family') || value.contains('mentor')) {
    return AppTheme.gold;
  }
  if (value.contains('friend') || value.contains('ally')) {
    return AppTheme.success;
  }
  return AppTheme.cyan;
}

class _RelationshipAvatarNode extends StatelessWidget {
  const _RelationshipAvatarNode({
    required this.node,
    required this.onTap,
    this.compact = false,
  });

  final _ChainNode node;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 48.0 : 72.0;
    final labelWidth = compact ? 70.0 : 96.0;
    return Semantics(
      button: true,
      label: node.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: labelWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: node.color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: node.color.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: node.avatar.isEmpty
                        ? ColoredBox(
                            color: AppTheme.bg,
                            child: Center(
                              child: Text(
                                node.name.isEmpty ? '?' : node.name[0],
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: node.color,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          )
                        : AppImage(
                            url: node.avatar,
                            width: avatarSize,
                            height: avatarSize,
                            borderRadius: avatarSize / 2,
                          ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  node.name.isEmpty ? 'Unknown' : node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationshipChainPainter extends CustomPainter {
  const _RelationshipChainPainter({
    required this.center,
    required this.nodes,
    required this.colors,
  });

  final Offset center;
  final List<Offset> nodes;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < nodes.length; index++) {
      final color = colors[index];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.65)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, nodes[index], paint);
      canvas.drawCircle(nodes[index], 4, Paint()..color = color);
    }
    canvas.drawCircle(
      center,
      42,
      Paint()
        ..color = AppTheme.cyan.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _RelationshipChainPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.nodes != nodes ||
        oldDelegate.colors != colors;
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
