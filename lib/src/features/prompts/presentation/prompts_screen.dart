import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_share_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/prompts_repository.dart';
import '../domain/prompt_summary.dart';

final promptsRepositoryProvider = Provider<PromptsRepository>((ref) {
  return PromptsRepository(apiClient: ref.watch(apiClientProvider));
});

final publicPromptsProvider = FutureProvider<List<PromptSummary>>((ref) {
  return ref.watch(promptListProvider(PromptListAction.explore).future);
});

final promptListProvider =
    FutureProvider.family<List<PromptSummary>, PromptListAction>((ref, action) {
      return ref.watch(promptsRepositoryProvider).loadPrompts(action: action);
    });

final promptListQueryProvider =
    FutureProvider.family<List<PromptSummary>, PromptListQuery>((ref, query) {
      if (query.isDefault) {
        return ref.watch(promptListProvider(query.action).future);
      }
      return ref
          .watch(promptsRepositoryProvider)
          .loadPrompts(
            action: query.action,
            search: query.search,
            sort: query.sort,
          );
    });

extension PromptListActionLabel on PromptListAction {
  String get label => switch (this) {
    PromptListAction.explore => 'Explore',
    PromptListAction.myPrompts => 'My Prompts',
    PromptListAction.favorites => 'Favorites',
  };
}

extension PromptListSortLabel on PromptListSort {
  String get label => switch (this) {
    PromptListSort.hot => 'Hot',
    PromptListSort.latest => 'Latest',
  };
}

class PromptListQuery {
  const PromptListQuery({
    required this.action,
    this.search = '',
    this.sort = PromptListSort.hot,
  });

  final PromptListAction action;
  final String search;
  final PromptListSort sort;

  bool get isDefault => search.trim().isEmpty && sort == PromptListSort.hot;

  @override
  bool operator ==(Object other) {
    return other is PromptListQuery &&
        other.action == action &&
        other.search == search &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(action, search, sort);
}

PromptListAction promptListActionFromRoute(String? value) {
  return switch ((value ?? '').trim()) {
    'myPrompts' => PromptListAction.myPrompts,
    'favorites' => PromptListAction.favorites,
    _ => PromptListAction.explore,
  };
}

class PromptsScreen extends ConsumerStatefulWidget {
  const PromptsScreen({
    super.key,
    this.initialAction = PromptListAction.explore,
    this.initialPromptId,
  });

  final PromptListAction initialAction;
  final String? initialPromptId;

  @override
  ConsumerState<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends ConsumerState<PromptsScreen> {
  late PromptListAction _action;
  late final TextEditingController _searchController;
  final _createdPrompts = <PromptSummary>[];
  final _updatedPrompts = <String, PromptSummary>{};
  final _deletedPromptIds = <String>{};
  List<PromptSummary>? _lastResolvedPrompts;
  String _search = '';
  PromptListSort _sort = PromptListSort.hot;

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated =
        ref.watch(authControllerProvider).valueOrNull != null;
    final activeAction = isAuthenticated ? _action : PromptListAction.explore;
    final query = PromptListQuery(
      action: activeAction,
      search: _search,
      sort: _sort,
    );
    final promptsValue = ref.watch(promptListQueryProvider(query));
    final freshPrompts = promptsValue.valueOrNull;
    if (freshPrompts != null) {
      _lastResolvedPrompts = freshPrompts;
    }

    return Material(
      color: context.hokTheme.backgroundDeep,
      child: AppAsyncView<List<PromptSummary>>(
        value: promptsValue,
        previousData: _lastResolvedPrompts,
        retry: () => ref.invalidate(promptListQueryProvider(query)),
        data: (prompts) {
          final visiblePrompts = _visiblePrompts(
            _mergePromptChanges([..._createdPrompts, ...prompts]),
          );
          return RefreshIndicator(
            onRefresh: () => ref.refresh(promptListQueryProvider(query).future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionHeader(
                          title: 'Prompts',
                          action: isAuthenticated
                              ? FilledButton.icon(
                                  onPressed: () => _openCreateSheet(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create'),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore public AI prompt templates from the community.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceMuted,
                              ),
                        ),
                        const SizedBox(height: 14),
                        if (isAuthenticated) ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SegmentedButton<PromptListAction>(
                              segments: PromptListAction.values
                                  .map(
                                    (action) => ButtonSegment(
                                      value: action,
                                      label: Text(action.label),
                                    ),
                                  )
                                  .toList(growable: false),
                              selected: {activeAction},
                              onSelectionChanged: (selection) {
                                setState(() => _action = selection.single);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: 'Search prompts',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _search = '');
                                    },
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Clear search',
                                  ),
                          ),
                          onChanged: (value) {
                            setState(() => _search = value.trim());
                          },
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<PromptListSort>(
                            segments: PromptListSort.values
                                .map(
                                  (sort) => ButtonSegment(
                                    value: sort,
                                    icon: Icon(
                                      sort == PromptListSort.hot
                                          ? Icons.local_fire_department_outlined
                                          : Icons.schedule,
                                    ),
                                    label: Text(sort.label),
                                  ),
                                )
                                .toList(growable: false),
                            selected: {_sort},
                            onSelectionChanged: (selection) {
                              setState(() => _sort = selection.single);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visiblePrompts.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: 'No prompts found',
                      message: 'Pull to refresh and try again.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: visiblePrompts.length,
                      itemBuilder: (context, index) {
                        final prompt = visiblePrompts[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (prompt.id == widget.initialPromptId) ...[
                              const _SharedPromptBadge(),
                              const SizedBox(height: 8),
                            ],
                            _PromptCard(
                              prompt: prompt,
                              canManage:
                                  activeAction == PromptListAction.myPrompts,
                              showVisibility:
                                  activeAction != PromptListAction.explore,
                              onView: () => _openPromptViewer(context, prompt),
                              onEdit: () => _openEditSheet(context, prompt),
                              onDelete: () => _confirmDelete(context, prompt),
                              onGenerate: () =>
                                  _openGenerateSheet(context, prompt),
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PromptSummary> _visiblePrompts(List<PromptSummary> prompts) {
    final initialPromptId = widget.initialPromptId?.trim();
    if (initialPromptId == null || initialPromptId.isEmpty) {
      return prompts;
    }

    final focusedIndex = prompts.indexWhere(
      (prompt) => prompt.id == initialPromptId,
    );
    if (focusedIndex < 0) {
      return prompts;
    }

    final focused = prompts[focusedIndex];
    final rest = prompts.where((prompt) => prompt.id != initialPromptId);
    return [focused, ...rest].toList(growable: false);
  }

  List<PromptSummary> _mergePromptChanges(List<PromptSummary> prompts) {
    final seen = <String>{};
    final rows = <PromptSummary>[];
    for (final prompt in prompts) {
      if (_deletedPromptIds.contains(prompt.id) || !seen.add(prompt.id)) {
        continue;
      }
      rows.add(_updatedPrompts[prompt.id] ?? prompt);
    }
    return rows;
  }

  PromptListQuery get _currentQuery =>
      PromptListQuery(action: _action, search: _search, sort: _sort);

  void _invalidatePromptList(PromptListAction action) {
    ref.invalidate(promptListProvider(action));
    ref.invalidate(
      promptListQueryProvider(
        PromptListQuery(action: action, search: _search, sort: _sort),
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final created = await showModalBottomSheet<PromptSummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PromptEditorSheet(),
    );
    if (created == null || !mounted) {
      return;
    }
    setState(() {
      _createdPrompts.removeWhere((prompt) => prompt.id == created.id);
      _createdPrompts.insert(0, created);
      _action = PromptListAction.myPrompts;
    });
    _invalidatePromptList(PromptListAction.myPrompts);
  }

  Future<void> _openEditSheet(
    BuildContext context,
    PromptSummary prompt,
  ) async {
    final updated = await showModalBottomSheet<PromptSummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PromptEditorSheet(prompt: prompt),
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() {
      _updatedPrompts[updated.id] = updated;
      final createdIndex = _createdPrompts.indexWhere(
        (prompt) => prompt.id == updated.id,
      );
      if (createdIndex >= 0) {
        _createdPrompts[createdIndex] = updated;
      }
    });
    _invalidatePromptList(PromptListAction.myPrompts);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PromptSummary prompt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete prompt?'),
        content: Text('Delete "${prompt.title}" from your prompt library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(promptsRepositoryProvider).deletePrompt(prompt.id);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _deletedPromptIds.add(prompt.id);
        _createdPrompts.removeWhere((row) => row.id == prompt.id);
        _updatedPrompts.remove(prompt.id);
      });
      _invalidatePromptList(PromptListAction.myPrompts);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Prompt deleted')));
    } catch (_) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete prompt')),
      );
    }
  }

  Future<void> _openGenerateSheet(
    BuildContext context,
    PromptSummary prompt,
  ) async {
    try {
      final enabled = await ref
          .read(promptsRepositoryProvider)
          .loadGenerationEnabled();
      if (!enabled) {
        if (!context.mounted) {
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Prompt generation is temporarily unavailable'),
          ),
        );
        return;
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Prompt generation is temporarily unavailable'),
        ),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    final updated = await showModalBottomSheet<PromptSummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PromptGenerationSheet(prompt: prompt),
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() {
      _updatedPrompts[updated.id] = updated;
      final createdIndex = _createdPrompts.indexWhere(
        (prompt) => prompt.id == updated.id,
      );
      if (createdIndex >= 0) {
        _createdPrompts[createdIndex] = updated;
      }
    });
    ref.invalidate(promptListQueryProvider(_currentQuery));
    ref.invalidate(promptListProvider(_action));
  }

  Future<void> _openPromptViewer(BuildContext context, PromptSummary prompt) {
    return showDialog<void>(
      context: context,
      builder: (_) => _PromptViewerDialog(prompt: prompt),
    );
  }
}

class _PromptGenerationSheet extends ConsumerStatefulWidget {
  const _PromptGenerationSheet({required this.prompt});

  final PromptSummary prompt;

  @override
  ConsumerState<_PromptGenerationSheet> createState() =>
      _PromptGenerationSheetState();
}

class _PromptGenerationSheetState
    extends ConsumerState<_PromptGenerationSheet> {
  late final TextEditingController _contentController;
  late final TextEditingController _sourceImageController;
  late Future<PromptGenerationQuota> _quotaFuture;
  PromptGenerationQuota? _quota;
  List<String> _images = const [];
  var _mode = _PromptGenerationMode.text;
  var _generating = false;
  String? _settingCoverUrl;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.prompt.content);
    _sourceImageController = TextEditingController(
      text: widget.prompt.sourceImageUrl,
    );
    _quotaFuture = ref.read(promptsRepositoryProvider).loadGenerationQuota();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _sourceImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Image generation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.hokTheme.onSurfaceStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _generating
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<PromptGenerationQuota>(
                        future: _quotaFuture,
                        builder: (context, snapshot) {
                          final quota = snapshot.data ?? _quota;
                          if (quota == null) {
                            return const LinearProgressIndicator();
                          }
                          _quota = quota;
                          return _QuotaPanel(
                            quota: quota,
                            onRecharge: _openRechargeSheet,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_PromptGenerationMode>(
                        segments: const [
                          ButtonSegment(
                            value: _PromptGenerationMode.text,
                            icon: Icon(Icons.text_fields),
                            label: Text('Text to image'),
                          ),
                          ButtonSegment(
                            value: _PromptGenerationMode.image,
                            icon: Icon(Icons.layers_outlined),
                            label: Text('Image to image'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: _generating
                            ? null
                            : (values) {
                                setState(() => _mode = values.single);
                              },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contentController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Prompt content',
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (_mode == _PromptGenerationMode.image) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sourceImageController,
                          decoration: const InputDecoration(
                            labelText: 'Source image URL',
                            hintText: 'https://example.com/source.png',
                            prefixIcon: Icon(Icons.image_search_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _generating || (_quota?.remaining ?? 1) <= 0
                              ? null
                              : _generate,
                          icon: _generating
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: const Text('Generate image'),
                        ),
                      ),
                      SizedBox(height: 14),
                      if (_images.isEmpty)
                        SizedBox(
                          height: 180,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: context.hokTheme.onSurfaceMuted,
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'No generated images yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.hokTheme.onSurfaceMuted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _images.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                              ),
                          itemBuilder: (context, index) {
                            final imageUrl = _images[index];
                            final isSettingCover = _settingCoverUrl == imageUrl;
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                AppImage(
                                  url: imageUrl,
                                  borderRadius: 14,
                                  semanticLabel: 'Generated image ${index + 1}',
                                ),
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  top: 8,
                                  child: OutlinedButton.icon(
                                    onPressed: _settingCoverUrl == null
                                        ? () => _setCover(imageUrl)
                                        : null,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: context
                                          .hokTheme
                                          .surfaceSlate
                                          .withValues(alpha: 0.92),
                                      foregroundColor:
                                          context.hokTheme.onSurfaceStrong,
                                      side: BorderSide(
                                        color: context.hokTheme.onSurfaceMuted,
                                      ),
                                      minimumSize: const Size.fromHeight(34),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: isSettingCover
                                        ? const SizedBox.square(
                                            dimension: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.image, size: 16),
                                    label: const Text('Set cover'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final result = await ref
          .read(promptsRepositoryProvider)
          .generateImages(
            promptId: widget.prompt.id,
            count: 1,
            customContent: _contentController.text,
            sourceImageUrl: _mode == _PromptGenerationMode.image
                ? _sourceImageController.text
                : null,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _images = result.images;
        _quota = result.quota;
        _quotaFuture = Future.value(result.quota);
        _generating = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _generating = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to generate image')),
      );
    }
  }

  Future<void> _setCover(String imageUrl) async {
    setState(() => _settingCoverUrl = imageUrl);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ref
          .read(promptsRepositoryProvider)
          .setPromptImage(promptId: widget.prompt.id, imageData: imageUrl);
      if (!mounted) {
        return;
      }
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Prompt cover updated')),
      );
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _settingCoverUrl = null);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to set prompt cover')),
      );
    }
  }

  Future<void> _openRechargeSheet() async {
    final result = await showModalBottomSheet<PromptRechargeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PromptRechargeSheet(),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _quota = result.quota;
      _quotaFuture = Future.value(result.quota);
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('Quota recharged +${result.added}')),
    );
  }
}

enum _PromptGenerationMode { text, image }

class _QuotaPanel extends StatelessWidget {
  const _QuotaPanel({required this.quota, this.onRecharge});

  final PromptGenerationQuota quota;
  final VoidCallback? onRecharge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.bolt_outlined, color: AppTheme.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${quota.remaining} / ${quota.total} left',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onRecharge,
              icon: const Icon(Icons.credit_card, size: 16),
              label: const Text('Recharge'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptRechargeSheet extends ConsumerStatefulWidget {
  const _PromptRechargeSheet();

  @override
  ConsumerState<_PromptRechargeSheet> createState() =>
      _PromptRechargeSheetState();
}

class _PromptRechargeSheetState extends ConsumerState<_PromptRechargeSheet> {
  var _planId = 'standard';
  var _paymentMethod = 'card';
  var _submitting = false;

  static const _plans = [
    _RechargePlan('basic', '+5', 'Starter'),
    _RechargePlan('standard', '+10', 'Standard'),
    _RechargePlan('pro', '+30', 'Pro'),
  ];

  static const _paymentMethods = [
    _PaymentMethod('wechat', 'WeChat', Icons.chat_bubble_outline),
    _PaymentMethod('alipay', 'Alipay', Icons.qr_code_2),
    _PaymentMethod('card', 'Card', Icons.credit_card),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recharge quota',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Plan',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.hokTheme.onSurfaceMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final plan in _plans) ...[
                  Expanded(
                    child: _OptionTile(
                      selected: _planId == plan.id,
                      title: plan.name,
                      subtitle: plan.count,
                      onTap: _submitting
                          ? null
                          : () => setState(() => _planId = plan.id),
                    ),
                  ),
                  if (plan != _plans.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Payment',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.hokTheme.onSurfaceMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (final method in _paymentMethods) ...[
              _PaymentTile(
                method: method,
                selected: _paymentMethod == method.id,
                onTap: _submitting
                    ? null
                    : () => setState(() => _paymentMethod = method.id),
              ),
              if (method != _paymentMethods.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open),
                label: const Text('Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(promptsRepositoryProvider)
          .rechargeGenerationQuota(
            planId: _planId,
            paymentMethod: _paymentMethod,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to recharge quota')),
      );
    }
  }
}

class _RechargePlan {
  const _RechargePlan(this.id, this.count, this.name);

  final String id;
  final String count;
  final String name;
}

class _PaymentMethod {
  const _PaymentMethod(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.gold.withValues(alpha: 0.14)
              : context.hokTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.gold : context.hokTheme.surfaceRaised,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: selected
          ? AppTheme.gold.withValues(alpha: 0.12)
          : context.hokTheme.surfaceRaised,
      leading: Icon(
        method.icon,
        color: selected ? AppTheme.gold : context.hokTheme.onSurfaceMuted,
      ),
      title: Text(
        method.label,
        style: TextStyle(
          color: context.hokTheme.onSurfaceStrong,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppTheme.gold)
          : null,
    );
  }
}

class _PromptEditorSheet extends ConsumerStatefulWidget {
  const _PromptEditorSheet({this.prompt});

  final PromptSummary? prompt;

  @override
  ConsumerState<_PromptEditorSheet> createState() => _PromptEditorSheetState();
}

class _PromptEditorSheetState extends ConsumerState<_PromptEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _customTagController = TextEditingController();
  final _imagePicker = ImagePicker();
  final Set<String> _tags = <String>{};
  var _language = _PromptLanguage.english;
  var _isPublic = true;
  var _submitting = false;
  String _sourceImageUrl = '';
  String _effectImageUrl = '';
  XFile? _sourceImageFile;
  XFile? _effectImageFile;

  @override
  void initState() {
    super.initState();
    final prompt = widget.prompt;
    if (prompt != null) {
      _titleController.text = prompt.title;
      _contentController.text = prompt.content;
      _tags.addAll(prompt.tags.where((tag) => !tag.startsWith('Lang:')));
      _language = _PromptLanguageOptionX.fromTag(prompt.tags);
      _sourceImageUrl = prompt.sourceImageUrl;
      _effectImageUrl = prompt.effectImageUrl;
      _isPublic = prompt.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEditing = widget.prompt != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit prompt' : 'Create prompt',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.hokTheme.onSurfaceStrong,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    return text.isEmpty ? 'Title is required' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Prompt content',
                    alignLabelWithHint: true,
                  ),
                  minLines: 4,
                  maxLines: 8,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    return text.isEmpty ? 'Prompt content is required' : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_PromptLanguage>(
                  initialValue: _language,
                  decoration: const InputDecoration(
                    labelText: 'Prompt language',
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                  items: _PromptLanguage.values
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _language = value);
                          }
                        },
                ),
                const SizedBox(height: 20),
                _PromptTagsEditor(
                  tags: _tags,
                  customTagController: _customTagController,
                  enabled: !_submitting,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 20),
                Text(
                  'Images (optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.hokTheme.onSurfaceStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 520;
                    final sourcePicker = _PromptImagePicker(
                      label: 'Source image',
                      localFile: _sourceImageFile,
                      imageUrl: _sourceImageUrl,
                      enabled: !_submitting,
                      onPick: () => _pickImage(_PromptImageTarget.source),
                      onRemove: () => setState(() {
                        _sourceImageFile = null;
                        _sourceImageUrl = '';
                      }),
                    );
                    final effectPicker = _PromptImagePicker(
                      label: 'Result image',
                      localFile: _effectImageFile,
                      imageUrl: _effectImageUrl,
                      enabled: !_submitting,
                      onPick: () => _pickImage(_PromptImageTarget.effect),
                      onRemove: () => setState(() {
                        _effectImageFile = null;
                        _effectImageUrl = '';
                      }),
                    );
                    return isWide
                        ? Row(
                            children: [
                              Expanded(child: sourcePicker),
                              const SizedBox(width: 12),
                              Expanded(child: effectPicker),
                            ],
                          )
                        : Column(
                            children: [
                              sourcePicker,
                              const SizedBox(height: 12),
                              effectPicker,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _isPublic,
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _isPublic = value),
                  title: const Text('Public'),
                  subtitle: const Text('Visible in Explore after publishing'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _save,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save prompt'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      var sourceImageUrl = _sourceImageUrl;
      var effectImageUrl = _effectImageUrl;
      if (_sourceImageFile != null) {
        sourceImageUrl = await ref
            .read(promptsRepositoryProvider)
            .uploadImage(File(_sourceImageFile!.path));
      }
      if (_effectImageFile != null) {
        effectImageUrl = await ref
            .read(promptsRepositoryProvider)
            .uploadImage(File(_effectImageFile!.path));
      }
      final draft = PromptDraft(
        title: _titleController.text,
        content: _contentController.text,
        tags: _tags.toList(growable: false),
        isPublic: _isPublic,
        language: _language.code,
        sourceImageUrl: sourceImageUrl,
        effectImageUrl: effectImageUrl,
      );
      final editingPrompt = widget.prompt;
      final saved = editingPrompt == null
          ? await ref.read(promptsRepositoryProvider).createPrompt(draft)
          : await ref
                .read(promptsRepositoryProvider)
                .updatePrompt(editingPrompt.id, draft);
      if (!mounted) {
        return;
      }
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pop(saved);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            editingPrompt == null ? 'Prompt created' : 'Prompt updated',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to create prompt')),
      );
    }
  }

  Future<void> _pickImage(_PromptImageTarget target) async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2048,
    );
    if (!mounted || file == null) {
      return;
    }
    setState(() {
      if (target == _PromptImageTarget.source) {
        _sourceImageFile = file;
      } else {
        _effectImageFile = file;
      }
    });
  }
}

class _PromptTagsEditor extends StatelessWidget {
  const _PromptTagsEditor({
    required this.tags,
    required this.customTagController,
    required this.enabled,
    required this.onChanged,
  });

  static const _popularTags = [
    'HOK Hero Portrait',
    'MOBA Splash Art',
    'Skin Concept Art',
    'Esports Poster',
    'Mythic China',
    'Battlefield Matte',
  ];

  final Set<String> tags;
  final TextEditingController customTagController;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags (optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: context.hokTheme.onSurfaceStrong,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularTags
              .map((tag) {
                final selected = tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: enabled
                      ? (value) {
                          if (value) {
                            tags.add(tag);
                          } else {
                            tags.remove(tag);
                          }
                          onChanged();
                        }
                      : null,
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: customTagController,
                enabled: enabled,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCustomTag(),
                decoration: const InputDecoration(
                  labelText: 'Custom tag',
                  hintText: 'Add a tag',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: enabled ? _addCustomTag : null,
              icon: const Icon(Icons.add),
              tooltip: 'Add tag',
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => InputChip(
                    label: Text(tag),
                    onDeleted: enabled
                        ? () {
                            tags.remove(tag);
                            onChanged();
                          }
                        : null,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  void _addCustomTag() {
    final tag = customTagController.text.trim();
    if (tag.isEmpty) {
      return;
    }
    tags.add(tag);
    customTagController.clear();
    onChanged();
  }
}

class _PromptImagePicker extends StatelessWidget {
  const _PromptImagePicker({
    required this.label,
    required this.localFile,
    required this.imageUrl,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String label;
  final XFile? localFile;
  final String imageUrl;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = localFile != null || imageUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (optional)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.hokTheme.onSurfaceMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: 'Upload $label',
          child: InkWell(
            onTap: enabled ? onPick : null,
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              height: 132,
              decoration: BoxDecoration(
                color: context.hokTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasImage
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  style: hasImage ? BorderStyle.solid : BorderStyle.none,
                ),
              ),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: localFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.file(
                                    File(localFile!.path),
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : AppImage(
                                  url: imageUrl,
                                  fit: BoxFit.contain,
                                  borderRadius: 5,
                                  semanticLabel: label,
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filled(
                            onPressed: enabled ? onRemove : null,
                            icon: Icon(Icons.close, size: 16),
                            tooltip: 'Remove $label',
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.upload_outlined,
                            color: context.hokTheme.onSurfaceMuted,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Upload image',
                            style: TextStyle(
                              color: context.hokTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _PromptImageTarget { source, effect }

enum _PromptLanguage {
  english('en', 'English'),
  chinese('zh', 'Chinese'),
  indonesian('id', 'Indonesian');

  const _PromptLanguage(this.code, this.label);

  final String code;
  final String label;
}

extension _PromptLanguageOptionX on _PromptLanguage {
  static _PromptLanguage fromTag(List<String> tags) {
    var langTag = '';
    for (final tag in tags) {
      if (!tag.toLowerCase().startsWith('lang:')) {
        continue;
      }
      langTag = tag.substring(5).trim().toLowerCase();
      if (langTag.isNotEmpty) {
        break;
      }
    }
    return switch (langTag) {
      'zh' || 'chinese' || '中文' => _PromptLanguage.chinese,
      'id' || 'indonesian' || 'bahasa' => _PromptLanguage.indonesian,
      _ => _PromptLanguage.english,
    };
  }
}

class _SharedPromptBadge extends StatelessWidget {
  const _SharedPromptBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.32)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'Shared prompt',
          style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PromptCard extends ConsumerStatefulWidget {
  const _PromptCard({
    required this.prompt,
    this.canManage = false,
    this.showVisibility = false,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.onGenerate,
  });

  final PromptSummary prompt;
  final bool canManage;
  final bool showVisibility;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onGenerate;

  @override
  ConsumerState<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends ConsumerState<_PromptCard> {
  late var _likeCount = widget.prompt.likeCount;
  late var _isLiked = widget.prompt.isLiked;
  late var _favoriteCount = widget.prompt.favoriteCount;
  late var _isFavorited = widget.prompt.isFavorited;
  var _likeSubmitting = false;
  var _favoriteSubmitting = false;

  @override
  void didUpdateWidget(covariant _PromptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt.id != widget.prompt.id ||
        oldWidget.prompt.likeCount != widget.prompt.likeCount ||
        oldWidget.prompt.isLiked != widget.prompt.isLiked ||
        oldWidget.prompt.favoriteCount != widget.prompt.favoriteCount ||
        oldWidget.prompt.isFavorited != widget.prompt.isFavorited) {
      _likeCount = widget.prompt.likeCount;
      _isLiked = widget.prompt.isLiked;
      _favoriteCount = widget.prompt.favoriteCount;
      _isFavorited = widget.prompt.isFavorited;
      _likeSubmitting = false;
      _favoriteSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prompt = widget.prompt;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppImage(
                  url: prompt.imageUrl,
                  width: 74,
                  height: 74,
                  borderRadius: 14,
                  semanticLabel: prompt.title,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              prompt.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: context.hokTheme.onSurfaceStrong,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (widget.showVisibility) ...[
                            const SizedBox(width: 8),
                            _PublicBadge(isPublic: prompt.isPublic),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      _PromptAuthorButton(
                        authorAvatarUrl: prompt.authorAvatarUrl,
                        authorId: prompt.authorId,
                        authorName: prompt.authorName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (prompt.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                prompt.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.hokTheme.onSurfaceMuted,
                  height: 1.35,
                ),
              ),
            ],
            if (prompt.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: prompt.tags.take(4).map(_TagChip.new).toList(),
              ),
            ],
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PromptCountAction(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    value: _likeCount,
                    tooltip: _isLiked ? 'Unlike' : 'Like',
                    color: _isLiked ? AppTheme.error : AppTheme.gold,
                    isLoading: _likeSubmitting,
                    onPressed: () => _likePrompt(context),
                  ),
                  const SizedBox(width: 4),
                  _PromptCountAction(
                    icon: _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                    value: _favoriteCount,
                    tooltip: _isFavorited ? 'Remove favorite' : 'Favorite',
                    isLoading: _favoriteSubmitting,
                    onPressed: () => _favoritePrompt(context),
                  ),
                  const SizedBox(width: 8),
                  _PromptIconAction(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View prompt',
                    onPressed: widget.onView,
                  ),
                  if (prompt.content.isNotEmpty)
                    _PromptIconAction(
                      icon: Icons.copy_outlined,
                      tooltip: 'Copy',
                      onPressed: () => _copyPrompt(context),
                    ),
                  _PromptIconAction(
                    icon: Icons.ios_share_outlined,
                    tooltip: 'Share',
                    onPressed: () => _sharePrompt(context),
                  ),
                  if (widget.canManage) ...[
                    _PromptIconAction(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onPressed: widget.onEdit,
                    ),
                    _PromptIconAction(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      color: AppTheme.error,
                      onPressed: widget.onDelete,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyPrompt(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.prompt.content));
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Prompt copied')));
  }

  Future<void> _sharePrompt(BuildContext context) {
    return showAppShareSheet(
      context,
      title: widget.prompt.title,
      url: 'https://hokhelper.com/tools/prompts?promptId=${widget.prompt.id}',
    );
  }

  Future<void> _likePrompt(BuildContext context) async {
    if (!_requirePromptLogin(context)) return;
    setState(() => _likeSubmitting = true);
    try {
      final result = await ref
          .read(promptsRepositoryProvider)
          .toggleLike(widget.prompt.id);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _isLiked = result.isLiked;
        _likeCount = result.likeCount;
        _likeSubmitting = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.isLiked ? 'Prompt liked' : 'Prompt unliked'),
        ),
      );
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _likeSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to like prompt')),
      );
    }
  }

  Future<void> _favoritePrompt(BuildContext context) async {
    if (!_requirePromptLogin(context)) return;
    setState(() => _favoriteSubmitting = true);
    try {
      final result = await ref
          .read(promptsRepositoryProvider)
          .toggleFavorite(widget.prompt.id);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _isFavorited = result.isFavorited;
        _favoriteCount = result.favoriteCount;
        _favoriteSubmitting = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.isFavorited ? 'Prompt favorited' : 'Prompt unfavorited',
          ),
        ),
      );
      if (!result.isFavorited) {
        ref.invalidate(promptListProvider(PromptListAction.favorites));
      }
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _favoriteSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to favorite prompt')),
      );
    }
  }

  bool _requirePromptLogin(BuildContext context) {
    if (ref.read(authControllerProvider).valueOrNull != null) {
      return true;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Sign in to interact with prompts'),
          action: SnackBarAction(
            label: 'Sign in',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
    return false;
  }
}

class _PromptViewerDialog extends StatelessWidget {
  const _PromptViewerDialog({required this.prompt});

  final PromptSummary prompt;

  @override
  Widget build(BuildContext context) {
    final sourceImage = prompt.sourceImageUrl;
    final resultImage = prompt.effectImageUrl.isNotEmpty
        ? prompt.effectImageUrl
        : prompt.imageUrl;
    final hasImages = sourceImage.isNotEmpty || resultImage.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prompt.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.hokTheme.onSurfaceStrong,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _copyPrompt(context),
                      icon: const Icon(Icons.copy_outlined, size: 19),
                      label: const Text('Copy'),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (prompt.content.isNotEmpty)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.hokTheme.backgroundDeep,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.48),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: SelectableText(
                              prompt.content,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: context.hokTheme.onSurfaceMuted,
                                    height: 1.55,
                                  ),
                            ),
                          ),
                        ),
                      if (hasImages) ...[
                        const SizedBox(height: 18),
                        _PromptImageComparison(
                          sourceImageUrl: sourceImage,
                          resultImageUrl: resultImage,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyPrompt(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: prompt.content));
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Prompt copied')));
  }
}

class _PromptImageComparison extends StatelessWidget {
  const _PromptImageComparison({
    required this.sourceImageUrl,
    required this.resultImageUrl,
  });

  final String sourceImageUrl;
  final String resultImageUrl;

  @override
  Widget build(BuildContext context) {
    final source = _PromptComparisonImage(
      label: 'Original',
      imageUrl: sourceImageUrl,
    );
    final result = _PromptComparisonImage(
      label: 'Result',
      imageUrl: resultImageUrl,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(children: [source, const SizedBox(height: 16), result]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: source),
            const SizedBox(width: 16),
            Expanded(child: result),
          ],
        );
      },
    );
  }
}

class _PromptComparisonImage extends StatelessWidget {
  const _PromptComparisonImage({required this.label, required this.imageUrl});

  final String label;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: context.hokTheme.onSurfaceMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (imageUrl.isEmpty)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.hokTheme.backgroundDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: context.hokTheme.onSurfaceMuted,
                ),
              ),
            ),
          )
        else
          Tooltip(
            message: 'View $label fullscreen',
            child: Semantics(
              button: true,
              label: 'View $label fullscreen',
              child: InkWell(
                onTap: () => _openFullscreen(context),
                borderRadius: BorderRadius.circular(10),
                child: AppImage(
                  url: imageUrl,
                  aspectRatio: 16 / 9,
                  borderRadius: 10,
                  semanticLabel: '$label image',
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _PromptFullscreenImage(label: label, imageUrl: imageUrl),
      ),
    );
  }
}

class _PromptFullscreenImage extends StatelessWidget {
  const _PromptFullscreenImage({required this.label, required this.imageUrl});

  final String label;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: context.hokTheme.onSurfaceStrong,
        title: Text(label),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Close full screen image',
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image_outlined,
              color: context.hokTheme.onSurfaceMuted,
              size: 48,
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }
              return const SizedBox.square(
                dimension: 44,
                child: CircularProgressIndicator(color: AppTheme.gold),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PromptAuthorButton extends StatelessWidget {
  const _PromptAuthorButton({
    required this.authorAvatarUrl,
    required this.authorId,
    required this.authorName,
  });

  final String authorAvatarUrl;
  final int authorId;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.hokTheme.onSurfaceMuted);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppImage(
          url: authorAvatarUrl,
          width: 24,
          height: 24,
          borderRadius: 999,
          semanticLabel: '$authorName avatar',
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: authorId <= 0
          ? content
          : TextButton(
              onPressed: () => context.go('/profile/$authorId'),
              style: TextButton.styleFrom(
                foregroundColor: context.hokTheme.onSurfaceMuted,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: textStyle,
              ),
              child: content,
            ),
    );
  }
}

class _PublicBadge extends StatelessWidget {
  const _PublicBadge({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: isPublic ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          isPublic ? 'Public' : 'Private',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.hokTheme.onSurfaceStrong,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PromptCountAction extends StatelessWidget {
  const _PromptCountAction({
    required this.icon,
    required this.value,
    required this.tooltip,
    required this.onPressed,
    this.color = AppTheme.gold,
    this.isLoading = false,
  });

  final IconData icon;
  final int value;
  final String tooltip;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: isLoading
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 20),
        label: Text(
          value.toString(),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PromptIconAction extends StatelessWidget {
  const _PromptIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppTheme.gold,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
      tooltip: tooltip,
      color: color,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    );
  }
}
