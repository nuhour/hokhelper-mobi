import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/network/api_error.dart';
import 'package:hok_helper_mobile/src/core/storage/secure_token_store.dart';

class _ThrowingTokenStore extends SecureTokenStore {
  @override
  Future<String?> readAccessToken() async {
    throw StateError('token storage unavailable');
  }
}

class _EnvelopeFailureInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(
      Response<Object?>(
        requestOptions: options,
        statusCode: 200,
        data: {
          'success': false,
          'message': 'Backend validation failed',
          'result': null,
        },
      ),
    );
  }
}

class _UnauthorizedInterceptor extends Interceptor {
  _UnauthorizedInterceptor(this.statusCode);

  final int statusCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: statusCode,
          data: {'message': 'Session expired'},
        ),
      ),
    );
  }
}

class _RetryableAuthInterceptor extends Interceptor {
  var requestCount = 0;
  final authorizationHeaders = <Object?>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requestCount++;
    authorizationHeaders.add(options.headers['Authorization']);
    if (requestCount == 1) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 403,
            data: {'message': 'Forbidden'},
          ),
        ),
      );
      return;
    }

    handler.resolve(
      Response<Object?>(
        requestOptions: options,
        statusCode: 200,
        data: const {
          'success': true,
          'result': {'source': 'anonymous'},
        },
      ),
    );
  }
}

class _MemoryTokenStore extends SecureTokenStore {
  String? access;
  var didClear = false;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<void> clear() async {
    didClear = true;
    access = null;
  }
}

void main() {
  test(
    'allows local development certificates for configured lan https hosts',
    () {
      final dio = Dio();
      ApiClient(
        dio: dio,
        config: const AppConfig(
          apiBaseUrl: 'https://192.168.1.180:8000',
          apiPrefix: '/hokx',
        ),
      );

      final adapter = dio.httpClientAdapter;
      expect(adapter, isA<IOHttpClientAdapter>());

      expect((adapter as IOHttpClientAdapter).createHttpClient, isNotNull);
    },
  );

  test('maps token read failures without hanging the request', () async {
    final client = ApiClient(
      dio: Dio(),
      tokenStore: _ThrowingTokenStore(),
      config: const AppConfig(
        apiBaseUrl: 'https://example.test',
        apiPrefix: '',
      ),
    );

    await expectLater(
      client.getJson('/heroes').timeout(const Duration(seconds: 2)),
      throwsA(
        isA<ApiError>()
            .having((error) => error.kind, 'kind', ApiErrorKind.network)
            .having(
              (error) => error.message,
              'message',
              contains('token storage unavailable'),
            ),
      ),
    );
  });

  test('maps failed backend envelopes to backend errors', () async {
    final dio = Dio()..interceptors.add(_EnvelopeFailureInterceptor());
    final client = ApiClient(
      dio: dio,
      config: const AppConfig(
        apiBaseUrl: 'https://example.test',
        apiPrefix: '',
      ),
    );

    await expectLater(
      client.postJson('/heroes', body: {}),
      throwsA(
        isA<ApiError>()
            .having((error) => error.kind, 'kind', ApiErrorKind.backend)
            .having(
              (error) => error.message,
              'message',
              'Backend validation failed',
            ),
      ),
    );
  });

  test('notifies auth failure callback for unauthorized responses', () async {
    ApiError? callbackError;
    final dio = Dio()..interceptors.add(_UnauthorizedInterceptor(401));
    final client = ApiClient(
      dio: dio,
      onAuthFailure: (error) async {
        callbackError = error;
      },
      config: const AppConfig(
        apiBaseUrl: 'https://example.test',
        apiPrefix: '',
      ),
    );

    await expectLater(
      client.getJson('/profile'),
      throwsA(
        isA<ApiError>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.authExpired,
        ),
      ),
    );

    expect(callbackError?.kind, ApiErrorKind.authExpired);
    expect(callbackError?.statusCode, 401);
  });

  test('retries a rejected authenticated GET without stale auth', () async {
    final tokenStore = _MemoryTokenStore()..access = 'stale-access-token';
    final authInterceptor = _RetryableAuthInterceptor();
    final dio = Dio();
    final client = ApiClient(
      dio: dio,
      tokenStore: tokenStore,
      onAuthFailure: (error) async => tokenStore.clear(),
      config: const AppConfig(
        apiBaseUrl: 'https://example.test',
        apiPrefix: '',
      ),
    );
    dio.interceptors.add(authInterceptor);

    final response = await client.getJson('/public-data');

    expect(response['result'], {'source': 'anonymous'});
    expect(authInterceptor.requestCount, 2);
    expect(authInterceptor.authorizationHeaders, [
      'Bearer stale-access-token',
      null,
    ]);
    expect(tokenStore.didClear, isTrue);
    expect(tokenStore.access, isNull);
  });

  test('retries public list POST without stale auth', () async {
    final tokenStore = _MemoryTokenStore()..access = 'stale-access-token';
    final authInterceptor = _RetryableAuthInterceptor();
    final dio = Dio();
    final client = ApiClient(
      dio: dio,
      tokenStore: tokenStore,
      onAuthFailure: (error) async => tokenStore.clear(),
      config: const AppConfig(
        apiBaseUrl: 'https://example.test',
        apiPrefix: '',
      ),
    );
    dio.interceptors.add(authInterceptor);

    final response = await client.postJson(
      '/hero/gallery',
      body: const {'page': 1, 'pageSize': 1},
    );

    expect(response['result'], {'source': 'anonymous'});
    expect(authInterceptor.requestCount, 2);
    expect(authInterceptor.authorizationHeaders, [
      'Bearer stale-access-token',
      null,
    ]);
    expect(tokenStore.didClear, isTrue);
    expect(tokenStore.access, isNull);
  });
}
