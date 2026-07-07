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
  int? _editingSlotIndex;
  BuildSchemeSummary? _editingScheme;

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
                  onSelected: (index) {
                    setState(() => _selectedHeroIndex = index);
                  },
                ),
                const SizedBox(height: 18),
                _SlotsPanel(
                  slotsValue: slotsValue,
                  onEdit: (slotIndex, scheme) {
                    setState(() {
                      _editingSlotIndex = slotIndex;
                      _editingScheme = scheme;
                    });
                  },
                ),
                if (_editingSlotIndex != null && heroId != null) ...[
                  const SizedBox(height: 14),
                  _BuildEditorPanel(
                    key: ValueKey(
                      '${selectedHero?.heroId}-$_editingSlotIndex-${_editingScheme?.id ?? 'new'}',
                    ),
                    heroId: heroId,
                    slotIndex: _editingSlotIndex!,
                    heroName: selectedHero?.name ?? '',
                    regionCode: ref
                        .watch(appSettingsControllerProvider)
                        .maybeWhen(
                          data: (settings) => settings.region.languageCode,
                          orElse: () => 'en',
                        ),
                    scheme: _editingScheme,
                    catalogValue: ref.watch(buildSimEditorCatalogProvider),
                    onCancel: () {
                      setState(() {
                        _editingSlotIndex = null;
                        _editingScheme = null;
                      });
                    },
                    onSaved: () {
                      ref.invalidate(buildSimUserSlotsProvider(heroId));
                      setState(() {
                        _editingSlotIndex = null;
                        _editingScheme = null;
                      });
                    },
                  ),
                ],
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
}

class _HeroSelector extends StatelessWidget {
  const _HeroSelector({
    required this.heroes,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<HeroSummary> heroes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

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
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AppImage(
                  url: selectedHero.avatar,
                  width: 54,
                  height: 54,
                  borderRadius: 14,
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
                      Text(
                        selectedHero.title.isEmpty
                            ? 'Ready for builds'
                            : selectedHero.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: heroes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final hero = heroes[index];
              final selected = index == selectedIndex;
              return ChoiceChip(
                selected: selected,
                label: Text(hero.name),
                onSelected: (_) => onSelected(index),
                selectedColor: AppTheme.gold.withValues(alpha: 0.22),
                backgroundColor: AppTheme.panelAlt,
                labelStyle: TextStyle(
                  color: selected ? AppTheme.gold : AppTheme.text,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected
                      ? AppTheme.gold.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
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
            return Column(
              children: [
                for (var index = 0; index < normalized.length; index++) ...[
                  _SlotCard(
                    index: index + 1,
                    scheme: normalized[index],
                    onTap: () => onEdit(index + 1, normalized[index]),
                  ),
                  if (index != normalized.length - 1)
                    const SizedBox(height: 10),
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
    final subtitle = scheme == null
        ? 'Create or clone a scheme here'
        : '${scheme!.heroName} · ${scheme!.isPublic ? 'Public' : 'Private'}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: AppTheme.gold.withValues(alpha: 0.14),
            foregroundColor: AppTheme.gold,
            child: Text('$index'),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Slot $index',
                style: const TextStyle(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.muted),
          ),
          trailing: Icon(
            scheme == null ? Icons.add_circle_outline : Icons.edit_outlined,
            color: AppTheme.gold,
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
    required this.regionCode,
    required this.scheme,
    required this.catalogValue,
    required this.onCancel,
    required this.onSaved,
  });

  final int heroId;
  final int slotIndex;
  final String heroName;
  final String regionCode;
  final BuildSchemeSummary? scheme;
  final AsyncValue<BuildEditorCatalog> catalogValue;
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.22)),
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
                    'Edit Build Slot ${widget.slotIndex}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Build name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Private'),
                  selected: !_isPublic,
                  onSelected: (_) => setState(() => _isPublic = false),
                ),
                ChoiceChip(
                  label: const Text('Public'),
                  selected: _isPublic,
                  onSelected: (_) => setState(() => _isPublic = true),
                ),
              ],
            ),
            const SizedBox(height: 14),
            widget.catalogValue.when(
              data: (catalog) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EditorSectionTitle('Equipment'),
                  const SizedBox(height: 8),
                  _EquipSelector(
                    equips: catalog.equips,
                    selectedIds: _equipIds,
                    onToggle: _toggleEquip,
                  ),
                  const SizedBox(height: 10),
                  _SelectedEquipOrder(
                    equips: catalog.equips,
                    selectedIds: _equipIds,
                    onMoveUp: _moveEquipUp,
                    onMoveDown: _moveEquipDown,
                    onRemove: _removeEquip,
                  ),
                  const SizedBox(height: 14),
                  _EditorSectionTitle('Arcana'),
                  const SizedBox(height: 8),
                  _RuneSelector(
                    runes: catalog.runes,
                    selectedIds: _runeIds,
                    onToggle: _toggleRune,
                  ),
                  const SizedBox(height: 14),
                  _EditorSectionTitle('Summoner Skill'),
                  const SizedBox(height: 8),
                  _SummonerSkillSelector(
                    skills: catalog.summonerSkills,
                    selectedId: _summonerSkillId,
                    onSelected: (skillId) {
                      setState(() => _summonerSkillId = skillId);
                    },
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text(
                error.toString(),
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save Build'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEquip(int equipId) {
    setState(() {
      if (_equipIds.contains(equipId)) {
        _equipIds = _equipIds.where((id) => id != equipId).toList();
      } else if (_equipIds.length < 6) {
        _equipIds = [..._equipIds, equipId];
      }
    });
  }

  void _moveEquipUp(int equipId) {
    final index = _equipIds.indexOf(equipId);
    if (index <= 0) return;
    setState(() {
      final next = [..._equipIds];
      final value = next.removeAt(index);
      next.insert(index - 1, value);
      _equipIds = next;
    });
  }

  void _moveEquipDown(int equipId) {
    final index = _equipIds.indexOf(equipId);
    if (index < 0 || index >= _equipIds.length - 1) return;
    setState(() {
      final next = [..._equipIds];
      final value = next.removeAt(index);
      next.insert(index + 1, value);
      _equipIds = next;
    });
  }

  void _removeEquip(int equipId) {
    setState(() {
      _equipIds = _equipIds.where((id) => id != equipId).toList();
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

class _EditorSectionTitle extends StatelessWidget {
  const _EditorSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppTheme.muted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EquipSelector extends StatelessWidget {
  const _EquipSelector({
    required this.equips,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<BuildEquipSummary> equips;
  final List<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (equips.isEmpty) {
      return const Text(
        'No equipment available',
        style: TextStyle(color: AppTheme.muted),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final equip in equips.take(24))
          FilterChip(
            selected: selectedIds.contains(equip.id),
            label: Text(equip.name),
            avatar: equip.iconUrl.isEmpty
                ? null
                : AppImage(
                    url: equip.iconUrl,
                    width: 24,
                    height: 24,
                    borderRadius: 6,
                    semanticLabel: equip.name,
                  ),
            onSelected: (_) => onToggle(equip.id),
          ),
      ],
    );
  }
}

class _SelectedEquipOrder extends StatelessWidget {
  const _SelectedEquipOrder({
    required this.equips,
    required this.selectedIds,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final List<BuildEquipSummary> equips;
  final List<int> selectedIds;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (selectedIds.isEmpty) {
      return const Text(
        'Select up to six items. Saved order follows this list.',
        style: TextStyle(color: AppTheme.muted),
      );
    }

    final equipById = {for (final equip in equips) equip.id: equip};

    return Column(
      children: [
        for (var index = 0; index < selectedIds.length; index++) ...[
          _SelectedEquipRow(
            index: index,
            equip:
                equipById[selectedIds[index]] ??
                BuildEquipSummary(
                  id: selectedIds[index],
                  name: 'Equipment ${selectedIds[index]}',
                  iconUrl: '',
                ),
            isFirst: index == 0,
            isLast: index == selectedIds.length - 1,
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            onRemove: onRemove,
          ),
          if (index != selectedIds.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _SelectedEquipRow extends StatelessWidget {
  const _SelectedEquipRow({
    required this.index,
    required this.equip,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int index;
  final BuildEquipSummary equip;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                equip.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Move ${equip.name} up',
              onPressed: isFirst ? null : () => onMoveUp(equip.id),
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
            IconButton(
              tooltip: 'Move ${equip.name} down',
              onPressed: isLast ? null : () => onMoveDown(equip.id),
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
            IconButton(
              tooltip: 'Remove ${equip.name}',
              onPressed: () => onRemove(equip.id),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuneSelector extends StatelessWidget {
  const _RuneSelector({
    required this.runes,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<BuildRuneSummary> runes;
  final List<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (runes.isEmpty) {
      return const Text(
        'No arcana available',
        style: TextStyle(color: AppTheme.muted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final color in const [1, 2, 3]) ...[
          _ArcanaMatrixCard(
            color: color,
            selectedCount: _selectedCountForColor(color),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rune in runes.where((rune) => rune.color == color))
                FilterChip(
                  selected: selectedIds.contains(rune.id),
                  label: Text(rune.name),
                  avatar: rune.iconUrl.isEmpty
                      ? null
                      : AppImage(
                          url: rune.iconUrl,
                          width: 24,
                          height: 24,
                          borderRadius: 6,
                          semanticLabel: rune.name,
                        ),
                  onSelected: (_) => onToggle(rune.id),
                ),
            ],
          ),
          if (color != 3) const SizedBox(height: 10),
        ],
      ],
    );
  }

  int _selectedCountForColor(int color) {
    final runeIdsForColor = runes
        .where((rune) => rune.color == color)
        .map((rune) => rune.id)
        .toSet();
    return selectedIds.where(runeIdsForColor.contains).length.clamp(0, 10);
  }
}

class _ArcanaMatrixCard extends StatelessWidget {
  const _ArcanaMatrixCard({required this.color, required this.selectedCount});

  final int color;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(color);
    final title = '${_colorName(color)} Arcana Matrix';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '$selectedCount/10',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var index = 0; index < 10; index++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < selectedCount
                          ? accent.withValues(alpha: 0.86)
                          : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: index < selectedCount
                            ? accent
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const SizedBox(width: 18, height: 18),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _colorName(int color) {
    return switch (color) {
      1 => 'Red',
      2 => 'Blue',
      3 => 'Green',
      _ => 'Arcana',
    };
  }

  Color _accentColor(int color) {
    return switch (color) {
      1 => const Color(0xFFFF6B6B),
      2 => AppTheme.cyan,
      3 => const Color(0xFF4ADE80),
      _ => AppTheme.gold,
    };
  }
}

class _SummonerSkillSelector extends StatelessWidget {
  const _SummonerSkillSelector({
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
      return const Text(
        'No summoner skills available',
        style: TextStyle(color: AppTheme.muted),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final skill in skills)
          ChoiceChip(
            selected: selectedId == skill.id,
            label: Text(skill.name),
            avatar: skill.iconUrl.isEmpty
                ? null
                : AppImage(
                    url: skill.iconUrl,
                    width: 24,
                    height: 24,
                    borderRadius: 6,
                    semanticLabel: skill.name,
                  ),
            onSelected: (_) => onSelected(skill.id),
          ),
      ],
    );
  }
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
