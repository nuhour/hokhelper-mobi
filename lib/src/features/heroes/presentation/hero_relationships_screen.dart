import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';

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
      color: context.hokTheme.backgroundDeep,
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
            fit: StackFit.expand,
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
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
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
    final degrees = <String, int>{};
    for (final relationship in relationships) {
      final source = relationship.sourceHeroName.isNotEmpty
          ? relationship.sourceHeroName
          : relationship.sourceHeroId;
      final target = relationship.targetHeroName.isNotEmpty
          ? relationship.targetHeroName
          : relationship.targetHeroId;
      if (source.isNotEmpty) degrees[source] = (degrees[source] ?? 0) + 1;
      if (target.isNotEmpty) degrees[target] = (degrees[target] ?? 0) + 1;
    }
    if (degrees.isEmpty) {
      return '';
    }
    final connectedHeroes = degrees.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final candidates = connectedHeroes
        .take(math.min(12, math.max(1, connectedHeroes.length ~/ 4)))
        .map((entry) => entry.key)
        .toList(growable: false);
    return candidates[math.Random().nextInt(candidates.length)];
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
    return IntrinsicWidth(
      child: DecoratedBox(
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

class _HeroRelationshipNetworkState extends State<_HeroRelationshipNetwork>
    with TickerProviderStateMixin {
  final _viewerKey = GlobalKey();
  final _controller = TransformationController();
  late final AnimationController _fitController;
  late final Ticker _physicsTicker;
  Animation<Matrix4>? _fitAnimation;
  late _RelationshipNetworkLayout _targetLayout;
  final Map<String, _AnimatedChainNode> _animatedNodes = {};
  List<_NetworkEdge> _activeEdges = const [];
  Duration? _lastPhysicsTick;
  var _canvasSize = 720.0;

  @override
  void initState() {
    super.initState();
    _targetLayout = _createTargetLayout();
    _canvasSize = _targetLayout.canvasSize;
    _activeEdges = _targetLayout.edges;
    for (final node in _targetLayout.nodes) {
      _animatedNodes[node.key] = _AnimatedChainNode.fromNode(node);
    }
    _fitController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 560),
        )..addListener(() {
          final value = _fitAnimation?.value;
          if (value != null) {
            _controller.value = value;
          }
        });
    _physicsTicker = createTicker(_tickPhysics);
    _scheduleFit();
  }

  @override
  void didUpdateWidget(covariant _HeroRelationshipNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode ||
        oldWidget.focusedHero != widget.focusedHero ||
        oldWidget.relationships.length != widget.relationships.length ||
        oldWidget.heroes.length != widget.heroes.length) {
      _retarget(_createTargetLayout());
      _scheduleFit();
    }
  }

  @override
  void dispose() {
    _physicsTicker.dispose();
    _fitController.dispose();
    _controller.dispose();
    super.dispose();
  }

  _RelationshipNetworkLayout _createTargetLayout() {
    return _RelationshipNetworkLayout.create(
      relationships: widget.relationships,
      heroes: widget.heroes,
      focusedHero: widget.focusedHero,
      viewMode: widget.viewMode,
    );
  }

  void _retarget(_RelationshipNetworkLayout nextLayout) {
    final previousLayout = _targetLayout;
    _targetLayout = nextLayout;
    _canvasSize = nextLayout.canvasSize;
    final nextNodes = {for (final node in nextLayout.nodes) node.key: node};
    final nextEdgesByNode = <String, List<String>>{};
    for (final edge in nextLayout.edges) {
      nextEdgesByNode.putIfAbsent(edge.sourceKey, () => []).add(edge.targetKey);
      nextEdgesByNode.putIfAbsent(edge.targetKey, () => []).add(edge.sourceKey);
    }

    for (final node in nextLayout.nodes) {
      final current = _animatedNodes[node.key];
      if (current != null) {
        current.retarget(node);
        continue;
      }
      Offset? entryPosition;
      for (final neighborKey in nextEdgesByNode[node.key] ?? const <String>[]) {
        final neighbor = _animatedNodes[neighborKey];
        if (neighbor != null) {
          entryPosition = neighbor.position;
          break;
        }
      }
      final center = Offset(
        nextLayout.canvasSize / 2,
        nextLayout.canvasSize / 2,
      );
      _animatedNodes[node.key] = _AnimatedChainNode.entering(
        node,
        entryPosition ?? center + (node.position - center) * 0.18,
      );
    }

    final exitCenter = Offset(
      previousLayout.canvasSize / 2,
      previousLayout.canvasSize / 2,
    );
    for (final entry in _animatedNodes.entries) {
      if (nextNodes.containsKey(entry.key)) continue;
      final node = entry.value;
      var direction = node.position - exitCenter;
      if (direction.distanceSquared < 1) {
        final angle = entry.key.hashCode % 360 * math.pi / 180;
        direction = Offset.fromDirection(angle);
      }
      node.exitToward(
        exitCenter + direction / direction.distance * nextLayout.canvasSize,
      );
    }

    final edgeKeys = <String>{};
    _activeEdges = [
      for (final edge in [..._activeEdges, ...nextLayout.edges])
        if (edgeKeys.add(_edgeKey(edge))) edge,
    ];
    _lastPhysicsTick = null;
    if (!_physicsTicker.isActive) _physicsTicker.start();
  }

  void _tickPhysics(Duration elapsed) {
    final previousTick = _lastPhysicsTick;
    _lastPhysicsTick = elapsed;
    if (previousTick == null) return;
    final dt = ((elapsed - previousTick).inMicroseconds / 1000000)
        .clamp(0.001, 0.032)
        .toDouble();
    var moving = false;
    final removable = <String>[];
    for (final entry in _animatedNodes.entries) {
      final node = entry.value;
      node.step(dt);
      moving = moving || !node.isSettled;
      if (node.canRemove) removable.add(entry.key);
    }
    for (final key in removable) {
      _animatedNodes.remove(key);
    }
    if (!mounted) return;
    setState(() {});
    if (!moving) {
      _physicsTicker.stop();
      _lastPhysicsTick = null;
      _activeEdges = _targetLayout.edges;
    }
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox =
          _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;
      final viewport = renderBox.size;
      final fitExtent = widget.viewMode == _RelationshipViewMode.focus
          ? math.min(760.0, _canvasSize)
          : _canvasSize;
      final scale = math
          .min(
            (viewport.width - 18) / fitExtent,
            (viewport.height - 18) / fitExtent,
          )
          .clamp(0.3, 1.0);
      final dx = viewport.width / 2 - _canvasSize * scale / 2;
      final dy = viewport.height / 2 - _canvasSize * scale / 2;
      final target = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
      _fitController.stop();
      _fitAnimation =
          Matrix4Tween(begin: _controller.value.clone(), end: target).animate(
            CurvedAnimation(parent: _fitController, curve: Curves.easeOutCubic),
          );
      _fitController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = _RelationshipNetworkLayout(
      canvasSize: _canvasSize,
      nodes: _animatedNodes.values
          .where((node) => node.opacity > 0.01)
          .map((node) => node.toNode())
          .toList(growable: false),
      edges: _activeEdges,
    );
    final content = SizedBox(
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
                      key: ValueKey(
                        'relationship-network-${widget.viewMode.name}',
                      ),
                      painter: _RelationshipNetworkPainter(layout: layout),
                    ),
                  ),
                  for (final node in layout.nodes)
                    Positioned(
                      left: node.position.dx - 38,
                      top: node.position.dy - node.size / 2,
                      width: 76,
                      child: IgnorePointer(
                        ignoring: node.opacity < 0.45,
                        child: Opacity(
                          opacity: node.opacity.clamp(0, 1),
                          child: _RelationshipAvatarNode(
                            node: node,
                            onTap: () => widget.onHeroSelected(node.name),
                          ),
                        ),
                      ),
                    ),
                ],
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
    final canvasSize = math
        .max(760, (math.sqrt(allKeys.length) * 120 + 250).ceil())
        .toDouble();
    if (viewMode == _RelationshipViewMode.global) {
      final center = Offset(canvasSize / 2, canvasSize / 2);
      final goldenAngle = math.pi * (3 - math.sqrt(5));
      final maxRadius = canvasSize * 0.43;
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
                  maxRadius *
                      math.sqrt(index / math.max(1, allKeys.length - 1)),
                ),
            size: 38,
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
    final center = Offset(canvasSize / 2, canvasSize / 2);
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
    this.opacity = 1,
    this.velocity = Offset.zero,
  });

  final String key;
  final String name;
  final String avatar;
  final Offset position;
  final double size;
  final bool showLabel;
  final bool highlighted;
  final double opacity;
  final Offset velocity;
}

class _AnimatedChainNode {
  _AnimatedChainNode({
    required this.key,
    required this.name,
    required this.avatar,
    required this.position,
    required this.targetPosition,
    required this.size,
    required this.targetSize,
    required this.opacity,
    required this.targetOpacity,
    required this.showLabel,
    required this.highlighted,
  });

  factory _AnimatedChainNode.fromNode(_ChainNode node) {
    return _AnimatedChainNode(
      key: node.key,
      name: node.name,
      avatar: node.avatar,
      position: node.position,
      targetPosition: node.position,
      size: node.size,
      targetSize: node.size,
      opacity: node.opacity,
      targetOpacity: node.opacity,
      showLabel: node.showLabel,
      highlighted: node.highlighted,
    );
  }

  factory _AnimatedChainNode.entering(_ChainNode node, Offset position) {
    return _AnimatedChainNode(
      key: node.key,
      name: node.name,
      avatar: node.avatar,
      position: position,
      targetPosition: node.position,
      size: math.max(8, node.size * 0.24),
      targetSize: node.size,
      opacity: 0,
      targetOpacity: node.opacity,
      showLabel: node.showLabel,
      highlighted: node.highlighted,
    );
  }

  final String key;
  String name;
  String avatar;
  Offset position;
  Offset targetPosition;
  Offset velocity = Offset.zero;
  double size;
  double targetSize;
  double sizeVelocity = 0;
  double opacity;
  double targetOpacity;
  bool showLabel;
  bool highlighted;

  bool get isSettled {
    return (targetPosition - position).distanceSquared < 0.2 &&
        velocity.distanceSquared < 0.4 &&
        (targetSize - size).abs() < 0.08 &&
        sizeVelocity.abs() < 0.08 &&
        (targetOpacity - opacity).abs() < 0.01;
  }

  bool get canRemove => targetOpacity == 0 && opacity < 0.012 && isSettled;

  void retarget(_ChainNode node) {
    name = node.name;
    avatar = node.avatar;
    targetPosition = node.position;
    targetSize = node.size;
    targetOpacity = node.opacity;
    showLabel = node.showLabel;
    highlighted = node.highlighted;
  }

  void exitToward(Offset position) {
    targetPosition = position;
    targetSize = 8;
    targetOpacity = 0;
    showLabel = false;
    highlighted = false;
  }

  void step(double dt) {
    const stiffness = 76.0;
    const damping = 9.5;
    final drag = math.exp(-damping * dt);
    velocity = (velocity + (targetPosition - position) * stiffness * dt) * drag;
    position += velocity * dt;

    sizeVelocity = (sizeVelocity + (targetSize - size) * stiffness * dt) * drag;
    size += sizeVelocity * dt;
    final opacityEase = 1 - math.exp(-8.5 * dt);
    opacity += (targetOpacity - opacity) * opacityEase;

    if (isSettled) {
      position = targetPosition;
      velocity = Offset.zero;
      size = targetSize;
      sizeVelocity = 0;
      opacity = targetOpacity;
    }
  }

  _ChainNode toNode() {
    return _ChainNode(
      key: key,
      name: name,
      avatar: avatar,
      position: position,
      size: math.max(1, size),
      showLabel: showLabel,
      highlighted: highlighted,
      opacity: opacity,
      velocity: velocity,
    );
  }
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

String _edgeKey(_NetworkEdge edge) {
  final nodes = [edge.sourceKey, edge.targetKey]..sort();
  return '${nodes[0]}|${nodes[1]}';
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
                      color: node.highlighted
                          ? AppTheme.cyan
                          : context.hokTheme.onSurfaceMuted,
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
                            color: context.hokTheme.backgroundDeep,
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
      if (sourceNode == null || targetNode == null) continue;
      final edgeOpacity = math.min(sourceNode.opacity, targetNode.opacity);
      if (edgeOpacity < 0.02) continue;
      final connectedToFocus = sourceNode.highlighted || targetNode.highlighted;
      final paint = Paint()
        ..color = edge.color.withValues(
          alpha: (connectedToFocus ? 0.84 : 0.34) * edgeOpacity,
        )
        ..strokeWidth = connectedToFocus ? 2.3 : 1.1
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final delta = target - source;
      final distance = delta.distance;
      final normal = distance <= 0.01
          ? Offset.zero
          : Offset(-delta.dy / distance, delta.dx / distance);
      final direction = edge.sourceKey.compareTo(edge.targetKey) <= 0 ? 1 : -1;
      final gravitySag = math.min(18.0, distance * 0.042) * direction;
      final velocityTrail = (sourceNode.velocity + targetNode.velocity) * 0.018;
      final control =
          Offset.lerp(source, target, 0.5)! +
          normal * gravitySag +
          velocityTrail;
      final path = Path()
        ..moveTo(source.dx, source.dy)
        ..quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);
      if (connectedToFocus) {
        canvas.drawPath(
          path,
          Paint()
            ..color = edge.color.withValues(alpha: 0.12 * edgeOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RelationshipNetworkPainter oldDelegate) {
    return oldDelegate.layout != layout;
  }
}
