import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/activity/domain/event_assistance_record.dart';
import 'package:hok_helper_mobile/src/features/activity/presentation/event_assistance_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/content',
    routes: [
      GoRoute(
        path: '/content',
        builder: (context, state) => const ContentScreen(),
        routes: [
          GoRoute(
            path: 'event-assistance',
            builder: (context, state) => const EventAssistanceScreen(),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('content screen opens event assistance route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async => const []),
          cgsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async => const []),
          eventAssistanceRecordsProvider.overrideWith((ref) async {
            return const [
              EventAssistanceRecord(
                id: '77',
                regionId: 1,
                content: 'Need one player for Friday event team.',
                eventTime: '2026-07-03T12:00:00Z',
                isReported: false,
                rawText: 'Need one player for Friday event team.',
                sharedBy: 'captain',
                createdAt: '2026-07-03T12:00:00Z',
                updatedAt: '2026-07-03T12:00:00Z',
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event Assistance'));
    await tester.pumpAndSettle();

    expect(find.text('Event Assistance'), findsOneWidget);
    expect(find.text('Need one player for Friday event team.'), findsOneWidget);
  });
}
