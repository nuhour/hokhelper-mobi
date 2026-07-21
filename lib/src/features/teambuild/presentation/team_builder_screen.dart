import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_lane_icon.dart';
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
    this.allyBans = const [null, null, null, null, null],
    this.enemyBans = const [null, null, null, null, null],
    this.activeSlotType = TeamBuilderSlotType.pick,
    this.activeSide = TeamBuilderSide.ally,
    this.activeIndex = 0,
    this.recommendType = TeamRecommendType.synergy,
    this.allyIsBlue = true,
  });

  final List<TeamBuildHero?> allyPicks;
  final List<TeamBuildHero?> enemyPicks;
  final List<TeamBuildHero?> allyBans;
  final List<TeamBuildHero?> enemyBans;
  final TeamBuilderSlotType activeSlotType;
  final TeamBuilderSide activeSide;
  final int activeIndex;
  final TeamRecommendType recommendType;
  final bool allyIsBlue;

  TeamBuilderDraft copyWith({
    List<TeamBuildHero?>? allyPicks,
    List<TeamBuildHero?>? enemyPicks,
    List<TeamBuildHero?>? allyBans,
    List<TeamBuildHero?>? enemyBans,
    TeamBuilderSlotType? activeSlotType,
    TeamBuilderSide? activeSide,
    int? activeIndex,
    TeamRecommendType? recommendType,
    bool? allyIsBlue,
  }) {
    return TeamBuilderDraft(
      allyPicks: allyPicks ?? this.allyPicks,
      enemyPicks: enemyPicks ?? this.enemyPicks,
      allyBans: allyBans ?? this.allyBans,
      enemyBans: enemyBans ?? this.enemyBans,
      activeSlotType: activeSlotType ?? this.activeSlotType,
      activeSide: activeSide ?? this.activeSide,
      activeIndex: activeIndex ?? this.activeIndex,
      recommendType: recommendType ?? this.recommendType,
      allyIsBlue: allyIsBlue ?? this.allyIsBlue,
    );
  }

  List<int> get allyIds => _heroIds(allyPicks);
  List<int> get enemyIds => _heroIds(enemyPicks);
  List<int> get banIds => _heroIds([...allyBans, ...enemyBans]);
  Set<int> get occupiedIds => {...allyIds, ...enemyIds, ...banIds};
}

List<int> _heroIds(List<TeamBuildHero?> heroes) => heroes
    .whereType<TeamBuildHero>()
    .map((hero) => hero.id)
    .toList(growable: false);

enum TeamBuilderSide { ally, enemy }

enum TeamBuilderSlotType {
  pick,
  ban;

  String get apiValue => name;
}

final teamBuilderDraftProvider = StateProvider<TeamBuilderDraft>((ref) {
  return const TeamBuilderDraft();
});

final teamRecommendationsProvider = FutureProvider<TeamRecommendationResult>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  final draft = ref.watch(teamBuilderDraftProvider);
  final isAllyTarget = draft.activeSide == TeamBuilderSide.ally;
  return ref
      .watch(teamBuilderRepositoryProvider)
      .loadRecommendations(
        regionId: settings.region.regionId,
        myPicks: isAllyTarget ? draft.allyIds : draft.enemyIds,
        enemyPicks: isAllyTarget ? draft.enemyIds : draft.allyIds,
        bans: draft.banIds,
        mySide: isAllyTarget == draft.allyIsBlue ? 'blue' : 'red',
        slotType: draft.activeSlotType.apiValue,
        slotIndex: draft.activeIndex,
        recommendType: draft.recommendType,
      );
});

class TeamBuilderScreen extends ConsumerStatefulWidget {
  const TeamBuilderScreen({
    this.initialAllyHeroIds = const [],
    this.initialEnemyHeroIds = const [],
    this.initialBanHeroIds = const [],
    this.initialSlotType,
    this.initialSide,
    this.initialSlotIndex,
    super.key,
  });

  final List<int> initialAllyHeroIds;
  final List<int> initialEnemyHeroIds;
  final List<int> initialBanHeroIds;
  final TeamBuilderSlotType? initialSlotType;
  final TeamBuilderSide? initialSide;
  final int? initialSlotIndex;

  @override
  ConsumerState<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends ConsumerState<TeamBuilderScreen> {
  bool _didHydrateInitialDraft = false;
  int? _poolLane;
  int? _recommendJob;

  void _hydrateInitialDraft(List<TeamBuildHero> heroes) {
    if (_didHydrateInitialDraft) return;
    final hasInitialIntent =
        widget.initialAllyHeroIds.isNotEmpty ||
        widget.initialEnemyHeroIds.isNotEmpty ||
        widget.initialBanHeroIds.isNotEmpty ||
        widget.initialSlotType != null ||
        widget.initialSide != null ||
        widget.initialSlotIndex != null;
    if (!hasInitialIntent) {
      _didHydrateInitialDraft = true;
      return;
    }
    if (heroes.isEmpty) return;
    _didHydrateInitialDraft = true;
    final bans = widget.initialBanHeroIds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(teamBuilderDraftProvider.notifier).state = TeamBuilderDraft(
        allyPicks: _hydrateSlots(heroes, widget.initialAllyHeroIds),
        enemyPicks: _hydrateSlots(heroes, widget.initialEnemyHeroIds),
        allyBans: _hydrateSlots(heroes, bans.take(5).toList()),
        enemyBans: _hydrateSlots(heroes, bans.skip(5).take(5).toList()),
        activeSlotType: widget.initialSlotType ?? TeamBuilderSlotType.pick,
        activeSide: widget.initialSide ?? TeamBuilderSide.ally,
        activeIndex: (widget.initialSlotIndex ?? 0).clamp(0, 4),
      );
    });
  }

  void _activateSlot(
    TeamBuilderSlotType type,
    TeamBuilderSide side,
    int index,
  ) {
    final draft = ref.read(teamBuilderDraftProvider);
    ref.read(teamBuilderDraftProvider.notifier).state = draft.copyWith(
      activeSlotType: type,
      activeSide: side,
      activeIndex: index,
    );
  }

  void _selectHero(TeamBuildHero hero) {
    final draft = ref.read(teamBuilderDraftProvider);
    final existingId = _heroAtActiveSlot(draft)?.id;
    if (draft.occupiedIds.contains(hero.id) && existingId != hero.id) return;
    final allyPicks = List<TeamBuildHero?>.from(draft.allyPicks);
    final enemyPicks = List<TeamBuildHero?>.from(draft.enemyPicks);
    final allyBans = List<TeamBuildHero?>.from(draft.allyBans);
    final enemyBans = List<TeamBuildHero?>.from(draft.enemyBans);
    final target = draft.activeSlotType == TeamBuilderSlotType.pick
        ? draft.activeSide == TeamBuilderSide.ally
              ? allyPicks
              : enemyPicks
        : draft.activeSide == TeamBuilderSide.ally
        ? allyBans
        : enemyBans;
    target[draft.activeIndex] = hero;
    ref.read(teamBuilderDraftProvider.notifier).state = draft.copyWith(
      allyPicks: allyPicks,
      enemyPicks: enemyPicks,
      allyBans: allyBans,
      enemyBans: enemyBans,
      activeIndex: (draft.activeIndex + 1).clamp(0, 4),
    );
  }

  TeamBuildHero? _heroAtActiveSlot(TeamBuilderDraft draft) {
    final slots = draft.activeSlotType == TeamBuilderSlotType.pick
        ? draft.activeSide == TeamBuilderSide.ally
              ? draft.allyPicks
              : draft.enemyPicks
        : draft.activeSide == TeamBuilderSide.ally
        ? draft.allyBans
        : draft.enemyBans;
    return slots[draft.activeIndex];
  }

  void _removeHero(TeamBuilderSlotType type, TeamBuilderSide side, int index) {
    final draft = ref.read(teamBuilderDraftProvider);
    final allyPicks = List<TeamBuildHero?>.from(draft.allyPicks);
    final enemyPicks = List<TeamBuildHero?>.from(draft.enemyPicks);
    final allyBans = List<TeamBuildHero?>.from(draft.allyBans);
    final enemyBans = List<TeamBuildHero?>.from(draft.enemyBans);
    final target = type == TeamBuilderSlotType.pick
        ? side == TeamBuilderSide.ally
              ? allyPicks
              : enemyPicks
        : side == TeamBuilderSide.ally
        ? allyBans
        : enemyBans;
    target[index] = null;
    ref.read(teamBuilderDraftProvider.notifier).state = draft.copyWith(
      allyPicks: allyPicks,
      enemyPicks: enemyPicks,
      allyBans: allyBans,
      enemyBans: enemyBans,
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroesValue = ref.watch(teamBuilderHeroesProvider);
    final draft = ref.watch(teamBuilderDraftProvider);
    final recommendations = ref.watch(teamRecommendationsProvider);
    if (heroesValue case AsyncData(value: final heroes)) {
      _hydrateInitialDraft(heroes);
    }

    return Material(
      color: context.hokTheme.backgroundDeep,
      child: SafeArea(
        child: Column(
          children: [
            _BuilderToolbar(
              allyIsBlue: draft.allyIsBlue,
              onSwap: () {
                ref.read(teamBuilderDraftProvider.notifier).state = draft
                    .copyWith(allyIsBlue: !draft.allyIsBlue);
              },
              onReset: () => ref.read(teamBuilderDraftProvider.notifier).state =
                  const TeamBuilderDraft(),
            ),
            _WinRateBar(
              rates: recommendations.valueOrNull?.sideWinRates,
              allyIsBlue: draft.allyIsBlue,
            ),
            _BanStrip(
              allyBans: draft.allyBans,
              enemyBans: draft.enemyBans,
              activeType: draft.activeSlotType,
              activeSide: draft.activeSide,
              activeIndex: draft.activeIndex,
              allyIsBlue: draft.allyIsBlue,
              onTap: (side, index) =>
                  _activateSlot(TeamBuilderSlotType.ban, side, index),
              onRemove: (side, index) =>
                  _removeHero(TeamBuilderSlotType.ban, side, index),
            ),
            SizedBox(
              height: 274,
              child: _DraftBoard(
                draft: draft,
                heroes: heroesValue.valueOrNull ?? const <TeamBuildHero>[],
                recommendations: recommendations,
                recommendJob: _recommendJob,
                onRecommendationJobChanged: (value) =>
                    setState(() => _recommendJob = value),
                onRecommendationTypeChanged: (type) {
                  ref.read(teamBuilderDraftProvider.notifier).state = draft
                      .copyWith(recommendType: type);
                },
                onSlotTap: (side, index) =>
                    _activateSlot(TeamBuilderSlotType.pick, side, index),
                onRemove: (side, index) =>
                    _removeHero(TeamBuilderSlotType.pick, side, index),
                onRecommendationTap: (recommendation) {
                  final heroes =
                      heroesValue.valueOrNull ?? const <TeamBuildHero>[];
                  final hero = heroes
                      .where(
                        (candidate) => candidate.id == recommendation.heroId,
                      )
                      .firstOrNull;
                  if (hero != null) _selectHero(hero);
                },
              ),
            ),
            Expanded(
              child: switch (heroesValue) {
                AsyncData(value: final heroes) => _HeroPool(
                  heroes: heroes,
                  lane: _poolLane,
                  occupiedIds: draft.occupiedIds,
                  onLaneChanged: (value) => setState(() => _poolLane = value),
                  onHeroTap: _selectHero,
                ),
                AsyncError() => _PoolMessage(
                  icon: Icons.error_outline,
                  message: 'Failed to load hero pool',
                  onRetry: () => ref.invalidate(teamBuilderHeroesProvider),
                ),
                _ => const _PoolMessage(
                  icon: Icons.hourglass_top_rounded,
                  message: 'Loading hero pool',
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension on Iterable<TeamBuildHero> {
  TeamBuildHero? get firstOrNull => isEmpty ? null : first;
}

List<TeamBuildHero?> _hydrateSlots(List<TeamBuildHero> heroes, List<int> ids) {
  final slots = List<TeamBuildHero?>.filled(5, null);
  for (var index = 0; index < ids.length && index < slots.length; index++) {
    slots[index] = heroes
        .where(
          (hero) =>
              hero.id == ids[index] || hero.externalHeroId == '${ids[index]}',
        )
        .firstOrNull;
  }
  return slots;
}

class _BuilderToolbar extends StatelessWidget {
  const _BuilderToolbar({
    required this.allyIsBlue,
    required this.onSwap,
    required this.onReset,
  });
  final bool allyIsBlue;
  final VoidCallback onSwap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.hokTheme.outlineSoft)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.psychology_alt_rounded,
          color: AppTheme.gold,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Smart Team Builder',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.hokTheme.onSurfaceStrong,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Swap Red/Blue',
          onPressed: onSwap,
          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Reset',
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
    ),
  );
}

class _WinRateBar extends StatelessWidget {
  const _WinRateBar({required this.rates, required this.allyIsBlue});
  final TeamSideWinRates? rates;
  final bool allyIsBlue;

  @override
  Widget build(BuildContext context) {
    final blue = rates?.blue ?? .5;
    final red = rates?.red ?? .5;
    final ally = allyIsBlue ? blue : red;
    final enemy = allyIsBlue ? red : blue;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RateLabel(
              label: 'My Side',
              color: allyIsBlue
                  ? const Color(0xFF4B8BFF)
                  : const Color(0xFFFF5A65),
              value: ally,
            ),
          ),
          Expanded(
            child: _RateLabel(
              label: 'Opponent',
              textAlign: TextAlign.end,
              color: allyIsBlue
                  ? const Color(0xFFFF5A65)
                  : const Color(0xFF4B8BFF),
              value: enemy,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateLabel extends StatelessWidget {
  const _RateLabel({
    required this.label,
    required this.color,
    required this.value,
    this.textAlign = TextAlign.start,
  });
  final String label;
  final Color color;
  final double value;
  final TextAlign textAlign;
  @override
  Widget build(BuildContext context) => Text(
    '$label: Win Rate ${(value * 100).toStringAsFixed(1)}%',
    textAlign: textAlign,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _BanStrip extends StatelessWidget {
  const _BanStrip({
    required this.allyBans,
    required this.enemyBans,
    required this.activeType,
    required this.activeSide,
    required this.activeIndex,
    required this.allyIsBlue,
    required this.onTap,
    required this.onRemove,
  });
  final List<TeamBuildHero?> allyBans;
  final List<TeamBuildHero?> enemyBans;
  final TeamBuilderSlotType activeType;
  final TeamBuilderSide activeSide;
  final int activeIndex;
  final bool allyIsBlue;
  final void Function(TeamBuilderSide, int) onTap;
  final void Function(TeamBuilderSide, int) onRemove;
  @override
  Widget build(BuildContext context) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .24),
      border: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: _SlotRow(
            slots: allyBans,
            type: TeamBuilderSlotType.ban,
            side: TeamBuilderSide.ally,
            color: allyIsBlue
                ? const Color(0xFF3B82F6)
                : const Color(0xFFEF4444),
            activeType: activeType,
            activeSide: activeSide,
            activeIndex: activeIndex,
            onTap: onTap,
            onRemove: onRemove,
          ),
        ),
        Container(
          width: 1,
          height: 34,
          color: Colors.white.withValues(alpha: .1),
        ),
        Expanded(
          child: _SlotRow(
            slots: enemyBans,
            type: TeamBuilderSlotType.ban,
            side: TeamBuilderSide.enemy,
            color: allyIsBlue
                ? const Color(0xFFEF4444)
                : const Color(0xFF3B82F6),
            reverse: true,
            activeType: activeType,
            activeSide: activeSide,
            activeIndex: activeIndex,
            onTap: onTap,
            onRemove: onRemove,
          ),
        ),
      ],
    ),
  );
}

class _DraftBoard extends StatelessWidget {
  const _DraftBoard({
    required this.draft,
    required this.heroes,
    required this.recommendations,
    required this.recommendJob,
    required this.onRecommendationJobChanged,
    required this.onRecommendationTypeChanged,
    required this.onSlotTap,
    required this.onRemove,
    required this.onRecommendationTap,
  });
  final TeamBuilderDraft draft;
  final List<TeamBuildHero> heroes;
  final AsyncValue<TeamRecommendationResult> recommendations;
  final int? recommendJob;
  final ValueChanged<int?> onRecommendationJobChanged;
  final ValueChanged<TeamRecommendType> onRecommendationTypeChanged;
  final void Function(TeamBuilderSide, int) onSlotTap;
  final void Function(TeamBuilderSide, int) onRemove;
  final ValueChanged<TeamRecommendation> onRecommendationTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 66,
        child: _SlotColumn(
          slots: draft.allyPicks,
          side: TeamBuilderSide.ally,
          color: draft.allyIsBlue
              ? const Color(0xFF3B82F6)
              : const Color(0xFFEF4444),
          activeType: draft.activeSlotType,
          activeSide: draft.activeSide,
          activeIndex: draft.activeIndex,
          onTap: onSlotTap,
          onRemove: onRemove,
        ),
      ),
      Expanded(
        child: _RecommendationPanel(
          value: recommendations,
          heroForRecommendation: (recommendation) => heroes
              .where(
                (hero) =>
                    hero.id == recommendation.heroId ||
                    hero.externalHeroId == recommendation.externalHeroId,
              )
              .firstOrNull,
          type: draft.recommendType,
          mainJob: recommendJob,
          onTypeChanged: onRecommendationTypeChanged,
          onMainJobChanged: onRecommendationJobChanged,
          onTap: onRecommendationTap,
        ),
      ),
      SizedBox(
        width: 66,
        child: _SlotColumn(
          slots: draft.enemyPicks,
          side: TeamBuilderSide.enemy,
          color: draft.allyIsBlue
              ? const Color(0xFFEF4444)
              : const Color(0xFF3B82F6),
          activeType: draft.activeSlotType,
          activeSide: draft.activeSide,
          activeIndex: draft.activeIndex,
          onTap: onSlotTap,
          onRemove: onRemove,
        ),
      ),
    ],
  );
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slots,
    required this.type,
    required this.side,
    required this.color,
    required this.activeType,
    required this.activeSide,
    required this.activeIndex,
    required this.onTap,
    required this.onRemove,
    this.reverse = false,
  });
  final List<TeamBuildHero?> slots;
  final TeamBuilderSlotType type;
  final TeamBuilderSide side;
  final Color color;
  final TeamBuilderSlotType activeType;
  final TeamBuilderSide activeSide;
  final int activeIndex;
  final void Function(TeamBuilderSide, int) onTap;
  final void Function(TeamBuilderSide, int) onRemove;
  final bool reverse;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = (constraints.maxWidth / slots.length)
          .clamp(28.0, 36.0)
          .toDouble();
      return Row(
        children: [
          for (var rawIndex = 0; rawIndex < slots.length; rawIndex++)
            () {
              final index = reverse ? slots.length - rawIndex - 1 : rawIndex;
              return Expanded(
                child: Center(
                  child: _TeamSlot(
                    key: ValueKey('team-ban-${side.name}-$index'),
                    hero: slots[index],
                    color: color,
                    size: size,
                    isBan: type == TeamBuilderSlotType.ban,
                    active:
                        activeType == type &&
                        activeSide == side &&
                        activeIndex == index,
                    onTap: () => onTap(side, index),
                    onLongPress: slots[index] == null
                        ? null
                        : () => onRemove(side, index),
                  ),
                ),
              );
            }(),
        ],
      );
    },
  );
}

class _SlotColumn extends StatelessWidget {
  const _SlotColumn({
    required this.slots,
    required this.side,
    required this.color,
    required this.activeType,
    required this.activeSide,
    required this.activeIndex,
    required this.onTap,
    required this.onRemove,
  });
  final List<TeamBuildHero?> slots;
  final TeamBuilderSide side;
  final Color color;
  final TeamBuilderSlotType activeType;
  final TeamBuilderSide activeSide;
  final int activeIndex;
  final void Function(TeamBuilderSide, int) onTap;
  final void Function(TeamBuilderSide, int) onRemove;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .04),
      border: Border.symmetric(
        vertical: BorderSide(color: color.withValues(alpha: .14)),
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var index = 0; index < slots.length; index++)
          _TeamSlot(
            key: ValueKey('team-pick-${side.name}-$index'),
            hero: slots[index],
            color: color,
            active:
                activeType == TeamBuilderSlotType.pick &&
                activeSide == side &&
                activeIndex == index,
            onTap: () => onTap(side, index),
            onLongPress: slots[index] == null
                ? null
                : () => onRemove(side, index),
          ),
      ],
    ),
  );
}

class _TeamSlot extends StatelessWidget {
  const _TeamSlot({
    super.key,
    required this.hero,
    required this.color,
    required this.active,
    required this.onTap,
    this.isBan = false,
    this.size,
    this.onLongPress,
  });
  final TeamBuildHero? hero;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  final bool isBan;
  final double? size;
  final VoidCallback? onLongPress;
  @override
  Widget build(BuildContext context) {
    final slotSize = size ?? (isBan ? 40.0 : 50.0);
    return Semantics(
      button: true,
      label: hero == null ? 'Empty ${isBan ? 'ban' : 'pick'} slot' : hero!.name,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: slotSize,
            height: slotSize,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: .22),
              border: Border.all(
                color: active
                    ? AppTheme.gold
                    : color.withValues(alpha: hero == null ? .25 : .85),
                width: active ? 3 : 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: .45),
                        blurRadius: 9,
                      ),
                    ]
                  : null,
            ),
            child: hero == null
                ? Icon(
                    Icons.add_rounded,
                    color: Colors.white.withValues(alpha: .26),
                    size: isBan ? 18 : 23,
                  )
                : AppImage(
                    url: hero!.avatarUrl,
                    borderRadius: 999,
                    semanticLabel: hero!.name,
                  ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
    required this.value,
    required this.heroForRecommendation,
    required this.type,
    required this.mainJob,
    required this.onTypeChanged,
    required this.onMainJobChanged,
    required this.onTap,
  });

  final AsyncValue<TeamRecommendationResult> value;
  final TeamBuildHero? Function(TeamRecommendation) heroForRecommendation;
  final TeamRecommendType type;
  final int? mainJob;
  final ValueChanged<TeamRecommendType> onTypeChanged;
  final ValueChanged<int?> onMainJobChanged;
  final ValueChanged<TeamRecommendation> onTap;

  @override
  Widget build(BuildContext context) {
    final result = value.valueOrNull;
    final items = (result?.recommendations ?? const <TeamRecommendation>[])
        .where((item) => mainJob == null || item.mainJob == mainJob)
        .toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
            child: Row(
              children: [
                Expanded(
                  child: _RecTab(
                    label: 'Synergy Picks',
                    selected: type == TeamRecommendType.synergy,
                    onTap: () => onTypeChanged(TeamRecommendType.synergy),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RecTab(
                    label: 'Counter Picks',
                    selected: type == TeamRecommendType.counter,
                    onTap: () => onTypeChanged(TeamRecommendType.counter),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 33,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .26),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Colors.white.withValues(alpha: .07),
                ),
              ),
            ),
            child: Text(
              type == TeamRecommendType.counter
                  ? 'COUNTER OPPONENT LINEUP'
                  : 'FIT MY SIDE LINEUP RECOMMENDATIONS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _JobFilter(selected: mainJob, onChanged: onMainJobChanged),
          Expanded(
            child: value.isLoading
                ? const Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : items.isEmpty
                ? Center(
                    child: Text(
                      'No recommendations',
                      style: TextStyle(
                        color: context.hokTheme.onSurfaceMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: .06),
                    ),
                    itemBuilder: (context, index) => _RecommendationTile(
                      item: items[index],
                      hero: heroForRecommendation(items[index]),
                      onTap: () => onTap(items[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecTab extends StatelessWidget {
  const _RecTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      backgroundColor: selected ? AppTheme.gold : Colors.transparent,
      foregroundColor: selected
          ? context.hokTheme.onSurfaceStrong
          : context.hokTheme.onSurfaceMuted,
      side: BorderSide(
        color: selected ? AppTheme.gold : Colors.white.withValues(alpha: .17),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.item,
    required this.hero,
    required this.onTap,
  });
  final TeamRecommendation item;
  final TeamBuildHero? hero;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final score = item.score <= 1 ? item.score * 100 : item.score;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          key: ValueKey('team-recommendation-${item.heroId}'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 34,
                child: hero == null
                    ? CircleAvatar(
                        backgroundColor: context.hokTheme.surfaceRaised,
                        child: Text(
                          item.name.isEmpty
                              ? '?'
                              : item.name.characters.first.toUpperCase(),
                          style: TextStyle(
                            color: context.hokTheme.onSurfaceStrong,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : AppImage(
                        url: hero!.avatarUrl,
                        borderRadius: 999,
                        semanticLabel: hero!.name,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.hokTheme.onSurfaceStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick ${(item.pickRate * 100).toStringAsFixed(1)}% · Synergy ${(item.synergy * 100).toStringAsFixed(1)}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.hokTheme.onSurfaceMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobFilter extends StatelessWidget {
  const _JobFilter({required this.selected, required this.onChanged});
  final int? selected;
  final ValueChanged<int?> onChanged;
  static const _jobs = <int?>[null, 1, 2, 3, 4, 5, 6];
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      itemCount: _jobs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 7),
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return _FilterIcon(
          selected: selected == job,
          tooltip: job == null ? 'All roles' : _jobLabel(job),
          icon: job == null
              ? const Icon(Icons.grid_view_rounded, size: 16)
              : AppLaneIcon(
                  assetName: _jobAssetName(job),
                  size: 18,
                  color: selected == job
                      ? Colors.white
                      : context.hokTheme.onSurfaceMuted,
                ),
          onTap: () => onChanged(job),
        );
      },
    ),
  );
}

class _HeroPool extends StatelessWidget {
  const _HeroPool({
    required this.heroes,
    required this.lane,
    required this.occupiedIds,
    required this.onLaneChanged,
    required this.onHeroTap,
  });
  final List<TeamBuildHero> heroes;
  final int? lane;
  final Set<int> occupiedIds;
  final ValueChanged<int?> onLaneChanged;
  final ValueChanged<TeamBuildHero> onHeroTap;

  @override
  Widget build(BuildContext context) {
    final visible = heroes
        .where((hero) => lane == null || hero.matchesLane(lane!))
        .toList();
    return Column(
      children: [
        _LaneFilter(selected: lane, onChanged: onLaneChanged),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final hero = visible[index];
              final locked = occupiedIds.contains(hero.id);
              return Semantics(
                button: !locked,
                label: hero.name,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    key: ValueKey('team-pool-${hero.id}'),
                    onTap: locked ? null : () => onHeroTap(hero),
                    borderRadius: BorderRadius.circular(9),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.hokTheme.surfaceSlate,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .05),
                        ),
                      ),
                      child: Opacity(
                        opacity: locked ? .3 : 1,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AppImage(
                            url: hero.avatarUrl,
                            borderRadius: 999,
                            semanticLabel: hero.name,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LaneFilter extends StatelessWidget {
  const _LaneFilter({required this.selected, required this.onChanged});
  final int? selected;
  final ValueChanged<int?> onChanged;
  static const _lanes = <int?>[null, 0, 1, 2, 3, 4];
  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final lane in _lanes)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _FilterIcon(
              selected: selected == lane,
              tooltip: lane == null ? 'All lanes' : _laneLabel(lane),
              icon: lane == null
                  ? const Icon(Icons.grid_view_rounded, size: 17)
                  : AppLaneIcon(
                      assetName: _laneAssetName(lane),
                      size: 19,
                      color: selected == lane
                          ? Colors.white
                          : context.hokTheme.onSurfaceMuted,
                    ),
              onTap: () => onChanged(lane),
            ),
          ),
      ],
    ),
  );
}

class _FilterIcon extends StatelessWidget {
  const _FilterIcon({
    required this.selected,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final bool selected;
  final String tooltip;
  final Widget icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 31,
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppTheme.gold : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppTheme.gold
                : Colors.white.withValues(alpha: .16),
          ),
        ),
        child: icon,
      ),
    ),
  );
}

class _PoolMessage extends StatelessWidget {
  const _PoolMessage({required this.icon, required this.message, this.onRetry});
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: context.hokTheme.onSurfaceMuted),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: context.hokTheme.onSurfaceMuted)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

String _laneAssetName(int lane) => switch (lane) {
  0 => 'clash',
  1 => 'mid',
  2 => 'adc',
  3 => 'jungle',
  _ => 'support',
};
String _laneLabel(int lane) => switch (lane) {
  0 => 'Clash lane',
  1 => 'Mid lane',
  2 => 'Farm lane',
  3 => 'Jungle',
  _ => 'Support',
};
String _jobAssetName(int job) => switch (job) {
  1 => 'tank',
  2 => 'clash',
  3 => 'jungle',
  4 => 'mid',
  5 => 'adc',
  _ => 'support',
};
String _jobLabel(int job) => switch (job) {
  1 => 'Tank',
  2 => 'Fighter',
  3 => 'Assassin',
  4 => 'Mage',
  5 => 'Marksman',
  _ => 'Support',
};
