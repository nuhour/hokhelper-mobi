import 'package:dio/dio.dart';
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

void main() {
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
}
