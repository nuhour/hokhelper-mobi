import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_lane_icon.dart';
import '../../../core/widgets/app_list_footer.dart';
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
    this.allyIsBlue = true,
  });

  final List<TeamBuildHero?> allyPicks;
  final List<TeamBuildHero?> enemyPicks;
  final List<TeamBuildHero?> allyBans;
  final List<TeamBuildHero?> enemyBans;
  final TeamBuilderSlotType activeSlotType;
  final TeamBuilderSide activeSide;
  final int activeIndex;
  final bool allyIsBlue;

  TeamBuilderDraft copyWith({
    List<TeamBuildHero?>? allyPicks,
    List<TeamBuildHero?>? enemyPicks,
    List<TeamBuildHero?>? allyBans,
    List<TeamBuildHero?>? enemyBans,
    TeamBuilderSlotType? activeSlotType,
    TeamBuilderSide? activeSide,
    int? activeIndex,
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
      allyIsBlue: allyIsBlue ?? this.allyIsBlue,
    );
  }

  List<int> get allyIds => _heroIds(allyPicks);
  List<int> get enemyIds => _heroIds(enemyPicks);
  List<int> get allyBanIds => _heroIds(allyBans);
  List<int> get enemyBanIds => _heroIds(enemyBans);
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

/// 只影响结果 Tab，不属于服务端 DraftState，切换时不重复请求推荐接口。
final teamBuilderRecommendTypeProvider = StateProvider<TeamRecommendType>((
  ref,
) {
  return TeamRecommendType.balanced;
});

final teamRecommendationsProvider =
    FutureProvider.family<TeamRecommendationResult, int?>((ref, mainJob) async {
      final settings = await ref.watch(appSettingsControllerProvider.future);
      final draft = ref.watch(teamBuilderDraftProvider);
      final repository = ref.watch(teamBuilderRepositoryProvider);
      final isAllyTarget = draft.activeSide == TeamBuilderSide.ally;
      final activeSide = isAllyTarget == draft.allyIsBlue ? 'blue' : 'red';
      final bluePicks = draft.allyIsBlue ? draft.allyIds : draft.enemyIds;
      final redPicks = draft.allyIsBlue ? draft.enemyIds : draft.allyIds;
      final blueBans = draft.allyIsBlue ? draft.allyBanIds : draft.enemyBanIds;
      final redBans = draft.allyIsBlue ? draft.enemyBanIds : draft.allyBanIds;
      // Draft v2：Ban 只使用双方已选阵容作为上下文，Pick 使用双方实际阵容；
      // 双方 Ban 独立传递，服务端一次返回适配/保护和克制/拆解两组结果。
      return repository.loadRecommendations(
        regionId: settings.region.regionId,
        bans: draft.banIds,
        mySide: activeSide,
        slotType: draft.activeSlotType.apiValue,
        slotIndex: draft.activeIndex,
        recommendType: TeamRecommendType.balanced,
        mainJob: mainJob,
        limit: 50,
        blueBans: blueBans,
        redBans: redBans,
        bluePicks: bluePicks,
        redPicks: redPicks,
        activeSide: activeSide,
        activeSlotType: draft.activeSlotType.apiValue,
        activeSlotIndex: draft.activeIndex,
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
      activeIndex: _nextActiveIndex(draft),
    );
  }

  int _nextActiveIndex(TeamBuilderDraft draft) {
    // 对方 Ban 位从右向左展示，数字索引递减才是视觉上的下一个位置。
    final step =
        draft.activeSlotType == TeamBuilderSlotType.ban &&
            draft.activeSide == TeamBuilderSide.enemy
        ? -1
        : 1;
    return (draft.activeIndex + step).clamp(0, 4);
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
    final recommendations = ref.watch(
      teamRecommendationsProvider(_recommendJob),
    );
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
              onReset: () {
                ref.read(teamBuilderDraftProvider.notifier).state =
                    const TeamBuilderDraft();
                ref.read(teamBuilderRecommendTypeProvider.notifier).state =
                    TeamRecommendType.balanced;
              },
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
                recommendationType: ref.watch(teamBuilderRecommendTypeProvider),
                hasEnemyPickContext:
                    (draft.activeSide == TeamBuilderSide.ally
                            ? draft.enemyPicks
                            : draft.allyPicks)
                        .whereType<TeamBuildHero>()
                        .isNotEmpty,
                onRecommendationJobChanged: (value) =>
                    setState(() => _recommendJob = value),
                onRecommendationTypeChanged: (type) {
                  ref.read(teamBuilderRecommendTypeProvider.notifier).state =
                      type;
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
                  message: AppLocalizations.of(context).serviceSlow,
                  onRetry: () => ref.invalidate(teamBuilderHeroesProvider),
                ),
                _ => _PoolMessage(
                  icon: Icons.hourglass_top_rounded,
                  message: AppLocalizations.of(context).loading,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.hokTheme.outlineSoft)),
      ),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            tooltip: l10n.translate('teamSwap'),
            onPressed: onSwap,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
          ),
          IconButton(
            tooltip: l10n.translate('commonReset'),
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _WinRateBar extends StatelessWidget {
  const _WinRateBar({required this.rates, required this.allyIsBlue});
  final TeamSideWinRates? rates;
  final bool allyIsBlue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blue = rates?.blue ?? .5;
    final red = rates?.red ?? .5;
    final ally = allyIsBlue ? blue : red;
    final enemy = allyIsBlue ? red : blue;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceMuted,
        border: Border(bottom: BorderSide(color: context.hokTheme.outlineSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RateLabel(
              label: l10n.translate('teamMySide'),
              color: allyIsBlue
                  ? const Color(0xFF4B8BFF)
                  : const Color(0xFFFF5A65),
              value: ally,
            ),
          ),
          Expanded(
            child: _RateLabel(
              label: l10n.translate('teamOpponent'),
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
      color: context.hokTheme.surfaceMuted,
      border: Border(bottom: BorderSide(color: context.hokTheme.outlineSoft)),
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
        Container(width: 1, height: 34, color: context.hokTheme.outlineSoft),
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
    required this.recommendationType,
    required this.hasEnemyPickContext,
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
  final TeamRecommendType recommendationType;
  final bool hasEnemyPickContext;
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
          type: recommendationType,
          slotType: draft.activeSlotType,
          hasEnemyPickContext: hasEnemyPickContext,
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
  Widget build(BuildContext context) {
    // Draft 槽位固定为五个；即使外部状态缺少元素，也不能让对方一侧少渲染槽位。
    final visibleSlots = List<TeamBuildHero?>.generate(
      5,
      (index) => index < slots.length ? slots[index] : null,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .04),
        border: Border.symmetric(
          vertical: BorderSide(color: color.withValues(alpha: .14)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var index = 0; index < visibleSlots.length; index++)
            _TeamSlot(
              key: ValueKey('team-pick-${side.name}-$index'),
              hero: visibleSlots[index],
              color: color,
              active:
                  activeType == TeamBuilderSlotType.pick &&
                  activeSide == side &&
                  activeIndex == index,
              onTap: () => onTap(side, index),
              onLongPress: visibleSlots[index] == null
                  ? null
                  : () => onRemove(side, index),
            ),
        ],
      ),
    );
  }
}

class _TeamSlot extends StatefulWidget {
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
  State<_TeamSlot> createState() => _TeamSlotState();
}

class _TeamSlotState extends State<_TeamSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.active) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _TeamSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _rotationController.repeat();
    } else {
      _rotationController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slotSize = widget.size ?? (widget.isBan ? 40.0 : 50.0);
    return Semantics(
      button: true,
      label: widget.hero == null
          ? 'Empty ${widget.isBan ? 'ban' : 'pick'} slot'
          : widget.hero!.name,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: slotSize,
            height: slotSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.active)
                  Positioned.fill(
                    child: RotationTransition(
                      turns: _rotationController,
                      child: CustomPaint(
                        painter: const _ActiveTeamSlotRingPainter(),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.all(widget.active ? 4 : 1),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.hokTheme.surfaceRaised,
                    border: Border.all(
                      color: widget.color.withValues(
                        alpha: widget.hero == null ? .25 : .85,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: widget.active
                        ? [
                            BoxShadow(
                              color: AppTheme.gold.withValues(alpha: .38),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: widget.hero == null
                      ? Icon(
                          Icons.add_rounded,
                          color: context.hokTheme.onSurfaceMuted,
                          size: widget.isBan ? 18 : 23,
                        )
                      : AppImage(
                          url: widget.hero!.avatarUrl,
                          borderRadius: 999,
                          semanticLabel: widget.hero!.name,
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

class _ActiveTeamSlotRingPainter extends CustomPainter {
  const _ActiveTeamSlotRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = AppTheme.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    const segments = 8;
    const sweep = math.pi / 7;
    for (var index = 0; index < segments; index++) {
      canvas.drawArc(rect, index * math.pi * 2 / segments, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ActiveTeamSlotRingPainter oldDelegate) {
    return false;
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
    required this.value,
    required this.heroForRecommendation,
    required this.type,
    required this.slotType,
    required this.hasEnemyPickContext,
    required this.mainJob,
    required this.onTypeChanged,
    required this.onMainJobChanged,
    required this.onTap,
  });

  final AsyncValue<TeamRecommendationResult> value;
  final TeamBuildHero? Function(TeamRecommendation) heroForRecommendation;
  final TeamRecommendType type;
  final TeamBuilderSlotType slotType;
  final bool hasEnemyPickContext;
  final int? mainJob;
  final ValueChanged<TeamRecommendType> onTypeChanged;
  final ValueChanged<int?> onMainJobChanged;
  final ValueChanged<TeamRecommendation> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = value.valueOrNull;
    final isBanSlot = slotType == TeamBuilderSlotType.ban;
    final counterNeedsContext =
        !isBanSlot && type == TeamRecommendType.counter && !hasEnemyPickContext;
    // HOKX 网页端全量渲染推荐列表，移动端保持一致，不做条数截断。
    final fitSource = result?.fitRecommendations.isNotEmpty == true
        ? result!.fitRecommendations
        : (result?.recommendations ?? const <TeamRecommendation>[]);
    final source = type == TeamRecommendType.counter
        ? (result?.counterRecommendations ?? const <TeamRecommendation>[])
        : fitSource;
    final items = source
        .where(
          (item) =>
              mainJob == null ||
              item.mainJob == mainJob ||
              item.minorJob == mainJob,
        )
        .toList(growable: false);
    // 短列表不渲染到底提示，避免噪音。
    final showEndFooter = items.length > 10;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: context.hokTheme.outlineSoft),
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
                    // HOKX 规则：ban 位展示禁用优先级推荐，pick 位展示适配阵容推荐。
                    label: isBanSlot
                        ? l10n.translate('teamProtectLineup')
                        : result?.phase == 'opening_pick'
                        ? l10n.translate('teamOpeningPicks')
                        : l10n.translate('teamSynergy'),
                    selected: type != TeamRecommendType.counter,
                    onTap: () => onTypeChanged(TeamRecommendType.balanced),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RecTab(
                    label: isBanSlot
                        ? l10n.translate('teamDenyEnemy')
                        : l10n.translate('teamCounter'),
                    selected: type == TeamRecommendType.counter,
                    onTap: () => onTypeChanged(TeamRecommendType.counter),
                  ),
                ),
              ],
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
                      counterNeedsContext
                          ? l10n.translate('teamCounterWaiting')
                          : l10n.translate('teamNoRecommendations'),
                      style: TextStyle(
                        color: context.hokTheme.onSurfaceMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length + (showEndFooter ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: context.hokTheme.outlineSoft),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const AppListFooter(hasMore: false);
                      }
                      return _RecommendationTile(
                        item: items[index],
                        hero: heroForRecommendation(items[index]),
                        isBanSlot: isBanSlot,
                        isCounterMode: type == TeamRecommendType.counter,
                        onTap: () => onTap(items[index]),
                      );
                    },
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
          ? Theme.of(context).colorScheme.onPrimary
          : context.hokTheme.onSurfaceMuted,
      side: BorderSide(
        color: selected ? AppTheme.gold : context.hokTheme.outlineSoft,
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
    required this.isBanSlot,
    required this.isCounterMode,
    required this.onTap,
  });
  final TeamRecommendation item;
  final TeamBuildHero? hero;
  final bool isBanSlot;
  final bool isCounterMode;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pickLabel = l10n.translate('statsPickRate');
    final banLabel = l10n.translate('statsBanRate');
    final synergyLabel = l10n.translate('teamSynergyScore');
    final counterLabel = l10n.translate('teamCounterScore');
    final protectLabel = l10n.translate('teamProtectLineup');
    final denyLabel = l10n.translate('teamDenyEnemy');
    final confidenceLabel = l10n.translate('teamRecommendationConfidence');
    final contextualValue = isBanSlot
        ? (isCounterMode ? item.deny : item.protect)
        : (isCounterMode ? item.counter : item.synergy);
    final contextualLabel = isBanSlot
        ? (isCounterMode ? denyLabel : protectLabel)
        : (isCounterMode ? counterLabel : synergyLabel);
    final contextualAvailable = isBanSlot
        ? true
        : isCounterMode
        ? item.counterAvailable
        : item.synergyAvailable;
    final rawScore = item.score > 0
        ? item.score
        : contextualValue > 0
        ? contextualValue
        : item.pickRate + item.banRate;
    final score = (rawScore <= 1 ? rawScore * 100 : rawScore)
        .clamp(0.0, 100.0)
        .toDouble();
    final contextualText = contextualAvailable
        ? '${(contextualValue * 100).toStringAsFixed(0)}%'
        : '—';
    final metricText = isBanSlot
        ? '$banLabel ${(item.banRate * 100).toStringAsFixed(1)}% · '
              '$contextualLabel ${(contextualValue * 100).toStringAsFixed(0)}% · '
              '$confidenceLabel ${(item.confidence * 100).toStringAsFixed(0)}%'
        : '$pickLabel ${(item.pickRate * 100).toStringAsFixed(1)}% · '
              '$contextualLabel $contextualText · '
              '$confidenceLabel ${(item.confidence * 100).toStringAsFixed(0)}%';
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
                      metricText,
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
                      ? Theme.of(context).colorScheme.onPrimary
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
                        border: Border.all(color: context.hokTheme.outlineSoft),
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
  static const _lanes = <int?>[null, 0, 3, 1, 2, 4];
  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: context.hokTheme.outlineSoft),
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
                          ? Theme.of(context).colorScheme.onPrimary
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
            color: selected ? AppTheme.gold : context.hokTheme.outlineSoft,
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
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).retry),
          ),
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
