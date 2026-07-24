import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_share_sheet.dart';
import '../data/rank_fortune_repository.dart';
import '../domain/rank_fortune.dart';

const _fortuneGold = Color(0xFFF6C453);
const _fortuneRed = Color(0xFFE5484D);

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

class _RankFortuneScreenState extends ConsumerState<RankFortuneScreen> {
  RankFortuneRecord? _localToday;
  List<RankFortuneRecord>? _localRows;
  List<RankFortuneRecord> _visibleRows = const [];
  bool? _localCanDraw;
  bool _isDrawing = false;
  bool _canDraw = false;
  WebViewController? _instrumentController;
  Completer<void>? _instrumentSpinCompleter;
  bool _instrumentReady = false;

  @override
  void dispose() {
    _instrumentSpinCompleter?.complete();
    super.dispose();
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
        _canDraw = canDraw && !_isDrawing;
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
                    isDrawing: _isDrawing,
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
    if (_isDrawing || !_canDraw) return;
    setState(() {
      _isDrawing = true;
      _canDraw = false;
    });
    final drawFuture = ref.read(rankFortuneRepositoryProvider).drawToday();
    final spinFuture = _spinInstrument();
    try {
      await spinFuture;
      final draw = await drawFuture;
      if (!mounted) return;
      setState(() {
        _localToday = draw.record;
        _localCanDraw = draw.canDraw;
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
          _canDraw = _localCanDraw ?? true;
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
    required this.isDrawing,
    required this.onDraw,
  });

  final RankFortuneRecord? today;
  final bool isDrawing;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: today == null
          ? _DrawPrompt(isDrawing: isDrawing, onDraw: onDraw)
          : _TodayFortune(record: today!),
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
          child: const Text(
            'Rank Fortune',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawPrompt extends StatelessWidget {
  const _DrawPrompt({required this.isDrawing, required this.onDraw});

  final bool isDrawing;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onDraw,
        style: FilledButton.styleFrom(
          backgroundColor: _fortuneRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _fortuneRed.withValues(alpha: 0.58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isDrawing
              ? const SizedBox.square(
                  key: ValueKey('drawing'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Try My Luck',
                  key: ValueKey('ready'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }
}

class _TodayFortune extends StatelessWidget {
  const _TodayFortune({required this.record});

  final RankFortuneRecord record;

  @override
  Widget build(BuildContext context) {
    final copy = _fortuneCopy(record.typeId);
    final scoreColor = _scoreColor(context, record.score);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF090E1C).withValues(alpha: 0.88),
        border: Border.all(color: _fortuneGold.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${record.score}',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        'Fortune Value',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  copy.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
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
      ),
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
) {
  return showAppShareSheet(
    context,
    title: 'HOK Helper Rank Fortune: ${copy.title} (${record.score})',
    url: 'https://hokhelper.com/tools/rank-fortune',
  );
}

({String title, String description}) _fortuneCopy(String typeId) {
  return switch (typeId) {
    'heavenly_win' => (
      title: 'Heavenly Win',
      description: 'Peak luck day, ideal for a hard rank push.',
    ),
    'destiny_surge' => (
      title: 'Destiny Surge',
      description: 'Momentum is on your side, climb aggressively.',
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
      description: 'Lower error rate, clearer decisions.',
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
      description: 'Tough lobbies expected, reduce game count.',
    ),
    'tilt_alert' => (
      title: 'Tilt Alert',
      description: 'Mental risk is high, take breaks between games.',
    ),
    'bad_timing' => (
      title: 'Bad Timing',
      description: 'Warm up first before entering ranked.',
    ),
    'lose_streak_risk' => (
      title: 'Lose Streak Risk',
      description: 'Not ideal for forcing a climb.',
    ),
    'doom_queue' => (
      title: 'Doom Queue',
      description: 'High-variance day, consider casual modes.',
    ),
    'legendary' => (
      title: 'Legendary Luck',
      description: 'Queue with your best hero and call tempo early.',
    ),
    'great' => (
      title: 'Great Fortune',
      description: 'Perfect day for ranked, win streak incoming!',
    ),
    'good' => (
      title: 'Good Fortune',
      description: "Good luck today, play steady and you'll climb.",
    ),
    'fair' => (
      title: 'Fair Fortune',
      description: 'Stable condition, good for duo queue.',
    ),
    'neutral' => (
      title: 'Neutral',
      description: 'Average luck, depends entirely on your skills.',
    ),
    'bad' => (
      title: 'Bad Fortune',
      description: 'Not in the best shape, maybe play some casual matches.',
    ),
    'terrible' => (
      title: 'Terrible Fortune',
      description: 'Avoid ranked today, lose streak warning!',
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
