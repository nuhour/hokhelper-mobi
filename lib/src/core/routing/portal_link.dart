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

  if (uri.path == '/community') {
    return _normalizeCommunityTarget(uri);
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
    return _normalizeProfileTarget(uri);
  }

  if (uri.path == '/prompts' || uri.path == '/tools/prompts') {
    return _normalizePromptsTarget(uri).toString();
  }

  if (uri.path == '/build-sim' || uri.path == '/tools/build-sim') {
    return _normalizeBuildSimTarget(uri).toString();
  }

  if (uri.path == '/bp-simulator' ||
      uri.path == '/tools/bp-simulator' ||
      _isBpSimulatorDetailPath(uri)) {
    return _normalizeBpSimulatorTarget(uri).toString();
  }

  if (uri.path == '/esports' || uri.path == '/tools/esports') {
    return _normalizeEsportsTarget(uri).toString();
  }

  final aliasPath = _mobileAliasPath(uri.path);
  if (aliasPath != null) {
    return uri.replace(path: aliasPath).toString();
  }

  return target;
}

String _normalizeCommunityTarget(Uri uri) {
  final queryParameters = <String, String>{};
  final view = uri.queryParameters['view']?.trim();
  if (view == 'my' || view == 'likes') {
    queryParameters['tab'] = view!;
  }
  final tag = uri.queryParameters['tag']?.trim();
  if (tag != null && tag.isNotEmpty) {
    queryParameters['tag'] = tag;
  }
  return Uri(
    path: '/content/community',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

String _normalizeProfileTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final userId = queryParameters.remove('user_id')?.trim();
  if (userId != null && userId.isNotEmpty) {
    return Uri(
      path: '/profile/$userId',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }
  return uri.replace(path: '/me').toString();
}

Uri _normalizePromptsTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final promptId = queryParameters.remove('prompt_id')?.trim();
  final normalizedQueryParameters = <String, String>{};
  if (promptId != null && promptId.isNotEmpty) {
    normalizedQueryParameters['promptId'] = promptId;
  }
  normalizedQueryParameters.addAll(queryParameters);
  return Uri(
    path: '/tools/prompts',
    queryParameters: normalizedQueryParameters.isEmpty
        ? null
        : normalizedQueryParameters,
  );
}

Uri _normalizeBuildSimTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final schemeId = queryParameters.remove('scheme_id')?.trim();
  final normalizedQueryParameters = <String, String>{};
  if (schemeId != null && schemeId.isNotEmpty) {
    normalizedQueryParameters['scheme'] = schemeId;
  }
  normalizedQueryParameters.addAll(queryParameters);
  return Uri(
    path: '/tools/build-sim',
    queryParameters: normalizedQueryParameters.isEmpty
        ? null
        : normalizedQueryParameters,
  );
}

Uri _normalizeBpSimulatorTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final schemeIdFromQuery = queryParameters.remove('scheme_id')?.trim();
  final gameIndex = queryParameters.remove('game_index')?.trim();
  final normalizedQueryParameters = <String, String>{};
  if (gameIndex != null && gameIndex.isNotEmpty) {
    normalizedQueryParameters['gameIndex'] = gameIndex;
  }
  normalizedQueryParameters.addAll(queryParameters);

  final schemeIdFromPath = _isBpSimulatorDetailPath(uri)
      ? uri.pathSegments[2].trim()
      : null;
  final schemeId = schemeIdFromPath != null && schemeIdFromPath.isNotEmpty
      ? schemeIdFromPath
      : schemeIdFromQuery;
  return Uri(
    path: schemeId == null || schemeId.isEmpty
        ? '/tools/bp-simulator'
        : '/tools/bp-simulator/$schemeId',
    queryParameters: normalizedQueryParameters.isEmpty
        ? null
        : normalizedQueryParameters,
  );
}

bool _isBpSimulatorDetailPath(Uri uri) {
  return uri.pathSegments.length == 3 &&
      uri.pathSegments[0] == 'tools' &&
      uri.pathSegments[1] == 'bp-simulator';
}

Uri _normalizeEsportsTarget(Uri uri) {
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  final teamId = queryParameters.remove('team_id')?.trim();
  final playerId = queryParameters.remove('player_id')?.trim();
  final routeBase = uri.path == '/tools/esports'
      ? '/tools/esports'
      : '/esports';
  final focusedPath = teamId != null && teamId.isNotEmpty
      ? '$routeBase/teams/$teamId'
      : playerId != null && playerId.isNotEmpty
      ? '$routeBase/players/$playerId'
      : routeBase;
  return Uri(
    path: focusedPath,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  );
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
