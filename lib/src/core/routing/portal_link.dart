String normalizePortalLinkTarget(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('#/')) {
    return trimmed.substring(1);
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null || !parsed.hasScheme) {
    return trimmed;
  }
  if (parsed.fragment.startsWith('/')) {
    return parsed.fragment;
  }
  return trimmed;
}

String externalLinkRoute(String url) {
  return Uri(path: '/external-link', queryParameters: {'url': url}).toString();
}
