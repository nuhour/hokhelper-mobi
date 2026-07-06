import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
import 'package:hok_helper_mobile/src/features/notifications/domain/notification_summary.dart';
import 'package:hok_helper_mobile/src/features/notifications/presentation/notifications_screen.dart';
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/me_screen.dart';

class _TestAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async {
    return const AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );
  }
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/me',
    routes: [
      GoRoute(path: '/me', builder: (context, state) => const MeScreen()),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}

const _profile = UserProfile(
  id: 42,
  username: 'lam',
  displayName: 'Lam',
  email: 'lam@example.test',
  avatar: '',
  level: 7,
  points: 1200,
  xpTotal: 1400,
  xpCurrentLevel: 260,
  xpToNextLevel: 740,
  levelProgress: 26,
  levelCap: false,
  bio: 'Jungle main',
  socialLinks: {},
  stats: ProfileStats(posts: 3, following: 4, followers: 5, likes: 6),
  isFollowing: false,
  isLiked: false,
  isSelf: true,
);

void main() {
  testWidgets('profile screen opens notifications route', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController()),
          currentUserProfileProvider.overrideWith((ref) async => _profile),
          notificationsProvider.overrideWith((ref) async {
            return const NotificationPage(
              total: 1,
              rows: [
                NotificationSummary(
                  id: 10,
                  type: 'social',
                  targetType: 'community_post_comment',
                  title: 'Comment',
                  content: 'Coach commented on your post',
                  link: '/community/post/99',
                  isRead: false,
                  createdAt: '2026-07-03T08:30:00Z',
                  actorName: 'Coach',
                  actorAvatar: '',
                  actorId: 7,
                ),
              ],
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    final notificationsButton = find
        .byKey(const Key('profile-notifications-button'))
        .last;
    await tester.tap(notificationsButton);
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Coach commented on your post'), findsOneWidget);
  });
}
