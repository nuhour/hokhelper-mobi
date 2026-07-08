import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/secure_token_store.dart';
import 'api_error.dart';

typedef AuthFailureCallback = Future<void> Function(ApiError error);

class ApiClient {
  ApiClient({
    Dio? dio,
    SecureTokenStore? tokenStore,
    this.onAuthFailure,
    AppConfig config = AppConfig.current,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: config.apiRoot)),
       _tokenStore = tokenStore ?? SecureTokenStore() {
    _dio.options.baseUrl = config.apiRoot;
    _configureDevelopmentCertificates(_dio, config);
    _dio.interceptors.removeWhere(
      (interceptor) => interceptor is _ApiClientAuthInterceptor,
    );
    _dio.interceptors.add(_ApiClientAuthInterceptor(_tokenStore));
  }

  final Dio _dio;
  final SecureTokenStore _tokenStore;
  final AuthFailureCallback? onAuthFailure;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Object?>(path, queryParameters: query);
      return _readJsonMap(response.data);
    } on DioException catch (error) {
      final apiError = _mapDioException(error);
      await _notifyAuthFailure(apiError);
      throw apiError;
    }
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    try {
      final response = await _dio.post<Object?>(path, data: body);
      return _readJsonMap(response.data);
    } on DioException catch (error) {
      final apiError = _mapDioException(error);
      await _notifyAuthFailure(apiError);
      throw apiError;
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

  Future<void> _notifyAuthFailure(ApiError error) async {
    if (error.kind != ApiErrorKind.authExpired &&
        error.kind != ApiErrorKind.forbidden) {
      return;
    }

    await onAuthFailure?.call(error);
  }
}

void _configureDevelopmentCertificates(Dio dio, AppConfig config) {
  if (kReleaseMode || !config.apiBaseUrl.startsWith('https://')) {
    return;
  }

  final uri = Uri.tryParse(config.apiBaseUrl);
  final host = uri?.host;
  if (host == null || !_isDevelopmentHost(host)) {
    return;
  }

  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) {
    return;
  }

  adapter.createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (certificate, certificateHost, port) {
      return certificateHost == host;
    };
    return client;
  };
}

bool _isDevelopmentHost(String host) {
  if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
    return true;
  }

  final address = InternetAddress.tryParse(host);
  if (address == null || address.type != InternetAddressType.IPv4) {
    return false;
  }

  final parts = host.split('.').map(int.parse).toList(growable: false);
  return parts[0] == 10 ||
      (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) ||
      (parts[0] == 192 && parts[1] == 168);
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
