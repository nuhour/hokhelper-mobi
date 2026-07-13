import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../heroes/domain/hero_summary.dart';
import '../../heroes/presentation/hero_gallery_screen.dart';
import '../../settings/presentation/settings_controller.dart';
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
        name: scheme.title,
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

  @override
  void didUpdateWidget(covariant BuildSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHeroId != widget.initialHeroId) {
      _didResolveInitialHero = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroesValue = ref.watch(buildSimHeroesProvider);
    final communitySchemesValue =
        widget.initialCommunityFilter == BuildSimCommunityFilter.favorites
        ? ref.watch(buildSimFavoriteSchemesProvider)
        : ref.watch(buildSimPublicSchemesProvider);

    return AppAsyncView<List<HeroSummary>>(
      value: heroesValue,
      retry: () => ref.invalidate(buildSimHeroesProvider),
      data: (heroes) {
        _resolveInitialHero(heroes);
        final selectedHero = heroes.isEmpty
            ? null
            : heroes[_selectedHeroIndex.clamp(0, heroes.length - 1)];
        final heroId = int.tryParse(selectedHero?.heroId ?? '');
        final slotsValue = heroId == null
            ? const AsyncValue<List<BuildSchemeSummary?>>.data([])
            : ref.watch(buildSimUserSlotsProvider(heroId));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(buildSimHeroesProvider);
            ref.invalidate(buildSimPublicSchemesProvider);
            if (heroId != null) {
              ref.invalidate(buildSimUserSlotsProvider(heroId));
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              if (heroes.isEmpty)
                const AppEmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No heroes available',
                  message: 'Pull to refresh or switch region in settings.',
                )
              else ...[
                _HeroSelector(
                  heroes: heroes,
                  selectedIndex: _selectedHeroIndex,
                  onOpenPicker: () => _openHeroPicker(context, heroes),
                ),
                const SizedBox(height: 28),
                _SlotsPanel(
                  slotsValue: slotsValue,
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
              const SizedBox(height: 32),
              _CommunityBuilds(
                value: communitySchemesValue,
                filter: widget.initialCommunityFilter,
                focusedSchemeId: widget.initialSchemeId,
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
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
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
          height: 214,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.62)),
          ),
          child: Row(
            children: [
              AppImage(
                url: selectedHero.avatar,
                width: 112,
                height: 112,
                borderRadius: 999,
                semanticLabel: selectedHero.name,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedHero.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Click to switch hero',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.chevron_right,
                  color: AppTheme.gold,
                  size: 32,
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
                  color: AppTheme.muted.withValues(alpha: 0.55),
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
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close hero pool',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                decoration: const InputDecoration(
                  hintText: 'Search heroes',
                  prefixIcon: Icon(Icons.search),
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
                    ? const AppEmptyState(
                        icon: Icons.person_search_outlined,
                        title: 'No matching heroes',
                        message: 'Try a different lane or search term.',
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
                                      : AppTheme.panelAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? AppTheme.gold
                                        : Colors.white.withValues(alpha: 0.08),
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
                                      style: const TextStyle(
                                        color: AppTheme.text,
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
    _BuildLaneOption(label: 'Mid', assetName: 'mid', value: 1),
    _BuildLaneOption(label: 'Farm', assetName: 'adc', value: 2),
    _BuildLaneOption(label: 'Jungle', assetName: 'jungle', value: 3),
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
                    color: selected ? AppTheme.gold : AppTheme.panelAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppTheme.gold
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: option.assetName == null
                      ? const Icon(Icons.grid_view_rounded, size: 18)
                      : Image.asset(
                          'assets/lane-icons/${option.assetName}.png',
                          width: 21,
                          height: 21,
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
  const _SlotsPanel({required this.slotsValue, required this.onEdit});

  final AsyncValue<List<BuildSchemeSummary?>> slotsValue;
  final void Function(int slotIndex, BuildSchemeSummary? scheme) onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              color: AppTheme.gold,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'My Builds',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _BuildCollectionTabs(),
        const SizedBox(height: 24),
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
            error.toString(),
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
    final title = scheme?.title ?? 'Create Build $index';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: scheme == null ? 260 : 194,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme == null
                  ? AppTheme.muted.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.12),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scheme != null)
                Row(
                  children: [
                    Text(
                      'BUILD $index',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      scheme == null
                          ? Icons.add_circle_outline
                          : Icons.edit_outlined,
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
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: AppTheme.muted.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppTheme.muted,
                          size: 46,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: scheme!.equipmentIcons
                      .take(6)
                      .map(
                        (icon) => AppImage(
                          url: icon,
                          width: 42,
                          height: 42,
                          borderRadius: 999,
                          excludeFromSemantics: true,
                        ),
                      )
                      .toList(growable: false),
                ),
              const Spacer(),
              if (scheme != null)
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildCollectionTabs extends StatelessWidget {
  const _BuildCollectionTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _BuildCollectionTab(
              icon: Icons.person_outline,
              label: 'My Builds',
              selected: true,
            ),
          ),
          Expanded(
            child: _BuildCollectionTab(
              icon: Icons.star_border_rounded,
              label: 'My Favorites',
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
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppTheme.gold : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : AppTheme.muted, size: 22),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.muted,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
  });

  final int heroId;
  final int slotIndex;
  final String heroName;
  final String heroAvatar;
  final String regionCode;
  final BuildSchemeSummary? scheme;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  ConsumerState<_BuildEditorPanel> createState() => _BuildEditorPanelState();
}

class _BuildEditorPanelState extends ConsumerState<_BuildEditorPanel> {
  late final TextEditingController _titleController;
  late bool _isPublic;
  late List<int> _equipIds;
  late List<int> _runeIds;
  int? _summonerSkillId;
  _BuildEditorTab _activeTab = _BuildEditorTab.equipment;
  int _activeRuneColor = 1;
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
    _runeIds = [...(scheme?.runeIds ?? const [])];
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
        color: AppTheme.bg,
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
                  onToggleVisibility: () =>
                      setState(() => _isPublic = !_isPublic),
                  onClear: _clearAll,
                  onClose: widget.onCancel,
                  onSave: _saving ? null : _save,
                ),
                _BuildEditorTabs(
                  selected: _activeTab,
                  onSelected: (tab) => setState(() => _activeTab = tab),
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
                            error.toString(),
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: switch (_activeTab) {
        _BuildEditorTab.equipment => _BuildEquipmentWorkspace(
          key: const ValueKey('equipment'),
          equips: catalog.equips,
          selectedIds: _equipIds,
          onToggle: _toggleEquip,
          onRemove: _removeEquip,
          onReorder: _reorderEquips,
        ),
        _BuildEditorTab.arcana => _BuildArcanaWorkspace(
          key: const ValueKey('arcana'),
          runes: catalog.runes,
          selectedIds: _runeIds,
          activeColor: _activeRuneColor,
          onColorSelected: (color) => setState(() => _activeRuneColor = color),
          onToggle: _toggleRune,
        ),
        _BuildEditorTab.skill => _BuildSkillWorkspace(
          key: const ValueKey('skill'),
          skills: catalog.summonerSkills,
          selectedId: _summonerSkillId,
          onSelected: (skillId) => setState(() => _summonerSkillId = skillId),
        ),
      },
    );
  }

  void _toggleEquip(int equipId) {
    setState(() {
      if (_equipIds.contains(equipId)) {
        _equipIds = _equipIds.where((id) => id != equipId).toList();
      } else if (_equipIds.length < 12) {
        _equipIds = [..._equipIds, equipId];
      }
    });
  }

  void _removeEquip(int equipId) {
    setState(() {
      _equipIds = _equipIds.where((id) => id != equipId).toList();
    });
  }

  void _reorderEquips(int oldIndex, int newIndex) {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _equipIds.length ||
        newIndex >= _equipIds.length) {
      return;
    }
    setState(() {
      final next = [..._equipIds];
      final item = next.removeAt(oldIndex);
      next.insert(newIndex, item);
      _equipIds = next;
    });
  }

  void _clearAll() {
    setState(() {
      _equipIds = [];
      _runeIds = [];
      _summonerSkillId = null;
    });
  }

  void _toggleRune(int runeId) {
    setState(() {
      if (_runeIds.contains(runeId)) {
        _runeIds = _runeIds.where((id) => id != runeId).toList();
      } else if (_runeIds.length < 30) {
        _runeIds = [..._runeIds, runeId];
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

class _BuildEditorToolbar extends StatelessWidget {
  const _BuildEditorToolbar({
    required this.heroName,
    required this.heroAvatar,
    required this.titleController,
    required this.isPublic,
    required this.saving,
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
  final VoidCallback onToggleVisibility;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
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
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: titleController,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: heroName.isEmpty ? 'Build name' : '$heroName build',
                hintStyle: const TextStyle(color: AppTheme.muted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggleVisibility,
            tooltip: isPublic ? 'Public build' : 'Private build',
            icon: Icon(isPublic ? Icons.public : Icons.lock_outline),
            color: isPublic ? AppTheme.success : AppTheme.muted,
          ),
          IconButton(
            onPressed: onClear,
            tooltip: 'Clear equipment, arcana, and skill',
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.error,
          ),
          IconButton(
            onPressed: onSave,
            tooltip: 'Save build',
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            color: AppTheme.gold,
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
    const tabs = [
      (
        tab: _BuildEditorTab.equipment,
        icon: Icons.flash_on_outlined,
        label: 'Equipment',
      ),
      (
        tab: _BuildEditorTab.arcana,
        icon: Icons.hexagon_outlined,
        label: 'Arcana Matrix',
      ),
      (
        tab: _BuildEditorTab.skill,
        icon: Icons.auto_fix_high_outlined,
        label: 'Skill',
      ),
    ];
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      color: AppTheme.panel,
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
                            : AppTheme.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected == entry.tab
                              ? AppTheme.gold
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            entry.icon,
                            size: 18,
                            color: selected == entry.tab
                                ? Colors.white
                                : AppTheme.muted,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              entry.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected == entry.tab
                                    ? Colors.white
                                    : AppTheme.muted,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
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
    required this.onToggle,
    required this.onRemove,
    required this.onReorder,
  });

  final List<BuildEquipSummary> equips;
  final List<int> selectedIds;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final equipById = {for (final equip in equips) equip.id: equip};
    final compactViewport = MediaQuery.sizeOf(context).height < 700;
    return Column(
      children: [
        Container(
          height: compactViewport ? 124 : 190,
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flash_on_outlined,
                    color: AppTheme.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EQUIPMENT',
                    style: TextStyle(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '+ Slot',
                    style: TextStyle(
                      color: AppTheme.muted.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compactViewport ? 4 : 10),
              Expanded(
                child: selectedIds.isEmpty
                    ? ListView(
                        scrollDirection: Axis.horizontal,
                        children: List.generate(
                          6,
                          (_) => const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: _BuildEmptyEquipmentSlot(),
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        buildDefaultDragHandles: false,
                        itemCount: selectedIds.length,
                        onReorderItem: onReorder,
                        itemBuilder: (context, index) {
                          final equipId = selectedIds[index];
                          final equip = equipById[equipId];
                          return Padding(
                            key: ValueKey('selected-equip-$equipId'),
                            padding: const EdgeInsets.only(right: 12),
                            child: ReorderableDelayedDragStartListener(
                              index: index,
                              child: Tooltip(
                                message: equip?.name ?? 'Equipment $equipId',
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child: AppImage(
                                        url: equip?.iconUrl,
                                        width: 62,
                                        height: 62,
                                        borderRadius: 999,
                                        semanticLabel: equip?.name,
                                      ),
                                    ),
                                    Positioned(
                                      right: -5,
                                      top: -5,
                                      child: InkWell(
                                        onTap: () => onRemove(equipId),
                                        borderRadius: BorderRadius.circular(99),
                                        child: const CircleAvatar(
                                          radius: 11,
                                          backgroundColor: AppTheme.error,
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
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
        if (!compactViewport) ...[
          const _BuildCatalogTabs(),
          const _EquipmentFilterBar(),
        ],
        Expanded(
          child: equips.isEmpty
              ? const AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No equipment available',
                  message: 'Pull to refresh and try again.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: equips.length,
                  itemBuilder: (context, index) {
                    final equip = equips[index];
                    final selected = selectedIds.contains(equip.id);
                    return _BuildCatalogAsset(
                      label: equip.name,
                      imageUrl: equip.iconUrl,
                      selected: selected,
                      onTap: () => onToggle(equip.id),
                      showLabel: false,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BuildEmptyEquipmentSlot extends StatelessWidget {
  const _BuildEmptyEquipmentSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: AppTheme.bg,
      ),
      child: const Icon(Icons.add, size: 18, color: AppTheme.muted),
    );
  }
}

class _BuildCatalogTabs extends StatelessWidget {
  const _BuildCatalogTabs();
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
    child: const Row(
      children: [
        Expanded(child: _CatalogTab(label: 'ITEMS', selected: true)),
        Expanded(child: _CatalogTab(label: 'ARCANA')),
        Expanded(child: _CatalogTab(label: 'ARCANA OVERVIEW')),
      ],
    ),
  );
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({required this.label, this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
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
        color: selected ? AppTheme.gold : AppTheme.muted,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _EquipmentFilterBar extends StatelessWidget {
  const _EquipmentFilterBar();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
    child: Wrap(
      spacing: 9,
      runSpacing: 9,
      children: const [
        _EquipmentFilter(label: 'All', selected: true),
        _EquipmentFilter(label: 'Attack'),
        _EquipmentFilter(label: 'Magic'),
        _EquipmentFilter(label: 'Defense'),
        _EquipmentFilter(label: 'Move'),
        _EquipmentFilter(label: 'Jungle'),
        _EquipmentFilter(label: 'Support'),
      ],
    ),
  );
}

class _EquipmentFilter extends StatelessWidget {
  const _EquipmentFilter({required this.label, this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    decoration: BoxDecoration(
      color: selected ? AppTheme.gold : AppTheme.bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: selected ? AppTheme.gold : Colors.white.withValues(alpha: 0.14),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: selected ? Colors.white : AppTheme.muted,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _BuildArcanaWorkspace extends StatelessWidget {
  const _BuildArcanaWorkspace({
    super.key,
    required this.runes,
    required this.selectedIds,
    required this.activeColor,
    required this.onColorSelected,
    required this.onToggle,
  });

  final List<BuildRuneSummary> runes;
  final List<int> selectedIds;
  final int activeColor;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final colorRunes = runes
        .where((rune) => rune.color == activeColor)
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              for (final color in const [1, 2, 3]) ...[
                Expanded(
                  child: _ArcanaColorButton(
                    color: color,
                    selected: activeColor == color,
                    selectedCount: _selectedCount(color),
                    onTap: () => onColorSelected(color),
                  ),
                ),
                if (color != 3) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose up to 10 arcana of each color.',
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: colorRunes.isEmpty
              ? const AppEmptyState(
                  icon: Icons.hexagon_outlined,
                  title: 'No arcana available',
                  message: 'Pull to refresh and try again.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: colorRunes.length,
                  itemBuilder: (context, index) {
                    final rune = colorRunes[index];
                    return _BuildCatalogAsset(
                      label: rune.name,
                      imageUrl: rune.iconUrl,
                      selected: selectedIds.contains(rune.id),
                      accent: _arcanaAccent(rune.color),
                      onTap: () => onToggle(rune.id),
                    );
                  },
                ),
        ),
      ],
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

class _ArcanaColorButton extends StatelessWidget {
  const _ArcanaColorButton({
    required this.color,
    required this.selected,
    required this.selectedCount,
    required this.onTap,
  });

  final int color;
  final bool selected;
  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _arcanaAccent(color);
    final label = switch (color) {
      1 => 'Red',
      2 => 'Blue',
      _ => 'Green',
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : AppTheme.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '$selectedCount/10',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      return const AppEmptyState(
        icon: Icons.auto_fix_high_outlined,
        title: 'No skills available',
        message: 'Pull to refresh and try again.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: 0.82,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return _BuildCatalogAsset(
          label: skill.name,
          imageUrl: skill.iconUrl,
          selected: selectedId == skill.id,
          onTap: () => onSelected(skill.id),
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
    this.accent = AppTheme.gold,
    this.showLabel = true,
  });

  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
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
                      ? accent.withValues(alpha: 0.14)
                      : AppTheme.panel,
                  border: Border.all(
                    width: selected ? 2 : 1,
                    color: selected
                        ? accent
                        : Colors.white.withValues(alpha: 0.1),
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
                style: const TextStyle(
                  color: AppTheme.text,
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
    required this.onActionDone,
  });

  final AsyncValue<List<BuildSchemeSummary>> value;
  final BuildSimCommunityFilter filter;
  final int? focusedSchemeId;
  final VoidCallback? onActionDone;

  @override
  ConsumerState<_CommunityBuilds> createState() => _CommunityBuildsState();
}

class _CommunityBuildsState extends ConsumerState<_CommunityBuilds> {
  String? _busyAction;
  bool _latestFirst = true;

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
                    ? 'Favorite Builds'
                    : 'Explore Builds',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.text,
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
                  label: 'Latest',
                  icon: Icons.schedule_outlined,
                  selected: _latestFirst,
                  onTap: () => setState(() => _latestFirst = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExploreSortButton(
                  label: 'Popular',
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
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt_outlined, color: AppTheme.muted),
                      SizedBox(width: 8),
                      Text(
                        'Sort',
                        style: TextStyle(
                          color: AppTheme.muted,
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
                const Icon(Icons.filter_alt_outlined, color: AppTheme.muted),
                const SizedBox(width: 10),
                const Text(
                  'Sort',
                  style: TextStyle(
                    color: AppTheme.muted,
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
            if (schemes.isEmpty) {
              return const AppEmptyState(
                icon: Icons.construction_outlined,
                title: 'No public builds',
                message: 'Pull to refresh or switch region in settings.',
              );
            }
            final visibleSchemes = _visibleSchemes(schemes).toList();
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
                    busyAction: _busyAction,
                    onLike: () => _runAction(
                      'like-${scheme.id}',
                      () => ref.read(buildSimLikeSchemeProvider)(scheme),
                    ),
                    onFavorite: () => _runAction(
                      'favorite-${scheme.id}',
                      () => ref.read(buildSimFavoriteSchemeProvider)(scheme),
                    ),
                    onClone: (slotIndex) => _runAction(
                      'clone-${scheme.id}-$slotIndex',
                      () => ref.read(buildSimCloneSchemeProvider)(
                        scheme,
                        slotIndex,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text(
            error.toString(),
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ],
    );
  }

  List<BuildSchemeSummary> _visibleSchemes(List<BuildSchemeSummary> schemes) {
    final focusedSchemeId = widget.focusedSchemeId;
    if (focusedSchemeId == null) {
      return schemes.take(5).toList(growable: false);
    }

    final focusedIndex = schemes.indexWhere(
      (scheme) => scheme.id == focusedSchemeId,
    );
    if (focusedIndex < 0) {
      return schemes.take(5).toList(growable: false);
    }

    final focused = schemes[focusedIndex];
    final rest = schemes.where((scheme) => scheme.id != focusedSchemeId);
    return [focused, ...rest].take(5).toList(growable: false);
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
        color: selected ? AppTheme.gold : AppTheme.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppTheme.gold
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : AppTheme.muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.muted,
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

class _SimulatorExploreBuildCard extends StatelessWidget {
  const _SimulatorExploreBuildCard({
    required this.scheme,
    required this.busyAction,
    required this.onLike,
    required this.onFavorite,
    required this.onClone,
  });
  final BuildSchemeSummary scheme;
  final String? busyAction;
  final VoidCallback onLike;
  final VoidCallback onFavorite;
  final ValueChanged<int> onClone;

  @override
  Widget build(BuildContext context) {
    final disabled = busyAction != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.panelAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.muted,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheme.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'by ${scheme.authorName}  ·  ${scheme.heroName.isEmpty ? 'Any hero' : scheme.heroName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: scheme.equipmentIcons.length.clamp(0, 6),
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: AppImage(
                  url: scheme.equipmentIcons[index],
                  width: 68,
                  height: 68,
                  borderRadius: 999,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _ExploreAction(
                icon: scheme.isLiked ? Icons.favorite : Icons.favorite_border,
                value: scheme.likeCount,
                onTap: disabled ? null : onLike,
                tooltip: scheme.isLiked ? 'Unlike build' : 'Like build',
              ),
              const SizedBox(width: 10),
              _ExploreAction(
                icon: scheme.isFavorited ? Icons.star : Icons.star_border,
                value: scheme.favoriteCount,
                onTap: disabled ? null : onFavorite,
                tooltip: scheme.isFavorited
                    ? 'Unfavorite build'
                    : 'Favorite build',
              ),
              const SizedBox(width: 10),
              _ExploreAction(
                icon: Icons.copy_outlined,
                value: scheme.cloneCount,
                onTap: disabled ? null : () => onClone(1),
                tooltip: 'Clone to slot 1',
              ),
              const Spacer(),
              _ExploreAction(
                icon: Icons.visibility_outlined,
                onTap: () {},
                tooltip: 'View build',
              ),
              const SizedBox(width: 10),
              _ExploreAction(
                icon: Icons.share_outlined,
                onTap: () {},
                tooltip: 'Share build',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreAction extends StatelessWidget {
  const _ExploreAction({
    required this.icon,
    this.value,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final int? value;
  final VoidCallback? onTap;
  final String tooltip;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.muted),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
