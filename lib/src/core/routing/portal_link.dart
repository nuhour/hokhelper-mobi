String normalizePortalLinkTarget(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('#/')) {
    return _normalizeInternalTarget(trimmed.substring(1));
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null || !parsed.hasScheme) {
    return _normalizeInternalTarget(trimmed);
  }
  if (parsed.fragment.startsWith('/')) {
    return _normalizeInternalTarget(parsed.fragment);
  }
  return trimmed;
}

String externalLinkRoute(String url) {
  return Uri(path: '/external-link', queryParameters: {'url': url}).toString();
}

String _normalizeInternalTarget(String target) {
  final uri = Uri.tryParse(target);
  if (uri == null) {
    return target;
  }

  if (uri.pathSegments.length == 3 &&
      uri.pathSegments[0] == 'community' &&
      uri.pathSegments[1] == 'post') {
    return uri.replace(
      path: '/content/community/post/${uri.pathSegments[2]}',
    ).toString();
  }

  if (uri.path == '/hero-gallery') {
    final heroId = uri.queryParameters['hero_id']?.trim();
    if (heroId != null && heroId.isNotEmpty) {
      return '/heroes/$heroId';
    }
    return uri.replace(path: '/heroes').toString();
  }

  if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'hero-gallery') {
    return uri.replace(path: '/heroes/${uri.pathSegments[1]}').toString();
  }

  if (uri.path == '/stats' && uri.queryParameters['entry'] == 'hero_trend') {
    final heroId = uri.queryParameters['hero_id']?.trim();
    return uri
        .replace(
          path: '/trends',
          queryParameters: heroId == null || heroId.isEmpty
              ? null
              : {'hero_id': heroId},
        )
        .toString();
  }

  if (uri.path == '/community/leaks' ||
      uri.path == '/leaks' ||
      uri.path == '/skin-leaks') {
    return uri
        .replace(
          path: '/content/community',
          queryParameters: {
            'tab': 'leaks',
            ...uri.queryParameters,
          },
        )
        .toString();
  }

  final aliasPath = _mobileAliasPath(uri.path);
  if (aliasPath != null) {
    return uri.replace(path: aliasPath).toString();
  }

  return target;
}

String? _mobileAliasPath(String path) {
  return switch (path) {
    '/builds' => '/tools/builds',
    '/build-sim' => '/tools/build-sim',
    '/bp-simulator' => '/tools/bp-simulator',
    '/rankings' => '/tools/rankings',
    '/game-assistant' => '/tools/game-assistant',
    '/rank-fortune' => '/tools/rank-fortune',
    '/curiosity-lab' => '/tools/curiosity-lab',
    '/team-builder' => '/tools/team-builder',
    '/prompts' => '/tools/prompts',
    '/stats' => '/tools/stats',
    '/event-assistance' => '/content/event-assistance',
    '/patch-notes' || '/versions' => '/content/patch-notes',
    _ => null,
  };
}
