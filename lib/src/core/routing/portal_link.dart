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
  if (_isPortalHost(parsed.host)) {
    return _normalizeInternalTarget(
      Uri(
        path: parsed.path.isEmpty ? '/' : parsed.path,
        queryParameters: parsed.queryParameters.isEmpty
            ? null
            : parsed.queryParameters,
      ).toString(),
    );
  }
  return trimmed;
}

String externalLinkRoute(String url) {
  return Uri(path: '/external-link', queryParameters: {'url': url}).toString();
}

String _normalizeInternalTarget(String target) {
  final uri = _stripLocalePrefix(Uri.tryParse(target));
  if (uri == null) {
    return target;
  }

  if (uri.pathSegments.length == 3 &&
      uri.pathSegments[0] == 'community' &&
      uri.pathSegments[1] == 'post') {
    return uri
        .replace(path: '/content/community/post/${uri.pathSegments[2]}')
        .toString();
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

  if (uri.path == '/skin-gallery') {
    final skinId = uri.queryParameters['skin_id']?.trim();
    if (skinId != null && skinId.isNotEmpty) {
      return _moveQueryIdToPath(uri, '/skin-gallery/$skinId', 'skin_id');
    }
  }

  if (uri.path == '/cg') {
    final cgId = uri.queryParameters['cg_id']?.trim();
    if (cgId != null && cgId.isNotEmpty) {
      return _moveQueryIdToPath(uri, '/cg/$cgId', 'cg_id');
    }
  }

  if (uri.path == '/community/leaks' ||
      uri.path == '/leaks' ||
      uri.path == '/skin-leaks') {
    return uri
        .replace(
          path: '/content/community',
          queryParameters: {'tab': 'leaks', ...uri.queryParameters},
        )
        .toString();
  }

  if (uri.path == '/honor-of-kings-world-tier-list' ||
      uri.path == '/hok-world-tier-list') {
    return uri.replace(path: '/hok-world/hok-world-tier-list').toString();
  }

  if (uri.path == '/profile') {
    return uri.replace(path: '/me').toString();
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

bool _isPortalHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1' ||
      normalized == 'hok-helper.com' ||
      normalized.endsWith('.hok-helper.com') ||
      normalized == 'hokhelper.com' ||
      normalized.endsWith('.hokhelper.com');
}

Uri? _stripLocalePrefix(Uri? uri) {
  if (uri == null || uri.pathSegments.isEmpty) {
    return uri;
  }
  final locale = uri.pathSegments.first.toLowerCase();
  if (locale != 'en' && locale != 'zh' && locale != 'id') {
    return uri;
  }
  final remainingPath = uri.pathSegments.skip(1).join('/');
  return uri.replace(path: remainingPath.isEmpty ? '/' : '/$remainingPath');
}

String _moveQueryIdToPath(Uri uri, String path, String idKey) {
  final queryParameters = Map<String, String>.from(uri.queryParameters)
    ..remove(idKey);
  return Uri(
    path: path,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}
