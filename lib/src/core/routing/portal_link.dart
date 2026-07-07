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

  return target;
}
