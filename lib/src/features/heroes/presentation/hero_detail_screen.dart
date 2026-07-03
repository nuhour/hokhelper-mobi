import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import 'hero_gallery_screen.dart';

class HeroDetailArgs {
  const HeroDetailArgs({required this.heroId, required this.regionId});

  final String heroId;
  final int regionId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HeroDetailArgs &&
            runtimeType == other.runtimeType &&
            heroId == other.heroId &&
            regionId == other.regionId;
  }

  @override
  int get hashCode => Object.hash(heroId, regionId);
}

final heroDetailProvider =
    FutureProvider.family<Map<String, dynamic>, HeroDetailArgs>((ref, args) {
      return ref
          .watch(heroesRepositoryProvider)
          .loadHeroDetail(args.heroId, args.regionId);
    });

class HeroDetailScreen extends ConsumerWidget {
  const HeroDetailScreen({required this.heroId, super.key});

  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = HeroDetailArgs(heroId: heroId, regionId: defaultHeroRegionId);
    final detailValue = ref.watch(heroDetailProvider(args));

    return Scaffold(
      appBar: AppBar(title: Text('Hero #$heroId')),
      body: AppAsyncView<Map<String, dynamic>>(
        value: detailValue,
        retry: () => ref.invalidate(heroDetailProvider(args)),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              const JsonEncoder.withIndent('  ').convert(detail),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.text,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
