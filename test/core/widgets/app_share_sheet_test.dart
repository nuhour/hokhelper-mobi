import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/i18n/app_localizations.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_platform_icon.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_share_sheet.dart';

void main() {
  test('localizes the share destination call to action', () {
    expect(
      AppLocalizations(const Locale('zh')).translate('shareSourceAttribution'),
      '更多内容请访问 HOK Helper',
    );
  });

  testWidgets('uses a destination-oriented HOK Helper attribution', (
    tester,
  ) async {
    late String shareText;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            shareText = buildAppShareText(
              context,
              content: 'Tier list',
              url: 'https://example.test/tier-list',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      shareText,
      'Tier list\n\nhttps://example.test/tier-list\n\nSee more on HOK Helper',
    );
    expect(shareText, endsWith('See more on HOK Helper'));
  });

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
