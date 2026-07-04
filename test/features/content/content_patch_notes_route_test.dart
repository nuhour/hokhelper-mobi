import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/content/domain/patch_note_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/patch_notes_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/content',
    routes: [
      GoRoute(
        path: '/content',
        builder: (context, state) => const ContentScreen(),
        routes: [
          GoRoute(
            path: 'patch-notes',
            builder: (context, state) => const PatchNotesScreen(),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('content screen opens patch notes route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async => const []),
          cgsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 31,
                version: '1.2.3',
                title: 'Version 1.2.3 Patch Notes',
                date: '2026-07-01',
                preview: 'Lam and Angela adjusted.',
                content: 'Full patch note body.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 42,
                    heroName: 'Lam',
                    avatarUrl: '',
                    changeType: 'buff',
                  ),
                ],
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patch Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3 Patch Notes'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
  });
}
