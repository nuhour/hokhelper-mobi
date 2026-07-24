import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    required this.title,
    required this.fallbackRoute,
    required this.body,
    super.key,
  });

  final String title;
  final String fallbackRoute;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack(context);
      },
      child: Scaffold(
        backgroundColor: context.hokTheme.backgroundDeep,
        appBar: AppBar(
          backgroundColor: context.hokTheme.backgroundDeep,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            key: ValueKey('auth-back-$fallbackRoute'),
            tooltip: 'Back',
            onPressed: () => _goBack(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: Text(title),
        ),
        body: body,
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
