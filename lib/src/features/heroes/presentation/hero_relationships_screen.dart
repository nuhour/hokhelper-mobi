import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
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

enum _RelationshipViewMode { global, focus }

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
  String _focusedHero = '';
  _RelationshipViewMode _viewMode = _RelationshipViewMode.global;
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
          if (relationships.isEmpty) {
            return const AppEmptyState(
              icon: Icons.hub_outlined,
              title: 'No relationships found',
              message: 'Pull to refresh and load the hero network again.',
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: _HeroRelationshipNetwork(
                  relationships: relationships,
                  heroes: graphHeroes,
                  focusedHero: _focusedHero,
                  viewMode: _viewMode,
                  expand: true,
                  onHeroSelected: (heroName) {
                    setState(() {
                      _focusedHero = heroName;
                      _viewMode = _RelationshipViewMode.focus;
                    });
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _NetworkModeControls(
                    viewMode: _viewMode,
                    onViewModeChanged: (mode) {
                      setState(() {
                        if (mode == _RelationshipViewMode.focus &&
                            _focusedHero.isEmpty) {
                          _focusedHero = _randomFocusHero(relationships);
                        }
                        _viewMode = mode;
                      });
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
    }
  }

  String _randomFocusHero(List<HeroRelationship> relationships) {
    final heroes = <String>{
      for (final relationship in relationships) ...[
        if (relationship.sourceHeroName.isNotEmpty)
          relationship.sourceHeroName
        else
          relationship.sourceHeroId,
        if (relationship.targetHeroName.isNotEmpty)
          relationship.targetHeroName
        else
          relationship.targetHeroId,
      ],
    }.where((hero) => hero.isNotEmpty).toList(growable: false);
    if (heroes.isEmpty) {
      return '';
    }
    return heroes[math.Random().nextInt(heroes.length)];
  }
}

class _NetworkModeControls extends StatelessWidget {
  const _NetworkModeControls({
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final _RelationshipViewMode viewMode;
  final ValueChanged<_RelationshipViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: SegmentedButton<_RelationshipViewMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: _RelationshipViewMode.focus,
              icon: Icon(Icons.center_focus_strong_rounded),
              label: Text('Focus'),
            ),
            ButtonSegment(
              value: _RelationshipViewMode.global,
              icon: Icon(Icons.hub_outlined),
              label: Text('Global'),
            ),
          ],
          selected: {viewMode},
          onSelectionChanged: (value) => onViewModeChanged(value.first),
        ),
      ),
    );
  }
}

class _HeroRelationshipNetwork extends StatefulWidget {
  const _HeroRelationshipNetwork({
    required this.relationships,
    required this.heroes,
    required this.focusedHero,
    required this.viewMode,
    required this.onHeroSelected,
    this.expand = false,
  });

  final List<HeroRelationship> relationships;
  final List<HeroSummary> heroes;
  final String focusedHero;
  final _RelationshipViewMode viewMode;
  final ValueChanged<String> onHeroSelected;
  final bool expand;

  @override
  State<_HeroRelationshipNetwork> createState() =>
      _HeroRelationshipNetworkState();
}

class _HeroRelationshipNetworkState extends State<_HeroRelationshipNetwork> {
  final _viewerKey = GlobalKey();
  final _controller = TransformationController();
  var _canvasSize = 720.0;

  @override
  void initState() {
    super.initState();
    _scheduleFit();
  }

  @override
  void didUpdateWidget(covariant _HeroRelationshipNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode ||
        oldWidget.focusedHero != widget.focusedHero ||
        oldWidget.relationships.length != widget.relationships.length) {
      _scheduleFit();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox =
          _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;
      final viewport = renderBox.size;
      final scale = math
          .min(
            (viewport.width - 18) / _canvasSize,
            (viewport.height - 18) / _canvasSize,
          )
          .clamp(0.3, 1.0);
      final dx = (viewport.width - _canvasSize * scale) / 2;
      final dy = (viewport.height - _canvasSize * scale) / 2;
      _controller.value = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = _RelationshipNetworkLayout.create(
      relationships: widget.relationships,
      heroes: widget.heroes,
      focusedHero: widget.focusedHero,
      viewMode: widget.viewMode,
    );
    _canvasSize = layout.canvasSize;
    final content = KeyedSubtree(
      key: ValueKey('relationship-network-${widget.viewMode.name}'),
      child: SizedBox(
        key: _viewerKey,
        child: ClipRRect(
          borderRadius: widget.expand
              ? BorderRadius.zero
              : BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF030712)),
            child: InteractiveViewer(
              transformationController: _controller,
              constrained: false,
              minScale: 0.25,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(160),
              child: SizedBox(
                width: layout.canvasSize,
                height: layout.canvasSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RelationshipNetworkPainter(layout: layout),
                      ),
                    ),
                    for (final node in layout.nodes)
                      Positioned(
                        left: node.position.dx - 38,
                        top: node.position.dy - node.size / 2,
                        width: 76,
                        child: _RelationshipAvatarNode(
                          node: node,
                          onTap: () => widget.onHeroSelected(node.name),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.expand) {
      return SizedBox.expand(child: content);
    }
    return SizedBox(
      height: widget.viewMode == _RelationshipViewMode.global ? 340 : 360,
      child: content,
    );
  }
}

class _RelationshipNetworkLayout {
  const _RelationshipNetworkLayout({
    required this.canvasSize,
    required this.nodes,
    required this.edges,
  });

  final double canvasSize;
  final List<_ChainNode> nodes;
  final List<_NetworkEdge> edges;

  factory _RelationshipNetworkLayout.create({
    required List<HeroRelationship> relationships,
    required List<HeroSummary> heroes,
    required String focusedHero,
    required _RelationshipViewMode viewMode,
  }) {
    final heroById = <String, HeroSummary>{
      for (final hero in heroes) ...{
        hero.id: hero,
        if (hero.heroId.isNotEmpty) hero.heroId: hero,
      },
    };
    final metadata = <String, _NetworkHeroMeta>{};
    void registerNode(String id, String name) {
      final key = _relationshipKey(id, name);
      final hero = heroById[id];
      metadata.putIfAbsent(
        key,
        () => _NetworkHeroMeta(
          key: key,
          name: name.isNotEmpty ? name : hero?.name ?? id,
          avatar: hero?.avatar ?? '',
        ),
      );
    }

    for (final relationship in relationships) {
      registerNode(relationship.sourceHeroId, relationship.sourceHeroName);
      registerNode(relationship.targetHeroId, relationship.targetHeroName);
    }
    final allEdges = [
      for (final relationship in relationships)
        _NetworkEdge(
          sourceKey: _relationshipKey(
            relationship.sourceHeroId,
            relationship.sourceHeroName,
          ),
          targetKey: _relationshipKey(
            relationship.targetHeroId,
            relationship.targetHeroName,
          ),
          color: _relationshipColor(relationship.title),
        ),
    ];
    final allKeys = metadata.keys.toList()..sort();
    if (allKeys.isEmpty) {
      return const _RelationshipNetworkLayout(
        canvasSize: 720,
        nodes: [],
        edges: [],
      );
    }

    final focusKey = allKeys.firstWhere(
      (key) => metadata[key]!.name.toLowerCase() == focusedHero.toLowerCase(),
      orElse: () => allKeys.first,
    );
    if (viewMode == _RelationshipViewMode.global) {
      final canvasSize = math
          .max(720, (math.sqrt(allKeys.length) * 120 + 250).ceil())
          .toDouble();
      final center = Offset(canvasSize / 2, canvasSize / 2);
      final goldenAngle = math.pi * (3 - math.sqrt(5));
      final nodes = [
        for (var index = 0; index < allKeys.length; index++)
          _ChainNode(
            key: allKeys[index],
            name: metadata[allKeys[index]]!.name,
            avatar: metadata[allKeys[index]]!.avatar,
            position:
                center +
                Offset.fromDirection(
                  index * goldenAngle,
                  38 * math.sqrt(index),
                ),
            size: 32,
            showLabel: false,
            highlighted: allKeys[index] == focusKey,
          ),
      ];
      return _RelationshipNetworkLayout(
        canvasSize: canvasSize,
        nodes: nodes,
        edges: allEdges,
      );
    }

    final direct = <String>{
      for (final edge in allEdges)
        if (edge.sourceKey == focusKey)
          edge.targetKey
        else if (edge.targetKey == focusKey)
          edge.sourceKey,
    }..remove(focusKey);
    final secondary = <String>{};
    for (final edge in allEdges) {
      if (direct.contains(edge.sourceKey) && edge.targetKey != focusKey) {
        secondary.add(edge.targetKey);
      }
      if (direct.contains(edge.targetKey) && edge.sourceKey != focusKey) {
        secondary.add(edge.sourceKey);
      }
    }
    secondary
      ..removeAll(direct)
      ..remove(focusKey);
    final directKeys = direct.toList()..sort();
    final secondaryKeys = secondary.take(14).toList()..sort();
    const canvasSize = 760.0;
    const center = Offset(380, 380);
    final nodes = <_ChainNode>[
      _ChainNode(
        key: focusKey,
        name: metadata[focusKey]!.name,
        avatar: metadata[focusKey]!.avatar,
        position: center,
        size: 76,
        showLabel: true,
        highlighted: true,
      ),
      for (var index = 0; index < directKeys.length; index++)
        _ChainNode(
          key: directKeys[index],
          name: metadata[directKeys[index]]!.name,
          avatar: metadata[directKeys[index]]!.avatar,
          position:
              center +
              Offset.fromDirection(
                -math.pi / 2 +
                    index * math.pi * 2 / math.max(1, directKeys.length),
                176,
              ),
          size: 52,
          showLabel: true,
          highlighted: false,
        ),
      for (var index = 0; index < secondaryKeys.length; index++)
        _ChainNode(
          key: secondaryKeys[index],
          name: metadata[secondaryKeys[index]]!.name,
          avatar: metadata[secondaryKeys[index]]!.avatar,
          position:
              center +
              Offset.fromDirection(
                -math.pi / 2 +
                    index * math.pi * 2 / math.max(1, secondaryKeys.length),
                294,
              ),
          size: 36,
          showLabel: false,
          highlighted: false,
        ),
    ];
    final visibleKeys = nodes.map((node) => node.key).toSet();
    return _RelationshipNetworkLayout(
      canvasSize: canvasSize,
      nodes: nodes,
      edges: allEdges
          .where(
            (edge) =>
                visibleKeys.contains(edge.sourceKey) &&
                visibleKeys.contains(edge.targetKey),
          )
          .toList(growable: false),
    );
  }
}

class _NetworkHeroMeta {
  const _NetworkHeroMeta({
    required this.key,
    required this.name,
    required this.avatar,
  });

  final String key;
  final String name;
  final String avatar;
}

class _ChainNode {
  const _ChainNode({
    required this.key,
    required this.name,
    required this.avatar,
    required this.position,
    required this.size,
    required this.showLabel,
    required this.highlighted,
  });

  final String key;
  final String name;
  final String avatar;
  final Offset position;
  final double size;
  final bool showLabel;
  final bool highlighted;
}

class _NetworkEdge {
  const _NetworkEdge({
    required this.sourceKey,
    required this.targetKey,
    required this.color,
  });

  final String sourceKey;
  final String targetKey;
  final Color color;
}

String _relationshipKey(String heroId, String heroName) {
  final id = heroId.trim();
  if (id.isNotEmpty) return 'id:$id';
  return 'name:${heroName.trim().toLowerCase()}';
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
  const _RelationshipAvatarNode({required this.node, required this.onTap});

  final _ChainNode node;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final avatarSize = node.size;
    return Semantics(
      button: true,
      label: node.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 76,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: node.highlighted ? AppTheme.cyan : AppTheme.muted,
                      width: node.highlighted ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyan.withValues(
                          alpha: node.highlighted ? 0.52 : 0.18,
                        ),
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
                                      color: AppTheme.cyan,
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
                if (node.showLabel) ...[
                  const SizedBox(height: 3),
                  Text(
                    node.name.isEmpty ? 'Unknown' : node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationshipNetworkPainter extends CustomPainter {
  const _RelationshipNetworkPainter({required this.layout});

  final _RelationshipNetworkLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final nodePositions = {
      for (final node in layout.nodes) node.key: node.position,
    };
    final nodeLookup = {for (final node in layout.nodes) node.key: node};
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.16);
    for (var index = 0; index < 84; index++) {
      final x = (math.sin(index * 83.7) * 0.5 + 0.5) * size.width;
      final y = (math.cos(index * 47.3) * 0.5 + 0.5) * size.height;
      canvas.drawCircle(Offset(x, y), index.isEven ? 1.1 : 0.65, starPaint);
    }
    for (final edge in layout.edges) {
      final source = nodePositions[edge.sourceKey];
      final target = nodePositions[edge.targetKey];
      if (source == null || target == null) continue;
      final sourceNode = nodeLookup[edge.sourceKey];
      final targetNode = nodeLookup[edge.targetKey];
      final connectedToFocus =
          sourceNode?.highlighted == true || targetNode?.highlighted == true;
      final paint = Paint()
        ..color = edge.color.withValues(alpha: connectedToFocus ? 0.84 : 0.34)
        ..strokeWidth = connectedToFocus ? 2.3 : 1.1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(source, target, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RelationshipNetworkPainter oldDelegate) {
    return oldDelegate.layout != layout;
  }
}
