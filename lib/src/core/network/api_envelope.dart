class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    required this.message,
    required this.result,
  });

  final bool success;
  final String message;
  final T? result;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) parseResult,
  ) {
    return ApiEnvelope<T>(
      success: json['success'] == true,
      message: (json['message'] ?? json['msg'] ?? '').toString(),
      result: json['result'] == null ? null : parseResult(json['result']),
    );
  }
}
