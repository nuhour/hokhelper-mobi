import 'package:go_router/go_router.dart';

import '../features/activity/presentation/event_assistance_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
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
import '../features/info/presentation/info_center_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/prompts/presentation/prompts_screen.dart';
import '../features/rank_fortune/presentation/rank_fortune_screen.dart';
import '../features/rankings/presentation/hero_ranking_screen.dart';
import '../features/rankings/presentation/player_leaderboard_screen.dart';
import '../features/profile/presentation/me_screen.dart';
import '../features/profile/presentation/public_profile_screen.dart';
import '../features/rankings/presentation/tools_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/stats/presentation/hero_trends_screen.dart';
import '../features/teambuild/presentation/team_builder_screen.dart';
import '../features/tierlist_tool/presentation/tierlist_scheme_detail_screen.dart';
import '../features/tierlist_tool/presentation/tierlist_tool_screen.dart';
import '../features/topics/presentation/topic_article_screen.dart';
import '../features/topics/presentation/topic_hub_screen.dart';
import 'app_shell.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
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
        path: '/skin-gallery',
        builder: (context, state) => const SkinGalleryScreen(),
        routes: [
          GoRoute(
            path: ':skinId',
            builder: (context, state) {
              return SkinGalleryScreen(
                initialSkinId: int.tryParse(
                  state.pathParameters['skinId'] ?? '',
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/cg',
        builder: (context, state) => const CgGalleryScreen(),
        routes: [
          GoRoute(
            path: ':cgId',
            builder: (context, state) {
              return CgGalleryScreen(
                initialCgId: int.tryParse(state.pathParameters['cgId'] ?? ''),
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
        builder: (context, state) => const HeroTrendsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const PlayerLeaderboardScreen(),
      ),
      GoRoute(
        path: '/esports',
        builder: (context, state) => const EsportsScreen(),
        routes: [
          GoRoute(
            path: 'teams/:teamId',
            builder: (context, state) {
              return const EsportsScreen(initialTab: EsportsInitialTab.teams);
            },
          ),
          GoRoute(
            path: 'players/:playerId',
            builder: (context, state) {
              return const EsportsScreen(initialTab: EsportsInitialTab.players);
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
        builder: (context, state) =>
            const InfoStaticPage(section: InfoStaticSection.about),
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
                builder: (context, state) => const HeroGalleryScreen(),
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
                    builder: (context, state) => const CommunityScreen(),
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
                    builder: (context, state) => const SkinGalleryScreen(),
                  ),
                  GoRoute(
                    path: 'cgs',
                    builder: (context, state) => const CgGalleryScreen(),
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
                    builder: (context, state) => const BuildSimulatorScreen(),
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
                    builder: (context, state) =>
                        const PlayerLeaderboardScreen(),
                  ),
                  GoRoute(
                    path: 'team-builder',
                    builder: (context, state) => const TeamBuilderScreen(),
                  ),
                  GoRoute(
                    path: 'prompts',
                    builder: (context, state) => const PromptsScreen(),
                  ),
                  GoRoute(
                    path: 'esports',
                    builder: (context, state) => const EsportsScreen(),
                  ),
                  GoRoute(
                    path: 'stats',
                    builder: (context, state) => const StatsScreen(),
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
    ],
  );
}
