import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
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
    with WidgetsBindingObserver {
  RankFortuneRecord? _localToday;
  List<RankFortuneRecord>? _localRows;
  List<RankFortuneRecord> _visibleRows = const [];
  List<RankFortuneCatalogEntry>? _localCatalog;
  bool? _localCanDraw;
  bool _isDrawing = false;
  bool _sensorAvailable = true;
  bool _canShakeDraw = false;
  int _shakePeaks = 0;
  DateTime? _shakeWindowStartedAt;
  DateTime? _lastShakePeakAt;
  DateTime? _lastShakeTriggeredAt;
  StreamSubscription<UserAccelerometerEvent>? _motionSubscription;
  WebViewController? _instrumentController;
  Completer<void>? _instrumentSpinCompleter;
  bool _instrumentReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForShake();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionSubscription?.cancel();
    _instrumentSpinCompleter?.complete();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _listenForShake();
    } else if (state != AppLifecycleState.hidden) {
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
      loadingStyle: AppAsyncLoadingStyle.dashboard,
      retry: () => _invalidateHistory(days),
      data: (history) {
        final today = _localToday ?? history.today;
        final rows = _localRows ?? history.rows;
        final canDraw = _localCanDraw ?? history.canDraw;
        _canShakeDraw = canDraw && !_isDrawing;
        _visibleRows = rows;

        return LayoutBuilder(
          builder: (context, constraints) {
            final stageHeight = constraints.maxHeight * 0.66;
            return ColoredBox(
              color: context.hokTheme.backgroundDeep,
              child: Column(
                children: [
                  SizedBox(
                    height: stageHeight,
                    child: _FortuneStage(
                      onWebViewCreated: (controller) {
                        _instrumentController = controller;
                      },
                      onInstrumentMessage: _handleInstrumentMessage,
                    ),
                  ),
                  _FortuneActionPanel(
                    today: today,
                    canDraw: canDraw,
                    isDrawing: _isDrawing,
                    sensorAvailable: _sensorAvailable,
                    onDraw: canDraw && !_isDrawing ? _drawToday : null,
                  ),
                  Expanded(child: _FortuneTrendPanel(rows: rows)),
                ],
              ),
            );
          },
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
    if (_motionSubscription != null) return;
    _motionSubscription =
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          _handleMotion,
          onError: (_) {
            if (mounted) setState(() => _sensorAvailable = false);
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
    if (_lastShakeTriggeredAt != null &&
        now.difference(_lastShakeTriggeredAt!) <
            const Duration(milliseconds: 2400)) {
      return;
    }
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < 12.5 ||
        (_lastShakePeakAt != null &&
            now.difference(_lastShakePeakAt!) <
                const Duration(milliseconds: 140))) {
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
    if (_shakePeaks < 2) return;
    _lastShakeTriggeredAt = now;
    _shakePeaks = 0;
    _shakeWindowStartedAt = null;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_drawToday());
  }

  void _handleInstrumentMessage(String message) {
    try {
      final payload = jsonDecode(message);
      if (payload is Map) {
        if (payload['type'] == 'ready') {
          _instrumentReady = true;
        } else if (payload['type'] == 'spinComplete') {
          _instrumentSpinCompleter?.complete();
          _instrumentSpinCompleter = null;
        }
      }
    } on FormatException {
      // Ignore malformed messages from the embedded scene.
    }
  }

  Future<void> _spinInstrument() async {
    final controller = _instrumentController;
    if (controller == null || !_instrumentReady) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return;
    }
    _instrumentSpinCompleter?.complete();
    final completer = Completer<void>();
    _instrumentSpinCompleter = completer;
    try {
      await controller.runJavaScript(
        'window.rankFortune3D && window.rankFortune3D.spin();',
      );
      await completer.future.timeout(const Duration(milliseconds: 3200));
    } on Object {
      if (!completer.isCompleted) completer.complete();
    } finally {
      if (identical(_instrumentSpinCompleter, completer)) {
        _instrumentSpinCompleter = null;
      }
    }
  }

  Future<void> _drawToday() async {
    if (_isDrawing || !_canShakeDraw) return;
    setState(() {
      _isDrawing = true;
      _canShakeDraw = false;
    });
    final drawFuture = ref.read(rankFortuneRepositoryProvider).drawToday();
    final spinFuture = _spinInstrument();
    try {
      final draw = await drawFuture;
      await spinFuture;
      if (!mounted) return;
      setState(() {
        _localToday = draw.record;
        _localCanDraw = draw.canDraw;
        _localCatalog = draw.catalog;
        _localRows = [
          ..._visibleRows.where((row) => row.date != draw.record.date),
          draw.record,
        ]..sort((a, b) => a.date.compareTo(b.date));
      });
      unawaited(HapticFeedback.heavyImpact());
    } catch (error) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Unable to draw fortune: $error')),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDrawing = false;
          _canShakeDraw = _localCanDraw ?? true;
        });
      }
    }
  }
}

class _FortuneStage extends StatelessWidget {
  const _FortuneStage({
    required this.onWebViewCreated,
    required this.onInstrumentMessage,
  });

  final ValueChanged<WebViewController> onWebViewCreated;
  final ValueChanged<String> onInstrumentMessage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _CoverGeometry.calculate(
          source: const Size(1044, 1507),
          destination: constraints.biggest,
        );
        final instrumentSize = math.min(
          geometry.renderedSize.width * 0.58,
          constraints.maxHeight * 0.54,
        );
        final instrumentCenter = geometry.point(0.76, 0.44);

        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/rank-fortune/background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.48),
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: instrumentCenter.dx - instrumentSize / 2,
                top: instrumentCenter.dy - instrumentSize / 2,
                width: instrumentSize,
                height: instrumentSize,
                child: _RankFortuneInstrument(
                  onCreated: onWebViewCreated,
                  onMessage: onInstrumentMessage,
                ),
              ),
              Positioned(
                left: 16,
                top: 14,
                right: 16,
                child: const _StageHeader(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FortuneActionPanel extends StatelessWidget {
  const _FortuneActionPanel({
    required this.today,
    required this.canDraw,
    required this.isDrawing,
    required this.sensorAvailable,
    required this.onDraw,
  });

  final RankFortuneRecord? today;
  final bool canDraw;
  final bool isDrawing;
  final bool sensorAvailable;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: today == null
          ? _DrawPrompt(
              canDraw: canDraw,
              isDrawing: isDrawing,
              sensorAvailable: sensorAvailable,
              onDraw: onDraw,
            )
          : _TodayFortune(record: today!, isDrawing: isDrawing),
    );
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rank Fortune',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'A daily ritual before your ranked queue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawPrompt extends StatelessWidget {
  const _DrawPrompt({
    required this.canDraw,
    required this.isDrawing,
    required this.sensorAvailable,
    required this.onDraw,
  });

  final bool canDraw;
  final bool isDrawing;
  final bool sensorAvailable;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF090E1C).withValues(alpha: 0.78),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isDrawing
                ? Icons.motion_photos_on_rounded
                : Icons.vibration_rounded,
            color: _fortuneGold,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDrawing
                      ? 'Shaking the fortune instrument...'
                      : 'Your daily sign is waiting',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  sensorAvailable
                      ? 'Shake your phone or tap to draw'
                      : 'Tap to draw your ranked omen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onDraw,
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: _fortuneRed,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isDrawing
                  ? 'Drawing...'
                  : canDraw
                  ? 'Tap to draw instead'
                  : 'Done',
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayFortune extends StatelessWidget {
  const _TodayFortune({required this.record, required this.isDrawing});

  final RankFortuneRecord record;
  final bool isDrawing;

  @override
  Widget build(BuildContext context) {
    final copy = _fortuneCopy(record.typeId);
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 52, 11),
          decoration: BoxDecoration(
            color: const Color(0xFF090E1C).withValues(alpha: 0.82),
            border: Border.all(color: _fortuneGold.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _scoreColor(
                    context,
                    record.score,
                  ).withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: _scoreColor(context, record.score)),
                ),
                child: Text(
                  '${record.score}',
                  style: TextStyle(
                    color: _scoreColor(context, record.score),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDrawing ? 'Recasting your omen...' : copy.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      copy.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.66),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 5,
          right: 4,
          child: IconButton(
            tooltip: 'Share Fortune',
            visualDensity: VisualDensity.compact,
            onPressed: () => _shareFortune(context, record, copy),
            icon: const Icon(
              Icons.ios_share_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _RankFortuneInstrument extends StatefulWidget {
  const _RankFortuneInstrument({
    required this.onCreated,
    required this.onMessage,
  });

  final ValueChanged<WebViewController> onCreated;
  final ValueChanged<String> onMessage;

  @override
  State<_RankFortuneInstrument> createState() => _RankFortuneInstrumentState();
}

class _RankFortuneInstrumentState extends State<_RankFortuneInstrument> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..addJavaScriptChannel(
          'RankFortuneBridge',
          onMessageReceived: (message) => widget.onMessage(message.message),
        )
        ..loadFlutterAsset('assets/rank-fortune-3d/embedded.html');
      _controller = controller;
      widget.onCreated(controller);
    } on Object {
      _controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const IgnorePointer(
        child: Center(
          child: Icon(
            Icons.blur_circular_rounded,
            color: _fortuneGold,
            size: 72,
          ),
        ),
      );
    }
    return WebViewWidget(controller: controller);
  }
}

class _FortuneTrendPanel extends StatelessWidget {
  const _FortuneTrendPanel({required this.rows});

  final List<RankFortuneRecord> rows;

  @override
  Widget build(BuildContext context) {
    final sorted = [...rows]..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.length > 30
        ? sorted.sublist(sorted.length - 30)
        : sorted;
    final scores = recent.map((row) => row.score).toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border(top: BorderSide(color: context.hokTheme.outlineSoft)),
      ),
      child: scores.isEmpty
          ? Center(
              child: Text(
                'Draw a fortune to start the trend.',
                style: TextStyle(color: context.hokTheme.onSurfaceMuted),
              ),
            )
          : CustomPaint(
              painter: _FortuneCurvePainter(
                scores: scores,
                lineColor: _scoreColor(context, scores.last),
                gridColor: context.hokTheme.outlineSoft,
              ),
              child: const SizedBox.expand(),
            ),
    );
  }
}

class _FortuneCurvePainter extends CustomPainter {
  const _FortuneCurvePainter({
    required this.scores,
    required this.lineColor,
    required this.gridColor,
  });

  final List<int> scores;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty || size.isEmpty) return;
    final chart = Rect.fromLTWH(2, 4, size.width - 4, size.height - 10);
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.62)
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index += 1) {
      final y = chart.top + chart.height * index / 2;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final points = <Offset>[];
    for (var index = 0; index < scores.length; index += 1) {
      final x = scores.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (scores.length - 1);
      final y =
          chart.bottom - chart.height * (scores[index].clamp(0, 100) / 100);
      points.add(Offset(x, y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      path.lineTo(points.first.dx + 0.1, points.first.dy);
    } else {
      for (var index = 0; index < points.length - 1; index += 1) {
        final current = points[index];
        final next = points[index + 1];
        final midX = (current.dx + next.dx) / 2;
        path.cubicTo(midX, current.dy, midX, next.dy, next.dx, next.dy);
      }
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, chart.bottom)
      ..lineTo(points.first.dx, chart.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.32),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(chart),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(points.last, 4, Paint()..color = contextFreeWhite);
    canvas.drawCircle(points.last, 2.5, Paint()..color = lineColor);
  }

  static const contextFreeWhite = Colors.white;

  @override
  bool shouldRepaint(_FortuneCurvePainter oldDelegate) {
    return oldDelegate.scores != scores ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _CoverGeometry {
  const _CoverGeometry({required this.offset, required this.renderedSize});

  factory _CoverGeometry.calculate({
    required Size source,
    required Size destination,
  }) {
    final scale = math.max(
      destination.width / source.width,
      destination.height / source.height,
    );
    final rendered = Size(source.width * scale, source.height * scale);
    return _CoverGeometry(
      offset: Offset(
        (destination.width - rendered.width) / 2,
        (destination.height - rendered.height) / 2,
      ),
      renderedSize: rendered,
    );
  }

  final Offset offset;
  final Size renderedSize;

  Offset point(double x, double y) {
    return Offset(
      offset.dx + renderedSize.width * x,
      offset.dy + renderedSize.height * y,
    );
  }
}

Future<void> _shareFortune(
  BuildContext context,
  RankFortuneRecord record,
  ({String title, String description}) copy,
) async {
  await Clipboard.setData(
    ClipboardData(
      text:
          'I just drew ${copy.title} on HOK Helper today! Fortune Value: ${record.score}\n/tools/rank-fortune',
    ),
  );
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Fortune link copied')));
}

int _currentStreak(List<RankFortuneRecord> rows) {
  if (rows.isEmpty) return 0;
  final dates =
      rows
          .map((row) => DateTime.tryParse(row.date))
          .whereType<DateTime>()
          .toList(growable: false)
        ..sort();
  if (dates.length != rows.length) return rows.length;
  var streak = 1;
  for (var index = dates.length - 1; index > 0; index -= 1) {
    final expected = dates[index].subtract(const Duration(days: 1));
    final previous = dates[index - 1];
    if (previous.year != expected.year ||
        previous.month != expected.month ||
        previous.day != expected.day) {
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
  if (score >= 75) return _fortuneGold;
  if (score >= 60) return AppTheme.cyan;
  if (score >= 45) return context.hokTheme.onSurfaceMuted;
  return const Color(0xFFA78BFA);
}
