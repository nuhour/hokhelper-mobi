import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/app_localizations.dart';
import '../core/theme/app_theme.dart';

class StandalonePageShell extends StatelessWidget {
  const StandalonePageShell({
    required this.fallbackRoute,
    required this.child,
    this.title,
    this.alwaysUseFallback = false,
    this.showAppBarInLandscape = false,
    super.key,
  });

  final String fallbackRoute;
  final String? title;
  final Widget child;
  final bool alwaysUseFallback;
  final bool showAppBarInLandscape;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack(context);
        }
      },
      child: Scaffold(
        appBar: isLandscape && !showAppBarInLandscape
            ? null
            : AppBar(
                leading: IconButton(
                  key: const ValueKey('standalone-back-button'),
                  tooltip: l10n.back,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => _goBack(context),
                ),
                title: title == null ? null : Text(title!),
                centerTitle: true,
                backgroundColor: context.hokTheme.backgroundDeep,
                surfaceTintColor: Colors.transparent,
              ),
        body: child,
      ),
    );
  }

  void _goBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (!alwaysUseFallback && router.canPop()) {
      router.pop();
      return;
    }
    context.go(fallbackRoute);
  }
}
