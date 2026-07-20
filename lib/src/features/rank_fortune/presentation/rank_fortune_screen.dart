import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/rank_fortune_repository.dart';
import '../domain/rank_fortune.dart';

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
  List<RankFortuneCatalogEntry>? _localCatalog;
  bool? _localCanDraw;
  var _isDrawing = false;

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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              const AppSectionHeader(title: 'Rank Fortune'),
              const SizedBox(height: 8),
              Text(
                "Draw your fortune for today's ranked matches.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.hokTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 18),
              _FortunePanel(
                today: today,
                canDraw: canDraw,
                isDrawing: _isDrawing,
                onDraw: canDraw && !_isDrawing ? _drawToday : null,
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

  Future<void> _drawToday() async {
    setState(() => _isDrawing = true);
    try {
      final draw = await ref.read(rankFortuneRepositoryProvider).drawToday();
      setState(() {
        _localToday = draw.record;
        _localCanDraw = draw.canDraw;
        _localCatalog = draw.catalog;
        _localRows = [...?_localRows, draw.record]
          ..sort((a, b) => a.date.compareTo(b.date));
      });
    } finally {
      if (mounted) {
        setState(() => _isDrawing = false);
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

class _FortunePanel extends StatelessWidget {
  const _FortunePanel({
    required this.today,
    required this.canDraw,
    required this.isDrawing,
    required this.onDraw,
  });

  final RankFortuneRecord? today;
  final bool canDraw;
  final bool isDrawing;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (today == null)
              const _FortuneJar()
            else
              _FortuneResult(record: today!),
            if (isDrawing) ...[
              const SizedBox(height: 16),
              const _DrawingFeedback(),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDraw,
                icon: Icon(
                  isDrawing
                      ? Icons.hourglass_top_outlined
                      : Icons.auto_awesome_outlined,
                ),
                label: Text(
                  isDrawing
                      ? 'Drawing...'
                      : canDraw
                      ? "Draw Today's Fortune"
                      : 'Already drawn today',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingFeedback extends StatelessWidget {
  const _DrawingFeedback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.26)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.gold,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Shaking the fortune jar...',
              style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FortuneJar extends StatelessWidget {
  const _FortuneJar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 118,
          height: 160,
          decoration: BoxDecoration(
            color: context.hokTheme.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(48),
              bottom: Radius.circular(24),
            ),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in const [-24.0, 0.0, 24.0])
                Transform.translate(
                  offset: Offset(offset, -20),
                  child: Transform.rotate(
                    angle: offset / 140,
                    child: Container(
                      width: 8,
                      height: 112,
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              Text(
                'Fortune Jar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Shake once per day before entering ranked queue.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.hokTheme.onSurfaceMuted),
        ),
      ],
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
          width: 88,
          height: 178,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF7D6), Color(0xFFECCB73)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF7C2D12), width: 2),
          ),
          child: Text(
            copy.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w900,
            ),
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
        Text(
          'Fortune Value',
          style: TextStyle(
            color: context.hokTheme.onSurfaceMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${record.score}',
          style: TextStyle(
            color: context.hokTheme.onSurfaceStrong,
            fontSize: 34,
            fontWeight: FontWeight.w900,
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
        color: Colors.black.withValues(alpha: 0.22),
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
