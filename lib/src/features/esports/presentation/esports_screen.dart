import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/esports_repository.dart';
import '../domain/esports_match_summary.dart';
import '../domain/esports_player_summary.dart';
import '../domain/esports_team_summary.dart';

final esportsRepositoryProvider = Provider<EsportsRepository>((ref) {
  return EsportsRepository(apiClient: ref.watch(apiClientProvider));
});

final esportsMatchesProvider = FutureProvider<List<EsportsMatchSummary>>((ref) {
  return ref.watch(esportsRepositoryProvider).loadMatches();
});

final esportsTeamsProvider = FutureProvider<List<EsportsTeamSummary>>((ref) {
  return ref.watch(esportsRepositoryProvider).loadTeams();
});

final esportsPlayersProvider = FutureProvider<List<EsportsPlayerSummary>>((
  ref,
) {
  return ref.watch(esportsRepositoryProvider).loadPlayers();
});

enum EsportsInitialTab {
  matches,
  teams,
  players;

  int get tabIndex => switch (this) {
    EsportsInitialTab.matches => 0,
    EsportsInitialTab.teams => 1,
    EsportsInitialTab.players => 2,
  };
}

EsportsInitialTab esportsInitialTabFromRoute(String? value) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'teams' => EsportsInitialTab.teams,
    'players' => EsportsInitialTab.players,
    'stats' => EsportsInitialTab.teams,
    'schedule' => EsportsInitialTab.matches,
    'matches' => EsportsInitialTab.matches,
    _ => EsportsInitialTab.matches,
  };
}

class EsportsScreen extends ConsumerWidget {
  const EsportsScreen({super.key, this.initialTab = EsportsInitialTab.matches});

  final EsportsInitialTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.tabIndex,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(title: 'Esports'),
                      const SizedBox(height: 8),
                      Text(
                        'Track pro matches, elite teams, and player form.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.panel,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: AppTheme.gold,
                          unselectedLabelColor: AppTheme.muted,
                          tabs: [
                            Tab(text: 'Matches'),
                            Tab(text: 'Teams'),
                            Tab(text: 'Players'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _MatchesTab(value: ref.watch(esportsMatchesProvider)),
              _TeamsTab(value: ref.watch(esportsTeamsProvider)),
              _PlayersTab(value: ref.watch(esportsPlayersProvider)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchesTab extends ConsumerWidget {
  const _MatchesTab({required this.value});

  final AsyncValue<List<EsportsMatchSummary>> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<EsportsMatchSummary>>(
      value: value,
      retry: () => ref.invalidate(esportsMatchesProvider),
      data: (matches) {
        if (matches.isEmpty) {
          return const AppEmptyState(
            icon: Icons.sports_esports_outlined,
            title: 'No matches found',
            message: 'Pull to refresh and try again.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(esportsMatchesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemBuilder: (context, index) => _MatchCard(match: matches[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: matches.length,
          ),
        );
      },
    );
  }
}

class _TeamsTab extends ConsumerWidget {
  const _TeamsTab({required this.value});

  final AsyncValue<List<EsportsTeamSummary>> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<EsportsTeamSummary>>(
      value: value,
      retry: () => ref.invalidate(esportsTeamsProvider),
      data: (teams) {
        if (teams.isEmpty) {
          return const AppEmptyState(
            icon: Icons.groups_2_outlined,
            title: 'No teams found',
            message: 'Pull to refresh and try again.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(esportsTeamsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemBuilder: (context, index) => _TeamCard(team: teams[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: teams.length,
          ),
        );
      },
    );
  }
}

class _PlayersTab extends ConsumerWidget {
  const _PlayersTab({required this.value});

  final AsyncValue<List<EsportsPlayerSummary>> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<EsportsPlayerSummary>>(
      value: value,
      retry: () => ref.invalidate(esportsPlayersProvider),
      data: (players) {
        if (players.isEmpty) {
          return const AppEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No players found',
            message: 'Pull to refresh and try again.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(esportsPlayersProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemBuilder: (context, index) =>
                _PlayerCard(player: players[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: players.length,
          ),
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final EsportsMatchSummary match;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.leagueName.isEmpty ? 'Match' : match.leagueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (match.stageName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        match.stageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Pill(label: match.statusLabel),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TeamIdentity(
                  name: match.teamAName,
                  logoUrl: match.teamALogoUrl,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  match.scoreText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: _TeamIdentity(
                  name: match.teamBName,
                  logoUrl: match.teamBLogoUrl,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (match.startTime.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              match.startTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team});

  final EsportsTeamSummary team;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Row(
        children: [
          AppImage(
            url: team.logoUrl,
            width: 58,
            height: 58,
            borderRadius: 14,
            semanticLabel: team.name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  team.club.isEmpty ? team.leagueName : team.club,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                team.recordText,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              _Pill(label: team.winRateText),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player});

  final EsportsPlayerSummary player;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Row(
        children: [
          AppImage(
            url: player.avatarUrl,
            width: 58,
            height: 58,
            borderRadius: 14,
            semanticLabel: player.name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                if (player.teamName.isNotEmpty)
                  Text(
                    player.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                if (player.role.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    player.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            direction: Axis.vertical,
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _Pill(label: player.gradeText),
              _Pill(label: '${player.kdaText} KDA'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamIdentity extends StatelessWidget {
  const _TeamIdentity({
    required this.name,
    required this.logoUrl,
    this.alignEnd = false,
  });

  final String name;
  final String logoUrl;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final children = [
      AppImage(
        url: logoUrl,
        width: 38,
        height: 38,
        borderRadius: 10,
        semanticLabel: name,
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ];

    return Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: alignEnd ? children.reversed.toList() : children,
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
