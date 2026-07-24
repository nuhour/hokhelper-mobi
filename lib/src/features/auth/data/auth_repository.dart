import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_error.dart';
import '../../../core/storage/secure_token_store.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository({required this.apiClient, required this.tokenStore});

  final ApiClient apiClient;
  final SecureTokenStore tokenStore;

  Future<AuthUser> loginWithEmail(String email, String password) async {
    final json = await apiClient.postJson(
      '/auth/email/login',
      body: {'email': email, 'password': password},
    );

    return _readAuthResponse(json, fallbackMessage: 'Login failed');
  }

  Future<AuthUser> loginWithOAuth({
    required String provider,
    required String code,
    required String redirectUri,
  }) async {
    final normalizedProvider = provider.trim().toLowerCase();
    if (!{'google', 'discord', 'reddit'}.contains(normalizedProvider)) {
      throw const ApiError(
        kind: ApiErrorKind.backend,
        message: 'Unsupported OAuth provider',
      );
    }

    final json = await apiClient.postJson(
      '/auth/$normalizedProvider/login',
      body: {'code': code, 'redirect_uri': redirectUri},
    );

    return _readAuthResponse(json, fallbackMessage: 'OAuth login failed');
  }

  Future<String> getOAuthAuthorizationUrl({
    required String provider,
    required String redirectUri,
    required String state,
  }) async {
    final normalizedProvider = provider.trim().toLowerCase();
    if (!{'google', 'discord'}.contains(normalizedProvider)) {
      throw const ApiError(
        kind: ApiErrorKind.backend,
        message: 'Unsupported OAuth provider',
      );
    }

    final json = await apiClient.postJson(
      '/auth/$normalizedProvider/auth_url',
      body: {'redirect_uri': redirectUri, 'state': state},
    );
    final result = json['result'];
    final payload = result is Map ? Map<String, dynamic>.from(result) : json;
    final authUrl = payload['auth_url']?.toString().trim() ?? '';
    if (authUrl.isEmpty) {
      throw const ApiError(
        kind: ApiErrorKind.backend,
        message: 'OAuth authorization URL is missing',
      );
    }

    return authUrl;
  }

  Future<void> sendRegisterCode({
    required String email,
    required String turnstileToken,
  }) {
    return _postVoid(
      '/auth/email/send_register_code',
      body: {'email': email, 'turnstile_token': turnstileToken},
      fallbackMessage: 'Failed to send verification code',
    );
  }

  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String code,
    String? username,
  }) async {
    final body = <String, String>{
      'email': email,
      'password': password,
      'code': code,
      if (username != null && username.isNotEmpty) 'username': username,
    };
    final json = await apiClient.postJson('/auth/email/register', body: body);

    return _readAuthResponse(json, fallbackMessage: 'Registration failed');
  }

  Future<void> sendVerificationCode(String email) {
    return _postVoid(
      '/auth/email/send_verification_code',
      body: {'email': email},
      fallbackMessage: 'Failed to send verification code',
    );
  }

  Future<void> verifyCode({required String email, required String code}) {
    return _postVoid(
      '/auth/email/verify_code',
      body: {'email': email, 'code': code},
      fallbackMessage: 'Invalid verification code',
    );
  }

  Future<void> resetForgottenPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _postVoid(
      '/auth/email/forgot_password_reset',
      body: {'email': email, 'code': code, 'new_password': newPassword},
      fallbackMessage: 'Failed to reset password',
    );
  }

  Future<void> logout() {
    return tokenStore.clear();
  }

  Future<void> _postVoid(
    String path, {
    required Object body,
    required String fallbackMessage,
  }) async {
    final json = await apiClient.postJson(path, body: body);
    if (json['success'] == false) {
      throw ApiError(
        kind: ApiErrorKind.backend,
        message: _readFailureMessage(json, fallbackMessage),
      );
    }
  }

  Future<AuthUser> _readAuthResponse(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) async {
    if (json['success'] == false) {
      throw ApiError(
        kind: ApiErrorKind.backend,
        message: _readFailureMessage(json, fallbackMessage),
      );
    }
    final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
      json,
      (result) => Map<String, dynamic>.from(result! as Map),
    );
    final payload = envelope.result ?? json;
    final access = _readRequiredString(payload, 'access');
    final refresh = _readRequiredString(payload, 'refresh');
    final userJson = payload['user'];

    if (userJson is! Map) {
      throw const ApiError(
        kind: ApiErrorKind.backend,
        message: 'Login response is missing user',
      );
    }

    await tokenStore.saveTokens(access: access, refresh: refresh);
    return AuthUser.fromJson(Map<String, dynamic>.from(userJson));
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value.toString().isEmpty) {
      throw ApiError(
        kind: ApiErrorKind.backend,
        message: 'Login response is missing $key',
      );
    }

    return value.toString();
  }

  String _readFailureMessage(Map<String, dynamic> json, String fallback) {
    final value = json['message'] ?? json['msg'];
    if (value == null || value.toString().isEmpty) {
      return fallback;
    }

    return value.toString();
  }
}
