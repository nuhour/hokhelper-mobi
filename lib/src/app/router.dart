import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/activity/presentation/event_assistance_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/oauth_callback_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/bp/presentation/bp_dashboard_screen.dart';
import '../features/bp/presentation/bp_scheme_detail_screen.dart';
import '../features/builds/presentation/build_explorer_screen.dart';
import '../features/builds/presentation/build_simulator_screen.dart';
import '../features/community/presentation/community_post_detail_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/content/presentation/cg_gallery_screen.dart';
import '../features/content/presentation/content_screen.dart';
import '../features/content/presentation/patch_notes_screen.dart';
import '../features/content/presentation/skin_gallery_screen.dart';
import '../features/curiosity/presentation/curiosity_lab_screen.dart';
import '../features/esports/presentation/esports_screen.dart';
import '../features/game_assistant/presentation/game_assistant_screen.dart';
import '../features/heroes/presentation/hero_detail_screen.dart';
import '../features/heroes/presentation/hero_gallery_screen.dart';
import '../features/heroes/presentation/hero_relationships_screen.dart';
import '../features/heroes/presentation/world_map_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/info/presentation/external_link_screen.dart';
import '../features/info/presentation/info_center_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/prompts/presentation/prompts_screen.dart';
import '../features/rank_fortune/presentation/rank_fortune_screen.dart';
import '../features/rankings/presentation/hero_ranking_screen.dart';
import '../features/rankings/presentation/player_leaderboard_screen.dart';
import '../features/profile/presentation/me_screen.dart';
import '../features/profile/presentation/public_profile_screen.dart';
import '../features/rankings/presentation/tools_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/stats/presentation/hero_trends_screen.dart';
import '../features/teambuild/presentation/team_builder_screen.dart';
import '../features/tierlist_tool/presentation/tierlist_scheme_detail_screen.dart';
import '../features/tierlist_tool/presentation/tierlist_tool_screen.dart';
import '../features/topics/presentation/topic_article_screen.dart';
import '../features/topics/presentation/topic_hub_screen.dart';
import 'app_shell.dart';
import 'standalone_page_shell.dart';

Widget _standalonePage({
  required String fallbackRoute,
  required Widget child,
  String? title,
  bool alwaysUseFallback = false,
}) {
  return StandalonePageShell(
    fallbackRoute: fallbackRoute,
    title: title,
    alwaysUseFallback: alwaysUseFallback,
    child: child,
  );
}

String _communityLeaksTarget(Uri uri) {
  final queryParameters = <String, String>{'tab': 'leaks'};
  for (final key in const ['q', 'category', 'platform']) {
    final value = uri.queryParameters[key]?.trim();
    if (value != null && value.isNotEmpty) {
      queryParameters[key] = value;
    }
  }
  return Uri(
    path: '/content/community',
    queryParameters: queryParameters,
  ).toString();
}

String _communityTarget(Uri uri) {
  final postQueryParameters = Map<String, String>.from(uri.queryParameters);
  final postId = postQueryParameters.remove('post_id')?.trim();
  if (postId != null && postId.isNotEmpty) {
    return Uri(
      path: '/content/community/post/$postId',
      queryParameters: postQueryParameters.isEmpty ? null : postQueryParameters,
    ).toString();
  }

  final queryParameters = <String, String>{};
  final view = uri.queryParameters['view'];
  if (view == 'my' || view == 'likes') {
    queryParameters['tab'] = view!;
  }
  final tag = uri.queryParameters['tag']?.trim();
  if (tag != null && tag.isNotEmpty) {
    queryParameters['tag'] = tag;
  }
  if (queryParameters.isEmpty) {
    return '/content/community';
  }
  return Uri(
    path: '/content/community',
    queryParameters: queryParameters,
  ).toString();
}

String _heroGalleryTarget(Uri uri) {
  final heroId = int.tryParse(uri.queryParameters['hero_id'] ?? '');
  if (heroId != null && heroId > 0) {
    final queryParameters = Map<String, String>.from(uri.queryParameters)
      ..remove('hero_id');
    return Uri(
      path: '/heroes/$heroId',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }
  final query = uri.queryParameters['q']?.trim();
  if (query == null || query.isEmpty) {
    return '/heroes';
  }
  return Uri(path: '/heroes', queryParameters: {'q': query}).toString();
}

String _profileTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final userId = queryParameters.remove('user_id')?.trim();
  if (userId == null || userId.isEmpty) {
    return '/me';
  }
  return Uri(
    path: '/profile/$userId',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

String? _cgGalleryRedirect(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final cgId = queryParameters.remove('cg_id')?.trim();
  if (cgId == null || cgId.isEmpty) {
    return null;
  }
  return Uri(
    path: '/cg/$cgId',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

String _targetWithQuery(String path, Uri uri) {
  final query = uri.query;
  return query.isEmpty ? path : '$path?$query';
}

List<int> _teamBuilderHeroIds(Uri uri, String pluralKey, String singleKey) {
  final values = [
    ...(uri.queryParametersAll[pluralKey] ?? const <String>[]),
    ...(uri.queryParametersAll[singleKey] ?? const <String>[]),
  ];
  return values
      .expand((value) => value.split(','))
      .map((value) => int.tryParse(value.trim()))
      .whereType<int>()
      .where((value) => value > 0)
      .take(5)
      .toList(growable: false);
}

TeamBuilderSide? _teamBuilderSide(Uri uri) {
  return switch (uri.queryParameters['side']?.trim()) {
    'enemy' || 'red' => TeamBuilderSide.enemy,
    'ally' || 'blue' => TeamBuilderSide.ally,
    _ => null,
  };
}

TeamBuilderSlotType? _teamBuilderSlotType(Uri uri) {
  return switch (uri.queryParameters['slot_type']?.trim() ??
      uri.queryParameters['type']?.trim()) {
    'ban' || 'bans' => TeamBuilderSlotType.ban,
    'pick' || 'picks' => TeamBuilderSlotType.pick,
    _ => null,
  };
}

int? _teamBuilderSlotIndex(Uri uri) {
  final rawValue =
      uri.queryParameters['slot'] ?? uri.queryParameters['slot_index'];
  if (rawValue == null) {
    return null;
  }
  final value = int.tryParse(rawValue) ?? 0;
  return value > 0 ? value - 1 : 0;
}

String _promptsTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final legacyPromptId = queryParameters.remove('prompt_id')?.trim();
  if (legacyPromptId != null &&
      legacyPromptId.isNotEmpty &&
      (queryParameters['promptId']?.trim().isEmpty ?? true)) {
    queryParameters['promptId'] = legacyPromptId;
  }
  return Uri(
    path: '/tools/prompts',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

String _buildSimTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final legacySchemeId = queryParameters.remove('scheme_id')?.trim();
  if (legacySchemeId != null &&
      legacySchemeId.isNotEmpty &&
      (queryParameters['scheme']?.trim().isEmpty ?? true)) {
    queryParameters['scheme'] = legacySchemeId;
  }
  return Uri(
    path: '/tools/build-sim',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

String _bpSimulatorTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final schemeIdFromQuery = queryParameters.remove('scheme_id')?.trim();
  final schemeIdFromPath =
      uri.pathSegments.length == 3 &&
          uri.pathSegments[0] == 'tools' &&
          uri.pathSegments[1] == 'bp-simulator'
      ? uri.pathSegments[2].trim()
      : null;
  final schemeId = schemeIdFromPath != null && schemeIdFromPath.isNotEmpty
      ? schemeIdFromPath
      : schemeIdFromQuery;
  final legacyGameIndex = queryParameters.remove('game_index')?.trim();
  if (legacyGameIndex != null &&
      legacyGameIndex.isNotEmpty &&
      (queryParameters['gameIndex']?.trim().isEmpty ?? true)) {
    queryParameters['gameIndex'] = legacyGameIndex;
  }
  return Uri(
    path: schemeId == null || schemeId.isEmpty
        ? '/tools/bp-simulator'
        : '/tools/bp-simulator/$schemeId',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

String _tierListToolTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final schemeId =
      queryParameters.remove('id')?.trim() ??
      queryParameters.remove('scheme_id')?.trim();
  return Uri(
    path: schemeId == null || schemeId.isEmpty
        ? '/tools/tier-list'
        : '/tools/tier-list/$schemeId',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

String? _esportsTarget(Uri uri, String routeBase) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final teamId = queryParameters.remove('team_id')?.trim();
  final playerId = queryParameters.remove('player_id')?.trim();
  final focusedPath = teamId != null && teamId.isNotEmpty
      ? '$routeBase/teams/$teamId'
      : playerId != null && playerId.isNotEmpty
      ? '$routeBase/players/$playerId'
      : null;
  if (focusedPath == null) {
    return null;
  }
  return Uri(
    path: focusedPath,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

int? _initialLanePosition(Uri uri) {
  return int.tryParse(
    uri.queryParameters['position'] ??
        uri.queryParameters['hero_position'] ??
        '',
  );
}

bool _aboutCommunityFocused(Uri uri) {
  return uri.queryParameters['section'] == 'community' ||
      uri.fragment.trim().toLowerCase() == 'community';
}

String _localizedTargetWithQuery(Uri uri, List<String> segments) {
  final path = segments.isEmpty ? '/' : '/${segments.join('/')}';
  return _targetWithQuery(path, uri);
}

List<GoRoute> _localizedPathRedirects() {
  return [
    for (final locale in const ['en', 'zh', 'id']) ...[
      GoRoute(
        path: '/$locale',
        redirect: (context, state) =>
            _localizedTargetWithQuery(state.uri, const []),
      ),
      GoRoute(
        path: '/$locale/:s1',
        redirect: (context, state) => _localizedTargetWithQuery(state.uri, [
          state.pathParameters['s1'] ?? '',
        ]),
      ),
      GoRoute(
        path: '/$locale/:s1/:s2',
        redirect: (context, state) => _localizedTargetWithQuery(state.uri, [
          state.pathParameters['s1'] ?? '',
          state.pathParameters['s2'] ?? '',
        ]),
      ),
      GoRoute(
        path: '/$locale/:s1/:s2/:s3',
        redirect: (context, state) => _localizedTargetWithQuery(state.uri, [
          state.pathParameters['s1'] ?? '',
          state.pathParameters['s2'] ?? '',
          state.pathParameters['s3'] ?? '',
        ]),
      ),
      GoRoute(
        path: '/$locale/:s1/:s2/:s3/:s4',
        redirect: (context, state) => _localizedTargetWithQuery(state.uri, [
          state.pathParameters['s1'] ?? '',
          state.pathParameters['s2'] ?? '',
          state.pathParameters['s3'] ?? '',
          state.pathParameters['s4'] ?? '',
        ]),
      ),
    ],
  ];
}

PlayerLeaderboardRankType? _playerLeaderboardRankType(Uri uri) {
  final rankType = uri.queryParameters['rank_type']?.trim().toLowerCase();
  return switch (rankType) {
    'peak' => PlayerLeaderboardRankType.peak,
    'rank' || 'ranked' => PlayerLeaderboardRankType.ranked,
    _ => null,
  };
}

int? _playerLeaderboardRegionId(Uri uri) {
  if (!uri.queryParameters.containsKey('region_id')) {
    return null;
  }
  return int.tryParse(uri.queryParameters['region_id'] ?? '') ?? 0;
}

int _rankFortuneDays(Uri uri) {
  final days = int.tryParse(uri.queryParameters['days'] ?? '') ?? 30;
  return days.clamp(1, 365);
}

int _rankingsTabIndex(Uri uri) {
  return switch (uri.queryParameters['tab']?.trim().toLowerCase()) {
    'players' || 'player' => 1,
    'equips' || 'equip' || 'equipment' => 2,
    'tier' || 'tier-list' || 'tier_list' => 3,
    _ => 0,
  };
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ..._localizedPathRedirects(),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/google/callback',
        builder: (context, state) => OAuthCallbackScreen(
          provider: 'google',
          code: state.uri.queryParameters['code'],
          error: state.uri.queryParameters['error'],
        ),
      ),
      GoRoute(
        path: '/auth/discord/callback',
        builder: (context, state) => OAuthCallbackScreen(
          provider: 'discord',
          code: state.uri.queryParameters['code'],
          error: state.uri.queryParameters['error'],
        ),
      ),
      GoRoute(
        path: '/auth/reddit/callback',
        builder: (context, state) => OAuthCallbackScreen(
          provider: 'reddit',
          code: state.uri.queryParameters['code'],
          error: state.uri.queryParameters['error'],
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/me',
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/settings',
          child: const ProfileAccountSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/',
          child: SearchScreen(initialQuery: state.uri.queryParameters['q']),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/me',
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/external-link',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/',
          child: ExternalLinkScreen(
            url: state.uri.queryParameters['url'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/profile',
        redirect: (context, state) => _profileTarget(state.uri),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          return _standalonePage(
            fallbackRoute: '/me',
            child: PublicProfileScreen(
              userId: int.tryParse(state.pathParameters['userId'] ?? '') ?? 0,
              initialFollowListType: profileFollowListTypeFromRoute(
                state.uri.queryParameters['tab'],
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/community/post/:postId',
        builder: (context, state) {
          return _standalonePage(
            fallbackRoute: '/content/community',
            child: CommunityPostDetailScreen(
              postId: state.pathParameters['postId'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/hero-gallery',
        redirect: (context, state) => _heroGalleryTarget(state.uri),
      ),
      GoRoute(
        path: '/hero-gallery/:heroId',
        redirect: (context, state) => _targetWithQuery(
          '/heroes/${state.pathParameters['heroId'] ?? ''}',
          state.uri,
        ),
      ),
      GoRoute(
        path: '/community',
        redirect: (context, state) => _communityTarget(state.uri),
      ),
      GoRoute(
        path: '/leaks',
        redirect: (context, state) => _communityLeaksTarget(state.uri),
      ),
      GoRoute(
        path: '/skin-leaks',
        redirect: (context, state) => _communityLeaksTarget(state.uri),
      ),
      GoRoute(
        path: '/community/leaks',
        redirect: (context, state) => _communityLeaksTarget(state.uri),
      ),
      GoRoute(
        path: '/event-assistance',
        redirect: (context, state) =>
            _targetWithQuery('/content/event-assistance', state.uri),
      ),
      GoRoute(
        path: '/patch-notes',
        redirect: (context, state) =>
            _targetWithQuery('/content/patch-notes', state.uri),
      ),
      GoRoute(
        path: '/versions',
        redirect: (context, state) =>
            _targetWithQuery('/content/patch-notes', state.uri),
      ),
      GoRoute(
        path: '/stats',
        redirect: (context, state) {
          if (state.uri.queryParameters['entry'] == 'hero_trend') {
            final heroId = state.uri.queryParameters['hero_id']?.trim();
            if (heroId != null && heroId.isNotEmpty) {
              return Uri(
                path: '/trends',
                queryParameters: {'hero_id': heroId},
              ).toString();
            }
            return '/trends';
          }
          final query = state.uri.query;
          return query.isEmpty ? '/tools/stats' : '/tools/stats?$query';
        },
      ),
      GoRoute(
        path: '/tier-list',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/tools/stats',
          child: const HeroRankingScreen(initialTabIndex: 3),
        ),
      ),
      GoRoute(
        path: '/builds',
        redirect: (context, state) =>
            _targetWithQuery('/tools/builds', state.uri),
      ),
      GoRoute(
        path: '/build-sim',
        redirect: (context, state) => _buildSimTarget(state.uri),
      ),
      GoRoute(
        path: '/bp-simulator',
        redirect: (context, state) => _bpSimulatorTarget(state.uri),
      ),
      GoRoute(
        path: '/tools/tier-list/:schemeId',
        builder: (context, state) {
          return TierListSchemeDetailScreen(
            schemeId: state.pathParameters['schemeId'] ?? '',
            initialEditMode: true,
          );
        },
      ),
      GoRoute(
        path: '/rankings',
        redirect: (context, state) =>
            _targetWithQuery('/tools/rankings', state.uri),
      ),
      GoRoute(
        path: '/game-assistant',
        redirect: (context, state) =>
            _targetWithQuery('/tools/game-assistant', state.uri),
      ),
      GoRoute(
        path: '/rank-fortune',
        redirect: (context, state) =>
            _targetWithQuery('/tools/rank-fortune', state.uri),
      ),
      GoRoute(
        path: '/curiosity-lab',
        redirect: (context, state) =>
            _targetWithQuery('/tools/curiosity-lab', state.uri),
      ),
      GoRoute(
        path: '/team-builder',
        redirect: (context, state) =>
            _targetWithQuery('/tools/team-builder', state.uri),
      ),
      GoRoute(
        path: '/prompts',
        redirect: (context, state) => _promptsTarget(state.uri),
      ),
      GoRoute(
        path: '/skin-gallery',
        redirect: (context, state) {
          final queryParameters = Map<String, String>.from(
            state.uri.queryParameters,
          );
          final skinId = int.tryParse(queryParameters['skin_id'] ?? '');
          if (skinId != null && skinId > 0) {
            queryParameters.remove('skin_id');
            return Uri(
              path: '/skin-gallery/$skinId',
              queryParameters: queryParameters.isEmpty ? null : queryParameters,
            ).toString();
          }
          return null;
        },
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/?tab=skins',
          child: SkinGalleryScreen(
            initialLanePosition: _initialLanePosition(state.uri),
            initialSearchQuery: state.uri.queryParameters['q'],
            initialMinRating:
                double.tryParse(
                  state.uri.queryParameters['min_rating'] ?? '',
                ) ??
                0,
          ),
        ),
        routes: [
          GoRoute(
            path: ':skinId',
            builder: (context, state) {
              return _standalonePage(
                fallbackRoute: '/?tab=skins',
                child: SkinGalleryScreen(
                  initialSkinId: int.tryParse(
                    state.pathParameters['skinId'] ?? '',
                  ),
                  initialLanePosition: _initialLanePosition(state.uri),
                  initialSearchQuery: state.uri.queryParameters['q'],
                  initialMinRating:
                      double.tryParse(
                        state.uri.queryParameters['min_rating'] ?? '',
                      ) ??
                      0,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/cg',
        redirect: (context, state) => _cgGalleryRedirect(state.uri),
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/?tab=skins',
          child: CgGalleryScreen(
            initialHeroId: int.tryParse(
              state.uri.queryParameters['hero_id'] ?? '',
            ),
            initialSearchQuery: state.uri.queryParameters['q'],
          ),
        ),
        routes: [
          GoRoute(
            path: ':cgId',
            builder: (context, state) {
              return _standalonePage(
                fallbackRoute: '/cg',
                child: CgGalleryScreen(
                  initialCgId: int.tryParse(state.pathParameters['cgId'] ?? ''),
                  initialHeroId: int.tryParse(
                    state.uri.queryParameters['hero_id'] ?? '',
                  ),
                  initialSearchQuery: state.uri.queryParameters['q'],
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/relationships',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/?tab=heroes',
          child: HeroRelationshipsScreen(
            initialHeroId: state.uri.queryParameters['hero_id'],
            initialHeroName:
                state.uri.queryParameters['hero'] ??
                state.uri.queryParameters['hero_name'],
          ),
        ),
      ),
      GoRoute(
        path: '/world-map',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/?tab=heroes',
          child: WorldMapScreen(
            initialHeroId: state.uri.queryParameters['hero_id'],
          ),
        ),
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/tools/stats',
          child: HeroTrendsScreen(
            initialHeroId: int.tryParse(
              state.uri.queryParameters['hero_id'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/tools/stats',
          child: PlayerLeaderboardScreen(
            initialRankType: _playerLeaderboardRankType(state.uri),
            initialRegionId: _playerLeaderboardRegionId(state.uri),
          ),
        ),
      ),
      GoRoute(
        path: '/esports',
        redirect: (context, state) => _esportsTarget(state.uri, '/esports'),
        builder: (context, state) => _standalonePage(
          fallbackRoute: '/tools',
          child: const EsportsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'teams/:teamId',
            builder: (context, state) {
              return _standalonePage(
                fallbackRoute: '/?tab=esports',
                child: EsportsScreen(
                  initialTab: EsportsInitialTab.teams,
                  initialTeamId: state.pathParameters['teamId'],
                ),
              );
            },
          ),
          GoRoute(
            path: 'players/:playerId',
            builder: (context, state) {
              return _standalonePage(
                fallbackRoute: '/?tab=esports',
                child: EsportsScreen(
                  initialTab: EsportsInitialTab.players,
                  initialPlayerId: state.pathParameters['playerId'],
                ),
              );
            },
          ),
          GoRoute(
            path: ':tab',
            builder: (context, state) {
              return _standalonePage(
                fallbackRoute: '/esports',
                child: EsportsScreen(
                  initialTab: esportsInitialTabFromRoute(
                    state.pathParameters['tab'],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => InfoStaticPage(
          section: InfoStaticSection.about,
          highlightCommunity: _aboutCommunityFocused(state.uri),
        ),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) =>
            const InfoStaticPage(section: InfoStaticSection.faq),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) =>
            const InfoStaticPage(section: InfoStaticSection.privacy),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) =>
            const InfoStaticPage(section: InfoStaticSection.terms),
      ),
      GoRoute(
        path: '/links',
        builder: (context, state) =>
            const InfoStaticPage(section: InfoStaticSection.links),
      ),
      GoRoute(
        path: '/honor-of-kings-world-tier-list',
        redirect: (context, state) => '/hok-world/hok-world-tier-list',
      ),
      GoRoute(
        path: '/hok-world-tier-list',
        redirect: (context, state) => '/hok-world/hok-world-tier-list',
      ),
      GoRoute(
        path: '/hok-world',
        builder: (context, state) =>
            const TopicHubScreen(topicKey: 'hok-world'),
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) {
              return TopicArticleScreen(
                topicKey: 'hok-world',
                slug: state.pathParameters['slug'] ?? '',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/topics/:topicKey',
        redirect: (context, state) {
          final topicKey = state.pathParameters['topicKey'] ?? '';
          if (state.uri.pathSegments.length == 2 && topicKey != 'hok-world') {
            return '/hok-world/$topicKey';
          }
          return null;
        },
        builder: (context, state) {
          return TopicHubScreen(
            topicKey: state.pathParameters['topicKey'] ?? '',
          );
        },
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) {
              return TopicArticleScreen(
                topicKey: state.pathParameters['topicKey'] ?? '',
                slug: state.pathParameters['slug'] ?? '',
              );
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => HomeScreen(
                  initialPortalTab: state.uri.queryParameters['tab'],
                  initialHeroId: state.uri.queryParameters['hero_id'],
                  initialSkinId: int.tryParse(
                    state.uri.queryParameters['skin_id'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats-home',
                builder: (context, state) => StatsScreen(
                  showPortalTabs: state.uri.queryParameters.isEmpty,
                  initialEntry: StatsEntry.fromRoute(
                    state.uri.queryParameters['entry'],
                    dimension: state.uri.queryParameters['dimension'],
                  ),
                  initialEquipId: state.uri.queryParameters['equip_id'],
                  initialHeroId: state.uri.queryParameters['hero_id'],
                ),
              ),
              GoRoute(
                path: '/heroes',
                builder: (context, state) => HeroGalleryScreen(
                  initialSearchQuery: state.uri.queryParameters['q'],
                ),
                routes: [
                  GoRoute(
                    path: ':heroId',
                    builder: (context, state) {
                      return _standalonePage(
                        fallbackRoute: '/heroes',
                        child: HeroDetailScreen(
                          heroId: state.pathParameters['heroId'] ?? '',
                          focusHistory:
                              state.uri.queryParameters['tab'] == 'history',
                          initialFocus: heroDetailFocusFromRoute(
                            state.uri.queryParameters['tab'],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/content',
                builder: (context, state) => const ContentScreen(),
                routes: [
                  GoRoute(
                    path: 'community',
                    builder: (context, state) {
                      final tab = state.uri.queryParameters['tab'];
                      final initialTabIndex = switch (tab) {
                        'leaks' => 0,
                        'event' || 'events' || 'assistance' => 2,
                        _ => 1,
                      };
                      final initialView = switch (tab) {
                        'my' => CommunityInitialView.myPosts,
                        'likes' => CommunityInitialView.likedPosts,
                        _ => CommunityInitialView.hot,
                      };
                      return CommunityScreen(
                        initialTabIndex: initialTabIndex,
                        initialView: initialView,
                        initialLeakQuery: state.uri.queryParameters['q'],
                        initialLeakCategory:
                            state.uri.queryParameters['category'],
                        initialLeakPlatform:
                            state.uri.queryParameters['platform'],
                        initialPostTag: state.uri.queryParameters['tag'],
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'post/:postId',
                        builder: (context, state) {
                          return _standalonePage(
                            fallbackRoute: '/content/community',
                            child: CommunityPostDetailScreen(
                              postId: state.pathParameters['postId'] ?? '',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'event-assistance',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/content/community?tab=event',
                      child: EventAssistanceScreen(
                        initialShareText: state.uri.queryParameters['text'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'skins',
                    redirect: (context, state) => Uri(
                      path: '/',
                      queryParameters: {
                        'tab': 'skins',
                        ...state.uri.queryParameters,
                      },
                    ).toString(),
                  ),
                  GoRoute(
                    path: 'cgs',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/content',
                      child: CgGalleryScreen(
                        initialSearchQuery: state.uri.queryParameters['q'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'patch-notes',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/',
                      alwaysUseFallback: true,
                      child: PatchNotesScreen(
                        initialNoteId: int.tryParse(
                          state.uri.queryParameters['note_id'] ??
                              state.uri.queryParameters['post_id'] ??
                              '',
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'info',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/content',
                      child: const InfoCenterScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tools',
                builder: (context, state) => const ToolsScreen(),
                routes: [
                  GoRoute(
                    path: 'builds',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: BuildExplorerScreen(
                        initialHeroId: int.tryParse(
                          state.uri.queryParameters['hero_id'] ?? '',
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'build-sim',
                    redirect: (context, state) {
                      if (state.uri.queryParameters.containsKey('scheme_id')) {
                        return _buildSimTarget(state.uri);
                      }
                      return null;
                    },
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: BuildSimulatorScreen(
                        initialHeroId: int.tryParse(
                          state.uri.queryParameters['hero_id'] ?? '',
                        ),
                        initialSchemeId: int.tryParse(
                          state.uri.queryParameters['scheme'] ?? '',
                        ),
                        initialCommunityFilter:
                            state.uri.queryParameters['filter'] == 'favorites'
                            ? BuildSimCommunityFilter.favorites
                            : BuildSimCommunityFilter.explore,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'bp-simulator',
                    redirect: (context, state) {
                      if (state.uri.queryParameters.containsKey('scheme_id') ||
                          state.uri.queryParameters.containsKey('game_index')) {
                        return _bpSimulatorTarget(state.uri);
                      }
                      return null;
                    },
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: const BpDashboardScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: ':schemeId',
                        redirect: (context, state) {
                          if (state.uri.queryParameters.containsKey(
                            'game_index',
                          )) {
                            return _bpSimulatorTarget(state.uri);
                          }
                          return null;
                        },
                        builder: (context, state) {
                          return _standalonePage(
                            fallbackRoute: '/tools/bp-simulator',
                            child: BpSchemeDetailScreen(
                              schemeId: state.pathParameters['schemeId'] ?? '',
                              initialGameIndex: int.tryParse(
                                state.uri.queryParameters['gameIndex'] ?? '',
                              ),
                              enableLandscapeEditor: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'tier-list',
                    redirect: (context, state) {
                      if (state.uri.queryParameters.containsKey('id') ||
                          state.uri.queryParameters.containsKey('scheme_id')) {
                        return _tierListToolTarget(state.uri);
                      }
                      return null;
                    },
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: const TierListToolScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: ':schemeId',
                        redirect: (context, state) =>
                            '/tools/tier-list/${state.pathParameters['schemeId'] ?? ''}',
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'game-assistant',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: GameAssistantScreen(
                        initialTrack: state.uri.queryParameters['track'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'rank-fortune',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: RankFortuneScreen(
                        initialDays: _rankFortuneDays(state.uri),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'curiosity-lab',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: CuriosityLabScreen(
                        initialQuestion: state.uri.queryParameters['q'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'rankings',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: HeroRankingScreen(
                        initialTabIndex: _rankingsTabIndex(state.uri),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'leaderboard',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: PlayerLeaderboardScreen(
                        initialRankType: _playerLeaderboardRankType(state.uri),
                        initialRegionId: _playerLeaderboardRegionId(state.uri),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'team-builder',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: TeamBuilderScreen(
                        initialAllyHeroIds: _teamBuilderHeroIds(
                          state.uri,
                          'ally_ids',
                          'ally_id',
                        ),
                        initialEnemyHeroIds: _teamBuilderHeroIds(
                          state.uri,
                          'enemy_ids',
                          'enemy_id',
                        ),
                        initialBanHeroIds: _teamBuilderHeroIds(
                          state.uri,
                          'ban_ids',
                          'ban_id',
                        ),
                        initialSlotType: _teamBuilderSlotType(state.uri),
                        initialSide: _teamBuilderSide(state.uri),
                        initialSlotIndex: _teamBuilderSlotIndex(state.uri),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'prompts',
                    redirect: (context, state) {
                      if (state.uri.queryParameters.containsKey('prompt_id')) {
                        return _promptsTarget(state.uri);
                      }
                      return null;
                    },
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: PromptsScreen(
                        initialAction: promptListActionFromRoute(
                          state.uri.queryParameters['tab'],
                        ),
                        initialPromptId: state.uri.queryParameters['promptId'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'esports',
                    redirect: (context, state) =>
                        _esportsTarget(state.uri, '/tools/esports'),
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: const EsportsScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'teams/:teamId',
                        builder: (context, state) {
                          return _standalonePage(
                            fallbackRoute: '/tools/esports',
                            child: EsportsScreen(
                              initialTab: EsportsInitialTab.teams,
                              initialTeamId: state.pathParameters['teamId'],
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'players/:playerId',
                        builder: (context, state) {
                          return _standalonePage(
                            fallbackRoute: '/tools/esports',
                            child: EsportsScreen(
                              initialTab: EsportsInitialTab.players,
                              initialPlayerId: state.pathParameters['playerId'],
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: ':tab',
                        builder: (context, state) {
                          return _standalonePage(
                            fallbackRoute: '/tools/esports',
                            child: EsportsScreen(
                              initialTab: esportsInitialTabFromRoute(
                                state.pathParameters['tab'],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'stats',
                    builder: (context, state) => _standalonePage(
                      fallbackRoute: '/tools',
                      child: StatsScreen(
                        showPortalTabs: state.uri.queryParameters.isEmpty,
                        initialEntry: StatsEntry.fromRoute(
                          state.uri.queryParameters['entry'],
                          dimension: state.uri.queryParameters['dimension'],
                        ),
                        initialEquipId: state.uri.queryParameters['equip_id'],
                        initialHeroId: state.uri.queryParameters['hero_id'],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => MeScreen(
                  initialFollowListTab: state.uri.queryParameters['tab'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/:topicKey',
        builder: (context, state) {
          return TopicHubScreen(
            topicKey: state.pathParameters['topicKey'] ?? '',
          );
        },
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) {
              return TopicArticleScreen(
                topicKey: state.pathParameters['topicKey'] ?? '',
                slug: state.pathParameters['slug'] ?? '',
              );
            },
          ),
        ],
      ),
    ],
  );
}
