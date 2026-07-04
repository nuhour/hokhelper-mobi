import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/info/domain/friend_link_summary.dart';
import 'package:hok_helper_mobile/src/features/info/presentation/info_center_screen.dart';

void main() {
  testWidgets('renders info center static pages and friend links', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendLinksProvider.overrideWith((ref) async {
            return const [
              FriendLinkSummary(
                id: 7,
                name: 'HOK Lab',
                url: 'https://hoklab.example',
                description: 'Draft tools and hero research.',
                logoUrl: '',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: InfoCenterScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Info Center'), findsOneWidget);
    expect(find.text('About HOK Helper'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Friend Links'), findsOneWidget);
    expect(find.text('HOK Lab'), findsOneWidget);
    expect(find.text('https://hoklab.example'), findsOneWidget);
  });
}
