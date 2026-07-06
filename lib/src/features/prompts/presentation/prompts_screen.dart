import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
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
    final query = PromptListQuery(
      action: _action,
      search: _search,
      sort: _sort,
    );
    final promptsValue = ref.watch(promptListQueryProvider(query));

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<List<PromptSummary>>(
        value: promptsValue,
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
                          action: FilledButton.icon(
                            onPressed: () => _openCreateSheet(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore public AI prompt templates from the community.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 14),
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
                            selected: {_action},
                            onSelectionChanged: (selection) {
                              setState(() => _action = selection.single);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
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
                              canManage: _action == PromptListAction.myPrompts,
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
      backgroundColor: AppTheme.panel,
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
      backgroundColor: AppTheme.panel,
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
      backgroundColor: AppTheme.panel,
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
  late Future<PromptGenerationQuota> _quotaFuture;
  PromptGenerationQuota? _quota;
  List<String> _images = const [];
  var _generating = false;
  String? _settingCoverUrl;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.prompt.content);
    _quotaFuture = ref.read(promptsRepositoryProvider).loadGenerationQuota();
  }

  @override
  void dispose() {
    _contentController.dispose();
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
                        color: AppTheme.text,
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
              TextField(
                controller: _contentController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Prompt content',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _generating || (_quota?.remaining ?? 1) <= 0
                      ? null
                      : _generate,
                  icon: _generating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Generate image'),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _images.isEmpty
                    ? const Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                color: AppTheme.muted,
                                size: 28,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'No generated images yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
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
                                    backgroundColor: AppTheme.panel.withValues(
                                      alpha: 0.92,
                                    ),
                                    foregroundColor: AppTheme.text,
                                    side: const BorderSide(
                                      color: AppTheme.muted,
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
      backgroundColor: AppTheme.panel,
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

class _QuotaPanel extends StatelessWidget {
  const _QuotaPanel({required this.quota, this.onRecharge});

  final PromptGenerationQuota quota;
  final VoidCallback? onRecharge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
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
                  color: AppTheme.text,
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
                      color: AppTheme.text,
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
                color: AppTheme.muted,
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
                color: AppTheme.muted,
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
              : AppTheme.panelAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.gold : AppTheme.panelAlt,
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
                style: const TextStyle(
                  color: AppTheme.text,
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
          : AppTheme.panelAlt,
      leading: Icon(
        method.icon,
        color: selected ? AppTheme.gold : AppTheme.muted,
      ),
      title: Text(
        method.label,
        style: const TextStyle(
          color: AppTheme.text,
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
  final _tagsController = TextEditingController();
  final _sourceImageController = TextEditingController();
  final _effectImageController = TextEditingController();
  var _isPublic = true;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    final prompt = widget.prompt;
    if (prompt != null) {
      _titleController.text = prompt.title;
      _contentController.text = prompt.content;
      _tagsController.text = prompt.tags
          .where((tag) => !tag.startsWith('Lang:'))
          .join(', ');
      _sourceImageController.text = prompt.sourceImageUrl;
      _effectImageController.text = prompt.effectImageUrl;
      _isPublic = prompt.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _sourceImageController.dispose();
    _effectImageController.dispose();
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
                          color: AppTheme.text,
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
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'skin, build, hero',
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sourceImageController,
                  decoration: const InputDecoration(
                    labelText: 'Source image URL',
                    hintText: 'https://example.com/source.png',
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _effectImageController,
                  decoration: const InputDecoration(
                    labelText: 'Effect image URL',
                    hintText: 'https://example.com/effect.png',
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
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
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);
      final draft = PromptDraft(
        title: _titleController.text,
        content: _contentController.text,
        tags: tags,
        isPublic: _isPublic,
        language: 'en',
        sourceImageUrl: _sourceImageController.text,
        effectImageUrl: _effectImageController.text,
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
    this.onEdit,
    this.onDelete,
    this.onGenerate,
  });

  final PromptSummary prompt;
  final bool canManage;
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
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                                color: AppTheme.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PublicBadge(isPublic: prompt.isPublic),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _PromptAuthorName(
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
                  color: AppTheme.muted,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  value: _likeCount,
                ),
                _MetricChip(icon: Icons.bookmark_border, value: _favoriteCount),
                OutlinedButton.icon(
                  onPressed: _likeSubmitting
                      ? null
                      : () => _likePrompt(context),
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                  ),
                  label: const Text('Like'),
                ),
                OutlinedButton.icon(
                  onPressed: _favoriteSubmitting
                      ? null
                      : () => _favoritePrompt(context),
                  icon: Icon(
                    _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                    size: 16,
                  ),
                  label: const Text('Favorite'),
                ),
                if (prompt.content.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _copyPrompt(context),
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copy'),
                  ),
                OutlinedButton.icon(
                  onPressed: widget.onGenerate,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate'),
                ),
                if (widget.canManage) ...[
                  OutlinedButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                  ),
                ],
              ],
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

  Future<void> _likePrompt(BuildContext context) async {
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
}

class _PromptAuthorName extends StatelessWidget {
  const _PromptAuthorName({
    required this.authorId,
    required this.authorName,
  });

  final int authorId;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted);

    if (authorId <= 0) {
      return Text(
        authorName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => context.go('/profile/$authorId'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.muted,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textStyle,
        ),
        child: Text(
          authorName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.gold),
            const SizedBox(width: 5),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
