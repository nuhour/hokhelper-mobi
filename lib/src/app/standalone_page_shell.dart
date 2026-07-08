import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/app_localizations.dart';
import '../core/theme/app_theme.dart';

class StandalonePageShell extends StatelessWidget {
  const StandalonePageShell({
    required this.fallbackRoute,
    required this.child,
    this.title,
    super.key,
  });

  final String fallbackRoute;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const ValueKey('standalone-back-button'),
            tooltip: l10n.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => _goBack(context),
          ),
          title: title == null ? null : Text(title!),
          backgroundColor: AppTheme.bg,
          surfaceTintColor: Colors.transparent,
        ),
        body: child,
      ),
    );
  }

  void _goBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    context.go(fallbackRoute);
  }
}
