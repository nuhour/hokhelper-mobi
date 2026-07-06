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

String _communityLeaksTarget(Uri uri) {
  final query = uri.queryParameters['q']?.trim();
  if (query == null || query.isEmpty) {
    return '/content/community?tab=leaks';
  }
  return Uri(
    path: '/content/community',
    queryParameters: {'tab': 'leaks', 'q': query},
  ).toString();
}

String _communityTarget(Uri uri) {
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
    return '/heroes/$heroId';
  }
  final query = uri.queryParameters['q']?.trim();
  if (query == null || query.isEmpty) {
    return '/heroes';
  }
  return Uri(path: '/heroes', queryParameters: {'q': query}).toString();
}

String _targetWithQuery(String path, Uri uri) {
  final query = uri.query;
  return query.isEmpty ? path : '$path?$query';
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
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/external-link',
        builder: (context, state) =>
            ExternalLinkScreen(url: state.uri.queryParameters['url'] ?? ''),
      ),
      GoRoute(path: '/profile', redirect: (context, state) => '/me'),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          return PublicProfileScreen(
            userId: int.tryParse(state.pathParameters['userId'] ?? '') ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/community/post/:postId',
        builder: (context, state) {
          return CommunityPostDetailScreen(
            postId: state.pathParameters['postId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/hero-gallery',
        redirect: (context, state) => _heroGalleryTarget(state.uri),
      ),
      GoRoute(
        path: '/hero-gallery/:heroId',
        redirect: (context, state) =>
            '/heroes/${state.pathParameters['heroId'] ?? ''}',
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
        redirect: (context, state) => '/content/event-assistance',
      ),
      GoRoute(
        path: '/patch-notes',
        redirect: (context, state) => '/content/patch-notes',
      ),
      GoRoute(
        path: '/versions',
        redirect: (context, state) => '/content/patch-notes',
      ),
      GoRoute(
        path: '/stats',
        redirect: (context, state) {
          if (state.uri.queryParameters['entry'] == 'hero_trend') {
            return '/trends';
          }
          final query = state.uri.query;
          return query.isEmpty ? '/tools/stats' : '/tools/stats?$query';
        },
      ),
      GoRoute(
        path: '/tier-list',
        builder: (context, state) =>
            const HeroRankingScreen(initialTabIndex: 3),
      ),
      GoRoute(
        path: '/builds',
        redirect: (context, state) =>
            _targetWithQuery('/tools/builds', state.uri),
      ),
      GoRoute(
        path: '/build-sim',
        redirect: (context, state) =>
            _targetWithQuery('/tools/build-sim', state.uri),
      ),
      GoRoute(
        path: '/bp-simulator',
        redirect: (context, state) =>
            _targetWithQuery('/tools/bp-simulator', state.uri),
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
        redirect: (context, state) =>
            _targetWithQuery('/tools/prompts', state.uri),
      ),
      GoRoute(
        path: '/skin-gallery',
        redirect: (context, state) {
          final skinId = int.tryParse(
            state.uri.queryParameters['skin_id'] ?? '',
          );
          if (skinId != null && skinId > 0) {
            return '/skin-gallery/$skinId';
          }
          return null;
        },
        builder: (context, state) => SkinGalleryScreen(
          initialSearchQuery: state.uri.queryParameters['q'],
        ),
        routes: [
          GoRoute(
            path: ':skinId',
            builder: (context, state) {
              return SkinGalleryScreen(
                initialSkinId: int.tryParse(
                  state.pathParameters['skinId'] ?? '',
                ),
                initialSearchQuery: state.uri.queryParameters['q'],
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/cg',
        builder: (context, state) =>
            CgGalleryScreen(initialSearchQuery: state.uri.queryParameters['q']),
        routes: [
          GoRoute(
            path: ':cgId',
            builder: (context, state) {
              return CgGalleryScreen(
                initialCgId: int.tryParse(state.pathParameters['cgId'] ?? ''),
                initialSearchQuery: state.uri.queryParameters['q'],
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/relationships',
        builder: (context, state) => const HeroRelationshipsScreen(),
      ),
      GoRoute(
        path: '/world-map',
        builder: (context, state) => const WorldMapScreen(),
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => HeroTrendsScreen(
          initialHeroId: int.tryParse(
            state.uri.queryParameters['hero_id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => PlayerLeaderboardScreen(
          initialRankType: _playerLeaderboardRankType(state.uri),
          initialRegionId: _playerLeaderboardRegionId(state.uri),
        ),
      ),
      GoRoute(
        path: '/esports',
        redirect: (context, state) {
          final teamId = state.uri.queryParameters['team_id']?.trim() ?? '';
          if (teamId.isNotEmpty) {
            return '/esports/teams/$teamId';
          }
          final playerId = state.uri.queryParameters['player_id']?.trim() ?? '';
          if (playerId.isNotEmpty) {
            return '/esports/players/$playerId';
          }
          return null;
        },
        builder: (context, state) => const EsportsScreen(),
        routes: [
          GoRoute(
            path: 'teams/:teamId',
            builder: (context, state) {
              return EsportsScreen(
                initialTab: EsportsInitialTab.teams,
                initialTeamId: state.pathParameters['teamId'],
              );
            },
          ),
          GoRoute(
            path: 'players/:playerId',
            builder: (context, state) {
              return EsportsScreen(
                initialTab: EsportsInitialTab.players,
                initialPlayerId: state.pathParameters['playerId'],
              );
            },
          ),
          GoRoute(
            path: ':tab',
            builder: (context, state) {
              return EsportsScreen(
                initialTab: esportsInitialTabFromRoute(
                  state.pathParameters['tab'],
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
          highlightCommunity:
              state.uri.queryParameters['section'] == 'community',
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/heroes',
                builder: (context, state) => HeroGalleryScreen(
                  initialSearchQuery: state.uri.queryParameters['q'],
                ),
                routes: [
                  GoRoute(
                    path: ':heroId',
                    builder: (context, state) {
                      return HeroDetailScreen(
                        heroId: state.pathParameters['heroId'] ?? '',
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
                      final initialTabIndex = tab == 'leaks' ? 1 : 0;
                      final initialView = switch (tab) {
                        'my' => CommunityInitialView.myPosts,
                        'likes' => CommunityInitialView.likedPosts,
                        _ => CommunityInitialView.hot,
                      };
                      return CommunityScreen(
                        initialTabIndex: initialTabIndex,
                        initialView: initialView,
                        initialLeakQuery: state.uri.queryParameters['q'],
                        initialPostTag: state.uri.queryParameters['tag'],
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'post/:postId',
                        builder: (context, state) {
                          return CommunityPostDetailScreen(
                            postId: state.pathParameters['postId'] ?? '',
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'event-assistance',
                    builder: (context, state) => const EventAssistanceScreen(),
                  ),
                  GoRoute(
                    path: 'skins',
                    builder: (context, state) => SkinGalleryScreen(
                      initialSearchQuery: state.uri.queryParameters['q'],
                    ),
                  ),
                  GoRoute(
                    path: 'cgs',
                    builder: (context, state) => CgGalleryScreen(
                      initialSearchQuery: state.uri.queryParameters['q'],
                    ),
                  ),
                  GoRoute(
                    path: 'patch-notes',
                    builder: (context, state) => const PatchNotesScreen(),
                  ),
                  GoRoute(
                    path: 'info',
                    builder: (context, state) => const InfoCenterScreen(),
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
                    builder: (context, state) => const BuildExplorerScreen(),
                  ),
                  GoRoute(
                    path: 'build-sim',
                    builder: (context, state) => BuildSimulatorScreen(
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
                  GoRoute(
                    path: 'bp-simulator',
                    builder: (context, state) => const BpDashboardScreen(),
                    routes: [
                      GoRoute(
                        path: ':schemeId',
                        builder: (context, state) {
                          return BpSchemeDetailScreen(
                            schemeId: state.pathParameters['schemeId'] ?? '',
                            initialGameIndex: int.tryParse(
                              state.uri.queryParameters['gameIndex'] ?? '',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'tier-list',
                    builder: (context, state) => const TierListToolScreen(),
                    routes: [
                      GoRoute(
                        path: ':schemeId',
                        builder: (context, state) {
                          return TierListSchemeDetailScreen(
                            schemeId: state.pathParameters['schemeId'] ?? '',
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'game-assistant',
                    builder: (context, state) => const GameAssistantScreen(),
                  ),
                  GoRoute(
                    path: 'rank-fortune',
                    builder: (context, state) => const RankFortuneScreen(),
                  ),
                  GoRoute(
                    path: 'curiosity-lab',
                    builder: (context, state) => const CuriosityLabScreen(),
                  ),
                  GoRoute(
                    path: 'rankings',
                    builder: (context, state) => const HeroRankingScreen(),
                  ),
                  GoRoute(
                    path: 'leaderboard',
                    builder: (context, state) => PlayerLeaderboardScreen(
                      initialRankType: _playerLeaderboardRankType(state.uri),
                      initialRegionId: _playerLeaderboardRegionId(state.uri),
                    ),
                  ),
                  GoRoute(
                    path: 'team-builder',
                    builder: (context, state) => const TeamBuilderScreen(),
                  ),
                  GoRoute(
                    path: 'prompts',
                    builder: (context, state) => PromptsScreen(
                      initialAction: promptListActionFromRoute(
                        state.uri.queryParameters['tab'],
                      ),
                      initialPromptId: state.uri.queryParameters['promptId'],
                    ),
                  ),
                  GoRoute(
                    path: 'esports',
                    builder: (context, state) => const EsportsScreen(),
                  ),
                  GoRoute(
                    path: 'stats',
                    builder: (context, state) => StatsScreen(
                      initialEntry: StatsEntry.fromRoute(
                        state.uri.queryParameters['entry'],
                      ),
                      initialEquipId: state.uri.queryParameters['equip_id'],
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
                builder: (context, state) => const MeScreen(),
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
