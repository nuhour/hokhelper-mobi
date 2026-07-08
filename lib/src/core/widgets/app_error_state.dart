import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';
import '../theme/app_theme.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({required this.message, this.retry, super.key});

  final String message;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: AppTheme.text),
            ),
            if (retry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
