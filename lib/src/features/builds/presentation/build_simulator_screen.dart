import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/app_notice.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_lane_icon.dart';
import '../../../core/widgets/app_list_footer.dart';
import '../../../core/widgets/app_share_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../heroes/domain/hero_summary.dart';
import '../../heroes/presentation/hero_gallery_screen.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/builds_repository.dart';
import '../domain/build_editor_asset.dart';
import '../domain/build_scheme_summary.dart';
import 'build_explorer_screen.dart';

final buildSimHeroesProvider = FutureProvider<List<HeroSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(heroesRepositoryProvider)
      .loadHeroes(settings.region.regionId);
});

final buildSimPublicSchemesProvider = FutureProvider<List<BuildSchemeSummary>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(buildsRepositoryProvider)
      .loadPublicSchemes(settings.region.regionId);
});

final buildSimFavoriteSchemesProvider =
    FutureProvider<List<BuildSchemeSummary>>((ref) {
      return ref.watch(buildsRepositoryProvider).loadFavoriteSchemes();
    });

final buildSimUserSlotsProvider =
    FutureProvider.family<List<BuildSchemeSummary?>, int>((ref, heroId) async {
      final settings = await ref.watch(appSettingsControllerProvider.future);
      return ref
          .watch(buildsRepositoryProvider)
          .loadUserHeroSlots(
            heroId: heroId,
            regionId: settings.region.regionId,
          );
    });

final buildSimEditorCatalogProvider = FutureProvider<BuildEditorCatalog>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  final repository = ref.watch(buildsRepositoryProvider);
  final equips = await repository.loadTopEquips(settings.region.regionId);
  final runes = await repository.loadRunes(settings.region.regionId);
  final summonerSkills = await repository.loadSummonerSkills(
    settings.region.regionId,
  );
  return BuildEditorCatalog(
    equips: equips,
    runes: runes,
    summonerSkills: summonerSkills,
  );
});

final buildSimTopEquipsProvider = FutureProvider<List<BuildEquipSummary>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(buildsRepositoryProvider)
      .loadTopEquips(settings.region.regionId);
});

final buildSimSaveSchemeProvider =
    Provider<Future<void> Function(BuildSchemeDraft)>((ref) {
      return ref.watch(buildsRepositoryProvider).saveBuildScheme;
    });

final buildSimLikeSchemeProvider =
    Provider<Future<void> Function(BuildSchemeSummary)>((ref) {
      final repository = ref.watch(buildsRepositoryProvider);
      return (scheme) => scheme.isLiked
          ? repository.unlikeBuildScheme(scheme.id)
          : repository.likeBuildScheme(scheme.id);
    });

final buildSimFavoriteSchemeProvider =
    Provider<Future<void> Function(BuildSchemeSummary)>((ref) {
      final repository = ref.watch(buildsRepositoryProvider);
      return (scheme) => scheme.isFavorited
          ? repository.unfavoriteBuildScheme(scheme.id)
          : repository.favoriteBuildScheme(scheme.id);
    });

final buildSimCloneSchemeProvider =
    Provider<Future<void> Function(BuildSchemeSummary, int)>((ref) {
      final repository = ref.watch(buildsRepositoryProvider);
      return (scheme, slotIndex) => repository.cloneBuildScheme(
        schemeId: scheme.id,
        slotIndex: slotIndex,
        name: 'Default Build $slotIndex',
      );
    });

enum BuildSimCommunityFilter { explore, favorites }

class BuildSimulatorScreen extends ConsumerStatefulWidget {
  const BuildSimulatorScreen({
    this.initialHeroId,
    this.initialSchemeId,
    this.initialCommunityFilter = BuildSimCommunityFilter.explore,
    super.key,
  });

  final int? initialHeroId;
  final int? initialSchemeId;
  final BuildSimCommunityFilter initialCommunityFilter;

  @override
  ConsumerState<BuildSimulatorScreen> createState() =>
      _BuildSimulatorScreenState();
}

class _BuildSimulatorScreenState extends ConsumerState<BuildSimulatorScreen> {
  int _selectedHeroIndex = 0;
  bool _didResolveInitialHero = false;
  late BuildSimCommunityFilter _communityFilter;

  @override
  void initState() {
    super.initState();
    _communityFilter = widget.initialCommunityFilter;
  }

  @override
  void didUpdateWidget(covariant BuildSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHeroId != widget.initialHeroId) {
      _didResolveInitialHero = false;
    }
    if (oldWidget.initialCommunityFilter != widget.initialCommunityFilter) {
      _communityFilter = widget.initialCommunityFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated =
        ref.watch(authControllerProvider).valueOrNull != null;
    final communityFilter = isAuthenticated
        ? _communityFilter
        : BuildSimCommunityFilter.explore;
    final heroesValue = ref.watch(buildSimHeroesProvider);
    final communitySchemesValue =
        communityFilter == BuildSimCommunityFilter.favorites
        ? ref.watch(buildSimFavoriteSchemesProvider)
        : ref.watch(buildSimPublicSchemesProvider);
    final topEquips =
        ref.watch(buildSimTopEquipsProvider).valueOrNull ??
        const <BuildEquipSummary>[];

    return AppAsyncView<List<HeroSummary>>(
      value: heroesValue,
      retry: () => ref.invalidate(buildSimHeroesProvider),
      data: (heroes) {
        _resolveInitialHero(heroes);
        final selectedHero = heroes.isEmpty
            ? null
            : heroes[_selectedHeroIndex.clamp(0, heroes.length - 1)];
        final heroId = int.tryParse(selectedHero?.heroId ?? '');
        final slotsValue = !isAuthenticated || heroId == null
            ? const AsyncValue<List<BuildSchemeSummary?>>.data([])
            : ref.watch(buildSimUserSlotsProvider(heroId));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(buildSimHeroesProvider);
            ref.invalidate(buildSimPublicSchemesProvider);
            ref.invalidate(buildSimTopEquipsProvider);
            if (heroId != null) {
              ref.invalidate(buildSimUserSlotsProvider(heroId));
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              if (heroes.isEmpty)
                AppEmptyState(
                  icon: Icons.person_search_outlined,
                  title: AppLocalizations.of(context).noData,
                  message: AppLocalizations.of(context).serviceSlow,
                )
              else ...[
                _HeroSelector(
                  heroes: heroes,
                  selectedIndex: _selectedHeroIndex,
                  onOpenPicker: () => _openHeroPicker(context, heroes),
                ),
                if (isAuthenticated) ...[
                  const SizedBox(height: 28),
                  _SlotsPanel(
                    slotsValue: slotsValue,
                    selectedCollection: communityFilter,
                    showSlots:
                        communityFilter == BuildSimCommunityFilter.explore,
                    onCollectionChanged: (filter) {
                      if (filter == BuildSimCommunityFilter.favorites) {
                        ref.invalidate(buildSimFavoriteSchemesProvider);
                      }
                      setState(() => _communityFilter = filter);
                    },
                    onEdit: (slotIndex, scheme) {
                      _openBuildEditor(
                        context: context,
                        heroId: heroId!,
                        heroName: selectedHero?.name ?? '',
                        heroAvatar: selectedHero?.avatar ?? '',
                        slotIndex: slotIndex,
                        scheme: scheme,
                      );
                    },
                  ),
                ],
              ],
              const SizedBox(height: 32),
              _CommunityBuilds(
                value: communitySchemesValue,
                filter: communityFilter,
                focusedSchemeId: widget.initialSchemeId,
                heroes: heroes,
                topEquips: topEquips,
                onHeroRequested: (requestedHeroId) {
                  final index = heroes.indexWhere((hero) {
                    return int.tryParse(hero.heroId) == requestedHeroId ||
                        int.tryParse(hero.id) == requestedHeroId;
                  });
                  if (index >= 0 && index != _selectedHeroIndex) {
                    setState(() => _selectedHeroIndex = index);
                  }
                },
                onActionDone: heroId == null
                    ? null
                    : () {
                        ref.invalidate(buildSimPublicSchemesProvider);
                        ref.invalidate(buildSimFavoriteSchemesProvider);
                        ref.invalidate(buildSimUserSlotsProvider(heroId));
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  void _resolveInitialHero(List<HeroSummary> heroes) {
    final initialHeroId = widget.initialHeroId;
    if (_didResolveInitialHero || initialHeroId == null || heroes.isEmpty) {
      return;
    }

    final index = heroes.indexWhere((hero) {
      return int.tryParse(hero.heroId) == initialHeroId ||
          int.tryParse(hero.id) == initialHeroId;
    });
    if (index >= 0) {
      _selectedHeroIndex = index;
    }
    _didResolveInitialHero = true;
  }

  Future<void> _openHeroPicker(
    BuildContext context,
    List<HeroSummary> heroes,
  ) async {
    final selected = await showModalBottomSheet<HeroSummary>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BuildHeroPoolSheet(
        heroes: heroes,
        selectedIndex: _selectedHeroIndex,
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    final selectedIndex = heroes.indexWhere((hero) => hero.id == selected.id);
    if (selectedIndex >= 0) {
      setState(() => _selectedHeroIndex = selectedIndex);
    }
  }

  Future<void> _openBuildEditor({
    required BuildContext context,
    required int heroId,
    required String heroName,
    required String heroAvatar,
    required int slotIndex,
    required BuildSchemeSummary? scheme,
  }) async {
    final regionCode = ref
        .read(appSettingsControllerProvider)
        .maybeWhen(
          data: (settings) => settings.region.languageCode,
          orElse: () => 'en',
        );
    final didSave = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (editorContext, animation, secondaryAnimation) =>
            _BuildEditorPanel(
              key: ValueKey('$heroId-$slotIndex-${scheme?.id ?? 'new'}'),
              heroId: heroId,
              slotIndex: slotIndex,
              heroName: heroName,
              heroAvatar: heroAvatar,
              regionCode: regionCode,
              scheme: scheme,
              onCancel: () => Navigator.of(editorContext).pop(false),
              onSaved: () => Navigator.of(editorContext).pop(true),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (didSave == true) {
      ref.invalidate(buildSimUserSlotsProvider(heroId));
    }
  }
}

class _HeroSelector extends StatelessWidget {
  const _HeroSelector({
    required this.heroes,
    required this.selectedIndex,
    required this.onOpenPicker,
  });

  final List<HeroSummary> heroes;
  final int selectedIndex;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    final selectedHero = heroes[selectedIndex.clamp(0, heroes.length - 1)];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onOpenPicker,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 132,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.62)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
                child: AppImage(
                  url: selectedHero.avatar,
                  width: 76,
                  height: 76,
                  borderRadius: 999,
                  semanticLabel: selectedHero.name,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedHero.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click to switch hero',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.chevron_right,
                  color: AppTheme.gold,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildHeroPoolSheet extends StatefulWidget {
  const _BuildHeroPoolSheet({
    required this.heroes,
    required this.selectedIndex,
  });

  final List<HeroSummary> heroes;
  final int selectedIndex;

  @override
  State<_BuildHeroPoolSheet> createState() => _BuildHeroPoolSheetState();
}

class _BuildHeroPoolSheetState extends State<_BuildHeroPoolSheet> {
  final _searchController = TextEditingController();
  int? _lanePosition;
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _search.trim().toLowerCase();
    final heroes = widget.heroes
        .where(
          (hero) =>
              (_lanePosition == null || hero.position == _lanePosition) &&
              (needle.isEmpty ||
                  hero.name.toLowerCase().contains(needle) ||
                  hero.title.toLowerCase().contains(needle)),
        )
        .toList(growable: false);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.hokTheme.onSurfaceMuted.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hero Pool',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.hokTheme.onSurfaceStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: AppLocalizations.of(context).close,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  ).translate('buildSearchHeroes'),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              _BuildLaneFilterBar(
                lanePosition: _lanePosition,
                onChanged: (value) => setState(() => _lanePosition = value),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: heroes.isEmpty
                    ? AppEmptyState(
                        icon: Icons.person_search_outlined,
                        title: AppLocalizations.of(context).noData,
                        message: AppLocalizations.of(context).serviceSlow,
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: heroes.length,
                        itemBuilder: (context, index) {
                          final hero = heroes[index];
                          final selected =
                              hero.id == widget.heroes[widget.selectedIndex].id;
                          return Semantics(
                            button: true,
                            selected: selected,
                            label: 'Select ${hero.name}',
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(hero),
                              borderRadius: BorderRadius.circular(10),
                              child: Ink(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.gold.withValues(alpha: 0.16)
                                      : context.hokTheme.surfaceRaised,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? AppTheme.gold
                                        : context.hokTheme.outlineSoft,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: AppImage(
                                        url: hero.avatar,
                                        borderRadius: 8,
                                        semanticLabel: hero.name,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      hero.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.hokTheme.onSurfaceStrong,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildLaneFilterBar extends StatelessWidget {
  const _BuildLaneFilterBar({
    required this.lanePosition,
    required this.onChanged,
  });

  final int? lanePosition;
  final ValueChanged<int?> onChanged;

  static const _options = [
    _BuildLaneOption(label: 'All', assetName: null, value: null),
    _BuildLaneOption(label: 'Clash', assetName: 'clash', value: 0),
    _BuildLaneOption(label: 'Jungle', assetName: 'jungle', value: 3),
    _BuildLaneOption(label: 'Mid', assetName: 'mid', value: 1),
    _BuildLaneOption(label: 'Farm', assetName: 'adc', value: 2),
    _BuildLaneOption(label: 'Support', assetName: 'support', value: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _options
          .map((option) {
            final selected = lanePosition == option.value;
            return Tooltip(
              message: option.label,
              child: InkWell(
                onTap: () => onChanged(option.value),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.gold
                        : context.hokTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppTheme.gold
                          : context.hokTheme.outlineSoft,
                    ),
                  ),
                  child: option.assetName == null
                      ? const Icon(Icons.grid_view_rounded, size: 18)
                      : AppLaneIcon(
                          assetName: option.assetName!,
                          size: 21,
                          color: selected
                              ? Colors.white
                              : context.hokTheme.onSurfaceMuted,
                        ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _BuildLaneOption {
  const _BuildLaneOption({
    required this.label,
    required this.assetName,
    required this.value,
  });

  final String label;
  final String? assetName;
  final int? value;
}

class _SlotsPanel extends StatelessWidget {
  const _SlotsPanel({
    required this.slotsValue,
    required this.selectedCollection,
    required this.showSlots,
    required this.onCollectionChanged,
    required this.onEdit,
  });

  final AsyncValue<List<BuildSchemeSummary?>> slotsValue;
  final BuildSimCommunityFilter selectedCollection;
  final bool showSlots;
  final ValueChanged<BuildSimCommunityFilter> onCollectionChanged;
  final void Function(int slotIndex, BuildSchemeSummary? scheme) onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.dashboard_customize_rounded,
              color: AppTheme.gold,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.translate('buildMyBuilds'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.hokTheme.onSurfaceStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _BuildCollectionTabs(
          selected: selectedCollection,
          onSelected: onCollectionChanged,
        ),
        if (showSlots) const SizedBox(height: 24),
        if (showSlots)
          slotsValue.when(
            data: (slots) {
              final normalized = List<BuildSchemeSummary?>.generate(
                3,
                (index) => index < slots.length ? slots[index] : null,
              );
              return Column(
                children: List.generate(
                  normalized.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == normalized.length - 1 ? 0 : 18,
                    ),
                    child: _SlotCard(
                      index: index + 1,
                      scheme: normalized[index],
                      onTap: () => onEdit(index + 1, normalized[index]),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text(
              friendlyErrorMessage(context, error),
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.index,
    required this.scheme,
    required this.onTap,
  });

  final int index;
  final BuildSchemeSummary? scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title =
        scheme?.title ??
        l10n.format('buildCreate', <String, String>{'index': '$index'});
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: scheme == null ? 118 : 142,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.hokTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme == null
                  ? context.hokTheme.onSurfaceMuted.withValues(alpha: 0.28)
                  : context.hokTheme.outlineSoft,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scheme != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.hokTheme.onSurfaceStrong,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 17,
                      color: AppTheme.gold,
                    ),
                  ],
                ),
              const Spacer(),
              if (scheme == null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: context.hokTheme.onSurfaceMuted.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.add_box_rounded,
                          color: context.hokTheme.onSurfaceMuted,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: TextStyle(
                          color: context.hokTheme.onSurfaceMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: scheme!.equipmentIcons
                      .take(6)
                      .map(
                        (icon) => AppImage(
                          url: icon,
                          width: 36,
                          height: 36,
                          borderRadius: 999,
                          excludeFromSemantics: true,
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: _CompactBuildLoadout(
                    summonerSkillIcon: scheme!.summonerSkillIcon,
                    runes: _buildRuneGroups(scheme!.runeIds),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

List<_BuildRuneGroup> _buildRuneGroups(List<int> runeIds) {
  final counts = <int, int>{};
  for (final runeId in runeIds) {
    if (runeId > 0) counts[runeId] = (counts[runeId] ?? 0) + 1;
  }
  return counts.entries
      .map((entry) => _BuildRuneGroup(id: entry.key, count: entry.value))
      .toList(growable: false);
}

class _BuildCollectionTabs extends StatelessWidget {
  const _BuildCollectionTabs({
    required this.selected,
    required this.onSelected,
  });

  final BuildSimCommunityFilter selected;
  final ValueChanged<BuildSimCommunityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 74,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.hokTheme.outlineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BuildCollectionTab(
              icon: Icons.bookmarks_rounded,
              label: l10n.translate('buildMyBuilds'),
              selected: selected == BuildSimCommunityFilter.explore,
              onTap: () => onSelected(BuildSimCommunityFilter.explore),
            ),
          ),
          Expanded(
            child: _BuildCollectionTab(
              icon: Icons.star_rounded,
              label: l10n.translate('buildMyFavorites'),
              selected: selected == BuildSimCommunityFilter.favorites,
              onTap: () => onSelected(BuildSimCommunityFilter.favorites),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildCollectionTab extends StatelessWidget {
  const _BuildCollectionTab({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : context.hokTheme.onSurfaceMuted,
              size: 22,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : context.hokTheme.onSurfaceMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildEditorPanel extends ConsumerStatefulWidget {
  const _BuildEditorPanel({
    super.key,
    required this.heroId,
    required this.slotIndex,
    required this.heroName,
    required this.heroAvatar,
    required this.regionCode,
    required this.scheme,
    required this.onCancel,
    required this.onSaved,
    this.isTemporary = false,
  });

  final int heroId;
  final int slotIndex;
  final String heroName;
  final String heroAvatar;
  final String regionCode;
  final BuildSchemeSummary? scheme;
  final VoidCallback onCancel;
  final VoidCallback onSaved;
  final bool isTemporary;

  @override
  ConsumerState<_BuildEditorPanel> createState() => _BuildEditorPanelState();
}

class _BuildEditorPanelState extends ConsumerState<_BuildEditorPanel> {
  late final TextEditingController _titleController;
  late bool _isPublic;
  late List<int> _equipIds;
  late List<int> _runeIds;
  late Map<int, int> _runeLevels;
  late int _equipSlotCount;
  int? _equipTypeFilter;
  int? _summonerSkillId;
  _BuildEditorTab _activeTab = _BuildEditorTab.equipment;
  int _activeRuneColor = 1;
  int _selectedRuneLevel = 5;
  bool _showArcanaOverview = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final scheme = widget.scheme;
    _titleController = TextEditingController(
      text:
          scheme?.title ??
          '${widget.heroName.isEmpty ? 'Hero' : widget.heroName} slot ${widget.slotIndex}',
    );
    _isPublic = scheme?.isPublic ?? false;
    _equipIds = [...(scheme?.equipmentIds ?? const [])];
    _equipSlotCount = math.max(6, _equipIds.length);
    _runeIds = [...(scheme?.runeIds ?? const [])];
    _runeLevels = {for (final runeId in _runeIds) runeId: 5};
    _summonerSkillId = scheme?.summonerSkillId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Material(
        color: context.hokTheme.backgroundDeep,
        child: SafeArea(
          child: SizedBox(
            height: constraints.maxHeight,
            child: Column(
              children: [
                _BuildEditorToolbar(
                  heroName: widget.heroName,
                  heroAvatar: widget.heroAvatar,
                  titleController: _titleController,
                  isPublic: _isPublic,
                  saving: _saving,
                  isTemporary: widget.isTemporary,
                  onToggleVisibility: () =>
                      setState(() => _isPublic = !_isPublic),
                  onClear: _clearAll,
                  onClose: widget.onCancel,
                  onSave: widget.isTemporary || _saving ? null : _save,
                ),
                _BuildEditorTabs(
                  selected: _activeTab,
                  onSelected: (tab) {
                    setState(() {
                      _activeTab = tab;
                      if (tab == _BuildEditorTab.arcana) {
                        _showArcanaOverview = false;
                      }
                    });
                  },
                ),
                Expanded(
                  child: ref
                      .watch(buildSimEditorCatalogProvider)
                      .when(
                        data: (catalog) => _buildEditorBody(catalog),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Center(
                          child: Text(
                            friendlyErrorMessage(context, error),
                            style: const TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorBody(BuildEditorCatalog catalog) {
    return switch (_activeTab) {
      _BuildEditorTab.equipment => _BuildEquipmentWorkspace(
        key: const ValueKey('equipment'),
        equips: catalog.equips,
        selectedIds: _equipIds,
        slotCount: _equipSlotCount,
        typeFilter: _equipTypeFilter,
        onToggle: _toggleEquip,
        onRemove: _removeEquip,
        onReorder: _reorderEquips,
        onAddSlot: _addEquipSlot,
        onTypeFilterChanged: (value) =>
            setState(() => _equipTypeFilter = value),
        onCatalogTabSelected: _selectCatalogTab,
      ),
      _BuildEditorTab.arcana => _BuildArcanaWorkspace(
        key: const ValueKey('arcana'),
        runes: catalog.runes,
        selectedIds: _runeIds,
        selectedLevels: _runeLevels,
        activeColor: _activeRuneColor,
        selectedLevel: _selectedRuneLevel,
        showOverview: _showArcanaOverview,
        onColorSelected: (color) => setState(() => _activeRuneColor = color),
        onLevelSelected: (level) => setState(() => _selectedRuneLevel = level),
        onCountChanged: (rune, delta) =>
            _updateRune(rune, delta, catalog.runes),
        onCatalogTabSelected: _selectCatalogTab,
      ),
      _BuildEditorTab.skill => _BuildSkillWorkspace(
        key: const ValueKey('skill'),
        skills: catalog.summonerSkills,
        selectedId: _summonerSkillId,
        onSelected: (skillId) => setState(() => _summonerSkillId = skillId),
      ),
    };
  }

  void _toggleEquip(int equipId) {
    setState(() {
      if (_equipIds.contains(equipId)) {
        _equipIds = _equipIds.where((id) => id != equipId).toList();
      } else if (_equipIds.length < math.min(12, _equipSlotCount)) {
        // 与 HOKX 一致：只有存在空槽位时才能加入新装备。
        _equipIds = [..._equipIds, equipId];
      }
    });
  }

  void _addEquipSlot() {
    if (_equipSlotCount >= 12) return;
    setState(() => _equipSlotCount++);
  }

  void _removeEquip(int equipId) {
    setState(() {
      _equipIds = _equipIds.where((id) => id != equipId).toList();
    });
  }

  void _reorderEquips(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _equipIds.length ||
        _equipIds.length < 2) {
      return;
    }
    final targetIndex = newIndex.clamp(0, _equipIds.length - 1);
    if (oldIndex == targetIndex) return;
    setState(() {
      final next = [..._equipIds];
      final item = next.removeAt(oldIndex);
      next.insert(targetIndex, item);
      _equipIds = next;
    });
  }

  void _clearAll() {
    setState(() {
      _equipIds = [];
      _runeIds = [];
      _runeLevels = {};
      _summonerSkillId = null;
    });
  }

  void _selectCatalogTab(_BuildCatalogTab tab) {
    setState(() {
      switch (tab) {
        case _BuildCatalogTab.items:
          _activeTab = _BuildEditorTab.equipment;
          _showArcanaOverview = false;
        case _BuildCatalogTab.arcana:
          _activeTab = _BuildEditorTab.arcana;
          _showArcanaOverview = false;
        case _BuildCatalogTab.overview:
          _activeTab = _BuildEditorTab.arcana;
          _showArcanaOverview = true;
      }
    });
  }

  void _updateRune(
    BuildRuneSummary rune,
    int delta,
    List<BuildRuneSummary> runes,
  ) {
    if (delta == 0) return;
    setState(() {
      final colorIds = runes
          .where((item) => item.color == rune.color)
          .map((item) => item.id)
          .toSet();
      final selectedInColor = _runeIds.where(colorIds.contains).length;
      if (delta < 0 && _runeIds.contains(rune.id)) {
        final next = [..._runeIds];
        next.remove(rune.id);
        _runeIds = next;
        if (!_runeIds.contains(rune.id)) {
          _runeLevels.remove(rune.id);
        } else {
          _runeLevels[rune.id] = _selectedRuneLevel;
        }
      } else if (delta > 0 && selectedInColor < 10) {
        _runeIds = [..._runeIds, rune.id];
        _runeLevels[rune.id] = _selectedRuneLevel;
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final draft = BuildSchemeDraft(
      schemeId: widget.scheme?.id == 0 ? null : widget.scheme?.id,
      heroId: widget.heroId,
      slotIndex: widget.slotIndex,
      title: title.isEmpty ? 'Slot ${widget.slotIndex} build' : title,
      isPublic: _isPublic,
      equipIds: _equipIds,
      runeIds: _runeIds,
      summonerSkillId: _summonerSkillId,
      regionCode: widget.regionCode,
    );
    setState(() => _saving = true);
    try {
      await ref.read(buildSimSaveSchemeProvider)(draft);
      widget.onSaved();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

enum _BuildEditorTab { equipment, arcana, skill }

enum _BuildCatalogTab { items, arcana, overview }

class _BuildEditorToolbar extends StatelessWidget {
  const _BuildEditorToolbar({
    required this.heroName,
    required this.heroAvatar,
    required this.titleController,
    required this.isPublic,
    required this.saving,
    required this.isTemporary,
    required this.onToggleVisibility,
    required this.onClear,
    required this.onClose,
    required this.onSave,
  });

  final String heroName;
  final String heroAvatar;
  final TextEditingController titleController;
  final bool isPublic;
  final bool saving;
  final bool isTemporary;
  final VoidCallback onToggleVisibility;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border(bottom: BorderSide(color: context.hokTheme.outlineSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold.withValues(alpha: 0.16),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.55)),
            ),
            child: heroAvatar.isEmpty
                ? const Icon(Icons.shield_outlined, size: 28)
                : ClipOval(
                    child: AppImage(url: heroAvatar, semanticLabel: heroName),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isTemporary)
                        IconButton(
                          onPressed: onToggleVisibility,
                          tooltip: isPublic ? 'Public build' : 'Private build',
                          icon: Icon(
                            isPublic ? Icons.public : Icons.lock_outline,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        onPressed: onClear,
                        tooltip: AppLocalizations.of(
                          context,
                        ).translate('commonReset'),
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: onClose,
                        tooltip: AppLocalizations.of(context).close,
                        icon: const Icon(Icons.close),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (!isTemporary)
                        IconButton(
                          onPressed: onSave,
                          tooltip: AppLocalizations.of(
                            context,
                          ).translate('buildSave'),
                          icon: saving
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          color: AppTheme.gold,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: titleController,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      color: context.hokTheme.onSurfaceStrong,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: heroName.isEmpty
                          ? 'Build name'
                          : '$heroName build',
                      hintStyle: TextStyle(
                        color: context.hokTheme.onSurfaceMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildEditorTabs extends StatelessWidget {
  const _BuildEditorTabs({required this.selected, required this.onSelected});

  final _BuildEditorTab selected;
  final ValueChanged<_BuildEditorTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (
        tab: _BuildEditorTab.equipment,
        icon: Icons.inventory_2_rounded,
        label: l10n.translate('buildEquipment'),
      ),
      (
        tab: _BuildEditorTab.arcana,
        icon: Icons.hub_rounded,
        label: l10n.translate('buildArcana'),
      ),
      (
        tab: _BuildEditorTab.skill,
        icon: Icons.auto_awesome_rounded,
        label: l10n.translate('buildSpells'),
      ),
    ];
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      color: context.hokTheme.surfaceSlate,
      child: Row(
        children: tabs
            .map(
              (entry) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => onSelected(entry.tab),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected == entry.tab
                            ? AppTheme.gold
                            : context.hokTheme.backgroundDeep,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected == entry.tab
                              ? AppTheme.gold
                              : context.hokTheme.outlineSoft,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            entry.icon,
                            size: 18,
                            color: selected == entry.tab
                                ? Theme.of(context).colorScheme.onPrimary
                                : context.hokTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              entry.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected == entry.tab
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : context.hokTheme.onSurfaceMuted,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _BuildEquipmentWorkspace extends StatelessWidget {
  const _BuildEquipmentWorkspace({
    super.key,
    required this.equips,
    required this.selectedIds,
    required this.slotCount,
    required this.typeFilter,
    required this.onToggle,
    required this.onRemove,
    required this.onReorder,
    required this.onAddSlot,
    required this.onTypeFilterChanged,
    required this.onCatalogTabSelected,
  });

  final List<BuildEquipSummary> equips;
  final List<int> selectedIds;
  final int slotCount;
  final int? typeFilter;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onAddSlot;
  final ValueChanged<int?> onTypeFilterChanged;
  final ValueChanged<_BuildCatalogTab> onCatalogTabSelected;

  @override
  Widget build(BuildContext context) {
    final equipById = {for (final equip in equips) equip.id: equip};
    final visibleEquips = typeFilter == null
        ? equips
        : equips
              .where((equip) => equip.category == '$typeFilter')
              .toList(growable: false);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: context.hokTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(22),
            border: Border(
              bottom: BorderSide(color: context.hokTheme.outlineSoft),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flash_on_outlined,
                    color: AppTheme.gold,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EQUIPMENT',
                    style: TextStyle(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: slotCount >= 12 ? null : onAddSlot,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 28),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('+ Slot'),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${selectedIds.length}/12',
                    style: TextStyle(
                      color: context.hokTheme.onSurfaceMuted.withValues(
                        alpha: 0.8,
                      ),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 槽位统一 48×48 且底对齐，填入/移除装备时其余槽位不发生位移。
              SizedBox(
                height: _BuildEquipmentSlots.itemHeight,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  itemCount: math.max(slotCount, selectedIds.length),
                  onReorderItem: onReorder,
                  itemBuilder: (context, index) {
                    if (index >= selectedIds.length) {
                      return SizedBox(
                        key: ValueKey('empty-equipment-slot-$index'),
                        width: _BuildEquipmentSlots.itemWidth,
                        height: _BuildEquipmentSlots.itemHeight,
                        child: const Align(
                          alignment: Alignment.bottomLeft,
                          child: _BuildEmptyEquipmentSlot(),
                        ),
                      );
                    }
                    final equipId = selectedIds[index];
                    final equip = equipById[equipId];
                    return SizedBox(
                      key: ValueKey('selected-equip-$equipId'),
                      width: _BuildEquipmentSlots.itemWidth,
                      height: _BuildEquipmentSlots.itemHeight,
                      // 长按槽位继续用于拖拽排序；装备详情从下方目录长按查看。
                      child: ReorderableDelayedDragStartListener(
                        index: index,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: Container(
                                width: _BuildEquipmentSlots.slotSize,
                                height: _BuildEquipmentSlots.slotSize,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.hokTheme.backgroundDeep
                                      .withValues(alpha: 0.7),
                                  border: Border.all(
                                    color: context.hokTheme.outlineSoft,
                                    width: 1.4,
                                  ),
                                ),
                                child: AppImage(
                                  url: equip?.iconUrl,
                                  borderRadius: 999,
                                  semanticLabel: equip?.name,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: _BuildEquipmentSlots.slotSize - 10,
                              child: InkWell(
                                onTap: () => onRemove(equipId),
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.error,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        _BuildCatalogTabs(
          selected: _BuildCatalogTab.items,
          onSelected: onCatalogTabSelected,
        ),
        _EquipmentFilterBar(
          selected: typeFilter,
          onChanged: onTypeFilterChanged,
        ),
        Expanded(
          child: visibleEquips.isEmpty
              ? AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: AppLocalizations.of(context).noData,
                  message: AppLocalizations.of(context).serviceSlow,
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: visibleEquips.length,
                  itemBuilder: (context, index) {
                    final equip = visibleEquips[index];
                    final selected = selectedIds.contains(equip.id);
                    return _BuildCatalogAsset(
                      label: equip.name,
                      imageUrl: equip.iconUrl,
                      selected: selected,
                      onTap: () => onToggle(equip.id),
                      onLongPress: () => _showBuildAssetDetails(
                        context: context,
                        title: equip.name,
                        iconUrl: equip.iconUrl,
                        lines: _equipmentDetailLines(
                          equip,
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                      tooltipMessage: _equipmentDetailsText(
                        equip,
                        Localizations.localeOf(context).languageCode,
                      ),
                      showLabel: false,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// 装备槽尺寸常量：空槽与满槽保持一致，避免选中装备后槽位发生位移。
abstract final class _BuildEquipmentSlots {
  static const double slotSize = 48;
  static const double itemWidth = 56;
  static const double itemHeight = 52;
}

class _BuildEmptyEquipmentSlot extends StatelessWidget {
  const _BuildEmptyEquipmentSlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _BuildEquipmentSlots.slotSize,
      height: _BuildEquipmentSlots.slotSize,
      child: CustomPaint(
        painter: _DashedCirclePainter(color: context.hokTheme.outlineSoft),
        child: Icon(
          Icons.add,
          size: 16,
          color: context.hokTheme.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final radius = (size.shortestSide - paint.strokeWidth) / 2;
    final center = size.center(Offset.zero);
    const dashCount = 12;
    const step = 2 * math.pi / dashCount;
    const sweep = step * 0.55;
    for (var index = 0; index < dashCount; index++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        index * step,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BuildCatalogTabs extends StatelessWidget {
  const _BuildCatalogTabs({required this.selected, required this.onSelected});

  final _BuildCatalogTab selected;
  final ValueChanged<_BuildCatalogTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.hokTheme.outlineSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CatalogTab(
              label: l10n.translate('buildItems').toUpperCase(),
              selected: selected == _BuildCatalogTab.items,
              onTap: () => onSelected(_BuildCatalogTab.items),
            ),
          ),
          Expanded(
            child: _CatalogTab(
              label: l10n.translate('buildArcana').toUpperCase(),
              selected: selected == _BuildCatalogTab.arcana,
              onTap: () => onSelected(_BuildCatalogTab.arcana),
            ),
          ),
          Expanded(
            child: _CatalogTab(
              label: l10n.translate('buildOverview').toUpperCase(),
              selected: selected == _BuildCatalogTab.overview,
              onTap: () => onSelected(_BuildCatalogTab.overview),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 3,
            color: selected ? AppTheme.gold : Colors.transparent,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppTheme.gold : context.hokTheme.onSurfaceMuted,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    ),
  );
}

class _EquipmentFilterBar extends StatelessWidget {
  const _EquipmentFilterBar({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  // HOKX equip_type 映射：物理 1 / 法术 2 / 防御 3 / 移动 4 / 打野 5 / 辅助 7。
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <({String label, int? value})>[
      (label: l10n.translate('commonAll'), value: null),
      (label: l10n.translate('buildAttack'), value: 1),
      (label: l10n.translate('buildMagic'), value: 2),
      (label: l10n.translate('buildDefense'), value: 3),
      (label: l10n.translate('buildMove'), value: 4),
      (label: l10n.translate('buildJungle'), value: 5),
      (label: l10n.translate('buildSupport'), value: 7),
    ];
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        children: [
          for (final option in options)
            _EquipmentFilter(
              label: option.label,
              selected: selected == option.value,
              onTap: () => onChanged(option.value),
            ),
        ],
      ),
    );
  }
}

class _EquipmentFilter extends StatelessWidget {
  const _EquipmentFilter({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold : context.hokTheme.backgroundDeep,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.gold : context.hokTheme.outlineSoft,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : context.hokTheme.onSurfaceMuted,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    ),
  );
}

class _BuildArcanaWorkspace extends StatelessWidget {
  const _BuildArcanaWorkspace({
    super.key,
    required this.runes,
    required this.selectedIds,
    required this.selectedLevels,
    required this.activeColor,
    required this.selectedLevel,
    required this.showOverview,
    required this.onColorSelected,
    required this.onLevelSelected,
    required this.onCountChanged,
    required this.onCatalogTabSelected,
  });

  final List<BuildRuneSummary> runes;
  final List<int> selectedIds;
  final Map<int, int> selectedLevels;
  final int activeColor;
  final int selectedLevel;
  final bool showOverview;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<int> onLevelSelected;
  final void Function(BuildRuneSummary rune, int delta) onCountChanged;
  final ValueChanged<_BuildCatalogTab> onCatalogTabSelected;

  @override
  Widget build(BuildContext context) {
    final colorRunes = runes
        .where((rune) => rune.color == activeColor)
        .toList();
    final tabs = _BuildCatalogTabs(
      selected: showOverview
          ? _BuildCatalogTab.overview
          : _BuildCatalogTab.arcana,
      onSelected: onCatalogTabSelected,
    );
    final details = showOverview
        ? _ArcanaOverview(
            runes: runes,
            selectedIds: selectedIds,
            selectedLevels: selectedLevels,
          )
        : Column(
            children: [
              _ArcanaSelectionHeader(
                activeColor: activeColor,
                selectedLevel: selectedLevel,
                selectedCount: _selectedCount(activeColor),
                onLevelSelected: onLevelSelected,
              ),
              Expanded(
                child: colorRunes.isEmpty
                    ? AppEmptyState(
                        icon: Icons.hexagon_outlined,
                        title: AppLocalizations.of(context).noData,
                        message: AppLocalizations.of(context).serviceSlow,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 5, 12, 18),
                        itemCount: colorRunes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 5),
                        itemBuilder: (context, index) {
                          final rune = colorRunes[index];
                          final count = selectedIds
                              .where((id) => id == rune.id)
                              .length;
                          return _ArcanaRuneRow(
                            rune: rune,
                            count: count,
                            selectedLevel:
                                selectedLevels[rune.id] ?? selectedLevel,
                            canAdd: _selectedCount(activeColor) < 10,
                            onDecrease: count == 0
                                ? null
                                : () => onCountChanged(rune, -1),
                            onIncrease: _selectedCount(activeColor) >= 10
                                ? null
                                : () => onCountChanged(rune, 1),
                          );
                        },
                      ),
              ),
            ],
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLandscape =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight < 300;
        final matrix = LayoutBuilder(
          builder: (context, matrixConstraints) {
            final size = math
                .max(
                  0,
                  math.min(
                    304.0,
                    math.min(
                      matrixConstraints.maxWidth - 16,
                      matrixConstraints.maxHeight - 8,
                    ),
                  ),
                )
                .toDouble();
            return Center(
              child: _ArcanaMatrixPreview(
                size: size,
                runes: runes,
                selectedIds: selectedIds,
                selectedLevels: selectedLevels,
                activeColor: activeColor,
                onColorSelected: onColorSelected,
                onRemove: (rune) => onCountChanged(rune, -1),
              ),
            );
          },
        );
        if (compactLandscape) {
          return Row(
            children: [
              Expanded(flex: 4, child: matrix),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    tabs,
                    Expanded(child: details),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(flex: 5, child: matrix),
            tabs,
            Expanded(flex: 4, child: details),
          ],
        );
      },
    );
  }

  int _selectedCount(int color) {
    final ids = runes
        .where((rune) => rune.color == color)
        .map((rune) => rune.id)
        .toSet();
    return selectedIds.where(ids.contains).length;
  }
}

class _ArcanaMatrixPreview extends StatelessWidget {
  const _ArcanaMatrixPreview({
    required this.size,
    required this.runes,
    required this.selectedIds,
    required this.selectedLevels,
    required this.activeColor,
    required this.onColorSelected,
    required this.onRemove,
  });

  final double size;
  final List<BuildRuneSummary> runes;
  final List<int> selectedIds;
  final Map<int, int> selectedLevels;
  final int activeColor;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<BuildRuneSummary> onRemove;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final rune in runes) rune.id: rune};
    final groups = <int, List<BuildRuneSummary?>>{1: [], 2: [], 3: []};
    for (final id in selectedIds) {
      final rune = byId[id];
      if (rune != null && groups.containsKey(rune.color)) {
        groups[rune.color]!.add(rune);
      }
    }
    for (final color in groups.keys) {
      while (groups[color]!.length < 10) {
        groups[color]!.add(null);
      }
    }
    final totalLevel = selectedIds.fold<int>(
      0,
      (sum, id) => sum + (selectedLevels[id] ?? byId[id]?.level ?? 5),
    );
    final scale = size / 288;
    final hexHeight = 23 * scale;
    final hexWidth = hexHeight * 1.15474;
    final distance = (23 * 0.866 + 4) * scale;
    final innerPadding = 8 * scale;
    final usage = <int, int>{1: 0, 2: 0, 3: 0};
    final sectors = <({int color, double angle})>[
      (color: 3, angle: -math.pi / 2),
      (color: 3, angle: -math.pi / 6),
      (color: 1, angle: math.pi / 6),
      (color: 1, angle: math.pi / 2),
      (color: 2, angle: 5 * math.pi / 6),
      (color: 2, angle: -5 * math.pi / 6),
    ];
    final slots = <Widget>[];
    var slotIndex = 0;
    for (final sector in sectors) {
      for (var ring = 2; ring <= 3; ring++) {
        for (var index = 0; index < ring; index++) {
          final rune = groups[sector.color]![usage[sector.color]!];
          usage[sector.color] = usage[sector.color]! + 1;
          final radius = ring * (distance * 0.866) + innerPadding;
          final offset = (index - (ring - 1) / 2) * distance;
          final x =
              radius * math.cos(sector.angle) - offset * math.sin(sector.angle);
          final y =
              radius * math.sin(sector.angle) + offset * math.cos(sector.angle);
          final rotation = sector.angle + math.pi / 2;
          slots.add(
            Positioned(
              key: ValueKey('arcana-matrix-slot-$slotIndex'),
              left: size / 2 + x - hexWidth / 2,
              top: size / 2 + y - hexHeight / 2,
              width: hexWidth,
              height: hexHeight,
              child: _ArcanaHexSlot(
                rune: rune,
                rotation: rotation,
                color: sector.color,
                onTap: rune == null ? null : () => onRemove(rune),
              ),
            ),
          );
          slotIndex++;
        }
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hokTheme.outlineSoft),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final color in const [3, 1, 2])
            _ArcanaColorCounter(
              boardSize: size,
              color: color,
              count: groups[color]!.whereType<BuildRuneSummary>().length,
              selected: activeColor == color,
              onTap: () => onColorSelected(color),
            ),
          ClipPath(
            clipper: const _ArcanaHexClipper(),
            child: Container(
              width: 78.52 * scale,
              height: 68 * scale,
              alignment: Alignment.center,
              color: context.hokTheme.backgroundDeep.withValues(alpha: 0.9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$totalLevel',
                    style: TextStyle(
                      color: context.hokTheme.onSurfaceStrong,
                      fontSize: math.max(12, 22 * scale),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'ARCANA',
                    style: TextStyle(
                      color: context.hokTheme.onSurfaceMuted,
                      fontSize: math.max(6, 8 * scale),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...slots,
        ],
      ),
    );
  }
}

class _ArcanaColorCounter extends StatelessWidget {
  const _ArcanaColorCounter({
    required this.boardSize,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final double boardSize;
  final int color;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = boardSize / 288;
    final angle = switch (color) {
      3 => -math.pi / 2,
      1 => math.pi / 6,
      _ => 5 * math.pi / 6,
    };
    final radius = 114 * scale;
    final buttonSize = math.max(28, 40 * scale).toDouble();
    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius;
    final accent = _arcanaAccent(color);
    return Positioned(
      left: boardSize / 2 + x - buttonSize / 2,
      top: boardSize / 2 + y - buttonSize / 2,
      width: buttonSize,
      height: buttonSize,
      child: Semantics(
        button: true,
        label: '${_arcanaColorName(color)} arcana, $count of 10',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: selected ? 0.92 : 0.58),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.24),
                width: selected ? 2.4 : 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.42),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcanaHexSlot extends StatelessWidget {
  const _ArcanaHexSlot({
    required this.rune,
    required this.rotation,
    required this.color,
    required this.onTap,
  });

  final BuildRuneSummary? rune;
  final double rotation;
  final int color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _arcanaAccent(color);
    return Tooltip(
      message: rune == null ? 'Empty arcana slot' : 'Remove ${rune!.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: rotation,
          child: ClipPath(
            clipper: const _ArcanaHexClipper(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: rune == null
                    ? accent.withValues(alpha: 0.07)
                    : accent.withValues(alpha: 0.22),
              ),
              child: rune == null
                  ? const SizedBox.expand()
                  : Transform.rotate(
                      angle: -rotation,
                      child: Transform.scale(
                        scale: 1.28,
                        child: AppImage(
                          url: rune!.iconUrl,
                          fit: BoxFit.cover,
                          borderRadius: 0,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcanaSelectionHeader extends StatelessWidget {
  const _ArcanaSelectionHeader({
    required this.activeColor,
    required this.selectedLevel,
    required this.selectedCount,
    required this.onLevelSelected,
  });

  final int activeColor;
  final int selectedLevel;
  final int selectedCount;
  final ValueChanged<int> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final accent = _arcanaAccent(activeColor);
    return Container(
      height: 42,
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.hokTheme.outlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
          const SizedBox(width: 6),
          Text(
            _arcanaColorName(activeColor),
            style: TextStyle(
              color: context.hokTheme.onSurfaceStrong,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Container(
            height: 28,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: context.hokTheme.backgroundDeep,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.hokTheme.outlineSoft),
            ),
            child: Row(
              children: [
                for (var level = 1; level <= 5; level++)
                  InkWell(
                    key: ValueKey('arcana-level-$level'),
                    onTap: () => onLevelSelected(level),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: selectedLevel == level
                            ? const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFF3B82F6)],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'L$level',
                        style: TextStyle(
                          color: selectedLevel == level
                              ? Colors.white
                              : context.hokTheme.onSurfaceMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$selectedCount/10',
            style: TextStyle(
              color: context.hokTheme.onSurfaceStrong,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcanaRuneRow extends StatelessWidget {
  const _ArcanaRuneRow({
    required this.rune,
    required this.count,
    required this.selectedLevel,
    required this.canAdd,
    required this.onDecrease,
    required this.onIncrease,
  });

  final BuildRuneSummary rune;
  final int count;
  final int selectedLevel;
  final bool canAdd;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final accent = _arcanaAccent(rune.color);
    final languageCode = Localizations.localeOf(context).languageCode;
    return Tooltip(
      message: _runeDetailsText(rune, selectedLevel, languageCode),
      preferBelow: false,
      triggerMode: TooltipTriggerMode.manual,
      child: Material(
        color: count > 0
            ? accent.withValues(alpha: 0.1)
            : context.hokTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onLongPress: () => _showArcanaDetails(context, rune, selectedLevel),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: count > 0
                    ? accent.withValues(alpha: 0.42)
                    : context.hokTheme.outlineSoft,
              ),
            ),
            child: Row(
              children: [
                AppImage(
                  url: rune.iconUrl,
                  width: 34,
                  height: 34,
                  borderRadius: 7,
                  semanticLabel: rune.name,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rune.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.hokTheme.onSurfaceStrong,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (rune.description.isNotEmpty)
                        Text(
                          rune.description.replaceAll('\n', ' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.hokTheme.onSurfaceMuted,
                            fontSize: 8,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: context.hokTheme.backgroundDeep,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: context.hokTheme.outlineSoft),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: ValueKey('arcana-minus-${rune.id}'),
                        onPressed: onDecrease,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        icon: const Icon(Icons.remove, size: 15),
                      ),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.hokTheme.onSurfaceStrong,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        key: ValueKey('arcana-plus-${rune.id}'),
                        onPressed: canAdd ? onIncrease : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        icon: const Icon(Icons.add, size: 15),
                      ),
                    ],
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

class _ArcanaOverview extends StatelessWidget {
  const _ArcanaOverview({
    required this.runes,
    required this.selectedIds,
    required this.selectedLevels,
  });

  final List<BuildRuneSummary> runes;
  final List<int> selectedIds;
  final Map<int, int> selectedLevels;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final rune in runes) rune.id: rune};
    final stats = <int, _ArcanaStat>{};
    var totalLevel = 0;
    for (final id in selectedIds) {
      final rune = byId[id];
      if (rune == null) continue;
      final level = selectedLevels[id] ?? rune.level;
      totalLevel += level;
      for (final effect in rune.effects) {
        final current = stats[effect.effectType];
        stats[effect.effectType] = _ArcanaStat(
          value: (current?.value ?? 0) + effect.value * (level / 5),
          valueType: effect.valueType == 0
              ? (current?.valueType ??
                    _defaultBuildEffectValueType(effect.effectType))
              : effect.valueType,
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: context.hokTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.hokTheme.outlineSoft),
          ),
          child: Column(
            children: [
              Text(
                'Lv.$totalLevel',
                style: TextStyle(
                  color: context.hokTheme.onSurfaceStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${selectedIds.length}/30 ARCANA',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        if (stats.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'Add arcana to see the combined attributes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.hokTheme.onSurfaceMuted),
            ),
          )
        else
          for (final entry in stats.entries) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: context.hokTheme.surfaceSlate,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.hokTheme.outlineSoft),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _arcanaEffectName(
                        entry.key,
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: TextStyle(
                        color: context.hokTheme.onSurfaceMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '+${_formatArcanaEffect(entry.value)}',
                    style: TextStyle(
                      color: context.hokTheme.onSurfaceStrong,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
          ],
      ],
    );
  }
}

class _ArcanaStat {
  const _ArcanaStat({required this.value, required this.valueType});

  final double value;
  final int valueType;
}

class _ArcanaHexClipper extends CustomClipper<Path> {
  const _ArcanaHexClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.75, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.25, size.height)
      ..lineTo(0, size.height * 0.5)
      ..close();
  }

  @override
  bool shouldReclip(covariant _ArcanaHexClipper oldClipper) => false;
}

String _arcanaColorName(int color) {
  return switch (color) {
    1 => 'Red',
    2 => 'Blue',
    _ => 'Green',
  };
}

String _arcanaEffectName(int type, String languageCode) {
  const names = <int, ({String en, String zh, String id})>{
    1: (en: 'Physical Attack', zh: '物理攻击', id: 'Serangan Fisik'),
    2: (en: 'Magical Attack', zh: '法术攻击', id: 'Serangan Magis'),
    3: (en: 'Physical Defense', zh: '物理防御', id: 'Pertahanan Fisik'),
    4: (en: 'Magical Defense', zh: '法术防御', id: 'Pertahanan Magis'),
    5: (en: 'Max Health', zh: '最大生命', id: 'HP Maks'),
    6: (en: 'Critical Rate', zh: '暴击率', id: 'Critical Rate'),
    7: (en: 'Physical Pierce', zh: '物理穿透', id: 'Penembusan Fisik'),
    8: (en: 'Magical Pierce', zh: '法术穿透', id: 'Penembusan Magis'),
    9: (en: 'Physical Lifesteal', zh: '物理吸血', id: 'Lifesteal Fisik'),
    10: (en: 'Magical Lifesteal', zh: '法术吸血', id: 'Lifesteal Magis'),
    12: (en: 'Critical Damage', zh: '暴击效果', id: 'Critical Damage'),
    15: (en: 'Movement Speed', zh: '移速', id: 'Kecepatan Gerakan'),
    16: (en: 'Health Recovery', zh: '每5秒回血', id: 'Pemulihan HP'),
    18: (en: 'Attack Speed', zh: '攻速', id: 'Kecepatan Serangan'),
    19: (en: 'Cooldown Reduction', zh: '冷却缩减', id: 'Reduksi Cooldown'),
  };
  final name = names[type];
  if (name == null) return 'Effect $type';
  if (languageCode == 'zh') return name.zh;
  if (languageCode == 'id') return name.id;
  return name.en;
}

String _formatArcanaEffect(_ArcanaStat stat) {
  final value = switch (stat.valueType) {
    2 => stat.value / 10000,
    3 || 4 => stat.value / 100,
    _ => stat.value,
  };
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return stat.valueType == 2 ? '$text%' : text;
}

List<String> _equipmentDetailLines(
  BuildEquipSummary equip,
  String languageCode,
) {
  final lines = <String>[];
  if (equip.price > 0) {
    lines.add('Price: ${equip.price}');
  }
  if (equip.level > 0) {
    lines.add('Level: ${equip.level}');
  }

  final description = _cleanBuildDescription(equip.description);
  if (description.isNotEmpty) {
    lines.add(description);
  }

  for (final effect in equip.effects) {
    final valueType = _defaultBuildEffectValueType(
      effect.effectType,
      effect.valueType,
    );
    final value = _formatBuildEffectValue(effect.value, valueType);
    final name = _equipEffectName(effect.effectType, languageCode);
    lines.add('+$value $name');
  }
  lines.addAll(_rawBuildDetailLines('Skill', equip.skills));
  lines.addAll(_rawBuildDetailLines('Passive', equip.passiveSkills));
  return lines;
}

String _equipmentDetailsText(BuildEquipSummary equip, String languageCode) {
  return _assetDetailsText(
    equip.name,
    _equipmentDetailLines(equip, languageCode),
  );
}

List<String> _skillDetailLines(BuildSummonerSkillSummary skill) {
  final lines = <String>[];
  final description = _cleanBuildDescription(skill.description);
  if (description.isNotEmpty) {
    lines.add(description);
  }
  if (skill.cooldown > 0) {
    lines.add('Cooldown: ${_formatBuildCooldown(skill.cooldown)}');
  }
  return lines;
}

String _skillDetailsText(BuildSummonerSkillSummary skill) {
  return _assetDetailsText(skill.name, _skillDetailLines(skill));
}

List<String> _runeDetailLines(
  BuildRuneSummary rune,
  int selectedLevel,
  String languageCode,
) {
  final lines = <String>[
    'Color: ${_arcanaColorName(rune.color)}',
    'Selected level: L$selectedLevel',
  ];
  final description = _cleanBuildDescription(rune.description);
  if (description.isNotEmpty) {
    lines.add(description);
  }
  for (final effect in rune.effects) {
    final valueType = _defaultBuildEffectValueType(
      effect.effectType,
      effect.valueType,
    );
    final value = _formatBuildEffectValue(
      effect.value * (selectedLevel / 5),
      valueType,
    );
    final name = _arcanaEffectName(effect.effectType, languageCode);
    lines.add('+$value $name');
  }
  return lines;
}

String _runeDetailsText(
  BuildRuneSummary rune,
  int selectedLevel,
  String languageCode,
) {
  return _assetDetailsText(
    rune.name,
    _runeDetailLines(rune, selectedLevel, languageCode),
  );
}

String _assetDetailsText(String title, List<String> lines) {
  return <String>[
    title,
    ...lines,
  ].where((line) => line.trim().isNotEmpty).join('\n');
}

String _cleanBuildDescription(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<color=[^>]*>'), '')
      .replaceAll(RegExp(r'</?color>'), '')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('\\n', '\n')
      .replaceAll('\r\n', '\n')
      .trim();
}

List<String> _rawBuildDetailLines(String label, List<Object?> values) {
  final lines = <String>[];
  for (final value in values) {
    final text = _formatRawBuildDetail(value);
    if (text.isNotEmpty) {
      lines.add('$label: $text');
    }
  }
  return lines;
}

String _formatRawBuildDetail(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return _cleanBuildDescription(value);
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  if (value is Map) {
    return value.entries
        .map((entry) {
          final detail = _formatRawBuildDetail(entry.value);
          if (detail.isEmpty) return '';
          return '${_humanizeBuildKey(entry.key.toString())}: $detail';
        })
        .where((entry) => entry.isNotEmpty)
        .join(', ');
  }
  if (value is Iterable) {
    return value
        .map(_formatRawBuildDetail)
        .where((entry) => entry.isNotEmpty)
        .join(', ');
  }
  return _cleanBuildDescription(value.toString());
}

String _humanizeBuildKey(String key) {
  final spaced = key
      .replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');
  if (spaced.isEmpty) return spaced;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _formatBuildEffectValue(double value, int valueType) {
  final converted = switch (valueType) {
    2 => value / 10000,
    3 || 4 => value / 100,
    _ => value,
  };
  final text = converted == converted.roundToDouble()
      ? converted.toStringAsFixed(0)
      : converted.toStringAsFixed(1);
  return valueType == 2 ? '$text%' : text;
}

int _defaultBuildEffectValueType(int effectType, [int valueType = 0]) {
  if (valueType > 0) return valueType;
  return switch (effectType) {
    6 || 9 || 10 || 12 || 18 || 19 => 2,
    15 => 3,
    _ => 1,
  };
}

String _formatBuildCooldown(int milliseconds) {
  final seconds = milliseconds / 1000;
  final text = seconds == seconds.roundToDouble()
      ? seconds.toStringAsFixed(0)
      : seconds.toStringAsFixed(1);
  return '${text}s';
}

String _equipEffectName(int type, String languageCode) {
  const names = <int, ({String en, String zh, String id})>{
    1: (en: 'Physical Attack', zh: '物理攻击', id: 'Serangan Fisik'),
    2: (en: 'Magical Attack', zh: '法术攻击', id: 'Serangan Magis'),
    3: (en: 'Physical Defense', zh: '物理防御', id: 'Pertahanan Fisik'),
    4: (en: 'Magical Defense', zh: '法术防御', id: 'Pertahanan Magis'),
    5: (en: 'Max Health', zh: '最大生命', id: 'HP Maks'),
    6: (en: 'Critical Rate', zh: '暴击率', id: 'Critical Rate'),
    9: (en: 'Physical Lifesteal', zh: '物理吸血', id: 'Lifesteal Fisik'),
    15: (en: 'Movement Speed', zh: '移速', id: 'Kecepatan Gerakan'),
    18: (en: 'Attack Speed', zh: '攻速', id: 'Kecepatan Serangan'),
    19: (en: 'Cooldown Reduction', zh: '冷却缩减', id: 'Reduksi Cooldown'),
    100: (en: 'Mana', zh: '法力值', id: 'Mana'),
  };
  final name = names[type];
  if (name == null) return 'Effect $type';
  if (languageCode == 'zh') return name.zh;
  if (languageCode == 'id') return name.id;
  return name.en;
}

Future<void> _showArcanaDetails(
  BuildContext context,
  BuildRuneSummary rune,
  int selectedLevel,
) {
  return _showBuildAssetDetails(
    context: context,
    title: rune.name,
    iconUrl: rune.iconUrl,
    lines: _runeDetailLines(
      rune,
      selectedLevel,
      Localizations.localeOf(context).languageCode,
    ),
  );
}

Future<void> _showBuildAssetDetails({
  required BuildContext context,
  required String title,
  required String iconUrl,
  required List<String> lines,
}) {
  final visibleLines = lines
      .map(_cleanBuildDescription)
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    backgroundColor: context.hokTheme.surfaceSlate,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = sheetContext.hokTheme;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppImage(
                      url: iconUrl,
                      width: 58,
                      height: 58,
                      borderRadius: 12,
                      semanticLabel: title,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.onSurfaceStrong,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (visibleLines.isEmpty)
                  Text(
                    'No additional details available.',
                    style: TextStyle(color: theme.onSurfaceMuted, height: 1.4),
                  )
                else
                  for (final line in visibleLines)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: theme.backgroundDeep.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: theme.outlineSoft),
                      ),
                      child: Text(
                        line,
                        style: TextStyle(
                          color: theme.onSurfaceMuted,
                          height: 1.4,
                          fontSize: 12,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _BuildSkillWorkspace extends StatelessWidget {
  const _BuildSkillWorkspace({
    super.key,
    required this.skills,
    required this.selectedId,
    required this.onSelected,
  });

  final List<BuildSummonerSkillSummary> skills;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return AppEmptyState(
        icon: Icons.auto_fix_high_outlined,
        title: AppLocalizations.of(context).noData,
        message: AppLocalizations.of(context).serviceSlow,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLandscape =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight < 300;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            compactLandscape ? 10 : 18,
            16,
            compactLandscape ? 12 : 24,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compactLandscape ? 8 : 5,
            crossAxisSpacing: compactLandscape ? 10 : 14,
            mainAxisSpacing: compactLandscape ? 10 : 18,
            childAspectRatio: compactLandscape ? 0.98 : 0.82,
          ),
          itemCount: skills.length,
          itemBuilder: (context, index) {
            final skill = skills[index];
            return _BuildCatalogAsset(
              label: skill.name,
              imageUrl: skill.iconUrl,
              selected: selectedId == skill.id,
              onTap: () => onSelected(skill.id),
              onLongPress: () => _showBuildAssetDetails(
                context: context,
                title: skill.name,
                iconUrl: skill.iconUrl,
                lines: _skillDetailLines(skill),
              ),
              tooltipMessage: _skillDetailsText(skill),
            );
          },
        );
      },
    );
  }
}

class _BuildCatalogAsset extends StatelessWidget {
  const _BuildCatalogAsset({
    required this.label,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.tooltipMessage,
    this.showLabel = true,
  });

  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? tooltipMessage;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipMessage ?? label,
      preferBelow: false,
      triggerMode: onLongPress == null
          ? TooltipTriggerMode.longPress
          : TooltipTriggerMode.manual,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppTheme.gold.withValues(alpha: 0.14)
                      : context.hokTheme.surfaceSlate,
                  border: Border.all(
                    width: selected ? 2 : 1,
                    color: selected
                        ? AppTheme.gold
                        : context.hokTheme.outlineSoft,
                  ),
                ),
                child: AppImage(
                  url: imageUrl,
                  borderRadius: 999,
                  semanticLabel: label,
                ),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.hokTheme.onSurfaceStrong,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color _arcanaAccent(int color) {
  return switch (color) {
    1 => const Color(0xFFFF6B6B),
    2 => AppTheme.cyan,
    3 => const Color(0xFF4ADE80),
    _ => AppTheme.gold,
  };
}

class _CommunityBuilds extends ConsumerStatefulWidget {
  const _CommunityBuilds({
    required this.value,
    required this.filter,
    required this.focusedSchemeId,
    required this.heroes,
    required this.topEquips,
    required this.onHeroRequested,
    required this.onActionDone,
  });

  final AsyncValue<List<BuildSchemeSummary>> value;
  final BuildSimCommunityFilter filter;
  final int? focusedSchemeId;
  final List<HeroSummary> heroes;
  final List<BuildEquipSummary> topEquips;
  final ValueChanged<int> onHeroRequested;
  final VoidCallback? onActionDone;

  @override
  ConsumerState<_CommunityBuilds> createState() => _CommunityBuildsState();
}

class _CommunityBuildsState extends ConsumerState<_CommunityBuilds> {
  static const _schemePageSize = 20;

  String? _busyAction;
  bool _latestFirst = true;
  final Map<int, BuildSchemeSummary> _schemeOverrides = {};

  // 第 1 页始终来自 provider；后续页在本地累积，provider 刷新/切换 tab 后重置。
  List<BuildSchemeSummary>? _pageOne;
  final List<BuildSchemeSummary> _extraSchemes = [];
  int _loadedPages = 1;
  bool _loadingMore = false;
  bool? _hasMoreOverride;

  void _syncWithPageOne(List<BuildSchemeSummary> schemes) {
    if (identical(_pageOne, schemes)) {
      return;
    }
    _pageOne = schemes;
    _extraSchemes.clear();
    _loadedPages = 1;
    _loadingMore = false;
    _hasMoreOverride = null;
  }

  Future<void> _loadMoreSchemes() async {
    if (_loadingMore) {
      return;
    }
    final pageOneAtRequest = _pageOne;
    final filterAtRequest = widget.filter;
    setState(() => _loadingMore = true);
    try {
      final repository = ref.read(buildsRepositoryProvider);
      final BuildSchemePage next;
      if (filterAtRequest == BuildSimCommunityFilter.favorites) {
        next = await repository.loadFavoriteSchemesPage(
          page: _loadedPages + 1,
          pageSize: _schemePageSize,
        );
      } else {
        final settings = await ref.read(appSettingsControllerProvider.future);
        next = await repository.loadPublicSchemesPage(
          settings.region.regionId,
          page: _loadedPages + 1,
          pageSize: _schemePageSize,
        );
      }
      if (!mounted ||
          !identical(pageOneAtRequest, _pageOne) ||
          filterAtRequest != widget.filter) {
        return;
      }
      setState(() {
        _extraSchemes.addAll(next.schemes);
        _loadedPages += 1;
        _hasMoreOverride = next.hasMore && next.schemes.isNotEmpty;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted ||
          !identical(pageOneAtRequest, _pageOne) ||
          filterAtRequest != widget.filter) {
        return;
      }
      setState(() => _loadingMore = false);
      AppNotice.failure(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_up_rounded,
              color: AppTheme.gold,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.filter == BuildSimCommunityFilter.favorites
                    ? AppLocalizations.of(context).translate('buildFavorites')
                    : AppLocalizations.of(context).translate('buildExplore'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final sortButtons = [
              Expanded(
                child: _ExploreSortButton(
                  label: AppLocalizations.of(context).translate('commonLatest'),
                  icon: Icons.schedule_outlined,
                  selected: _latestFirst,
                  onTap: () => setState(() => _latestFirst = true),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ExploreSortButton(
                  label: AppLocalizations.of(
                    context,
                  ).translate('commonPopular'),
                  icon: Icons.trending_up,
                  selected: !_latestFirst,
                  onTap: () => setState(() => _latestFirst = false),
                ),
              ),
            ];
            if (constraints.maxWidth < 390) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt_outlined,
                        color: context.hokTheme.onSurfaceMuted,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sort',
                        style: TextStyle(
                          color: context.hokTheme.onSurfaceMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: sortButtons),
                ],
              );
            }
            return Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  color: context.hokTheme.onSurfaceMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sort',
                  style: TextStyle(
                    color: context.hokTheme.onSurfaceMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                ...sortButtons,
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        widget.value.when(
          data: (schemes) {
            _syncWithPageOne(schemes);
            if (schemes.isEmpty) {
              return AppEmptyState(
                icon: Icons.construction_outlined,
                title: AppLocalizations.of(context).noData,
                message: AppLocalizations.of(context).serviceSlow,
              );
            }
            final allSchemes = _extraSchemes.isEmpty
                ? schemes
                : [...schemes, ..._extraSchemes];
            final hasMore =
                _hasMoreOverride ?? (schemes.length >= _schemePageSize);
            final visibleSchemes = _visibleSchemes(
              allSchemes,
            ).map((scheme) => _schemeOverrides[scheme.id] ?? scheme).toList();
            if (!_latestFirst) {
              visibleSchemes.sort(
                (left, right) => right.likeCount.compareTo(left.likeCount),
              );
            }
            return Column(
              children: [
                for (final scheme in visibleSchemes) ...[
                  if (scheme.id == widget.focusedSchemeId) ...[
                    const _SharedBuildBadge(),
                    const SizedBox(height: 8),
                  ],
                  _SimulatorExploreBuildCard(
                    scheme: scheme,
                    heroAvatar: _heroFor(scheme)?.avatar ?? scheme.heroAvatar,
                    equipmentIcons: _topEquipmentIcons(scheme),
                    busyAction: _busyAction,
                    onLike: () => _toggleLike(context, scheme),
                    onFavorite: () => _toggleFavorite(context, scheme),
                    onClone: () => _showCloneSheet(context, scheme),
                    onView: () => _openTemporaryEditor(context, scheme),
                    onShare: () => showAppShareSheet(
                      context,
                      title: scheme.title,
                      url:
                          'https://hokhelper.com/tools/build-sim?scheme=${scheme.id}',
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                // 短列表不渲染到底提示，避免噪音；可翻页时才挂加载页脚。
                if (hasMore || visibleSchemes.length > 10)
                  AppListFooter(
                    hasMore: hasMore,
                    loading: _loadingMore,
                    onLoadMore: _loadMoreSchemes,
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text(
            friendlyErrorMessage(context, error),
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ],
    );
  }

  List<BuildSchemeSummary> _visibleSchemes(List<BuildSchemeSummary> schemes) {
    final focusedSchemeId = widget.focusedSchemeId;
    if (focusedSchemeId == null) {
      return schemes;
    }

    final focusedIndex = schemes.indexWhere(
      (scheme) => scheme.id == focusedSchemeId,
    );
    if (focusedIndex < 0) {
      return schemes;
    }

    final focused = schemes[focusedIndex];
    final rest = schemes.where((scheme) => scheme.id != focusedSchemeId);
    return [focused, ...rest].toList(growable: false);
  }

  HeroSummary? _heroFor(BuildSchemeSummary scheme) {
    for (final hero in widget.heroes) {
      final heroId = int.tryParse(hero.heroId);
      final id = int.tryParse(hero.id);
      if ((scheme.heroId > 0 &&
              (scheme.heroId == heroId || scheme.heroId == id)) ||
          (scheme.heroName.isNotEmpty && hero.name == scheme.heroName)) {
        return hero;
      }
    }
    return null;
  }

  List<String> _topEquipmentIcons(BuildSchemeSummary scheme) {
    if (widget.topEquips.isEmpty) {
      return scheme.equipmentIcons.take(6).toList(growable: false);
    }
    final iconsById = {
      for (final equip in widget.topEquips) equip.id: equip.iconUrl,
    };
    final icons = scheme.equipmentIds
        .where(iconsById.containsKey)
        .map((id) => iconsById[id] ?? '')
        .where((url) => url.isNotEmpty)
        .take(6)
        .toList(growable: false);
    return icons.isEmpty
        ? scheme.equipmentIcons.take(6).toList(growable: false)
        : icons;
  }

  Future<void> _runAction(String key, Future<void> Function() action) async {
    setState(() => _busyAction = key);
    try {
      await action();
      widget.onActionDone?.call();
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _runProtectedAction(
    BuildContext context,
    String key,
    Future<void> Function() action,
  ) async {
    if (ref.read(authControllerProvider).valueOrNull == null) {
      _showBuildLoginPrompt(context);
      return;
    }
    try {
      await _runAction(key, action);
    } catch (_) {
      if (!context.mounted) return;
      AppNotice.failure(context);
    }
  }

  Future<void> _toggleLike(
    BuildContext context,
    BuildSchemeSummary scheme,
  ) async {
    await _runProtectedAction(context, 'like-${scheme.id}', () async {
      await ref.read(buildSimLikeSchemeProvider)(scheme);
      if (!mounted) return;
      setState(() {
        _schemeOverrides[scheme.id] = scheme.copyWith(
          isLiked: !scheme.isLiked,
          likeCount: math.max(0, scheme.likeCount + (scheme.isLiked ? -1 : 1)),
        );
      });
    });
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    BuildSchemeSummary scheme,
  ) async {
    await _runProtectedAction(context, 'favorite-${scheme.id}', () async {
      await ref.read(buildSimFavoriteSchemeProvider)(scheme);
      if (!mounted) return;
      setState(() {
        _schemeOverrides[scheme.id] = scheme.copyWith(
          isFavorited: !scheme.isFavorited,
          favoriteCount: math.max(
            0,
            scheme.favoriteCount + (scheme.isFavorited ? -1 : 1),
          ),
        );
      });
    });
  }

  Future<void> _showCloneSheet(
    BuildContext context,
    BuildSchemeSummary scheme,
  ) async {
    if (ref.read(authControllerProvider).valueOrNull == null) {
      _showBuildLoginPrompt(context);
      return;
    }
    final hero = _heroFor(scheme);
    final heroId = scheme.heroId > 0
        ? scheme.heroId
        : int.tryParse(hero?.heroId ?? '');
    if (heroId == null || heroId <= 0) {
      AppNotice.failure(context);
      return;
    }
    widget.onHeroRequested(heroId);
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.hokTheme.surfaceSlate,
      builder: (_) => _BuildCloneSheet(
        scheme: scheme,
        heroId: heroId,
        onClone: (slotIndex) => _cloneToSlot(scheme, heroId, slotIndex),
      ),
    );
  }

  Future<bool> _cloneToSlot(
    BuildSchemeSummary scheme,
    int heroId,
    int slotIndex,
  ) async {
    final key = 'clone-${scheme.id}-$slotIndex';
    try {
      await _runAction(
        key,
        () => ref.read(buildSimCloneSchemeProvider)(scheme, slotIndex),
      );
      final refreshedSlots = await ref.refresh(
        buildSimUserSlotsProvider(heroId).future,
      );
      if (refreshedSlots.length < slotIndex) {
        ref.invalidate(buildSimUserSlotsProvider(heroId));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openTemporaryEditor(
    BuildContext context,
    BuildSchemeSummary scheme,
  ) async {
    final hero = _heroFor(scheme);
    final heroId = scheme.heroId > 0
        ? scheme.heroId
        : int.tryParse(hero?.heroId ?? '') ?? 0;
    final regionCode = ref
        .read(appSettingsControllerProvider)
        .maybeWhen(
          data: (settings) => settings.region.languageCode,
          orElse: () => 'en',
        );
    await Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (editorContext, animation, secondaryAnimation) =>
            _BuildEditorPanel(
              heroId: heroId,
              slotIndex: scheme.slotIndex,
              heroName: hero?.name ?? scheme.heroName,
              heroAvatar: hero?.avatar ?? scheme.heroAvatar,
              regionCode: regionCode,
              scheme: scheme,
              isTemporary: true,
              onCancel: () => Navigator.of(editorContext).pop(),
              onSaved: () => Navigator.of(editorContext).pop(),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

void _showBuildLoginPrompt(BuildContext context) {
  AppNotice.show(
    context,
    AppLocalizations.of(context).translate('buildSignInToInteract'),
  );
}

class _ExploreSortButton extends StatelessWidget {
  const _ExploreSortButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Ink(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selected ? AppTheme.gold : context.hokTheme.backgroundDeep,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppTheme.gold : context.hokTheme.outlineSoft,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : context.hokTheme.onSurfaceMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : context.hokTheme.onSurfaceMuted,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BuildCloneSheet extends ConsumerStatefulWidget {
  const _BuildCloneSheet({
    required this.scheme,
    required this.heroId,
    required this.onClone,
  });

  final BuildSchemeSummary scheme;
  final int heroId;
  final Future<bool> Function(int slotIndex) onClone;

  @override
  ConsumerState<_BuildCloneSheet> createState() => _BuildCloneSheetState();
}

class _BuildCloneSheetState extends ConsumerState<_BuildCloneSheet> {
  int? _busySlot;

  @override
  Widget build(BuildContext context) {
    final slotsValue = ref.watch(buildSimUserSlotsProvider(widget.heroId));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.copy_outlined, color: AppTheme.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Clone build',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: AppLocalizations.of(context).close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              'Choose where to save ${widget.scheme.title}. Existing builds will be replaced.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.hokTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            slotsValue.when(
              data: (slots) => Column(
                children: List.generate(3, (index) {
                  final slot = index < slots.length ? slots[index] : null;
                  final slotIndex = index + 1;
                  final busy = _busySlot == slotIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _busySlot == null
                            ? () => _clone(slotIndex)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          height: slot == null ? 68 : 86,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: context.hokTheme.backgroundDeep,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: slot == null
                                  ? AppTheme.gold.withValues(alpha: 0.42)
                                  : context.hokTheme.outlineSoft,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.gold.withValues(
                                  alpha: 0.14,
                                ),
                                child: Text(
                                  '$slotIndex',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slot?.title ?? 'Empty slot',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.hokTheme.onSurfaceStrong,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (slot == null)
                                      Text(
                                        'Save to Slot $slotIndex',
                                        style: TextStyle(
                                          color:
                                              context.hokTheme.onSurfaceMuted,
                                          fontSize: 12,
                                        ),
                                      )
                                    else ...[
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          for (final icon
                                              in slot.equipmentIcons.take(
                                                4,
                                              )) ...[
                                            AppImage(
                                              url: icon,
                                              width: 23,
                                              height: 23,
                                              borderRadius: 12,
                                              excludeFromSemantics: true,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            'Replace Slot $slotIndex',
                                            style: TextStyle(
                                              color: context
                                                  .hokTheme
                                                  .onSurfaceMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (busy)
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Icon(
                                  slot == null
                                      ? Icons.save_outlined
                                      : Icons.find_replace_outlined,
                                  color: AppTheme.gold,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              loading: () => const SizedBox(
                height: 212,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => SizedBox(
                height: 160,
                child: AppEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: AppLocalizations.of(context).serviceSlow,
                  message: friendlyErrorMessage(context, error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clone(int slotIndex) async {
    setState(() => _busySlot = slotIndex);
    final success = await widget.onClone(slotIndex);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busySlot = null);
    AppNotice.failure(context);
  }
}

class _SimulatorExploreBuildCard extends StatelessWidget {
  const _SimulatorExploreBuildCard({
    required this.scheme,
    required this.heroAvatar,
    required this.equipmentIcons,
    required this.busyAction,
    required this.onLike,
    required this.onFavorite,
    required this.onClone,
    required this.onView,
    required this.onShare,
  });
  final BuildSchemeSummary scheme;
  final String heroAvatar;
  final List<String> equipmentIcons;
  final String? busyAction;
  final VoidCallback onLike;
  final VoidCallback onFavorite;
  final VoidCallback onClone;
  final VoidCallback onView;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final disabled = busyAction != null;
    final runes = _groupRunes(scheme.runeIds);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.hokTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.hokTheme.outlineSoft),
        ),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            final compact = cardConstraints.maxHeight < 176;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: compact ? 40 : 44,
                  child: Row(
                    children: [
                      AppImage(
                        url: heroAvatar,
                        width: 38,
                        height: 38,
                        borderRadius: 9,
                        semanticLabel: scheme.heroName,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onView,
                              child: Text(
                                scheme.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.hokTheme.onSurfaceStrong,
                                  fontSize: 15,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              'by ${scheme.authorName} · ${scheme.heroName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.hokTheme.onSurfaceMuted,
                                fontSize: 11,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _CompactBuildIconButton(
                        icon: Icons.ios_share_outlined,
                        tooltip: AppLocalizations.of(
                          context,
                        ).translate('commonShare'),
                        onTap: onShare,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  flex: 5,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final icons = equipmentIcons.take(6).toList();
                      final size = math.min(
                        constraints.maxHeight,
                        ((constraints.maxWidth - 25) / 6).clamp(24.0, 42.0),
                      );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final icon in icons)
                            AppImage(
                              url: icon,
                              width: size,
                              height: size,
                              borderRadius: 999,
                              excludeFromSemantics: true,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  flex: 4,
                  child: _CompactBuildLoadout(
                    summonerSkillIcon: scheme.summonerSkillIcon,
                    runes: runes,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: SizedBox(
                    height: compact ? 34 : 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _CompactBuildAction(
                          icon: scheme.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          value: scheme.likeCount,
                          active: scheme.isLiked,
                          tooltip: scheme.isLiked
                              ? 'Unlike build'
                              : 'Like build',
                          onTap: disabled ? null : onLike,
                        ),
                        const SizedBox(width: 10),
                        _CompactBuildAction(
                          icon: scheme.isFavorited
                              ? Icons.star
                              : Icons.star_border,
                          value: scheme.favoriteCount,
                          active: scheme.isFavorited,
                          tooltip: scheme.isFavorited
                              ? 'Unfavorite build'
                              : 'Favorite build',
                          onTap: disabled ? null : onFavorite,
                        ),
                        const SizedBox(width: 10),
                        _CompactBuildAction(
                          icon: Icons.copy_outlined,
                          value: scheme.cloneCount,
                          tooltip: AppLocalizations.of(
                            context,
                          ).translate('buildClone'),
                          onTap: disabled ? null : onClone,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_BuildRuneGroup> _groupRunes(List<int> runeIds) {
    final counts = <int, int>{};
    for (final runeId in runeIds) {
      if (runeId > 0) counts[runeId] = (counts[runeId] ?? 0) + 1;
    }
    return counts.entries
        .map((entry) => _BuildRuneGroup(id: entry.key, count: entry.value))
        .toList(growable: false);
  }
}

class _BuildRuneGroup {
  const _BuildRuneGroup({required this.id, required this.count});
  final int id;
  final int count;
  String get iconUrl => '/static/game/rune/$id.png';
}

class _CompactBuildLoadout extends StatelessWidget {
  const _CompactBuildLoadout({
    required this.summonerSkillIcon,
    required this.runes,
  });
  final String summonerSkillIcon;
  final List<_BuildRuneGroup> runes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: context.hokTheme.backgroundDeep.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.hokTheme.outlineSoft),
      ),
      child: Row(
        children: [
          if (summonerSkillIcon.isNotEmpty)
            AppImage(
              url: summonerSkillIcon,
              width: 24,
              height: 24,
              borderRadius: 999,
              excludeFromSemantics: true,
            )
          else
            Icon(
              Icons.flash_on_outlined,
              size: 18,
              color: context.hokTheme.onSurfaceMuted,
            ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: context.hokTheme.onSurfaceMuted.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.62
                  : 0.42,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: runes.length,
              separatorBuilder: (_, index) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final rune = runes[index];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppImage(
                      url: rune.iconUrl,
                      width: 24,
                      height: 24,
                      borderRadius: 999,
                      excludeFromSemantics: true,
                    ),
                    if (rune.count > 1) ...[
                      const SizedBox(width: 2),
                      Text(
                        '×${rune.count}',
                        style: TextStyle(
                          color: context.hokTheme.onSurfaceMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBuildIconButton extends StatelessWidget {
  const _CompactBuildIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 19,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: context.hokTheme.onSurfaceMuted),
    ),
  );
}

class _CompactBuildAction extends StatelessWidget {
  const _CompactBuildAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.value,
    this.active = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int? value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.gold : context.hokTheme.onSurfaceMuted;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                if (value != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$value',
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedBuildBadge extends StatelessWidget {
  const _SharedBuildBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.32)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            'Shared build',
            style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
