import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
import 'package:hok_helper_mobile/src/features/profile/data/profile_repository.dart';
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/me_screen.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/public_profile_screen.dart';

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
  _FakeProfileRepository() : super(apiClient: _NoopApiClient());

  int? followedUserId;
  int? likedUserId;
  int? loadedFollowingUserId;
  int? loadedFollowersUserId;

  @override
  Future<ProfileFollowResult> followUser(int userId) async {
    followedUserId = userId;
    return ProfileFollowResult(isFollowing: true, targetUserId: userId);
  }

  @override
  Future<ProfileLikeResult> toggleProfileLike(int userId) async {
    likedUserId = userId;
    return ProfileLikeResult(
      isLiked: true,
      likesCount: 7,
      targetUserId: userId,
    );
  }

  @override
  Future<ProfileFollowList> loadFollowing({int? userId, int page = 1}) async {
    loadedFollowingUserId = userId;
    return const ProfileFollowList(
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
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    );
  }

  @override
  Future<ProfileFollowList> loadFollowers({int? userId, int page = 1}) async {
    loadedFollowersUserId = userId;
    return const ProfileFollowList(
      users: [
        ProfileFollowUser(
          id: 88,
          username: 'angela',
          displayName: 'Angela',
          avatar: '',
          bio: 'Mid mage',
          isFollowing: false,
          isSelf: false,
        ),
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    );
  }
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async {
    return const AuthUser(
      id: 7,
      username: 'viewer',
      email: 'viewer@example.test',
      displayName: 'Viewer',
    );
  }
}

void main() {
  testWidgets('profile user id route renders public profile details', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/profile/42');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicUserProfileProvider(42).overrideWith((ref) async {
            return const UserProfile(
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
              stats: ProfileStats(
                posts: 3,
                following: 4,
                followers: 5,
                likes: 6,
              ),
              isFollowing: true,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Public Profile'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('Jungle main'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);
    expect(find.text('Logout'), findsNothing);
  });

  testWidgets('signed-in users can follow and like public profiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter();
    router.go('/profile/42');
    final repository = _FakeProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController()),
          profileRepositoryProvider.overrideWithValue(repository),
          publicUserProfileProvider(42).overrideWith((ref) async {
            return const UserProfile(
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
              stats: ProfileStats(
                posts: 3,
                following: 4,
                followers: 5,
                likes: 4,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final followButton = find.widgetWithText(OutlinedButton, 'Follow');
    await tester.ensureVisible(followButton);
    await tester.tap(followButton);
    await tester.pumpAndSettle();

    expect(repository.followedUserId, 42);
    expect(find.widgetWithText(OutlinedButton, 'Following'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    final likeButton = find.widgetWithText(OutlinedButton, 'Like');
    await tester.ensureVisible(likeButton);
    await tester.tap(likeButton);
    await tester.pumpAndSettle();

    expect(repository.likedUserId, 42);
    expect(find.widgetWithText(OutlinedButton, 'Liked'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('copies public profile share links', (tester) async {
    MethodCall? clipboardCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCall = call;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final router = createAppRouter();
    router.go('/profile/42');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicUserProfileProvider(42).overrideWith((ref) async {
            return const UserProfile(
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
              stats: ProfileStats(
                posts: 3,
                following: 4,
                followers: 5,
                likes: 6,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Share'));
    await tester.pumpAndSettle();

    expect(clipboardCall, isNotNull);
    expect(clipboardCall!.arguments, {'text': '/profile/42'});
    expect(find.text('Profile link copied'), findsOneWidget);
  });

  testWidgets('profile stats open following and followers lists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter();
    router.go('/profile/42');
    final repository = _FakeProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController()),
          profileRepositoryProvider.overrideWithValue(repository),
          publicUserProfileProvider(42).overrideWith((ref) async {
            return const UserProfile(
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
              stats: ProfileStats(
                posts: 3,
                following: 4,
                followers: 5,
                likes: 6,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
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
    expect(find.text('Mid mage'), findsOneWidget);
  });

  testWidgets('profile followers tab query opens followers list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter();
    router.go('/profile/42?tab=followers');
    final repository = _FakeProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController()),
          profileRepositoryProvider.overrideWithValue(repository),
          publicUserProfileProvider(42).overrideWith((ref) async {
            return const UserProfile(
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
              stats: ProfileStats(
                posts: 3,
                following: 4,
                followers: 5,
                likes: 6,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadedFollowersUserId, 42);
    expect(find.text('Followers'), findsWidgets);
    expect(find.text('Angela'), findsOneWidget);
    expect(find.text('Mid mage'), findsOneWidget);
  });
}
