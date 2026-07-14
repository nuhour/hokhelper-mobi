import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/hero_summary.dart';
import '../domain/world_map_region.dart';
import 'hero_gallery_screen.dart';

final worldMapHeroesProvider = FutureProvider<List<HeroSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(heroesRepositoryProvider)
      .loadHeroes(settings.region.regionId);
});

class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({this.initialHeroId, super.key});

  final String? initialHeroId;

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  String? _openedInitialHeroId;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WorldMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHeroId != widget.initialHeroId) {
      _openedInitialHeroId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroesValue = ref.watch(worldMapHeroesProvider);

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<List<HeroSummary>>(
        value: heroesValue,
        retry: () => ref.invalidate(worldMapHeroesProvider),
        data: (heroes) {
          final regions = attachWorldMapHeroes(heroes);
          _openInitialHeroRegion(regions);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: _WorldAtlas(
                  regions: regions,
                  immersive: true,
                  onOpenDetail: (region) => _openRegionDetail(context, region),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Exit world map',
                        onPressed: () => context.go('/heroes'),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openInitialHeroRegion(List<WorldMapRegion> regions) {
    final heroId = widget.initialHeroId?.trim();
    if (heroId == null || heroId.isEmpty || _openedInitialHeroId == heroId) {
      return;
    }

    WorldMapRegion? focusedRegion;
    for (final region in regions) {
      final containsHero = region.representativeHeroes.any((hero) {
        return hero.heroId == heroId || hero.id == heroId;
      });
      if (containsHero) {
        focusedRegion = region;
        break;
      }
    }
    _openedInitialHeroId = heroId;

    if (focusedRegion == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openRegionDetail(context, focusedRegion!);
    });
  }

  void _openRegionDetail(BuildContext context, WorldMapRegion region) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.panel,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Domain Records',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  region.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  region.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                ),
                const SizedBox(height: 20),
                Text(
                  'Representative Heroes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (region.representativeHeroes.isEmpty)
                  const AppEmptyState(
                    icon: Icons.travel_explore_outlined,
                    title: 'No hero data',
                    message: 'Switch region or pull to refresh hero records.',
                  )
                else
                  ...region.representativeHeroes.map((hero) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HeroDetailRow(hero: hero),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WorldAtlas extends StatefulWidget {
  const _WorldAtlas({
    required this.regions,
    required this.onOpenDetail,
    this.immersive = false,
  });

  final List<WorldMapRegion> regions;
  final ValueChanged<WorldMapRegion> onOpenDetail;
  final bool immersive;

  @override
  State<_WorldAtlas> createState() => _WorldAtlasState();
}

class _WorldAtlasState extends State<_WorldAtlas>
    with TickerProviderStateMixin {
  static const _mapWidth = 1500.0;
  static const _mapHeight = 743.0;
  static const _regionAnchors = <String, Offset>{
    'riluohai': Offset(100, 445),
    'yunzhongmodi': Offset(496, 402),
    'beihuang': Offset(599, 279),
    'heluo': Offset(803, 499),
    'jianmu': Offset(886, 319),
    'daheliuyu': Offset(962, 470),
    'zhulu': Offset(1025, 374),
    'sanfenzhidi': Offset(1103, 470),
    'dongfenghaiyu': Offset(1210, 548),
  };

  late final TransformationController _controller;
  late final AnimationController _cloudFrontController;
  late final AnimationController _cloudBackController;
  var _hasCenteredMap = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _cloudFrontController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();
    _cloudBackController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 47),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cloudFrontController.dispose();
    _cloudBackController.dispose();
    super.dispose();
  }

  bool _centerMap() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return false;
    }
    final viewport = renderBox.size;
    final scale = widget.immersive
        ? math.max(viewport.width / _mapWidth, viewport.height / _mapHeight)
        : 1.0;
    final scaledWidth = _mapWidth * scale;
    final scaledHeight = _mapHeight * scale;
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - scaledWidth) / 2,
        (viewport.height - scaledHeight) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCenteredMap) {
      _hasCenteredMap = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_centerMap()) {
          _hasCenteredMap = false;
        }
      });
    }
    final height = (MediaQuery.sizeOf(context).height * 0.7).clamp(
      460.0,
      720.0,
    );

    final atlas = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: widget.immersive
            ? BorderRadius.zero
            : BorderRadius.circular(18),
        border: widget.immersive
            ? null
            : Border.all(color: AppTheme.muted.withValues(alpha: 0.22)),
      ),
      child: SizedBox.expand(
        child: ClipRRect(
          borderRadius: widget.immersive
              ? BorderRadius.zero
              : BorderRadius.circular(17),
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _controller,
                constrained: false,
                minScale: 0.28,
                maxScale: 2.8,
                boundaryMargin: const EdgeInsets.all(180),
                child: SizedBox(
                  width: _mapWidth,
                  height: _mapHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/world/hok_world.png',
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x12000000), Color(0x56000000)],
                          ),
                        ),
                      ),
                      for (final region in widget.regions)
                        if (_regionAnchors[region.id] case final anchor?)
                          Positioned(
                            left: anchor.dx - 46,
                            top: anchor.dy - 40,
                            child: _WorldRegionMarker(
                              region: region,
                              onTap: () => widget.onOpenDetail(region),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _cloudFrontController,
                        _cloudBackController,
                      ]),
                      builder: (context, child) {
                        return Stack(
                          children: [
                            _FloatingCloudBand(
                              progress: _cloudBackController.value,
                              assetPath: 'assets/world/cloud_2.png',
                              topFactor: 0.02,
                              opacity: 0.31,
                              scale: 1.36,
                              reverse: true,
                            ),
                            _FloatingCloudBand(
                              progress: _cloudFrontController.value,
                              assetPath: 'assets/world/cloud_1.png',
                              topFactor: 0.12,
                              opacity: 0.43,
                              scale: 1.56,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filledTonal(
                  tooltip: 'Recenter map',
                  onPressed: _centerMap,
                  icon: const Icon(Icons.center_focus_strong_rounded),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 14,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Text(
                        'Pinch to zoom · Drag to explore',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return widget.immersive ? atlas : SizedBox(height: height, child: atlas);
  }
}

class _FloatingCloudBand extends StatelessWidget {
  const _FloatingCloudBand({
    required this.progress,
    required this.assetPath,
    required this.topFactor,
    required this.opacity,
    required this.scale,
    this.reverse = false,
  });

  final double progress;
  final String assetPath;
  final double topFactor;
  final double opacity;
  final double scale;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final imageWidth = width * scale;
        final travel = width + imageWidth;
        final start = reverse
            ? progress * travel - imageWidth
            : width - progress * travel;

        return Stack(
          children: [
            for (var index = -1; index <= 1; index++)
              Positioned(
                top:
                    constraints.maxHeight * topFactor + (index.isEven ? 0 : 26),
                left: start + index * travel,
                width: imageWidth,
                child: Opacity(
                  opacity: opacity,
                  child: Image.asset(assetPath, fit: BoxFit.fitWidth),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WorldRegionMarker extends StatelessWidget {
  const _WorldRegionMarker({required this.region, required this.onTap});

  final WorldMapRegion region;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: region.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: region.color, blurRadius: 14)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                region.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroDetailRow extends StatelessWidget {
  const _HeroDetailRow({required this.hero});

  final HeroSummary hero;

  @override
  Widget build(BuildContext context) {
    final detailRouteId = hero.detailRouteId;

    return Material(
      color: AppTheme.panelAlt,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: detailRouteId == null
            ? null
            : () {
                Navigator.of(context).pop();
                context.go('/heroes/$detailRouteId');
              },
        leading: AppImage(
          url: hero.avatar,
          aspectRatio: 1,
          width: 44,
          height: 44,
          borderRadius: 12,
          semanticLabel: '${hero.name} avatar',
        ),
        title: Text(hero.name),
        subtitle: Text(hero.title.isEmpty ? 'Hero ${hero.heroId}' : hero.title),
      ),
    );
  }
}
