import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
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
              const AppSectionHeader(title: 'Build Simulator'),
              const SizedBox(height: 8),
              Text(
                'Select a hero to manage the three mobile slots.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),
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
                const SizedBox(height: 18),
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
              const SizedBox(height: 22),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hero',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onOpenPicker,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.38),
                ),
              ),
              child: Row(
                children: [
                  AppImage(
                    url: selectedHero.avatar,
                    width: 52,
                    height: 52,
                    borderRadius: 999,
                    semanticLabel: selectedHero.name,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedHero.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.text,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedHero.title.isEmpty
                              ? 'Select a hero to manage builds'
                              : selectedHero.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.swap_horiz, color: AppTheme.gold),
                ],
              ),
            ),
          ),
        ),
      ],
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
        Text(
          'My Slots',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        slotsValue.when(
          data: (slots) {
            final normalized = List<BuildSchemeSummary?>.generate(
              3,
              (index) => index < slots.length ? slots[index] : null,
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < normalized.length; index++) ...[
                  Expanded(
                    child: _SlotCard(
                      index: index + 1,
                      scheme: normalized[index],
                      onTap: () => onEdit(index + 1, normalized[index]),
                    ),
                  ),
                  if (index != normalized.length - 1) const SizedBox(width: 8),
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
    final title = scheme?.title ?? 'Empty slot';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 142,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme == null
                  ? AppTheme.gold.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Slot $index',
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
                const Center(
                  child: Icon(Icons.add, color: AppTheme.gold, size: 30),
                )
              else
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: scheme!.equipmentIcons
                      .take(6)
                      .map(
                        (icon) => AppImage(
                          url: icon,
                          width: 22,
                          height: 22,
                          borderRadius: 5,
                          excludeFromSemantics: true,
                        ),
                      )
                      .toList(growable: false),
                ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            tooltip: 'Discard changes',
            icon: const Icon(Icons.close),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold.withValues(alpha: 0.16),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.55)),
            ),
            child: heroAvatar.isEmpty
                ? const Icon(Icons.shield_outlined, size: 18)
                : ClipOval(
                    child: AppImage(url: heroAvatar, semanticLabel: heroName),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: titleController,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: AppTheme.text,
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
            icon: Icon(
              isPublic ? Icons.lock_open_outlined : Icons.lock_outline,
            ),
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
        label: 'Arcana',
      ),
      (
        tab: _BuildEditorTab.skill,
        icon: Icons.auto_fix_high_outlined,
        label: 'Skill',
      ),
    ];
    return Container(
      height: 48,
      color: AppTheme.panel,
      child: Row(
        children: tabs
            .map(
              (entry) => Expanded(
                child: InkWell(
                  onTap: () => onSelected(entry.tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: selected == entry.tab
                              ? AppTheme.gold
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          entry.icon,
                          size: 17,
                          color: selected == entry.tab
                              ? AppTheme.gold
                              : AppTheme.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.label,
                          style: TextStyle(
                            color: selected == entry.tab
                                ? AppTheme.text
                                : AppTheme.muted,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
    final placeholderCount = (6 - selectedIds.length).clamp(0, 6);
    return Column(
      children: [
        Container(
          height: 90,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: selectedIds.isEmpty
                    ? Row(
                        children: List.generate(
                          6,
                          (_) => const Padding(
                            padding: EdgeInsets.only(right: 7),
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
                            padding: const EdgeInsets.only(right: 8),
                            child: ReorderableDelayedDragStartListener(
                              index: index,
                              child: Tooltip(
                                message: equip?.name ?? 'Equipment $equipId',
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AppImage(
                                      url: equip?.iconUrl,
                                      width: 54,
                                      height: 54,
                                      borderRadius: 999,
                                      semanticLabel: equip?.name,
                                    ),
                                    Positioned(
                                      right: -5,
                                      top: -5,
                                      child: InkWell(
                                        onTap: () => onRemove(equipId),
                                        borderRadius: BorderRadius.circular(99),
                                        child: const CircleAvatar(
                                          radius: 10,
                                          backgroundColor: AppTheme.error,
                                          child: Icon(
                                            Icons.close,
                                            size: 13,
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
              if (placeholderCount > 0 && selectedIds.isNotEmpty)
                Row(
                  children: List.generate(
                    placeholderCount,
                    (_) => const Padding(
                      padding: EdgeInsets.only(left: 7),
                      child: _BuildEmptyEquipmentSlot(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Icon(
                Icons.flash_on_outlined,
                size: 17,
                color: AppTheme.gold,
              ),
              const SizedBox(width: 7),
              Text(
                'Equipment ${selectedIds.length}/12',
                style: const TextStyle(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: equips.isEmpty
              ? const AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No equipment available',
                  message: 'Pull to refresh and try again.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.8,
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
      width: 54,
      height: 54,
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
  });

  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.filter == BuildSimCommunityFilter.favorites
              ? 'Favorite Builds'
              : 'Community Builds',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        widget.value.when(
          data: (schemes) {
            if (schemes.isEmpty) {
              return const AppEmptyState(
                icon: Icons.construction_outlined,
                title: 'No public builds',
                message: 'Pull to refresh or switch region in settings.',
              );
            }
            final visibleSchemes = _visibleSchemes(schemes);
            return Column(
              children: [
                for (final scheme in visibleSchemes) ...[
                  if (scheme.id == widget.focusedSchemeId) ...[
                    const _SharedBuildBadge(),
                    const SizedBox(height: 8),
                  ],
                  BuildSchemeCard(scheme: scheme),
                  const SizedBox(height: 8),
                  _CommunityBuildActions(
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
                  const SizedBox(height: 12),
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

class _CommunityBuildActions extends StatelessWidget {
  const _CommunityBuildActions({
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: disabled ? null : onLike,
              icon: Icon(
                scheme.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 18,
              ),
              label: Text(
                '${scheme.isLiked ? 'Liked' : 'Like'} ${scheme.likeCount}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: disabled ? null : onFavorite,
              icon: Icon(
                scheme.isFavorited
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 18,
              ),
              label: Text(
                '${scheme.isFavorited ? 'Favorited' : 'Favorite'} ${scheme.favoriteCount}',
              ),
            ),
            for (final slotIndex in const [1, 2, 3])
              OutlinedButton.icon(
                onPressed: disabled ? null : () => onClone(slotIndex),
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: Text('Clone S$slotIndex'),
              ),
          ],
        ),
      ),
    );
  }
}
