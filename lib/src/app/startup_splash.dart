import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/presentation/home_screen.dart';

class StartupSplash extends ConsumerStatefulWidget {
  const StartupSplash({
    required this.child,
    this.minimumGatherDelay,
    super.key,
  });

  final Widget child;
  final Duration? minimumGatherDelay;

  @override
  ConsumerState<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends ConsumerState<StartupSplash>
    with TickerProviderStateMixin {
  static const _maximumPreloadWait = Duration(milliseconds: 4500);

  late final AnimationController _gatherController;
  late final AnimationController _pulseController;
  late final AnimationController _exitController;
  late final Future<void> _homePreload;
  bool _showSplash = true;
  bool _assetsPrecached = false;

  @override
  void initState() {
    super.initState();
    _gatherController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _homePreload = ref
        .read(homeStatsProvider.future)
        .then<void>((_) {})
        .catchError((Object _) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _beginVisibleStartup();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsPrecached) {
      return;
    }
    _assetsPrecached = true;
    precacheImage(
      const AssetImage('assets/home/season_pc_background.jpg'),
      context,
    );
    precacheImage(const AssetImage('assets/brand/light-logo.png'), context);
    for (final particle in _SplashCanvas.toolParticles) {
      precacheImage(AssetImage(particle.assetPath), context);
    }
  }

  Future<void> _beginVisibleStartup() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    _pulseController.repeat();
    final minimumGatherDelay =
        widget.minimumGatherDelay ??
        (kDebugMode
            ? const Duration(milliseconds: 6500)
            : const Duration(milliseconds: 1200));
    await Future.wait<void>([
      _homePreload.timeout(_maximumPreloadWait, onTimeout: () {}),
      Future<void>.delayed(minimumGatherDelay),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    final gatherAnimation = _gatherController.forward().then<void>((_) {});
    await _runStartup(gatherAnimation);
  }

  Future<void> _runStartup(Future<void> gatherAnimation) async {
    await gatherAnimation;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) {
      return;
    }
    await _exitController.forward();
    if (mounted) {
      _pulseController.stop();
      setState(() => _showSplash = false);
    }
  }

  @override
  void dispose() {
    _gatherController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final splashMediaQuery =
        MediaQuery.maybeOf(context) ??
        MediaQueryData.fromView(View.of(context));
    Widget splash = MediaQuery(
      data: splashMediaQuery,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _gatherController,
          _pulseController,
          _exitController,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: 1 - _exitController.value,
            child: _SplashCanvas(
              gatherProgress: _gatherController.value,
              pulseProgress: _pulseController.value,
            ),
          );
        },
      ),
    );
    if (Directionality.maybeOf(context) == null) {
      splash = Directionality(textDirection: TextDirection.ltr, child: splash);
    }

    return Stack(
      fit: StackFit.expand,
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_showSplash) Positioned.fill(child: IgnorePointer(child: splash)),
      ],
    );
  }
}

class _SplashCanvas extends StatelessWidget {
  const _SplashCanvas({
    required this.gatherProgress,
    required this.pulseProgress,
  });

  final double gatherProgress;
  final double pulseProgress;

  static const toolParticles = <_ToolParticle>[
    _ToolParticle('assets/tools/bp.png', Color(0xFF60A5FA)),
    _ToolParticle('assets/tools/tier.png', Color(0xFFFBBF24)),
    _ToolParticle('assets/tools/prompt.png', Color(0xFFFB7185)),
    _ToolParticle('assets/tools/team.png', Color(0xFF93C5FD)),
    _ToolParticle('assets/tools/build.png', Color(0xFFF87171)),
    _ToolParticle('assets/tools/fortune.png', Color(0xFFFDE68A)),
  ];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final gathered = reduceMotion
        ? 1.0
        : Curves.easeInOutCubic.transform(
            (gatherProgress / 0.82).clamp(0.0, 1.0),
          );
    final logoProgress = reduceMotion
        ? 1.0
        : Curves.easeOutBack.transform(
            const Interval(0.78, 1).transform(gatherProgress),
          );

    return ColoredBox(
      color: const Color(0xFF020617),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.16),
            radius: 0.78,
            colors: [Color(0xFF172554), Color(0xFF070B1B), Color(0xFF020617)],
            stops: [0, 0.54, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final center = Offset(
                constraints.maxWidth / 2,
                constraints.maxHeight * 0.43,
              );
              final startRadius =
                  math.min(constraints.maxWidth, constraints.maxHeight) * 0.34;

              return Stack(
                children: [
                  for (var index = 0; index < toolParticles.length; index++)
                    _buildParticle(
                      particle: toolParticles[index],
                      index: index,
                      center: center,
                      startRadius: startRadius,
                      gathered: gathered,
                    ),
                  Positioned(
                    left: center.dx - 94,
                    top: center.dy - 94,
                    width: 188,
                    height: 188,
                    child: Transform.rotate(
                      angle: pulseProgress * math.pi * 2,
                      child: Opacity(
                        opacity: 0.18 + (logoProgress * 0.3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF60A5FA),
                              width: 1.2,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Transform.translate(
                              offset: const Offset(0, -4),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: center.dx - 68,
                    top: center.dy - 68,
                    width: 136,
                    height: 136,
                    child: Transform.scale(
                      scale: 0.72 + (0.28 * logoProgress),
                      child: Opacity(
                        opacity: logoProgress.clamp(0.0, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1224),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.34),
                                blurRadius: 38,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.22),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/brand/light-logo.png',
                                fit: BoxFit.cover,
                                semanticLabel: 'HOK Helper',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: center.dy + 102,
                    child: Opacity(
                      opacity: logoProgress.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'HOK HELPER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LoadingDots(progress: pulseProgress),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildParticle({
    required _ToolParticle particle,
    required int index,
    required Offset center,
    required double startRadius,
    required double gathered,
  }) {
    final initialAngle =
        (-math.pi / 2) + (index * math.pi * 2 / toolParticles.length);
    final waitingOrbit = (1 - gathered) * pulseProgress * math.pi * 0.36;
    final orbit =
        waitingOrbit +
        ((1 - gathered) * math.sin(gatherProgress * math.pi) * 0.52);
    final angle = initialAngle + orbit;
    final radius = startRadius * (1 - gathered);
    final position = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    final fade = (1 - const Interval(0.64, 0.98).transform(gathered)).clamp(
      0.0,
      1.0,
    );

    return Positioned(
      left: position.dx - 27,
      top: position.dy - 27,
      width: 54,
      height: 54,
      child: Transform.rotate(
        angle: (index.isEven ? 1 : -1) * gathered * math.pi * 0.75,
        child: Transform.scale(
          scale: 1 - (gathered * 0.28),
          child: Opacity(
            opacity: fade,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                shape: BoxShape.circle,
                border: Border.all(
                  color: particle.color.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: particle.color.withValues(alpha: 0.25),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  particle.assetPath,
                  fit: BoxFit.cover,
                  semanticLabel: 'Tool icon ${index + 1}',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final distance = (progress - (index * 0.18)).abs();
        final active = (1 - (distance * 2.2)).clamp(0.25, 1.0);
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF475569),
              index == 1 ? const Color(0xFFEF4444) : const Color(0xFF60A5FA),
              active,
            ),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _ToolParticle {
  const _ToolParticle(this.assetPath, this.color);

  final String assetPath;
  final Color color;
}
