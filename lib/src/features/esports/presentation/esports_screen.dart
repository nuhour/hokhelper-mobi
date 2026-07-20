import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/esports_repository.dart';
import '../domain/esports_match_summary.dart';
import '../domain/esports_meta.dart';
import '../domain/esports_player_summary.dart';
import '../domain/esports_stat_summary.dart';
import '../domain/esports_team_summary.dart';

final esportsRepositoryProvider = Provider<EsportsRepository>((ref) {
  return EsportsRepository(apiClient: ref.watch(apiClientProvider));
});

final esportsMatchesProvider = FutureProvider<List<EsportsMatchSummary>>((ref) {
  return ref.watch(esportsRepositoryProvider).loadMatches();
});

final esportsMatchesByLeagueProvider =
    FutureProvider.family<List<EsportsMatchSummary>, String>((ref, league) {
      return ref.watch(esportsRepositoryProvider).loadMatches(league: league);
    });

final esportsTeamsProvider = FutureProvider<List<EsportsTeamSummary>>((ref) {
  return ref.watch(esportsRepositoryProvider).loadTeams();
});

final esportsTeamsByLeagueProvider =
    FutureProvider.family<List<EsportsTeamSummary>, String>((ref, league) {
      return ref.watch(esportsRepositoryProvider).loadTeams(league: league);
    });

final esportsPlayersProvider = FutureProvider<List<EsportsPlayerSummary>>((
  ref,
) {
  return ref.watch(esportsRepositoryProvider).loadPlayers();
});

final esportsPlayersByLeagueProvider =
    FutureProvider.family<List<EsportsPlayerSummary>, String>((ref, league) {
      return ref.watch(esportsRepositoryProvider).loadPlayers(league: league);
    });

final esportsStatsProvider = FutureProvider<List<EsportsStatSummary>>((ref) {
  return ref
      .watch(appSettingsControllerProvider.future)
      .then(
        (settings) => ref
            .watch(esportsRepositoryProvider)
            .loadStats(regionId: settings.region.regionId),
      );
});

final esportsStatsByRankProvider =
    FutureProvider.family<List<EsportsStatSummary>, int>((ref, rankType) {
      if (rankType == 1) {
        return ref.watch(esportsStatsProvider.future);
      }
      return ref
          .watch(appSettingsControllerProvider.future)
          .then(
            (settings) => ref
                .watch(esportsRepositoryProvider)
                .loadStats(
                  rankType: rankType,
                  regionId: settings.region.regionId,
                ),
          );
    });

typedef _EsportsStatsQuery = ({int rankType, String league});

final esportsStatsByQueryProvider =
    FutureProvider.family<List<EsportsStatSummary>, _EsportsStatsQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(appSettingsControllerProvider.future)
          .then(
            (settings) => ref
                .watch(esportsRepositoryProvider)
                .loadStats(
                  rankType: query.rankType,
                  league: query.league,
                  regionId: settings.region.regionId,
                ),
          );
    });

final esportsMetaProvider = FutureProvider<EsportsMeta>((ref) {
  return ref.watch(esportsRepositoryProvider).loadMeta();
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

class EsportsScreen extends ConsumerStatefulWidget {
  const EsportsScreen({
    super.key,
    this.initialTab = EsportsInitialTab.matches,
    this.initialTeamId,
    this.initialPlayerId,
    this.syncRouteOnTabTap = true,
  });

  final EsportsInitialTab initialTab;
  final String? initialTeamId;
  final String? initialPlayerId;
  final bool syncRouteOnTabTap;

  @override
  ConsumerState<EsportsScreen> createState() => _EsportsScreenState();
}

class _EsportsScreenState extends ConsumerState<EsportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.tabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _EsportsTabStrip(
              controller: _tabController,
              labels: const ['Matches', 'Stats', 'Teams', 'Players'],
              onTap: widget.syncRouteOnTabTap
                  ? (index) => _syncRouteWithTab(context, index)
                  : null,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MatchesTab(value: ref.watch(esportsMatchesProvider)),
                const _StatsTab(),
                _TeamsTab(
                  value: ref.watch(esportsTeamsProvider),
                  focusedTeamId: widget.initialTeamId,
                ),
                _PlayersTab(
                  value: ref.watch(esportsPlayersProvider),
                  focusedPlayerId: widget.initialPlayerId,
                ),
              ],
            ),
          ),
        ],
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

class _EsportsTabStrip extends StatelessWidget {
  const _EsportsTabStrip({
    required this.controller,
    required this.labels,
    this.onTap,
  });

  final TabController controller;
  final List<String> labels;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        dividerColor: Colors.transparent,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.gold, width: 3),
          borderRadius: BorderRadius.all(Radius.circular(999)),
          insets: EdgeInsets.symmetric(horizontal: 18),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        labelColor: AppTheme.text,
        unselectedLabelColor: AppTheme.muted,
        labelStyle: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        unselectedLabelStyle: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        onTap: onTap,
        tabs: [for (final label in labels) Tab(text: label, height: 42)],
      ),
    );
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
  bool _leagueSelectionTouched = false;
  String _statusFilter = 'all';
  String _dateFilter = '';

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(esportsMetaProvider).valueOrNull;
    final leagueFilter = _effectiveLeagueFilter(
      meta,
      selected: _leagueFilter,
      selectionTouched: _leagueSelectionTouched,
    );
    final leagueRequestValue = _leagueRequestValue(meta, leagueFilter);
    final baseMatches = widget.value.valueOrNull ?? const [];
    final hasLeagueInBase = baseMatches.any(
      (match) => match.leagueName == leagueFilter,
    );
    final activeProvider = leagueFilter == 'all' || hasLeagueInBase
        ? null
        : esportsMatchesByLeagueProvider(leagueRequestValue);
    final activeValue = activeProvider == null
        ? widget.value
        : ref.watch(activeProvider);
    return AppAsyncView<List<EsportsMatchSummary>>(
      value: activeValue,
      retry: () => activeProvider == null
          ? ref.invalidate(esportsMatchesProvider)
          : ref.invalidate(activeProvider),
      data: (matches) {
        if (matches.isEmpty) {
          return const AppEmptyState(
            icon: Icons.sports_esports_outlined,
            title: 'No matches found',
            message: 'Pull to refresh and try again.',
          );
        }
        final leagueOptions = _leagueNames(
          meta,
          matches.map((match) => match.leagueName),
        );
        final selectedLeague = leagueOptions.contains(leagueFilter)
            ? leagueFilter
            : 'all';
        final statusOptions = _matchStatusOptions(matches);
        final selectedStatus =
            statusOptions.map((option) => option.value).contains(_statusFilter)
            ? _statusFilter
            : 'all';
        final filteredMatches = matches.where((match) {
          final matchesLeague =
              selectedLeague == 'all' ||
              match.leagueName.trim() == selectedLeague;
          final matchesStatus =
              selectedStatus == 'all' ||
              match.statusKey.trim().toLowerCase() == selectedStatus;
          final matchesDate =
              _dateFilter.trim().isEmpty ||
              _matchDateValue(match.startTime) == _dateFilter.trim();
          return matchesLeague && matchesStatus && matchesDate;
        }).toList();
        final groupedMatches = _groupMatchesByStatus(filteredMatches);
        final championMatchId = _championMatchId(matches);
        final matchSections = _matchStatusOptions(matches).map((status) {
          return _MatchStatusSection(
            status: status,
            matches: groupedMatches[status.value] ?? const [],
            championMatchId: championMatchId,
          );
        });
        final cards = <Widget>[
          _FilterCard(
            children: [
              _FilterDropdown(
                width: 180,
                value: selectedLeague,
                fallbackLabel: 'All Leagues',
                options: _textFilterOptions(leagueOptions),
                onChanged: (value) {
                  setState(() {
                    _leagueFilter = value;
                    _leagueSelectionTouched = true;
                  });
                },
              ),
              _FilterDropdown(
                width: 160,
                value: selectedStatus,
                fallbackLabel: 'All Status',
                options: statusOptions,
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                },
              ),
              _FilterTextField(
                width: 150,
                label: 'Match Date',
                value: _dateFilter,
                hintText: 'YYYY-MM-DD',
                onChanged: (value) {
                  setState(() {
                    _dateFilter = value;
                  });
                },
              ),
            ],
          ),
          if (filteredMatches.isEmpty)
            const AppEmptyState(
              icon: Icons.sports_esports_outlined,
              title: 'No matches found',
              message: 'Try another match filter.',
            )
          else
            ...matchSections,
        ];
        return RefreshIndicator(
          onRefresh: () => activeProvider == null
              ? ref.refresh(esportsMatchesProvider.future)
              : ref.refresh(activeProvider.future),
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

class _StatsTab extends ConsumerStatefulWidget {
  const _StatsTab();

  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
  int _rankType = 1;
  String _leagueFilter = 'all';
  bool _leagueSelectionTouched = false;
  final Map<String, List<EsportsStatSummary>> _cachedStats = {};

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(esportsMetaProvider).valueOrNull;
    final leagueFilter = _effectiveLeagueFilter(
      meta,
      selected: _leagueFilter,
      selectionTouched: _leagueSelectionTouched,
    );
    final leagueRequestValue = _leagueRequestValue(meta, leagueFilter);
    final rankTypes = meta?.rankTypes.isNotEmpty == true
        ? meta!.rankTypes
        : const [
            EsportsRankType(value: 1, label: 'Team'),
            EsportsRankType(value: 2, label: 'Player'),
            EsportsRankType(value: 3, label: 'Player Hero'),
            EsportsRankType(value: 4, label: 'Hero'),
          ];
    final selectedRank = rankTypes.any((type) => type.value == _rankType)
        ? _rankType
        : rankTypes.first.value;
    final statsProvider = leagueFilter == 'all'
        ? null
        : esportsStatsByQueryProvider((
            rankType: selectedRank,
            league: leagueRequestValue,
          ));
    final value = statsProvider == null
        ? ref.watch(esportsStatsByRankProvider(selectedRank))
        : ref.watch(statsProvider);
    final cacheKey = '$selectedRank:${leagueFilter.trim()}';
    final freshStats = value.valueOrNull;
    if (freshStats != null) {
      _cachedStats[cacheKey] = freshStats;
    }
    final stats = freshStats ?? _cachedStats[cacheKey] ?? const [];
    final leagueNames = _leagueNames(
      meta,
      stats.map((stat) => stat.leagueName),
    );
    final selectedLeague = leagueNames.contains(leagueFilter)
        ? leagueFilter
        : 'all';
    final visibleStats = stats
        .where(
          (stat) =>
              selectedLeague == 'all' || stat.leagueName == selectedLeague,
        )
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: () => statsProvider == null
          ? ref.refresh(esportsStatsByRankProvider(selectedRank).future)
          : ref.refresh(statsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _StatsIntroCard(
            rankTypes: rankTypes,
            selectedRank: selectedRank,
            onRankChanged: (rankType) => setState(() => _rankType = rankType),
          ),
          const SizedBox(height: 10),
          _FilterCard(
            children: [
              _FilterDropdown(
                width: 220,
                value: selectedLeague,
                fallbackLabel: 'All Leagues',
                options: _textFilterOptions(leagueNames),
                onChanged: (league) => setState(() {
                  _leagueFilter = league;
                  _leagueSelectionTouched = true;
                }),
              ),
            ],
          ),
          if (value.isLoading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 12),
          if (visibleStats.isNotEmpty)
            _EsportsStatsTable(stats: visibleStats, rankType: selectedRank)
          else if (value.hasError)
            AppEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Stats unavailable',
              message: '${value.error}',
            )
          else if (!value.isLoading)
            const AppEmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'No stats data',
              message: 'Try another league or pull to refresh.',
            )
          else
            const _StatsLoadingTable(),
        ],
      ),
    );
  }
}

class _TeamsTab extends ConsumerStatefulWidget {
  const _TeamsTab({required this.value, required this.focusedTeamId});

  final AsyncValue<List<EsportsTeamSummary>> value;
  final String? focusedTeamId;

  @override
  ConsumerState<_TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends ConsumerState<_TeamsTab> {
  String _leagueFilter = 'all';
  bool _leagueSelectionTouched = false;

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(esportsMetaProvider).valueOrNull;
    final leagueFilter = _effectiveLeagueFilter(
      meta,
      selected: _leagueFilter,
      selectionTouched: _leagueSelectionTouched,
    );
    final leagueRequestValue = _leagueRequestValue(meta, leagueFilter);
    final baseTeams = widget.value.valueOrNull ?? const [];
    final hasLeagueInBase = baseTeams.any(
      (team) => team.leagueName == leagueFilter,
    );
    final activeProvider = leagueFilter == 'all' || hasLeagueInBase
        ? null
        : esportsTeamsByLeagueProvider(leagueRequestValue);
    final activeValue = activeProvider == null
        ? widget.value
        : ref.watch(activeProvider);
    return AppAsyncView<List<EsportsTeamSummary>>(
      value: activeValue,
      retry: () => activeProvider == null
          ? ref.invalidate(esportsTeamsProvider)
          : ref.invalidate(activeProvider),
      data: (teams) {
        if (teams.isEmpty) {
          return const AppEmptyState(
            icon: Icons.groups_2_outlined,
            title: 'No teams found',
            message: 'Pull to refresh and try again.',
          );
        }
        final leagues = _leagueNames(
          meta,
          teams.map((team) => team.leagueName),
        );
        final selectedLeague = leagues.contains(leagueFilter)
            ? leagueFilter
            : 'all';
        final visibleTeams = teams
            .where(
              (team) =>
                  selectedLeague == 'all' || team.leagueName == selectedLeague,
            )
            .toList();
        final focusedTeam = _findTeam(visibleTeams, widget.focusedTeamId);
        final cards = [
          _FilterCard(
            children: [
              _FilterDropdown(
                width: 220,
                value: selectedLeague,
                fallbackLabel: 'All Leagues',
                options: _textFilterOptions(leagues),
                onChanged: (league) => setState(() {
                  _leagueFilter = league;
                  _leagueSelectionTouched = true;
                }),
              ),
            ],
          ),
          if (focusedTeam != null) _FocusedTeamCard(team: focusedTeam),
          ...visibleTeams.map((team) => _TeamCard(team: team)),
        ];
        return RefreshIndicator(
          onRefresh: () => activeProvider == null
              ? ref.refresh(esportsTeamsProvider.future)
              : ref.refresh(activeProvider.future),
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
  String _leagueFilter = 'all';
  bool _leagueSelectionTouched = false;
  String _teamFilter = 'all';
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(esportsMetaProvider).valueOrNull;
    final leagueFilter = _effectiveLeagueFilter(
      meta,
      selected: _leagueFilter,
      selectionTouched: _leagueSelectionTouched,
    );
    final leagueRequestValue = _leagueRequestValue(meta, leagueFilter);
    final basePlayers = widget.value.valueOrNull ?? const [];
    final hasLeagueInBase = basePlayers.any(
      (player) => player.leagueName == leagueFilter,
    );
    final activeProvider = leagueFilter == 'all' || hasLeagueInBase
        ? null
        : esportsPlayersByLeagueProvider(leagueRequestValue);
    final activeValue = activeProvider == null
        ? widget.value
        : ref.watch(activeProvider);
    return AppAsyncView<List<EsportsPlayerSummary>>(
      value: activeValue,
      retry: () => activeProvider == null
          ? ref.invalidate(esportsPlayersProvider)
          : ref.invalidate(activeProvider),
      data: (players) {
        if (players.isEmpty) {
          return const AppEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No players found',
            message: 'Pull to refresh and try again.',
          );
        }
        final teamOptions = _playerTeamOptions(players);
        final leagueOptions = _leagueNames(
          meta,
          players.map((player) => player.leagueName),
        );
        final roleOptions = _playerRoleOptions(players);
        final selectedTeam = teamOptions.contains(_teamFilter)
            ? _teamFilter
            : 'all';
        final selectedLeague = leagueOptions.contains(leagueFilter)
            ? leagueFilter
            : 'all';
        final selectedRole = roleOptions.contains(_roleFilter)
            ? _roleFilter
            : 'all';
        final filteredPlayers = players.where((player) {
          final matchesTeam =
              selectedTeam == 'all' || player.teamName.trim() == selectedTeam;
          final matchesLeague =
              selectedLeague == 'all' ||
              player.leagueName.trim() == selectedLeague;
          final matchesRole =
              selectedRole == 'all' || player.role.trim() == selectedRole;
          return matchesLeague && matchesTeam && matchesRole;
        }).toList();
        final focusedPlayer = _findPlayer(players, widget.focusedPlayerId);
        final cards = <Widget>[
          _FilterCard(
            children: [
              _FilterDropdown(
                width: 180,
                value: selectedLeague,
                fallbackLabel: 'All Leagues',
                options: _textFilterOptions(leagueOptions),
                onChanged: (value) {
                  setState(() {
                    _leagueFilter = value;
                    _leagueSelectionTouched = true;
                  });
                },
              ),
              _FilterDropdown(
                width: 160,
                value: selectedTeam,
                fallbackLabel: 'All Teams',
                options: _textFilterOptions(teamOptions),
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
                options: _textFilterOptions(roleOptions),
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
          onRefresh: () => activeProvider == null
              ? ref.refresh(esportsPlayersProvider.future)
              : ref.refresh(activeProvider.future),
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
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => children[index],
            ),
          ),
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
  final List<_FilterOption> options;
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
                    value: option.value,
                    child: Text(
                      option.label,
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

class _FilterTextField extends StatelessWidget {
  const _FilterTextField({
    required this.width,
    required this.label,
    required this.value,
    required this.hintText,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String value;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.datetime,
        textInputAction: TextInputAction.done,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppTheme.text,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          isDense: true,
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.gold),
          ),
          labelStyle: const TextStyle(color: AppTheme.muted),
          hintStyle: const TextStyle(color: AppTheme.muted),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _MatchStatusSection extends StatelessWidget {
  const _MatchStatusSection({
    required this.status,
    required this.matches,
    required this.championMatchId,
  });

  final _FilterOption status;
  final List<EsportsMatchSummary> matches;
  final String? championMatchId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: ValueKey('match-status-heading-${status.value}'),
          children: [
            Icon(
              _matchStatusIcon(status.value),
              color: _matchStatusColor(status.value),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              status.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (matches.isEmpty)
          const _InlineEmptyState(message: 'No matches')
        else
          ...matches.expand(
            (match) => [
              _MatchCard(
                match: match,
                isChampion:
                    championMatchId != null && match.id == championMatchId,
              ),
              if (match != matches.last) const SizedBox(height: 10),
            ],
          ),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              color: AppTheme.muted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.isChampion});

  final EsportsMatchSummary match;
  final bool isChampion;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      onTap: () => _showMatchDetailSheet(context, match, isChampion),
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
                    if (_matchMetaText(match).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _matchMetaText(match),
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
                  highlightColor: match.winnerSide == 'a'
                      ? Colors.greenAccent
                      : null,
                  showChampionIcon: isChampion && match.winnerSide == 'a',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _MatchScoreText(match: match),
              ),
              Expanded(
                child: _TeamIdentity(
                  name: match.teamBName,
                  logoUrl: match.teamBLogoUrl,
                  alignEnd: true,
                  highlightColor: match.winnerSide == 'b'
                      ? Colors.greenAccent
                      : null,
                  showChampionIcon: isChampion && match.winnerSide == 'b',
                ),
              ),
            ],
          ),
          if (match.startTime.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _formatMatchShortTime(match.startTime),
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

void _showMatchDetailSheet(
  BuildContext context,
  EsportsMatchSummary match,
  bool isChampion,
) {
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
                          highlightColor: match.winnerSide == 'a'
                              ? Colors.greenAccent
                              : null,
                          showChampionIcon:
                              isChampion && match.winnerSide == 'a',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _MatchScoreText(match: match),
                      ),
                      Expanded(
                        child: _TeamIdentity(
                          name: match.teamBName,
                          logoUrl: match.teamBLogoUrl,
                          alignEnd: true,
                          highlightColor: match.winnerSide == 'b'
                              ? Colors.greenAccent
                              : null,
                          showChampionIcon:
                              isChampion && match.winnerSide == 'b',
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
  const _StatsIntroCard({
    required this.rankTypes,
    required this.selectedRank,
    required this.onRankChanged,
  });

  final List<EsportsRankType> rankTypes;
  final int selectedRank;
  final ValueChanged<int> onRankChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < rankTypes.length; index++) ...[
            _UnderlineSelectButton(
              label: rankTypes[index].label,
              selected: rankTypes[index].value == selectedRank,
              onTap: () => onRankChanged(rankTypes[index].value),
            ),
            if (index != rankTypes.length - 1) const SizedBox(width: 22),
          ],
        ],
      ),
    );
  }
}

class _UnderlineSelectButton extends StatelessWidget {
  const _UnderlineSelectButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppTheme.text : AppTheme.muted,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EsportsStatsTable extends StatelessWidget {
  const _EsportsStatsTable({required this.stats, required this.rankType});

  final List<EsportsStatSummary> stats;
  final int rankType;

  @override
  Widget build(BuildContext context) {
    final metricLabels = <String>[];
    for (final stat in stats) {
      for (final metric in stat.metrics) {
        if (!metricLabels.contains(metric.label)) {
          metricLabels.add(metric.label);
        }
      }
    }
    final columns = metricLabels.toList(growable: false);
    final tableWidth = 206.0 + columns.length * 106;
    final leagueName = stats
        .map((stat) => stat.leagueName)
        .firstWhere((name) => name.isNotEmpty, orElse: () => '');

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart_outlined, color: AppTheme.gold),
              const SizedBox(width: 8),
              Text(
                'Rankings',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.length} entries',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (leagueName.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              leagueName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _StatsTableHeader(columns: columns, rankType: rankType),
                  for (final stat in stats)
                    _StatsTableRow(
                      stat: stat,
                      columns: columns,
                      rankType: rankType,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoadingTable extends StatelessWidget {
  const _StatsLoadingTable();

  @override
  Widget build(BuildContext context) {
    final placeholder = AppTheme.muted.withValues(alpha: 0.18);
    return _PanelCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 96, height: 18, color: placeholder),
              const Spacer(),
              Container(width: 62, height: 12, color: placeholder),
            ],
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < 5; index++) ...[
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: placeholder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 13, color: placeholder)),
                const SizedBox(width: 28),
                Container(width: 72, height: 13, color: placeholder),
              ],
            ),
            if (index != 4) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatsTableHeader extends StatelessWidget {
  const _StatsTableHeader({required this.columns, required this.rankType});

  final List<String> columns;
  final int rankType;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppTheme.muted,
      fontWeight: FontWeight.w900,
    );
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Center(child: Text('#', style: labelStyle)),
          ),
          SizedBox(
            width: 168,
            child: Text(_statsObjectLabel(rankType), style: labelStyle),
          ),
          for (final column in columns)
            SizedBox(width: 106, child: Text(column, style: labelStyle)),
        ],
      ),
    );
  }
}

class _StatsTableRow extends StatelessWidget {
  const _StatsTableRow({
    required this.stat,
    required this.columns,
    required this.rankType,
  });

  final EsportsStatSummary stat;
  final List<String> columns;
  final int rankType;

  @override
  Widget build(BuildContext context) {
    final metrics = {
      for (final metric in stat.metrics) metric.label: metric.value,
    };
    return Container(
      height: 68,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Center(
              child: Text(
                '${stat.rank}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 168,
            child: _StatsIdentityCell(stat: stat, rankType: rankType),
          ),
          for (final column in columns)
            SizedBox(
              width: 106,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  metrics[column] ?? '--',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsIdentityCell extends StatelessWidget {
  const _StatsIdentityCell({required this.stat, required this.rankType});

  final EsportsStatSummary stat;
  final int rankType;

  @override
  Widget build(BuildContext context) {
    final isTeam = rankType == 1;
    final isPlayer = rankType == 2 || rankType == 3;
    final route = isTeam && stat.teamId.isNotEmpty
        ? '/esports/teams/${stat.teamId}'
        : isPlayer && stat.playerId.isNotEmpty
        ? '/esports/players/${stat.playerId}'
        : null;
    final imageUrl = switch (rankType) {
      1 => stat.teamLogoUrl,
      2 => stat.playerAvatarUrl,
      3 || 4 => stat.heroIconUrl,
      _ => stat.imageUrl,
    };
    final title = switch (rankType) {
      1 => stat.teamName.isEmpty ? stat.objectName : stat.teamName,
      2 || 3 => stat.playerName.isEmpty ? stat.objectName : stat.playerName,
      4 => stat.heroName.isEmpty ? stat.objectName : stat.heroName,
      _ => stat.objectName,
    };
    final subtitle = rankType == 3
        ? stat.heroName
        : rankType == 2
        ? stat.subtitle.replaceFirst(stat.teamName, '').replaceAll(' · ', '')
        : '';
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: route == null ? null : () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          children: [
            AppImage(
              url: imageUrl,
              width: 38,
              height: 38,
              borderRadius: 10,
              semanticLabel: title,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statsObjectLabel(int rankType) => switch (rankType) {
  1 => 'Team',
  2 => 'Player',
  3 => 'Player Hero',
  4 => 'Hero',
  _ => 'Entry',
};

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
              _EsportsAvatarLink(
                route: '/esports/teams/${team.id}',
                label: 'Open ${team.displayName}',
                child: AppImage(
                  url: team.logoUrl,
                  width: 62,
                  height: 62,
                  borderRadius: 16,
                  semanticLabel: team.name,
                ),
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
              _EsportsAvatarLink(
                route: '/esports/players/${player.id}',
                label: 'Open ${player.name}',
                child: AppImage(
                  url: player.avatarUrl,
                  width: 62,
                  height: 62,
                  borderRadius: 16,
                  semanticLabel: player.name,
                ),
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
              _EsportsAvatarLink(
                route: '/esports/teams/${team.id}',
                label: 'Open ${team.displayName}',
                child: AppImage(
                  url: team.logoUrl,
                  width: 58,
                  height: 58,
                  borderRadius: 14,
                  semanticLabel: team.name,
                ),
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
              _EsportsAvatarLink(
                route: '/esports/players/${player.id}',
                label: 'Open ${player.name}',
                child: AppImage(
                  url: player.avatarUrl,
                  width: 58,
                  height: 58,
                  borderRadius: 14,
                  semanticLabel: player.name,
                ),
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

class _EsportsAvatarLink extends StatelessWidget {
  const _EsportsAvatarLink({
    required this.route,
    required this.label,
    required this.child,
  });

  final String route;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(route),
        child: child,
      ),
    );
  }
}

class _TeamIdentity extends StatelessWidget {
  const _TeamIdentity({
    required this.name,
    required this.logoUrl,
    this.alignEnd = false,
    this.highlightColor,
    this.showChampionIcon = false,
  });

  final String name;
  final String logoUrl;
  final bool alignEnd;
  final Color? highlightColor;
  final bool showChampionIcon;

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
            color: highlightColor ?? AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (showChampionIcon) ...[
        const SizedBox(width: 4),
        const Icon(
          Icons.emoji_events,
          color: AppTheme.gold,
          size: 16,
          semanticLabel: 'Champion winner',
        ),
      ],
    ];

    return Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: alignEnd ? children.reversed.toList() : children,
    );
  }
}

class _MatchScoreText extends StatelessWidget {
  const _MatchScoreText({required this.match});

  final EsportsMatchSummary match;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: AppTheme.gold,
      fontWeight: FontWeight.w900,
    );

    if (match.scoreA == null || match.scoreB == null) {
      return Text(match.scoreText, style: baseStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${match.scoreA}',
          style: baseStyle?.copyWith(
            color: match.winnerSide == 'a' ? Colors.greenAccent : AppTheme.gold,
          ),
        ),
        Text(' : ', style: baseStyle),
        Text(
          '${match.scoreB}',
          style: baseStyle?.copyWith(
            color: match.winnerSide == 'b' ? Colors.greenAccent : AppTheme.gold,
          ),
        ),
      ],
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

List<String> _leagueNames(EsportsMeta? meta, Iterable<String> fallback) {
  final names = <String>{
    ...?meta?.leagues.map((league) => league.name.trim()),
    ...fallback.map((name) => name.trim()),
  }..removeWhere((name) => name.isEmpty);
  return names.toList()..sort();
}

String _effectiveLeagueFilter(
  EsportsMeta? meta, {
  required String selected,
  required bool selectionTouched,
}) {
  if (selectionTouched) {
    return selected;
  }
  final leagues = [...?meta?.leagues]
    ..sort((a, b) {
      final aTime = DateTime.tryParse(a.startTime)?.millisecondsSinceEpoch ?? 0;
      final bTime = DateTime.tryParse(b.startTime)?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
  for (final league in leagues) {
    if (league.name.trim().isNotEmpty) {
      return league.name.trim();
    }
  }
  return selected;
}

String _leagueRequestValue(EsportsMeta? meta, String leagueName) {
  for (final league in meta?.leagues ?? const <EsportsLeague>[]) {
    if (league.name.trim() == leagueName.trim()) {
      if (league.sourceId.trim().isNotEmpty) {
        return league.sourceId.trim();
      }
      if (league.id.trim().isNotEmpty) {
        return league.id.trim();
      }
    }
  }
  return leagueName;
}

List<_FilterOption> _matchStatusOptions(List<EsportsMatchSummary> matches) {
  final statusByValue = <String, String>{};
  for (final match in matches) {
    final value = match.statusKey.trim().toLowerCase();
    if (value.isNotEmpty) {
      statusByValue[value] = match.statusLabel;
    }
  }
  const preferredOrder = ['live', 'upcoming', 'finished'];
  final extraValues =
      statusByValue.keys
          .where((value) => !preferredOrder.contains(value))
          .toList()
        ..sort();
  final orderedValues = [
    ...preferredOrder.where(statusByValue.containsKey),
    ...extraValues,
  ];
  return orderedValues
      .map((value) => _FilterOption(value: value, label: statusByValue[value]!))
      .toList();
}

Map<String, List<EsportsMatchSummary>> _groupMatchesByStatus(
  List<EsportsMatchSummary> matches,
) {
  final grouped = <String, List<EsportsMatchSummary>>{};
  for (final match in matches) {
    final status = match.statusKey.trim().toLowerCase();
    grouped.putIfAbsent(status, () => []).add(match);
  }
  return grouped;
}

String? _championMatchId(List<EsportsMatchSummary> matches) {
  final finished = matches
      .where((match) => match.statusKey.trim().toLowerCase() == 'finished')
      .toList();
  if (finished.isEmpty) {
    return null;
  }
  finished.sort((a, b) {
    final timeA = DateTime.tryParse(a.startTime.trim());
    final timeB = DateTime.tryParse(b.startTime.trim());
    return (timeB?.millisecondsSinceEpoch ?? 0).compareTo(
      timeA?.millisecondsSinceEpoch ?? 0,
    );
  });
  return finished.first.id;
}

IconData _matchStatusIcon(String status) {
  return switch (status) {
    'live' => Icons.wifi_tethering,
    'upcoming' => Icons.schedule,
    'finished' => Icons.emoji_events_outlined,
    _ => Icons.sports_esports_outlined,
  };
}

Color _matchStatusColor(String status) {
  return switch (status) {
    'live' => Colors.redAccent,
    'upcoming' => AppTheme.cyan,
    'finished' => Colors.greenAccent,
    _ => AppTheme.gold,
  };
}

String _matchDateValue(String startTime) {
  final trimmed = startTime.trim();
  if (trimmed.length >= 10) {
    return trimmed.substring(0, 10);
  }
  return trimmed;
}

String _formatMatchShortTime(String value) {
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) {
    return value.trim();
  }
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.month}/${parsed.day} $hour:$minute';
}

String _matchMetaText(EsportsMatchSummary match) {
  return [
    match.stageName.trim(),
    match.boText,
  ].where((value) => value.isNotEmpty).join(' · ');
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

List<_FilterOption> _textFilterOptions(List<String> values) {
  return values
      .map((value) => _FilterOption(value: value, label: value))
      .toList();
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
