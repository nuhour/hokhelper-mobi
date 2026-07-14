import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';

void main() {
  testWidgets('hero detail renders app-native sections instead of raw json', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {
                'id': 166,
                'name': 'Lam',
                'title': 'Shark Rider',
                'mainJobName': 'Assassin',
                'minorJobName': 'Fighter',
                'rating': 4.6,
                'rating_count': 12,
                'baseTechVideo': 'https://media.example.com/lam.mp4',
                'lore': 'Lam rides the waves between battlefields.',
                'height': '180 cm',
                'world_region': 'Navenia',
                'identity': 'Sea Hunter',
                'energy': 'Mana',
              },
              'skills': [
                {
                  'name': 'Wavebreaker',
                  'description': 'Dash forward and damage enemies.',
                  'order': 1,
                  'cooldown': 8000,
                  'videoUrl': 'https://media.example.com/wavebreaker.mp4',
                },
              ],
              'history': [
                {
                  'version': '1.2.3',
                  'date': '2026-07-01',
                  'type': 'buff',
                  'title': 'Jungle tuning',
                  'content': 'Improved early clear speed.',
                },
              ],
              'stats': {'tier': 'T1', 'win_rate': 0.521, 'pick_rate': 12.4},
            };
          }),
        ],
        child: const MaterialApp(home: HeroDetailScreen(heroId: '166')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Lam'), findsWidgets);
    expect(find.text('Shark Rider'), findsOneWidget);
    expect(find.text('Assassin / Fighter'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
    expect(find.text('12 ratings'), findsOneWidget);
    expect(find.byTooltip('Play hero introduction'), findsOneWidget);
    expect(find.text('T1'), findsOneWidget);
    expect(find.text('52.1%'), findsOneWidget);
    expect(find.text('Skills', skipOffstage: false), findsOneWidget);
    expect(find.text('Wavebreaker', skipOffstage: false), findsOneWidget);
    expect(find.text('Cooldown 8s', skipOffstage: false), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lore'),
      260,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('hero-detail-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Lore', skipOffstage: false), findsOneWidget);
    expect(find.text('180 cm', skipOffstage: false), findsOneWidget);
    expect(find.text('Navenia', skipOffstage: false), findsOneWidget);
    expect(
      find.text(
        'Lam rides the waves between battlefields.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Jungle tuning'),
      260,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('hero-detail-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('History', skipOffstage: false), findsOneWidget);
    expect(find.text('Jungle tuning', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('"hero"'), findsNothing);
  });
}
