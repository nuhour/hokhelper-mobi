import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_rating_stars.dart';
import '../../settings/presentation/settings_controller.dart';
import 'hero_gallery_screen.dart';

class HeroDetailArgs {
  const HeroDetailArgs({required this.heroId, required this.regionId});

  final String heroId;
  final int regionId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HeroDetailArgs &&
            runtimeType == other.runtimeType &&
            heroId == other.heroId &&
            regionId == other.regionId;
  }

  @override
  int get hashCode => Object.hash(heroId, regionId);
}

final heroDetailProvider =
    FutureProvider.family<Map<String, dynamic>, HeroDetailArgs>((ref, args) {
      return ref
          .watch(heroesRepositoryProvider)
          .loadHeroDetail(args.heroId, args.regionId);
    });

final selectedRegionHeroDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, heroId) async {
      final settings = await ref.watch(appSettingsControllerProvider.future);
      return ref
          .watch(heroesRepositoryProvider)
          .loadHeroDetail(heroId, settings.region.regionId);
    });

enum HeroDetailFocus { skills, lore, history }

HeroDetailFocus heroDetailFocusFromRoute(String? value) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'lore' => HeroDetailFocus.lore,
    'history' => HeroDetailFocus.history,
    _ => HeroDetailFocus.skills,
  };
}

class HeroDetailScreen extends ConsumerWidget {
  const HeroDetailScreen({
    required this.heroId,
    this.focusHistory = false,
    this.initialFocus,
    this.onBack,
    super.key,
  });

  final String heroId;
  final bool focusHistory;
  final HeroDetailFocus? initialFocus;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailValue = ref.watch(selectedRegionHeroDetailProvider(heroId));

    final body = AppAsyncView<Map<String, dynamic>>(
      value: detailValue,
      retry: () => ref.invalidate(selectedRegionHeroDetailProvider(heroId)),
      data: (detail) => _HeroDetailContent(
        detail: detail,
        routeHeroId: heroId,
        focus: focusHistory
            ? HeroDetailFocus.history
            : initialFocus ?? HeroDetailFocus.skills,
      ),
    );
    if (onBack == null) return body;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onBack!();
      },
      child: Stack(
        children: [
          body,
          Positioned(
            top: 10,
            left: 12,
            child: Material(
              color: AppTheme.bg.withValues(alpha: 0.86),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Back to heroes',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDetailContent extends StatelessWidget {
  const _HeroDetailContent({
    required this.detail,
    required this.routeHeroId,
    required this.focus,
  });

  final Map<String, dynamic> detail;
  final String routeHeroId;
  final HeroDetailFocus focus;

  @override
  Widget build(BuildContext context) {
    final bundle = _readBundle(detail);
    final hero = _readMap(bundle['hero']).isNotEmpty
        ? _readMap(bundle['hero'])
        : bundle;
    final skills = _readList(bundle['skills']);
    final history = _readList(bundle['history']);
    final stats = _readMap(bundle['stats']);

    if (hero.isEmpty && skills.isEmpty && history.isEmpty) {
      return const AppEmptyState(
        icon: Icons.shield_outlined,
        title: 'Hero detail unavailable',
        message: 'Pull to refresh or try again later.',
      );
    }

    final name = _readString(hero, const ['name', 'heroName', 'hero_name']);
    final title = _readString(hero, const ['title', 'heroTitle', 'hero_title']);
    final avatar = _readString(hero, const [
      'avatar_url_large',
      'avatar_url_medium',
      'avatar_url',
      'avatar',
      'icon',
      'image',
    ]);
    final lore = _readString(hero, const ['lore', 'story', 'background']);
    final heroVideoUrl = _readString(hero, const [
      'baseTechVideo',
      'base_tech_video',
      'videoUrl',
      'video_url',
    ]);
    final roles = _roleLabel(hero);
    final rating = _readDouble(hero, const ['rating', 'avg_rating']);
    final ratingCount = _readInt(hero, const ['rating_count', 'ratings']);
    final tier = _readString(stats, const ['tier']).isNotEmpty
        ? _readString(stats, const ['tier'])
        : _readString(hero, const ['tier']);
    final winRate = _readPercent(stats, hero, const ['win_rate', 'winRate']);
    final pickRate = _readPercent(stats, hero, const ['pick_rate', 'pickRate']);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _HeroHeader(
          name: name.isEmpty ? 'Hero #$routeHeroId' : name,
          title: title,
          avatar: avatar,
          roles: roles,
          rating: rating,
          ratingCount: ratingCount,
          videoUrl: heroVideoUrl,
        ),
        const SizedBox(height: 14),
        if (focus == HeroDetailFocus.history) ...[
          const _HistoryFocusPanel(),
          const SizedBox(height: 14),
        ] else if (focus == HeroDetailFocus.lore) ...[
          const _LoreFocusPanel(),
          const SizedBox(height: 14),
        ],
        _MetricGrid(
          items: [
            _MetricItem(label: 'Tier', value: tier.isEmpty ? '--' : tier),
            _MetricItem(label: 'Win Rate', value: winRate),
            _MetricItem(label: 'Pick Rate', value: pickRate),
          ],
        ),
        const SizedBox(height: 18),
        _DetailSection(
          title: 'Skills',
          icon: Icons.flash_on_outlined,
          emptyMessage: 'No skills available.',
          children: [
            for (final skill in skills) _SkillTile(skill: _readMap(skill)),
          ],
        ),
        const SizedBox(height: 18),
        _DetailSection(
          title: 'Lore',
          icon: Icons.menu_book_outlined,
          emptyMessage: 'No lore available.',
          children: lore.isEmpty
              ? const []
              : [
                  Text(
                    _cleanMarkup(lore),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.text,
                      height: 1.5,
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 18),
        _DetailSection(
          title: 'History',
          icon: Icons.history_outlined,
          emptyMessage: 'No balance history available.',
          children: [
            for (final item in history) _HistoryTile(item: _readMap(item)),
          ],
        ),
      ],
    );
  }
}

class _LoreFocusPanel extends StatelessWidget {
  const _LoreFocusPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.menu_book_outlined, color: AppTheme.cyan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lore focus',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Opened from a hero lore link. Story and background details are included below.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                      height: 1.4,
                    ),
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

class _HistoryFocusPanel extends StatelessWidget {
  const _HistoryFocusPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.update_outlined, color: AppTheme.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patch history focus',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Opened from a patch note link. Balance changes are highlighted below.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                      height: 1.4,
                    ),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.name,
    required this.title,
    required this.avatar,
    required this.roles,
    required this.rating,
    required this.ratingCount,
    required this.videoUrl,
  });

  final String name;
  final String title;
  final String avatar;
  final String roles;
  final double? rating;
  final int ratingCount;
  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.muted.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(
            url: avatar,
            width: 84,
            height: 84,
            borderRadius: 18,
            semanticLabel: '$name hero portrait',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (videoUrl.isNotEmpty)
                      _VideoPlayButton(
                        url: videoUrl,
                        tooltip: 'Play hero introduction',
                      ),
                  ],
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                ],
                if (roles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoPill(icon: Icons.category_outlined, label: roles),
                ],
                const SizedBox(height: 10),
                AppRatingStars(
                  rating: rating ?? 0,
                  ratingCount: ratingCount,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(child: _MetricCard(item: item)),
          if (item != items.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.muted.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.muted.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.gold),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(
              emptyMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.skill});

  final Map<String, dynamic> skill;

  @override
  Widget build(BuildContext context) {
    final name = _readString(skill, const ['name', 'skillName', 'skill_name']);
    final description = _cleanMarkup(
      _readString(skill, const ['description', 'desc']),
    );
    final icon = _readString(skill, const ['iconUrl', 'icon_url', 'icon']);
    final order = _readInt(skill, const ['order', 'skill_index']);
    final cooldown = _readCooldown(skill);
    final videoUrl = _readString(skill, const [
      'videoUrl',
      'video_url',
      'default_video_url',
    ]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(
            url: icon,
            width: 48,
            height: 48,
            borderRadius: 14,
            semanticLabel: name.isEmpty ? 'Skill icon' : '$name skill icon',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      name.isEmpty ? 'Skill' : name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (order >= 0) _TinyLabel(label: _skillTypeLabel(order)),
                    if (cooldown.isNotEmpty) _TinyLabel(label: cooldown),
                    if (videoUrl.isNotEmpty)
                      _VideoPlayButton(
                        url: videoUrl,
                        tooltip: 'Play ${name.isEmpty ? 'skill' : name}',
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final title = _readString(item, const ['title', 'version']);
    final date = _readString(item, const ['date', 'created_at']);
    final type = _readString(item, const ['type']);
    final content = _cleanMarkup(_readString(item, const ['content', 'desc']));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title.isEmpty ? 'Update' : title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (type.isNotEmpty) _HistoryTypeLabel(type: type),
              if (date.isNotEmpty) _TinyLabel(label: date),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TinyLabel extends StatelessWidget {
  const _TinyLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistoryTypeLabel extends StatelessWidget {
  const _HistoryTypeLabel({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final normalized = type.trim().toLowerCase();
    final color = switch (normalized) {
      'buff' => const Color(0xFF22C55E),
      'nerf' => const Color(0xFFEF4444),
      'adjust' || 'adjustment' => AppTheme.cyan,
      _ => AppTheme.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VideoPlayButton extends StatelessWidget {
  const _VideoPlayButton({required this.url, required this.tooltip});

  final String url;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: () => _openVideo(context, url),
      icon: const Icon(Icons.play_circle_fill_rounded),
      color: AppTheme.cyan,
    );
  }

  Future<void> _openVideo(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this video')),
      );
    }
  }
}

Map<String, dynamic> _readBundle(Map<String, dynamic> detail) {
  final result = detail['result'];
  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }
  return detail;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}

List<Object?> _readList(Object? value) {
  if (value is List) {
    return value;
  }
  return const [];
}

String _readString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

int _readInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return 0;
}

double? _readDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

String _readPercent(
  Map<String, dynamic> stats,
  Map<String, dynamic> hero,
  List<String> keys,
) {
  final value = _readDouble(stats, keys) ?? _readDouble(hero, keys);
  if (value == null) {
    return '--';
  }
  final percent = value <= 1 ? value * 100 : value;
  return '${percent.toStringAsFixed(1)}%';
}

String _roleLabel(Map<String, dynamic> hero) {
  final roles = hero['roles'];
  if (roles is List) {
    final values = roles
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (values.isNotEmpty) {
      return values.join(' / ');
    }
  }

  final main = _readString(hero, const ['mainJobName', 'main_job_name']);
  final minor = _readString(hero, const ['minorJobName', 'minor_job_name']);
  return [main, minor].where((value) => value.isNotEmpty).join(' / ');
}

String _readCooldown(Map<String, dynamic> skill) {
  final value = _readDouble(skill, const ['cooldown']);
  if (value == null || value <= 0) {
    return '';
  }
  final seconds = value > 100 ? (value / 1000).round() : value.round();
  return 'Cooldown ${seconds}s';
}

String _skillTypeLabel(int order) {
  return switch (order) {
    0 => 'Passive',
    1 => 'Skill 1',
    2 => 'Skill 2',
    3 => 'Skill 3',
    4 => 'Ultimate',
    _ => 'Skill',
  };
}

String _cleanMarkup(String value) {
  return value
      .replaceAll(RegExp(r'</?color[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .trim();
}
