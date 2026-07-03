enum ApiErrorKind {
  network,
  backend,
  authExpired,
  forbidden,
  validation,
  unknown,
}

class ApiError implements Exception {
  const ApiError({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'ApiError[$kind$status]: $message';
  }
}
