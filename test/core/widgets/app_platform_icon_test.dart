import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_platform_icon.dart';

void main() {
  test('maps supported platform ids to brand icon data', () {
    for (final platform in [
      'x',
      'instagram',
      'facebook',
      'telegram',
      'tiktok',
      'discord',
      'youtube',
      'whatsapp',
      'reddit',
      'wechat',
    ]) {
      expect(appPlatformFaIconData(platform), isNotNull, reason: platform);
    }
    expect(appPlatformFaIconData('unknown'), isNull);
  });

  testWidgets('renders a Font Awesome brand icon for known platforms', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppPlatformIcon(platform: 'telegram')),
      ),
    );

    expect(find.byType(FaIcon), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });
}
