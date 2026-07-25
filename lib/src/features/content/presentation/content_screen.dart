import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/content_repository.dart';
import '../domain/content_item_summary.dart';
import '../domain/patch_note_summary.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(apiClient: ref.watch(apiClientProvider));
});

final skinsProvider = FutureProvider<List<ContentItemSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(contentRepositoryProvider)
      .loadSkins(settings.region.regionId);
});

final cgsProvider = FutureProvider<List<ContentItemSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref.watch(contentRepositoryProvider).loadCgs(settings.region.regionId);
});

final patchNotesRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

final patchNotesProvider = FutureProvider<List<PatchNoteSummary>>((ref) async {
  final regionId = await ref.watch(patchNotesRegionProvider.future);
  return ref.watch(contentRepositoryProvider).loadPatchNotes(regionId);
});
