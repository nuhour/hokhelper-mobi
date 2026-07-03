import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class EventAssistanceScreen extends ConsumerWidget {
  const EventAssistanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsValue = ref.watch(eventAssistanceRecordsProvider);

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
                      onPressed: () => _showShareSheet(context, ref),
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

  Future<void> _showShareSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => const _ShareAssistanceSheet(),
    );
  }
}

class _ShareAssistanceSheet extends ConsumerStatefulWidget {
  const _ShareAssistanceSheet();

  @override
  ConsumerState<_ShareAssistanceSheet> createState() =>
      _ShareAssistanceSheetState();
}

class _ShareAssistanceSheetState extends ConsumerState<_ShareAssistanceSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _submitting = false;

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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Submitting...' : 'Submit'),
              ),
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
    await ref
        .read(eventAssistanceRepositoryProvider)
        .submitText(
          text: _controller.text.trim(),
          regionId: settings.value?.region.regionId ?? 1,
        );
    ref.invalidate(eventAssistanceRecordsProvider);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final EventAssistanceRecord record;

  @override
  Widget build(BuildContext context) {
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
                _Pill(label: record.reportedLabel),
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
                record.eventTime,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ],
        ),
      ),
    );
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
