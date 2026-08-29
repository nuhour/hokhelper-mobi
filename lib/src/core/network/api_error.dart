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
    this.code,
    this.params,
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? params;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'ApiError[$kind$status]: $message';
  }
}
