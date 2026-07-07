import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
import 'package:hok_helper_mobile/src/features/profile/data/profile_repository.dart';
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/me_screen.dart';

class _TestAuthController extends AuthController {
  _TestAuthController(this.user);

  final AuthUser? user;

  @override
  Future<AuthUser?> build() async {
    return user;
  }
}

class _NoopApiClient extends ApiClient {
  _NoopApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(this.profile) : super(apiClient: _NoopApiClient());

  UserProfile profile;
  String? updatedDisplayName;
  String? updatedAvatar;
  String? updatedBio;
  Map<String, dynamic>? updatedSocialLinks;
  String? oldPassword;
  String? newPassword;
  int? loadedFollowingUserId;
  int? loadedFollowersUserId;

  @override
  Future<UserProfile> loadProfile({int? userId}) async {
    return profile;
  }

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? avatar,
    String? bio,
    Map<String, dynamic>? socialLinks,
  }) async {
    updatedDisplayName = displayName;
    updatedAvatar = avatar;
    updatedBio = bio;
    updatedSocialLinks = socialLinks;
    profile = UserProfile(
      id: profile.id,
      username: profile.username,
      displayName: displayName ?? profile.displayName,
      email: profile.email,
      avatar: avatar ?? profile.avatar,
      level: profile.level,
      points: profile.points,
      xpTotal: profile.xpTotal,
      xpCurrentLevel: profile.xpCurrentLevel,
      xpToNextLevel: profile.xpToNextLevel,
      levelProgress: profile.levelProgress,
      levelCap: profile.levelCap,
      bio: bio ?? profile.bio,
      socialLinks: socialLinks ?? profile.socialLinks,
      stats: profile.stats,
      isFollowing: profile.isFollowing,
      isLiked: profile.isLiked,
      isSelf: profile.isSelf,
    );
    return profile;
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    this.oldPassword = oldPassword;
    this.newPassword = newPassword;
  }

  @override
  Future<ProfileFollowList> loadFollowing({int? userId, int page = 1}) async {
    loadedFollowingUserId = userId;
    return const ProfileFollowList(
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
      users: [
        ProfileFollowUser(
          id: 77,
          username: 'arthur',
          displayName: 'Arthur',
          avatar: '',
          bio: 'Clash lane',
          isFollowing: true,
          isSelf: false,
        ),
      ],
    );
  }

  @override
  Future<ProfileFollowList> loadFollowers({int? userId, int page = 1}) async {
    loadedFollowersUserId = userId;
    return const ProfileFollowList(
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
      users: [
        ProfileFollowUser(
          id: 88,
          username: 'angela',
          displayName: 'Angela',
          avatar: '',
          bio: 'Mid lane',
          isFollowing: false,
          isSelf: false,
        ),
      ],
    );
  }
}

Widget _buildMeScreen(AuthUser? user) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _TestAuthController(user)),
    ],
    child: MaterialApp(
      routes: {'/login': (_) => const Scaffold(body: Text('Login screen'))},
      home: const Scaffold(body: MeScreen()),
    ),
  );
}

Widget _buildMeScreenWithProfile(AuthUser user, UserProfile profile) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _TestAuthController(user)),
      currentUserProfileProvider.overrideWith((ref) async => profile),
    ],
    child: MaterialApp(
      routes: {'/login': (_) => const Scaffold(body: Text('Login screen'))},
      home: const Scaffold(body: MeScreen()),
    ),
  );
}

Widget _buildMeScreenWithRepository(
  AuthUser user,
  ProfileRepository repository,
) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _TestAuthController(user)),
      profileRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      routes: {'/login': (_) => const Scaffold(body: Text('Login screen'))},
      home: const Scaffold(body: MeScreen()),
    ),
  );
}

Widget _buildMeScreenRouter(AuthUser user, UserProfile profile) {
  final router = GoRouter(
    initialLocation: '/me',
    routes: [
      GoRoute(path: '/me', builder: (context, state) => const MeScreen()),
      GoRoute(
        path: '/content/community',
        builder: (context, state) => Scaffold(
          body: Text('Community ${state.uri.queryParameters['tab']}'),
        ),
      ),
      GoRoute(
        path: '/tools/prompts',
        builder: (context, state) =>
            Scaffold(body: Text('Prompts ${state.uri.queryParameters['tab']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _TestAuthController(user)),
      currentUserProfileProvider.overrideWith((ref) async => profile),
    ],
    child: MaterialApp.router(routerConfig: router),
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
  socialLinks: {'discord': 'lam#0001'},
  stats: ProfileStats(posts: 3, following: 4, followers: 5, likes: 6),
  isFollowing: false,
  isLiked: false,
  isSelf: true,
);

void main() {
  testWidgets('signed-in compact viewport handles long identity text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const user = AuthUser(
      id: 42,
      username: 'very-long-username-that-should-not-break-layout',
      displayName:
          'Extremely Long Display Name For A Player Who Uses Many Words',
      email:
          'extremely.long.email.address.for.mobile.layout.testing@example.test',
    );

    await tester.pumpWidget(_buildMeScreen(user));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('signed-out profile shows login CTA', (tester) async {
    await tester.pumpWidget(_buildMeScreen(null));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
  });

  testWidgets('signed-in profile renders backend stats and growth', (
    tester,
  ) async {
    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );
    await tester.pumpWidget(_buildMeScreenWithProfile(user, _profile));
    await tester.pumpAndSettle();

    expect(find.text('LV.7'), findsOneWidget);
    expect(find.text('1,200 XP'), findsOneWidget);
    expect(find.text('Jungle main'), findsOneWidget);
    expect(find.text('Posts'), findsWidgets);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('signed-in profile exposes hokx favorite shortcuts', (
    tester,
  ) async {
    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );

    await tester.pumpWidget(_buildMeScreenRouter(user, _profile));
    await tester.pumpAndSettle();

    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.text('Posts'), findsWidgets);
    expect(find.text('Builds'), findsOneWidget);
    expect(find.text('Prompts'), findsOneWidget);

    await tester.ensureVisible(find.text('Prompts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prompts'));
    await tester.pumpAndSettle();

    expect(find.text('Prompts favorites'), findsOneWidget);
  });

  testWidgets('signed-in profile opens liked posts on mobile community tab', (
    tester,
  ) async {
    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );

    await tester.pumpWidget(_buildMeScreenRouter(user, _profile));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Posts').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Posts').last);
    await tester.pumpAndSettle();

    expect(find.text('Community likes'), findsOneWidget);
  });

  testWidgets('signed-in profile stats posts open my community posts', (
    tester,
  ) async {
    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );

    await tester.pumpWidget(_buildMeScreenRouter(user, _profile));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Posts').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Posts').first);
    await tester.pumpAndSettle();

    expect(find.text('Community my'), findsOneWidget);
  });

  testWidgets('signed-in profile opens following and followers from stats', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );
    final repository = _FakeProfileRepository(_profile);

    await tester.pumpWidget(_buildMeScreenWithRepository(user, repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();

    expect(repository.loadedFollowingUserId, 42);
    expect(find.text('Following users'), findsOneWidget);
    expect(find.text('Arthur'), findsOneWidget);
    expect(find.text('Clash lane'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Followers'));
    await tester.pumpAndSettle();

    expect(repository.loadedFollowersUserId, 42);
    expect(find.text('Followers'), findsWidgets);
    expect(find.text('Angela'), findsOneWidget);
    expect(find.text('Mid lane'), findsOneWidget);
  });

  testWidgets('signed-in profile follow list users open public profiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );
    final repository = _FakeProfileRepository(_profile);
    final router = GoRouter(
      initialLocation: '/me',
      routes: [
        GoRoute(path: '/me', builder: (context, state) => const MeScreen()),
        GoRoute(
          path: '/profile/:userId',
          builder: (context, state) =>
              Scaffold(body: Text('Profile ${state.pathParameters['userId']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController(user)),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arthur'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/profile/77');
    expect(find.text('Profile 77'), findsOneWidget);
  });

  testWidgets('signed-in profile followers tab query opens followers list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );
    final repository = _FakeProfileRepository(_profile);
    final router = GoRouter(
      initialLocation: '/me?tab=followers',
      routes: [
        GoRoute(
          path: '/me',
          builder: (context, state) =>
              MeScreen(initialFollowListTab: state.uri.queryParameters['tab']),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController(user)),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadedFollowersUserId, 42);
    expect(find.text('Followers'), findsWidgets);
    expect(find.text('Angela'), findsOneWidget);
    expect(find.text('Mid lane'), findsOneWidget);
  });

  testWidgets('signed-in profile opens hokx points rules from level badge', (
    tester,
  ) async {
    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );

    await tester.pumpWidget(_buildMeScreenWithProfile(user, _profile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LV.7'));
    await tester.pumpAndSettle();

    expect(find.text('Points Rules'), findsOneWidget);
    expect(find.text('Daily Login'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(find.text('Create Prompt'), findsOneWidget);
    expect(find.text('+20'), findsWidgets);
    expect(find.text('Like/Favorite'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('profile editor saves updated mobile profile fields', (
    tester,
  ) async {
    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );
    final repository = _FakeProfileRepository(_profile);

    await tester.pumpWidget(_buildMeScreenWithRepository(user, repository));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Display name'),
      'Lam Mobile',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Avatar URL'),
      'https://example.test/new.png',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bio'),
      'Roamer main',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Discord'),
      'lam#9999',
    );
    await tester.ensureVisible(find.text('Save profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.updatedDisplayName, 'Lam Mobile');
    expect(repository.updatedAvatar, 'https://example.test/new.png');
    expect(repository.updatedBio, 'Roamer main');
    expect(repository.updatedSocialLinks, {'discord': 'lam#9999'});
  });

  testWidgets('change password sheet submits old and new passwords', (
    tester,
  ) async {
    const user = AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );
    final repository = _FakeProfileRepository(_profile);

    await tester.pumpWidget(_buildMeScreenWithRepository(user, repository));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Change password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'OldPass1!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'NewPass1!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'NewPass1!',
    );
    await tester.ensureVisible(find.text('Update password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(repository.oldPassword, 'OldPass1!');
    expect(repository.newPassword, 'NewPass1!');
  });
}
