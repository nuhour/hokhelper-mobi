import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
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
}
