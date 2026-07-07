import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/team_builder_repository.dart';
import '../domain/team_build_hero.dart';
import '../domain/team_recommendation.dart';

final teamBuilderRepositoryProvider = Provider<TeamBuilderRepository>((ref) {
  return TeamBuilderRepository(apiClient: ref.watch(apiClientProvider));
});

final teamBuilderHeroesProvider = FutureProvider<List<TeamBuildHero>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(teamBuilderRepositoryProvider)
      .loadHeroes(settings.region.regionId);
});

class TeamBuilderDraft {
  const TeamBuilderDraft({
    this.allyPicks = const [null, null, null, null, null],
    this.enemyPicks = const [null, null, null, null, null],
    this.activeSide = TeamBuilderSide.ally,
    this.activeIndex = 0,
  });

  final List<TeamBuildHero?> allyPicks;
  final List<TeamBuildHero?> enemyPicks;
  final TeamBuilderSide activeSide;
  final int activeIndex;

  TeamBuilderDraft copyWith({
    List<TeamBuildHero?>? allyPicks,
    List<TeamBuildHero?>? enemyPicks,
    TeamBuilderSide? activeSide,
    int? activeIndex,
  }) {
    return TeamBuilderDraft(
      allyPicks: allyPicks ?? this.allyPicks,
      enemyPicks: enemyPicks ?? this.enemyPicks,
      activeSide: activeSide ?? this.activeSide,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }

  List<int> get allyIds => allyPicks
      .whereType<TeamBuildHero>()
      .map((hero) => hero.id)
      .toList(growable: false);

  List<int> get enemyIds => enemyPicks
      .whereType<TeamBuildHero>()
      .map((hero) => hero.id)
      .toList(growable: false);
}

enum TeamBuilderSide { ally, enemy }

final teamBuilderDraftProvider = StateProvider<TeamBuilderDraft>((ref) {
  return const TeamBuilderDraft();
});

final teamRecommendationsProvider = FutureProvider<TeamRecommendationResult>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  final draft = ref.watch(teamBuilderDraftProvider);
  return ref
      .watch(teamBuilderRepositoryProvider)
      .loadRecommendations(
        regionId: settings.region.regionId,
        myPicks: draft.activeSide == TeamBuilderSide.ally
            ? draft.allyIds
            : draft.enemyIds,
        enemyPicks: draft.activeSide == TeamBuilderSide.ally
            ? draft.enemyIds
            : draft.allyIds,
        slotIndex: draft.activeIndex,
      );
});

class TeamBuilderScreen extends ConsumerStatefulWidget {
  const TeamBuilderScreen({
    this.initialAllyHeroIds = const [],
    this.initialEnemyHeroIds = const [],
    this.initialSide,
    this.initialSlotIndex,
    super.key,
  });

  final List<int> initialAllyHeroIds;
  final List<int> initialEnemyHeroIds;
  final TeamBuilderSide? initialSide;
  final int? initialSlotIndex;

  @override
  ConsumerState<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends ConsumerState<TeamBuilderScreen> {
  bool _didHydrateInitialDraft = false;

  void _selectHero(WidgetRef ref, TeamBuildHero hero) {
    final draft = ref.read(teamBuilderDraftProvider);
    final ally = List<TeamBuildHero?>.of(draft.allyPicks);
    final enemy = List<TeamBuildHero?>.of(draft.enemyPicks);
    final slots = draft.activeSide == TeamBuilderSide.ally ? ally : enemy;
    slots[draft.activeIndex] = hero;
    ref.read(teamBuilderDraftProvider.notifier).state = draft.copyWith(
      allyPicks: ally,
      enemyPicks: enemy,
      activeIndex: (draft.activeIndex + 1).clamp(0, 4),
    );
  }

  void _setActiveSlot(WidgetRef ref, TeamBuilderSide side, int index) {
    final draft = ref.read(teamBuilderDraftProvider);
    ref.read(teamBuilderDraftProvider.notifier).state = draft.copyWith(
      activeSide: side,
      activeIndex: index,
    );
  }

  void _clearAll(WidgetRef ref) {
    ref.read(teamBuilderDraftProvider.notifier).state =
        const TeamBuilderDraft();
  }

  void _hydrateInitialDraft(List<TeamBuildHero> heroes) {
    if (_didHydrateInitialDraft) {
      return;
    }
    final hasInitialIntent =
        widget.initialAllyHeroIds.isNotEmpty ||
        widget.initialEnemyHeroIds.isNotEmpty ||
        widget.initialSide != null ||
        widget.initialSlotIndex != null;
    if (!hasInitialIntent) {
      _didHydrateInitialDraft = true;
      return;
    }
    if (heroes.isEmpty) {
      return;
    }

    final allyPicks = _hydratePicks(heroes, widget.initialAllyHeroIds);
    final enemyPicks = _hydratePicks(heroes, widget.initialEnemyHeroIds);
    final activeSide = widget.initialSide ?? TeamBuilderSide.ally;
    final activeIndex = (widget.initialSlotIndex ?? 0).clamp(0, 4);
    _didHydrateInitialDraft = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(teamBuilderDraftProvider.notifier).state = TeamBuilderDraft(
        allyPicks: allyPicks,
        enemyPicks: enemyPicks,
        activeSide: activeSide,
        activeIndex: activeIndex,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final heroesValue = ref.watch(teamBuilderHeroesProvider);
    if (heroesValue case AsyncData(value: final heroes)) {
      _hydrateInitialDraft(heroes);
    }
    final draft = ref.watch(teamBuilderDraftProvider);
    final recommendations = ref.watch(teamRecommendationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teamBuilderHeroesProvider);
        ref.invalidate(teamRecommendationsProvider);
        await ref.read(teamBuilderHeroesProvider.future);
        await ref.read(teamRecommendationsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(child: AppSectionHeader(title: 'Team Builder')),
              IconButton(
                tooltip: 'Reset',
                onPressed: () => _clearAll(ref),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Draft ally and enemy picks, then review data-backed recommendations.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 20),
          _PickPanel(
            title: 'Ally Picks',
            slots: draft.allyPicks,
            activeSide: draft.activeSide,
            activeIndex: draft.activeIndex,
            side: TeamBuilderSide.ally,
            onSlotTap: (side, index) => _setActiveSlot(ref, side, index),
          ),
          const SizedBox(height: 12),
          _PickPanel(
            title: 'Enemy Picks',
            slots: draft.enemyPicks,
            activeSide: draft.activeSide,
            activeIndex: draft.activeIndex,
            side: TeamBuilderSide.enemy,
            onSlotTap: (side, index) => _setActiveSlot(ref, side, index),
          ),
          const SizedBox(height: 20),
          AppAsyncView<List<TeamBuildHero>>(
            value: heroesValue,
            retry: () => ref.invalidate(teamBuilderHeroesProvider),
            data: (heroes) => _HeroPool(
              heroes: heroes,
              onHeroTap: (hero) => _selectHero(ref, hero),
            ),
          ),
          const SizedBox(height: 20),
          _RecommendationsPanel(value: recommendations),
        ],
      ),
    );
  }
}

List<TeamBuildHero?> _hydratePicks(List<TeamBuildHero> heroes, List<int> ids) {
  final picks = List<TeamBuildHero?>.filled(5, null);
  for (var index = 0; index < ids.length && index < picks.length; index += 1) {
    picks[index] = _findTeamBuildHero(heroes, ids[index]);
  }
  return picks;
}

TeamBuildHero? _findTeamBuildHero(List<TeamBuildHero> heroes, int id) {
  for (final hero in heroes) {
    if (hero.id == id || hero.externalHeroId == '$id') {
      return hero;
    }
  }
  return null;
}

class _PickPanel extends StatelessWidget {
  const _PickPanel({
    required this.title,
    required this.slots,
    required this.activeSide,
    required this.activeIndex,
    required this.side,
    required this.onSlotTap,
  });

  final String title;
  final List<TeamBuildHero?> slots;
  final TeamBuilderSide activeSide;
  final int activeIndex;
  final TeamBuilderSide side;
  final void Function(TeamBuilderSide side, int index) onSlotTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(slots.length, (index) {
                final hero = slots[index];
                final isActive = side == activeSide && index == activeIndex;
                return SizedBox(
                  width: 128,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onSlotTap(side, index),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.panelAlt : Colors.black12,
                          border: Border.all(
                            color: isActive ? AppTheme.gold : Colors.white10,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            hero == null
                                ? 'Slot ${index + 1}: Empty'
                                : 'Slot ${index + 1}: ${hero.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: hero == null
                                      ? AppTheme.muted
                                      : AppTheme.text,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPool extends StatelessWidget {
  const _HeroPool({required this.heroes, required this.onHeroTap});

  final List<TeamBuildHero> heroes;
  final ValueChanged<TeamBuildHero> onHeroTap;

  @override
  Widget build(BuildContext context) {
    if (heroes.isEmpty) {
      return const AppEmptyState(
        icon: Icons.shield_outlined,
        title: 'No heroes found',
        message: 'Pull to refresh or switch region in settings.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hero Pool',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: heroes
              .take(30)
              .map((hero) {
                return _HeroChip(hero: hero, onTap: () => onHeroTap(hero));
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.hero, required this.onTap});

  final TeamBuildHero hero;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppImage(
                  url: hero.avatarUrl,
                  height: 28,
                  width: 28,
                  borderRadius: 999,
                  semanticLabel: hero.name,
                ),
                const SizedBox(width: 8),
                Text(
                  hero.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationsPanel extends StatelessWidget {
  const _RecommendationsPanel({required this.value});

  final AsyncValue<TeamRecommendationResult> value;

  @override
  Widget build(BuildContext context) {
    return AppAsyncView<TeamRecommendationResult>(
      value: value,
      retry: null,
      data: (result) {
        if (result.recommendations.isEmpty) {
          return const AppEmptyState(
            icon: Icons.psychology_alt_outlined,
            title: 'No recommendations',
            message: 'Select heroes to refresh team recommendations.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recommendations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (result.sideWinRates case final rates?)
                  Text(
                    'Blue ${_formatPercent(rates.blue)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...result.recommendations.take(10).map(_RecommendationCard.new),
          ],
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard(this.recommendation);

  final TeamRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.panel,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recommendation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'Score ${recommendation.score.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (recommendation.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  recommendation.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    label: 'Pick',
                    value: _formatPercent(recommendation.pickRate),
                  ),
                  _MetricChip(
                    label: 'Synergy',
                    value: _formatPercent(recommendation.synergy),
                  ),
                  _MetricChip(
                    label: 'Counter',
                    value: _formatPercent(recommendation.counter),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          '$label $value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(1)}%';
}
