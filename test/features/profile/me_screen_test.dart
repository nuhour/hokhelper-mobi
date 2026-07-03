import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
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
    const profile = UserProfile(
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

    await tester.pumpWidget(_buildMeScreenWithProfile(user, profile));
    await tester.pumpAndSettle();

    expect(find.text('LV.7'), findsOneWidget);
    expect(find.text('1,200 XP'), findsOneWidget);
    expect(find.text('Jungle main'), findsOneWidget);
    expect(find.text('Posts'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });
}
