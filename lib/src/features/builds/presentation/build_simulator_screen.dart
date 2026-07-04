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

class BuildSimulatorScreen extends ConsumerStatefulWidget {
  const BuildSimulatorScreen({super.key});

  @override
  ConsumerState<BuildSimulatorScreen> createState() =>
      _BuildSimulatorScreenState();
}

class _BuildSimulatorScreenState extends ConsumerState<BuildSimulatorScreen> {
  int _selectedHeroIndex = 0;

  @override
  Widget build(BuildContext context) {
    final heroesValue = ref.watch(buildSimHeroesProvider);
    final publicSchemesValue = ref.watch(buildSimPublicSchemesProvider);

    return AppAsyncView<List<HeroSummary>>(
      value: heroesValue,
      retry: () => ref.invalidate(buildSimHeroesProvider),
      data: (heroes) {
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
                _SlotsPanel(slotsValue: slotsValue),
              ],
              const SizedBox(height: 22),
              _CommunityBuilds(value: publicSchemesValue),
            ],
          ),
        );
      },
    );
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
  const _SlotsPanel({required this.slotsValue});

  final AsyncValue<List<BuildSchemeSummary?>> slotsValue;

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
                  _SlotCard(index: index + 1, scheme: normalized[index]),
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
  const _SlotCard({required this.index, required this.scheme});

  final int index;
  final BuildSchemeSummary? scheme;

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
      child: ListTile(
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
    );
  }
}

class _CommunityBuilds extends StatelessWidget {
  const _CommunityBuilds({required this.value});

  final AsyncValue<List<BuildSchemeSummary>> value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Builds',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        value.when(
          data: (schemes) {
            if (schemes.isEmpty) {
              return const AppEmptyState(
                icon: Icons.construction_outlined,
                title: 'No public builds',
                message: 'Pull to refresh or switch region in settings.',
              );
            }
            return Column(
              children: [
                for (final scheme in schemes.take(5)) ...[
                  BuildSchemeCard(scheme: scheme),
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
}
