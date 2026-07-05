import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/public_profile_screen.dart';

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
}
