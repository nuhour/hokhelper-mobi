import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../data/rank_fortune_repository.dart';
import '../domain/rank_fortune.dart';

const _fortuneGold = Color(0xFFF6C453);
const _fortuneRed = Color(0xFFE5484D);
const _fortuneBlue = Color(0xFF4F7CFF);

final rankFortuneRepositoryProvider = Provider<RankFortuneRepository>((ref) {
  return RankFortuneRepository(apiClient: ref.watch(apiClientProvider));
});

final rankFortuneHistoryProvider = FutureProvider<RankFortuneHistory>((ref) {
  return ref.watch(rankFortuneRepositoryProvider).loadHistory();
});

final rankFortuneHistoryByDaysProvider =
    FutureProvider.family<RankFortuneHistory, int>((ref, days) {
      return ref.watch(rankFortuneRepositoryProvider).loadHistory(days: days);
    });

class RankFortuneScreen extends ConsumerStatefulWidget {
  const RankFortuneScreen({this.initialDays = 30, super.key});

  final int initialDays;

  @override
  ConsumerState<RankFortuneScreen> createState() => _RankFortuneScreenState();
}

class _RankFortuneScreenState extends ConsumerState<RankFortuneScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  RankFortuneRecord? _localToday;
  List<RankFortuneRecord>? _localRows;
  List<RankFortuneRecord> _visibleRows = const [];
  List<RankFortuneCatalogEntry>? _localCatalog;
  bool? _localCanDraw;
  var _isDrawing = false;
  var _isRevealing = false;
  var _sensorAvailable = true;
  var _canShakeDraw = false;
  var _shakePeaks = 0;
  DateTime? _shakeWindowStartedAt;
  DateTime? _lastShakePeakAt;
  DateTime? _lastShakeTriggeredAt;
  StreamSubscription<UserAccelerometerEvent>? _motionSubscription;
  late final AnimationController _shakeController;
  late final AnimationController _revealController;
  late final AnimationController _hintController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _listenForShake();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionSubscription?.cancel();
    _shakeController.dispose();
    _revealController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _listenForShake();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _motionSubscription?.cancel();
      _motionSubscription = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.initialDays.clamp(1, 365);
    final historyValue = days == 30
        ? ref.watch(rankFortuneHistoryProvider)
        : ref.watch(rankFortuneHistoryByDaysProvider(days));

    return AppAsyncView<RankFortuneHistory>(
      value: historyValue,
      retry: () => _invalidateHistory(days),
      data: (history) {
        final today = _localToday ?? history.today;
        final rows = _localRows ?? history.rows;
        final catalog = _localCatalog ?? history.catalog;
        final canDraw = _localCanDraw ?? history.canDraw;
        _canShakeDraw = canDraw && !_isDrawing;
        _visibleRows = rows;

        return RefreshIndicator(
          onRefresh: () {
            _clearLocalState();
            final future = days == 30
                ? ref.refresh(rankFortuneHistoryProvider.future)
                : ref.refresh(rankFortuneHistoryByDaysProvider(days).future);
            return future.then((_) {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _FortuneHeader(canDraw: canDraw),
              const SizedBox(height: 16),
              RepaintBoundary(
                child: _FortunePanel(
                  today: today,
                  canDraw: canDraw,
                  isDrawing: _isDrawing,
                  isRevealing: _isRevealing,
                  sensorAvailable: _sensorAvailable,
                  shakeAnimation: _shakeController,
                  revealAnimation: _revealController,
                  hintAnimation: _hintController,
                  onDraw: canDraw && !_isDrawing ? _drawToday : null,
                ),
              ),
              const SizedBox(height: 16),
              _HistoryPanel(rows: rows, catalog: catalog, days: days),
            ],
          ),
        );
      },
    );
  }

  void _invalidateHistory(int days) {
    if (days == 30) {
      ref.invalidate(rankFortuneHistoryProvider);
    } else {
      ref.invalidate(rankFortuneHistoryByDaysProvider(days));
    }
  }

  void _listenForShake() {
    if (_motionSubscription != null) {
      return;
    }
    _motionSubscription =
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          _handleMotion,
          onError: (_) {
            if (mounted) {
              setState(() => _sensorAvailable = false);
            }
            _motionSubscription = null;
          },
          cancelOnError: true,
        );
  }

  void _handleMotion(UserAccelerometerEvent event) {
    if (!_canShakeDraw || _isDrawing) {
      _shakePeaks = 0;
      _shakeWindowStartedAt = null;
      return;
    }
    final now = DateTime.now();
    final cooldown = _lastShakeTriggeredAt == null
        ? const Duration(seconds: 3)
        : now.difference(_lastShakeTriggeredAt!);
    if (cooldown < const Duration(milliseconds: 2400)) {
      return;
    }
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < 12.5) {
      return;
    }
    if (_lastShakePeakAt != null &&
        now.difference(_lastShakePeakAt!) < const Duration(milliseconds: 140)) {
      return;
    }
    if (_shakeWindowStartedAt == null ||
        now.difference(_shakeWindowStartedAt!) >
            const Duration(milliseconds: 850)) {
      _shakeWindowStartedAt = now;
      _shakePeaks = 0;
    }
    _lastShakePeakAt = now;
    _shakePeaks += 1;
    if (_shakePeaks < 2) {
      return;
    }
    _lastShakeTriggeredAt = now;
    _shakePeaks = 0;
    _shakeWindowStartedAt = null;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_drawToday());
  }

  Future<void> _drawToday() async {
    if (_isDrawing || !_canShakeDraw) {
      return;
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    setState(() {
      _isDrawing = true;
      _isRevealing = false;
      _canShakeDraw = false;
    });
    final drawFuture = ref.read(rankFortuneRepositoryProvider).drawToday();
    try {
      if (!reduceMotion) {
        await _shakeController.forward(from: 0);
      }
      final draw = await drawFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _localToday = draw.record;
        _localCanDraw = draw.canDraw;
        _localCatalog = draw.catalog;
        _localRows = [
          ..._visibleRows.where((row) => row.date != draw.record.date),
          draw.record,
        ]..sort((a, b) => a.date.compareTo(b.date));
        _isRevealing = true;
      });
      unawaited(HapticFeedback.heavyImpact());
      if (!reduceMotion) {
        await _revealController.forward(from: 0);
      }
    } catch (error) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('Unable to draw fortune: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDrawing = false;
          _isRevealing = false;
          _canShakeDraw = _localCanDraw ?? true;
        });
      }
    }
  }

  void _clearLocalState() {
    setState(() {
      _localToday = null;
      _localRows = null;
      _localCatalog = null;
      _localCanDraw = null;
    });
  }
}

class _FortuneHeader extends StatelessWidget {
  const _FortuneHeader({required this.canDraw});

  final bool canDraw;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_fortuneBlue, _fortuneRed]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rank Fortune',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'A daily ritual before your ranked queue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.hokTheme.onSurfaceMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: (canDraw ? _fortuneGold : AppTheme.cyan).withValues(
              alpha: 0.12,
            ),
            border: Border.all(
              color: (canDraw ? _fortuneGold : AppTheme.cyan).withValues(
                alpha: 0.34,
              ),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            canDraw ? 'READY' : 'DRAWN',
            style: TextStyle(
              color: canDraw ? _fortuneGold : AppTheme.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _FortunePanel extends StatelessWidget {
  const _FortunePanel({
    required this.today,
    required this.canDraw,
    required this.isDrawing,
    required this.isRevealing,
    required this.sensorAvailable,
    required this.shakeAnimation,
    required this.revealAnimation,
    required this.hintAnimation,
    required this.onDraw,
  });

  final RankFortuneRecord? today;
  final bool canDraw;
  final bool isDrawing;
  final bool isRevealing;
  final bool sensorAvailable;
  final Animation<double> shakeAnimation;
  final Animation<double> revealAnimation;
  final Animation<double> hintAnimation;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF121A2D), Color(0xFF090E1C)]
              : const [Color(0xFFFFFFFF), Color(0xFFF2F6FF)],
        ),
        border: Border.all(color: _fortuneBlue.withValues(alpha: 0.38)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _fortuneBlue.withValues(alpha: isDark ? 0.16 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: today == null
                  ? _AnimatedFortuneJar(
                      key: const ValueKey('jar'),
                      isDrawing: isDrawing,
                      animation: shakeAnimation,
                    )
                  : _AnimatedFortuneResult(
                      key: ValueKey(today!.date),
                      record: today!,
                      animation: isRevealing
                          ? revealAnimation
                          : const AlwaysStoppedAnimation(1),
                    ),
            ),
            const SizedBox(height: 16),
            if (canDraw)
              _ShakeHint(
                isDrawing: isDrawing,
                sensorAvailable: sensorAvailable,
                animation: hintAnimation,
              )
            else
              const _CompletedHint(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _fortuneBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: context.hokTheme.surfaceRaised,
                  disabledForegroundColor: context.hokTheme.onSurfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onDraw,
                icon: Icon(
                  isDrawing ? Icons.motion_photos_on_rounded : Icons.touch_app,
                ),
                label: Text(
                  isDrawing
                      ? 'Drawing your fortune...'
                      : canDraw
                      ? 'Tap to draw instead'
                      : 'Come back tomorrow',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShakeHint extends StatelessWidget {
  const _ShakeHint({
    required this.isDrawing,
    required this.sensorAvailable,
    required this.animation,
  });

  final bool isDrawing;
  final bool sensorAvailable;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, reduceMotion ? 0 : -2 * animation.value),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _fortuneGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _fortuneGold.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDrawing
                  ? Icons.motion_photos_on_rounded
                  : Icons.vibration_rounded,
              size: 20,
              color: _fortuneGold,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                isDrawing
                    ? 'Shaking the fortune jar...'
                    : sensorAvailable
                    ? 'Shake your phone to draw'
                    : 'Motion sensor unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _fortuneGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedHint extends StatelessWidget {
  const _CompletedHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.cyan),
        SizedBox(width: 8),
        Text(
          'Today’s fortune is sealed',
          style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _AnimatedFortuneJar extends StatelessWidget {
  const _AnimatedFortuneJar({
    required this.isDrawing,
    required this.animation,
    super.key,
  });

  final bool isDrawing;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 236,
          child: Center(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                if (!isDrawing) return child!;
                final envelope = math.sin(animation.value * math.pi);
                final wave = math.sin(animation.value * math.pi * 13);
                return Transform.translate(
                  offset: Offset(wave * 11 * envelope, -3 * envelope),
                  child: Transform.rotate(
                    angle: wave * 0.055 * envelope,
                    child: child,
                  ),
                );
              },
              child: const _JarArtwork(),
            ),
          ),
        ),
        Text(
          isDrawing
              ? 'Listen for the lucky stick'
              : 'Your daily sign is waiting',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.hokTheme.onSurfaceStrong,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'One draw each day. Make it count before ranked.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.hokTheme.onSurfaceMuted),
        ),
      ],
    );
  }
}

class _JarArtwork extends StatelessWidget {
  const _JarArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 222,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 2,
            left: 28,
            right: 28,
            height: 154,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                for (var index = 0; index < 7; index += 1)
                  Transform.translate(
                    offset: Offset((index - 3) * 12, (index % 2) * 4),
                    child: Transform.rotate(
                      angle: (index - 3) * 0.055,
                      child: Container(
                        width: 8,
                        height: 145 - (index % 3) * 7,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFE9A5), _fortuneGold],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFB7781B),
                            width: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 144,
            height: 142,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEB5860), Color(0xFF8F1828)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(34),
                bottom: Radius.circular(48),
              ),
              border: Border.all(color: _fortuneGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _fortuneRed.withValues(alpha: 0.26),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF74131F),
                  shape: BoxShape.circle,
                  border: Border.all(color: _fortuneGold, width: 2),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _fortuneGold,
                  size: 28,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 128,
            child: Container(
              width: 152,
              height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD69A2D),
                    Color(0xFFFFE08A),
                    Color(0xFFD69A2D),
                  ],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFortuneResult extends StatelessWidget {
  const _AnimatedFortuneResult({
    required this.record,
    required this.animation,
    super.key,
  });

  final RankFortuneRecord record;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: _FortuneResult(record: record),
      ),
    );
  }
}

class _FortuneResult extends StatelessWidget {
  const _FortuneResult({required this.record});

  final RankFortuneRecord record;

  @override
  Widget build(BuildContext context) {
    final copy = _fortuneCopy(record.typeId);
    return Column(
      children: [
        Container(
          width: 112,
          height: 176,
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF9F1D2D),
                Color(0xFF9F1D2D),
                Color(0xFFFFF9DE),
                Color(0xFFF0C75E),
              ],
              stops: [0, 0.09, 0.09, 1],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8F1828), width: 2),
            boxShadow: [
              BoxShadow(
                color: _fortuneGold.withValues(alpha: 0.24),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFD69A2D).withValues(alpha: 0.65),
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 17,
                      color: Color(0xFF8F1828),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      copy.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF24283A),
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          copy.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _scoreColor(context, record.score),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          copy.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.hokTheme.onSurfaceMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _scoreColor(context, record.score).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _scoreColor(context, record.score).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fortune Value',
                style: TextStyle(
                  color: context.hokTheme.onSurfaceMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${record.score}',
                style: TextStyle(
                  color: _scoreColor(context, record.score),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _shareFortune(context, copy),
          icon: const Icon(Icons.ios_share_outlined, size: 18),
          label: const Text('Share Fortune'),
        ),
      ],
    );
  }

  Future<void> _shareFortune(
    BuildContext context,
    ({String title, String description}) copy,
  ) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'I just drew ${copy.title} on HOK Helper today! Fortune Value: ${record.score}\n/tools/rank-fortune',
      ),
    );
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Fortune link copied')),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.rows,
    required this.catalog,
    required this.days,
  });

  final List<RankFortuneRecord> rows;
  final List<RankFortuneCatalogEntry> catalog;
  final int days;

  @override
  Widget build(BuildContext context) {
    final sorted = [...rows]..sort((a, b) => a.date.compareTo(b.date));
    final latestRows = sorted.reversed
        .take(days)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$days-day History',
                    style: TextStyle(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  '${catalog.length} tiers',
                  style: TextStyle(color: context.hokTheme.onSurfaceMuted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (sorted.isEmpty)
              const AppEmptyState(
                icon: Icons.insights_outlined,
                title: 'No fortune history yet',
                message: 'Draw a fortune to start the trend.',
              )
            else ...[
              _HistorySummary(rows: latestRows),
              const SizedBox(height: 14),
              _HistoryBars(rows: latestRows),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.rows});

  final List<RankFortuneRecord> rows;

  @override
  Widget build(BuildContext context) {
    final scores = rows.map((row) => row.score).toList(growable: false);
    final average = scores.isEmpty
        ? 0
        : (scores.reduce((a, b) => a + b) / scores.length).round();
    final best = scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b);
    final lowest = scores.isEmpty ? 0 : scores.reduce((a, b) => a < b ? a : b);
    final streak = _currentStreak(rows);

    return Row(
      children: [
        Expanded(
          child: _SummaryMetric(
            label: '30d Average',
            value: '$average',
            color: _scoreColor(context, average),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryMetric(
            label: 'Best',
            value: '$best',
            color: _scoreColor(context, best),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryMetric(
            label: 'Lowest',
            value: '$lowest',
            color: _scoreColor(context, lowest),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryMetric(
            label: 'Streak',
            value: '$streak days',
            color: AppTheme.cyan,
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.hokTheme.onSurfaceMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryBars extends StatelessWidget {
  const _HistoryBars({required this.rows});

  final List<RankFortuneRecord> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 116,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final row in rows) ...[
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: (row.score.clamp(8, 100)) / 100,
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _scoreColor(
                          context,
                          row.score,
                        ).withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...rows.reversed.take(5).map((row) => _HistoryRow(row: row)),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row});

  final RankFortuneRecord row;

  @override
  Widget build(BuildContext context) {
    final copy = _fortuneCopy(row.typeId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.hokTheme.onSurfaceMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              copy.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: context.hokTheme.onSurfaceStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${row.score}',
            style: TextStyle(
              color: _scoreColor(context, row.score),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

int _currentStreak(List<RankFortuneRecord> rows) {
  if (rows.isEmpty) {
    return 0;
  }
  final dates =
      rows
          .map((row) => DateTime.tryParse(row.date))
          .whereType<DateTime>()
          .toList(growable: false)
        ..sort();
  if (dates.length != rows.length) {
    return rows.length;
  }
  var streak = 1;
  for (var index = dates.length - 1; index > 0; index -= 1) {
    final expectedPrevious = dates[index].subtract(const Duration(days: 1));
    final previous = dates[index - 1];
    if (previous.year != expectedPrevious.year ||
        previous.month != expectedPrevious.month ||
        previous.day != expectedPrevious.day) {
      break;
    }
    streak += 1;
  }
  return streak;
}

({String title, String description}) _fortuneCopy(String typeId) {
  return switch (typeId) {
    'heavenly_win' => (
      title: 'Heavenly Win',
      description: 'Peak luck day, ideal for a hard rank push.',
    ),
    'destiny_surge' => (
      title: 'Destiny Surge',
      description: 'Momentum is on your side. Climb aggressively.',
    ),
    'lucky_star' => (
      title: 'Lucky Star',
      description: 'Teamfights are likely to go your way.',
    ),
    'clutch_master' => (
      title: 'Clutch Master',
      description: 'Strong comeback potential in close games.',
    ),
    'stable_up' => (
      title: 'Stable Climb',
      description: 'Consistent gains if you play disciplined.',
    ),
    'duo_bonus' => (
      title: 'Duo Bonus',
      description: 'Best day to queue with your trusted partner.',
    ),
    'map_control' => (
      title: 'Map Control',
      description: 'Macro decisions should convert into objectives.',
    ),
    'calm_focus' => (
      title: 'Calm Focus',
      description: 'Lower error rate and clearer decisions.',
    ),
    'even_match' => (
      title: 'Even Match',
      description: 'Skill execution will decide the outcome.',
    ),
    'slight_headwind' => (
      title: 'Light Headwind',
      description: 'Play safe early and avoid coin-flip fights.',
    ),
    'queue_trap' => (
      title: 'Queue Trap',
      description: 'Tough lobbies expected. Reduce your game count.',
    ),
    'tilt_alert' => (
      title: 'Tilt Alert',
      description: 'Mental risk is high. Take breaks between games.',
    ),
    'bad_timing' => (
      title: 'Bad Timing',
      description: 'Warm up first before entering ranked.',
    ),
    'lose_streak_risk' => (
      title: 'Lose Streak Risk',
      description: 'Not an ideal day for forcing a climb.',
    ),
    'doom_queue' => (
      title: 'Doom Queue',
      description: 'High-variance day. Consider casual modes.',
    ),
    'legendary' => (
      title: 'Legendary Luck',
      description: 'Queue with your best hero and call tempo early.',
    ),
    'great' => (
      title: 'Great Luck',
      description: 'Push your main role and play around objective windows.',
    ),
    'good' => (
      title: 'Good Luck',
      description: 'Stable climb energy. Draft comfort picks first.',
    ),
    'steady' => (
      title: 'Steady Luck',
      description: 'Play controlled lanes and avoid coin-flip fights.',
    ),
    'cautious' => (
      title: 'Cautious Luck',
      description: 'Warm up first and protect your mental stack.',
    ),
    'reset' => (
      title: 'Reset Day',
      description: 'Review replays or play casual before ranked.',
    ),
    _ => (
      title: typeId.isEmpty ? 'Unknown Luck' : typeId,
      description: 'Use the signal as a light ritual before queueing.',
    ),
  };
}

Color _scoreColor(BuildContext context, int score) {
  if (score >= 90) return AppTheme.error;
  if (score >= 75) return AppTheme.gold;
  if (score >= 60) return AppTheme.cyan;
  if (score >= 45) return context.hokTheme.onSurfaceMuted;
  return const Color(0xFFA78BFA);
}
