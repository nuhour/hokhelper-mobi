import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/esports_repository.dart';
import '../domain/esports_match_summary.dart';
import '../domain/esports_player_summary.dart';
import '../domain/esports_stat_summary.dart';
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

final esportsStatsProvider = FutureProvider<List<EsportsStatSummary>>((ref) {
  return ref.watch(esportsRepositoryProvider).loadStats();
});

enum EsportsInitialTab {
  matches,
  stats,
  teams,
  players;

  int get tabIndex => switch (this) {
    EsportsInitialTab.matches => 0,
    EsportsInitialTab.stats => 1,
    EsportsInitialTab.teams => 2,
    EsportsInitialTab.players => 3,
  };
}

EsportsInitialTab esportsInitialTabFromRoute(String? value) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'teams' => EsportsInitialTab.teams,
    'players' => EsportsInitialTab.players,
    'stats' => EsportsInitialTab.stats,
    'schedule' => EsportsInitialTab.matches,
    'matches' => EsportsInitialTab.matches,
    _ => EsportsInitialTab.matches,
  };
}

class EsportsScreen extends ConsumerWidget {
  const EsportsScreen({
    super.key,
    this.initialTab = EsportsInitialTab.matches,
    this.initialTeamId,
    this.initialPlayerId,
  });

  final EsportsInitialTab initialTab;
  final String? initialTeamId;
  final String? initialPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
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
                        child: TabBar(
                          isScrollable: true,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: AppTheme.gold,
                          unselectedLabelColor: AppTheme.muted,
                          onTap: (index) => _syncRouteWithTab(context, index),
                          tabs: [
                            Tab(text: 'Matches'),
                            Tab(text: 'Stats'),
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
              _StatsTab(value: ref.watch(esportsStatsProvider)),
              _TeamsTab(
                value: ref.watch(esportsTeamsProvider),
                focusedTeamId: initialTeamId,
              ),
              _PlayersTab(
                value: ref.watch(esportsPlayersProvider),
                focusedPlayerId: initialPlayerId,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncRouteWithTab(BuildContext context, int index) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    final tabPath = switch (index) {
      1 => 'stats',
      2 => 'teams',
      3 => 'players',
      _ => 'schedule',
    };
    final currentUri = router.routeInformationProvider.value.uri;
    final routeBase = currentUri.path.startsWith('/tools/esports')
        ? '/tools/esports'
        : '/esports';
    final nextUri = Uri(path: '$routeBase/$tabPath');
    if (nextUri == currentUri) {
      return;
    }
    router.go(nextUri.toString());
  }
}

class _MatchesTab extends ConsumerStatefulWidget {
  const _MatchesTab({required this.value});

  final AsyncValue<List<EsportsMatchSummary>> value;

  @override
  ConsumerState<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<_MatchesTab> {
  String _leagueFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return AppAsyncView<List<EsportsMatchSummary>>(
      value: widget.value,
      retry: () => ref.invalidate(esportsMatchesProvider),
      data: (matches) {
        if (matches.isEmpty) {
          return const AppEmptyState(
            icon: Icons.sports_esports_outlined,
            title: 'No matches found',
            message: 'Pull to refresh and try again.',
          );
        }
        final leagueOptions = _matchLeagueOptions(matches);
        final selectedLeague = leagueOptions.contains(_leagueFilter)
            ? _leagueFilter
            : 'all';
        final filteredMatches = selectedLeague == 'all'
            ? matches
            : matches
                  .where((match) => match.leagueName.trim() == selectedLeague)
                  .toList();
        final cards = <Widget>[
          _FilterCard(
            children: [
              _FilterDropdown(
                width: 180,
                value: selectedLeague,
                fallbackLabel: 'All Leagues',
                options: leagueOptions,
                onChanged: (value) {
                  setState(() {
                    _leagueFilter = value;
                  });
                },
              ),
            ],
          ),
          if (filteredMatches.isEmpty)
            const AppEmptyState(
              icon: Icons.sports_esports_outlined,
              title: 'No matches found',
              message: 'Try another league filter.',
            )
          else
            ...filteredMatches.map((match) => _MatchCard(match: match)),
        ];
        return RefreshIndicator(
          onRefresh: () => ref.refresh(esportsMatchesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemBuilder: (context, index) => cards[index],
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: cards.length,
          ),
        );
      },
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.value});

  final AsyncValue<List<EsportsStatSummary>> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<EsportsStatSummary>>(
      value: value,
      retry: () => ref.invalidate(esportsStatsProvider),
      data: (stats) {
        if (stats.isEmpty) {
          return const AppEmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'No stats data',
            message: 'Pull to refresh and try again.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(esportsStatsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StatsIntroCard(),
                    const SizedBox(height: 12),
                    _StatCard(stat: stats[index]),
                  ],
                );
              }
              return _StatCard(stat: stats[index]);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: stats.length,
          ),
        );
      },
    );
  }
}

class _TeamsTab extends ConsumerWidget {
  const _TeamsTab({required this.value, required this.focusedTeamId});

  final AsyncValue<List<EsportsTeamSummary>> value;
  final String? focusedTeamId;

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
        final focusedTeam = _findTeam(teams, focusedTeamId);
        final cards = [
          if (focusedTeam != null) _FocusedTeamCard(team: focusedTeam),
          ...teams.map((team) => _TeamCard(team: team)),
        ];
        return RefreshIndicator(
          onRefresh: () => ref.refresh(esportsTeamsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemBuilder: (context, index) => cards[index],
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: cards.length,
          ),
        );
      },
    );
  }
}

class _PlayersTab extends ConsumerStatefulWidget {
  const _PlayersTab({required this.value, required this.focusedPlayerId});

  final AsyncValue<List<EsportsPlayerSummary>> value;
  final String? focusedPlayerId;

  @override
  ConsumerState<_PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends ConsumerState<_PlayersTab> {
  String _teamFilter = 'all';
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return AppAsyncView<List<EsportsPlayerSummary>>(
      value: widget.value,
      retry: () => ref.invalidate(esportsPlayersProvider),
      data: (players) {
        if (players.isEmpty) {
          return const AppEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No players found',
            message: 'Pull to refresh and try again.',
          );
        }
        final teamOptions = _playerTeamOptions(players);
        final roleOptions = _playerRoleOptions(players);
        final selectedTeam = teamOptions.contains(_teamFilter)
            ? _teamFilter
            : 'all';
        final selectedRole = roleOptions.contains(_roleFilter)
            ? _roleFilter
            : 'all';
        final filteredPlayers = players.where((player) {
          final matchesTeam =
              selectedTeam == 'all' || player.teamName.trim() == selectedTeam;
          final matchesRole =
              selectedRole == 'all' || player.role.trim() == selectedRole;
          return matchesTeam && matchesRole;
        }).toList();
        final focusedPlayer = _findPlayer(players, widget.focusedPlayerId);
        final cards = <Widget>[
          _FilterCard(
            children: [
              _FilterDropdown(
                width: 160,
                value: selectedTeam,
                fallbackLabel: 'All Teams',
                options: teamOptions,
                onChanged: (value) {
                  setState(() {
                    _teamFilter = value;
                  });
                },
              ),
              _FilterDropdown(
                width: 150,
                value: selectedRole,
                fallbackLabel: 'All Roles',
                options: roleOptions,
                onChanged: (value) {
                  setState(() {
                    _roleFilter = value;
                  });
                },
              ),
            ],
          ),
          if (focusedPlayer != null) _FocusedPlayerCard(player: focusedPlayer),
          if (filteredPlayers.isEmpty)
            const AppEmptyState(
              icon: Icons.person_search_outlined,
              title: 'No players found',
              message: 'Try another team filter.',
            )
          else
            ...filteredPlayers
                .where((player) => player.id != focusedPlayer?.id)
                .map((player) => _PlayerCard(player: player)),
        ];
        return RefreshIndicator(
          onRefresh: () => ref.refresh(esportsPlayersProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemBuilder: (context, index) => cards[index],
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: cards.length,
          ),
        );
      },
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: AppTheme.gold, size: 20),
              const SizedBox(width: 10),
              Text(
                'Filters',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: children),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.value,
    required this.fallbackLabel,
    required this.options,
    required this.onChanged,
  });

  final double width;
  final String value;
  final String fallbackLabel;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.panel,
              iconEnabledColor: AppTheme.gold,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text(fallbackLabel)),
                ...options.map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (nextValue) {
                if (nextValue != null) {
                  onChanged(nextValue);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final EsportsMatchSummary match;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      onTap: () => _showMatchDetailSheet(context, match),
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

void _showMatchDetailSheet(BuildContext context, EsportsMatchSummary match) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.panel,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Match Detail',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                match.title.isEmpty ? 'Match' : match.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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
                ),
              ),
              const SizedBox(height: 14),
              _MatchDetailRow(label: 'Status', value: match.statusLabel),
              if (match.startTime.isNotEmpty)
                _MatchDetailRow(label: 'Start', value: match.startTime),
            ],
          ),
        ),
      );
    },
  );
}

class _MatchDetailRow extends StatelessWidget {
  const _MatchDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsIntroCard extends StatelessWidget {
  const _StatsIntroCard();

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      accentColor: AppTheme.gold,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.leaderboard_outlined,
                color: AppTheme.gold,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esports Stats',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hero rankings and player performance',
                  maxLines: 2,
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
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final EsportsStatSummary stat;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${stat.rank}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              AppImage(
                url: stat.imageUrl,
                width: 48,
                height: 48,
                borderRadius: 12,
                semanticLabel: stat.objectName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.objectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (stat.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        stat.subtitle,
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
              if (stat.leagueName.isNotEmpty) ...[
                const SizedBox(width: 8),
                _Pill(label: stat.leagueName),
              ],
            ],
          ),
          if (stat.metrics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stat.metrics
                  .map((metric) => _StatMetricChip(metric: metric))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatMetricChip extends StatelessWidget {
  const _StatMetricChip({required this.metric});

  final EsportsStatMetric metric;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              metric.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              metric.value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusedTeamCard extends StatelessWidget {
  const _FocusedTeamCard({required this.team});

  final EsportsTeamSummary team;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      accentColor: AppTheme.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FocusLabel(label: 'Focused Team'),
          const SizedBox(height: 12),
          Row(
            children: [
              AppImage(
                url: team.logoUrl,
                width: 62,
                height: 62,
                borderRadius: 16,
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
                      team.leagueName.isEmpty
                          ? 'League unknown'
                          : team.leagueName,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FocusMetric(label: 'Record', value: team.recordText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FocusMetric(label: 'Win Rate', value: team.winRateText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusedPlayerCard extends StatelessWidget {
  const _FocusedPlayerCard({required this.player});

  final EsportsPlayerSummary player;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      accentColor: AppTheme.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FocusLabel(label: 'Focused Player'),
          const SizedBox(height: 12),
          Row(
            children: [
              AppImage(
                url: player.avatarUrl,
                width: 62,
                height: 62,
                borderRadius: 16,
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
                    if (player.teamName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        player.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                    if (player.role.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        player.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.gold),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FocusMetric(label: 'Grade', value: player.gradeText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FocusMetric(label: 'KDA', value: player.kdaText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FocusMetric(
                  label: 'Win Rate',
                  value: player.winRateText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusLabel extends StatelessWidget {
  const _FocusLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.gold,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _FocusMetric extends StatelessWidget {
  const _FocusMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team});

  final EsportsTeamSummary team;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/esports/teams/${team.id}'),
        child: _PanelCard(
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
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player});

  final EsportsPlayerSummary player;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/esports/players/${player.id}'),
        child: _PanelCard(
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
        ),
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
  const _PanelCard({required this.child, this.accentColor, this.onTap});

  final Widget child;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(
          color: (accentColor ?? Colors.white).withValues(
            alpha: accentColor == null ? 0.08 : 0.28,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
    if (onTap == null) {
      return card;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

EsportsTeamSummary? _findTeam(
  List<EsportsTeamSummary> teams,
  String? focusedTeamId,
) {
  final id = focusedTeamId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final team in teams) {
    if (team.id == id) {
      return team;
    }
  }
  return null;
}

EsportsPlayerSummary? _findPlayer(
  List<EsportsPlayerSummary> players,
  String? focusedPlayerId,
) {
  final id = focusedPlayerId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final player in players) {
    if (player.id == id) {
      return player;
    }
  }
  return null;
}

List<String> _matchLeagueOptions(List<EsportsMatchSummary> matches) {
  final leagues = <String>{};
  for (final match in matches) {
    final leagueName = match.leagueName.trim();
    if (leagueName.isNotEmpty) {
      leagues.add(leagueName);
    }
  }
  return leagues.toList()..sort();
}

List<String> _playerTeamOptions(List<EsportsPlayerSummary> players) {
  final teams = <String>{};
  for (final player in players) {
    final teamName = player.teamName.trim();
    if (teamName.isNotEmpty) {
      teams.add(teamName);
    }
  }
  return teams.toList()..sort();
}

List<String> _playerRoleOptions(List<EsportsPlayerSummary> players) {
  final roles = <String>{};
  for (final player in players) {
    final role = player.role.trim();
    if (role.isNotEmpty) {
      roles.add(role);
    }
  }
  return roles.toList()..sort();
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
