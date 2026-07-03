import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/builds/presentation/build_explorer_screen.dart';
import '../features/content/presentation/content_screen.dart';
import '../features/heroes/presentation/hero_detail_screen.dart';
import '../features/heroes/presentation/hero_gallery_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/rankings/presentation/hero_ranking_screen.dart';
import '../features/profile/presentation/me_screen.dart';
import '../features/rankings/presentation/tools_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/teambuild/presentation/team_builder_screen.dart';
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
                    path: 'rankings',
                    builder: (context, state) => const HeroRankingScreen(),
                  ),
                  GoRoute(
                    path: 'team-builder',
                    builder: (context, state) => const TeamBuilderScreen(),
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
