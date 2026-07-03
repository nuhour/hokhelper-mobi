import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_token_store.dart';
import 'api_error.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    SecureTokenStore? tokenStore,
    AppConfig config = AppConfig.current,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: config.apiRoot)),
       _tokenStore = tokenStore ?? SecureTokenStore() {
    _dio.options.baseUrl = config.apiRoot;
    _dio.interceptors.removeWhere(
      (interceptor) => interceptor is _ApiClientAuthInterceptor,
    );
    _dio.interceptors.add(_ApiClientAuthInterceptor(_tokenStore));
  }

  final Dio _dio;
  final SecureTokenStore _tokenStore;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Object?>(path, queryParameters: query);
      return _readJsonMap(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    try {
      final response = await _dio.post<Object?>(path, data: body);
      return _readJsonMap(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Map<String, dynamic> _readJsonMap(Object? data) {
    final json = switch (data) {
      Map<String, dynamic>() => data,
      Map() => Map<String, dynamic>.from(data),
      _ => throw const ApiError(
        kind: ApiErrorKind.backend,
        message: 'Unexpected backend response',
      ),
    };

    if (json['success'] == false) {
      throw ApiError(
        kind: ApiErrorKind.backend,
        message: _readEnvelopeMessage(json),
      );
    }

    return json;
  }

  ApiError _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 401) {
      return ApiError(
        kind: ApiErrorKind.authExpired,
        message: _readErrorMessage(error),
        statusCode: statusCode,
      );
    }

    if (statusCode == 403) {
      return ApiError(
        kind: ApiErrorKind.forbidden,
        message: _readErrorMessage(error),
        statusCode: statusCode,
      );
    }

    if (statusCode != null && statusCode >= 400) {
      return ApiError(
        kind: ApiErrorKind.backend,
        message: _readErrorMessage(error),
        statusCode: statusCode,
      );
    }

    return ApiError(
      kind: ApiErrorKind.network,
      message:
          error.error?.toString() ?? error.message ?? 'Network request failed',
      statusCode: statusCode,
    );
  }

  String _readErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      return _readEnvelopeMessage(data);
    }

    return error.message ?? 'Request failed';
  }

  String _readEnvelopeMessage(Map<dynamic, dynamic> json) {
    final message = json['message'] ?? json['msg'] ?? json['error'];
    if (message != null && message.toString().isNotEmpty) {
      return message.toString();
    }

    return 'Request failed';
  }
}

class _ApiClientAuthInterceptor extends Interceptor {
  _ApiClientAuthInterceptor(this._tokenStore);

  final SecureTokenStore _tokenStore;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers[Headers.contentTypeHeader] = Headers.jsonContentType;

    try {
      final accessToken = await _tokenStore.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }

    handler.next(options);
  }
}
