import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/event_assistance_repository.dart';
import '../domain/event_assistance_record.dart';

final eventAssistanceRepositoryProvider = Provider<EventAssistanceRepository>((
  ref,
) {
  return EventAssistanceRepository(apiClient: ref.watch(apiClientProvider));
});

final eventAssistanceRecordsProvider =
    FutureProvider<List<EventAssistanceRecord>>((ref) async {
      final settings = await ref.watch(appSettingsControllerProvider.future);
      return ref
          .watch(eventAssistanceRepositoryProvider)
          .loadRecords(regionId: settings.region.regionId);
    });

class EventAssistanceScreen extends ConsumerStatefulWidget {
  const EventAssistanceScreen({this.initialShareText, super.key});

  final String? initialShareText;

  @override
  ConsumerState<EventAssistanceScreen> createState() =>
      _EventAssistanceScreenState();
}

class _EventAssistanceScreenState extends ConsumerState<EventAssistanceScreen> {
  var _didOpenInitialShareSheet = false;

  @override
  Widget build(BuildContext context) {
    final recordsValue = ref.watch(eventAssistanceRecordsProvider);
    _openInitialShareSheet();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppAsyncView<List<EventAssistanceRecord>>(
        value: recordsValue,
        retry: () => ref.invalidate(eventAssistanceRecordsProvider),
        data: (records) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(eventAssistanceRecordsProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: AppSectionHeader(title: 'Event Assistance'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _showShareSheet(context),
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: const Text('Share Text'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Share event codes, teammate requests, and activity help.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                ),
                const SizedBox(height: 20),
                if (records.isEmpty)
                  const AppEmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No assistance records yet',
                    message: 'Share the first event help text for the board.',
                  )
                else
                  ...records.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecordCard(record: record),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openInitialShareSheet() {
    final initialText = widget.initialShareText?.trim() ?? '';
    if (_didOpenInitialShareSheet || initialText.isEmpty) {
      return;
    }
    _didOpenInitialShareSheet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showShareSheet(context, initialText: initialText);
      }
    });
  }

  Future<void> _showShareSheet(
    BuildContext context, {
    String? initialText,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) =>
          _ShareAssistanceSheet(initialText: initialText),
    );
  }
}

class _ShareAssistanceSheet extends ConsumerStatefulWidget {
  const _ShareAssistanceSheet({this.initialText});

  final String? initialText;

  @override
  ConsumerState<_ShareAssistanceSheet> createState() =>
      _ShareAssistanceSheetState();
}

class _ShareAssistanceSheetState extends ConsumerState<_ShareAssistanceSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    final initialText = widget.initialText?.trim() ?? '';
    if (initialText.isNotEmpty) {
      _controller.text = initialText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Assistance Text',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste your event-assistance text. It will be parsed and published to the shared board.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Enter event text here...',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Please enter assistance text';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? 'Submitting...' : 'Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    final settings = ref.read(appSettingsControllerProvider);
    try {
      await ref
          .read(eventAssistanceRepositoryProvider)
          .submitText(
            text: _controller.text.trim(),
            regionId: settings.value?.region.regionId ?? 1,
          );
      ref.invalidate(eventAssistanceRecordsProvider);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to submit assistance text')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

String _formatEventTime(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return '';
  }
  final date = DateTime.tryParse(text);
  if (date == null) {
    return text;
  }
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.isNegative) {
    return date.toLocal().toIso8601String().split('T').first;
  }
  if (diff.inSeconds < 60) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} hr ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} day(s) ago';
  }
  final weeks = diff.inDays ~/ 7;
  if (weeks < 4) {
    return '$weeks week(s) ago';
  }
  final months = diff.inDays ~/ 30;
  if (months < 12) {
    return '$months month(s) ago';
  }
  return '${diff.inDays ~/ 365} year(s) ago';
}

class _RecordCard extends ConsumerStatefulWidget {
  const _RecordCard({required this.record});

  final EventAssistanceRecord record;

  @override
  ConsumerState<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends ConsumerState<_RecordCard> {
  var _reporting = false;
  late var _isReported = widget.record.isReported;

  @override
  void didUpdateWidget(covariant _RecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id ||
        oldWidget.record.isReported != widget.record.isReported) {
      _isReported = widget.record.isReported;
      _reporting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
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
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: AppTheme.gold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    record.sharedBy,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(label: _isReported ? 'Reported' : 'Active'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.text,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (record.eventTime.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _formatEventTime(record.eventTime),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyRecord(context, record.content),
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Report',
                  onPressed: _reporting || _isReported
                      ? null
                      : () => _reportRecord(context, record.id),
                  icon: _reporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.flag_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyRecord(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) {
      return;
    }
    _showRecordSnackBar(context, 'Copied to clipboard');
  }

  Future<void> _reportRecord(BuildContext context, String recordId) async {
    setState(() => _reporting = true);
    try {
      await ref.read(eventAssistanceRepositoryProvider).reportRecord(recordId);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _isReported = true;
        _reporting = false;
      });
      _showRecordSnackBar(context, 'Record reported');
      ref.invalidate(eventAssistanceRecordsProvider);
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _reporting = false);
      _showRecordSnackBar(context, 'Failed to report record');
    }
  }

  void _showRecordSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
