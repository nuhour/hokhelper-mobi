import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_section_header.dart';

class ExternalLinkScreen extends StatelessWidget {
  const ExternalLinkScreen({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = url.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('External Link')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const AppSectionHeader(title: 'External Link'),
          const SizedBox(height: 10),
          Text(
            'This notification points outside HOK Helper. Review the URL before opening it in your browser.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                normalizedUrl.isEmpty ? 'No URL provided' : normalizedUrl,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: normalizedUrl.isEmpty
                    ? null
                    : () => _copyUrl(context, normalizedUrl),
                icon: const Icon(Icons.copy),
                label: const Text('Copy link'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyUrl(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(const SnackBar(content: Text('Link copied')));
  }
}
