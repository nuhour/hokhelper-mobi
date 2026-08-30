import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_platform_icon.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_share_sheet.dart';

void main() {
  testWidgets('centers social icons inside share targets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('open-share-sheet'),
                onPressed: () => showAppShareSheet(
                  context,
                  title: 'Tier list',
                  url: 'https://example.test/tier-list',
                ),
                child: const Text('Share'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-share-sheet')));
    await tester.pumpAndSettle();

    final platformIcons = find.byType(AppPlatformIcon);
    expect(platformIcons, findsNWidgets(4));
    for (var index = 0; index < platformIcons.evaluate().length; index++) {
      final icon = platformIcons.at(index);
      final target = find
          .ancestor(of: icon, matching: find.byType(Container))
          .first;
      expect(tester.getCenter(icon), tester.getCenter(target));
    }
  });
}
