import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_section_header.dart';

class GameAssistantScreen extends StatelessWidget {
  const GameAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Game Assistant'),
          SizedBox(height: 8),
          Text(
            'Mobile Companion App',
            style: TextStyle(
              color: AppTheme.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'A lightweight match companion for timers, economy reads, cooldown tracking, and tactical prompts.',
            style: TextStyle(color: AppTheme.muted, height: 1.45),
          ),
          SizedBox(height: 18),
          _PhonePreview(),
          SizedBox(height: 18),
          _FeatureGrid(),
          SizedBox(height: 18),
          _DownloadPanel(),
        ],
      ),
    );
  }
}

class _PhonePreview extends StatelessWidget {
  const _PhonePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyan.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.panelAlt,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const _ScoreStrip(),
            const SizedBox(height: 12),
            const _GoldPanel(),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _TimerChip(
                    title: 'Blue Buff',
                    value: '15s',
                    color: AppTheme.cyan,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _TimerChip(
                    title: 'Red Buff',
                    value: '42s',
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _CooldownPanel(),
          ],
        ),
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '5/0/2',
              style: TextStyle(
                color: AppTheme.cyan,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text('12:30', style: TextStyle(color: AppTheme.muted)),
            Text(
              '2/3/1',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldPanel extends StatelessWidget {
  const _GoldPanel();

  @override
  Widget build(BuildContext context) {
    const bars = [0.24, 0.38, 0.48, 0.44, 0.58, 0.72, 0.68, 0.82];
    return _PreviewPanel(
      title: 'Gold analytics',
      icon: Icons.paid_outlined,
      color: AppTheme.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 86,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in bars) ...[
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: value,
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.28),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '+2.5k',
            style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.text,
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

class _CooldownPanel extends StatelessWidget {
  const _CooldownPanel();

  @override
  Widget build(BuildContext context) {
    return _PreviewPanel(
      title: 'Enemy cooldowns',
      icon: Icons.bolt_outlined,
      color: AppTheme.error,
      child: Column(
        children: const [
          _CooldownRow(name: 'Enemy Mid Flash', value: '120s'),
          SizedBox(height: 8),
          _CooldownRow(name: 'Enemy Mid Ultimate', value: '45s'),
        ],
      ),
    );
  }
}

class _CooldownRow extends StatelessWidget {
  const _CooldownRow({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.text),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: const [
        _FeatureCard(
          icon: Icons.timer_outlined,
          title: 'Jungle timers',
          color: AppTheme.cyan,
        ),
        _FeatureCard(
          icon: Icons.paid_outlined,
          title: 'Gold analytics',
          color: AppTheme.gold,
        ),
        _FeatureCard(
          icon: Icons.bolt_outlined,
          title: 'Enemy cooldowns',
          color: AppTheme.error,
        ),
        _FeatureCard(
          icon: Icons.psychology_outlined,
          title: 'AI tactical tips',
          color: Color(0xFFA78BFA),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadPanel extends StatelessWidget {
  const _DownloadPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.qr_code_2_outlined,
                color: AppTheme.muted,
                size: 42,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coming soon',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Store download links will unlock when the companion build is ready.',
                    style: TextStyle(color: AppTheme.muted, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
