import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../routing/portal_link.dart';
import '../theme/app_theme.dart';

class AppMarkdownContent extends StatelessWidget {
  const AppMarkdownContent({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _normalizeContent(content),
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppTheme.text, height: 1.5),
        h1: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppTheme.text,
          fontWeight: FontWeight.w900,
        ),
        h2: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.text,
          fontWeight: FontWeight.w900,
        ),
        h3: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.text,
          fontWeight: FontWeight.w800,
        ),
        a: const TextStyle(
          color: AppTheme.gold,
          decoration: TextDecoration.underline,
        ),
        code: const TextStyle(color: AppTheme.text),
        codeblockDecoration: BoxDecoration(
          color: AppTheme.panelAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppTheme.gold, width: 3)),
          color: AppTheme.panel,
        ),
        blockquotePadding: const EdgeInsets.all(12),
      ),
      onTapLink: (text, href, title) {
        if (href == null || href.trim().isEmpty) {
          return;
        }
        final target = normalizePortalLinkTarget(href);
        final uri = Uri.tryParse(target);
        context.go(
          uri != null && uri.hasScheme ? externalLinkRoute(target) : target,
        );
      },
    );
  }

  String _normalizeContent(String value) {
    return value
        .replaceAllMapped(_mediaMarkerPattern, (match) => '![](${match[1]})')
        .trim();
  }
}

final _mediaMarkerPattern = RegExp(r'\[(?:GIF|STICKER):(https?://[^\]]+)\]');
