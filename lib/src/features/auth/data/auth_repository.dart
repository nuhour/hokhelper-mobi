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
    if (json['success'] == false) {
      throw ApiError(
        kind: ApiErrorKind.backend,
        message: _readFailureMessage(json),
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

  Future<void> logout() {
    return tokenStore.clear();
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

  String _readFailureMessage(Map<String, dynamic> json) {
    final value = json['message'] ?? json['msg'];
    if (value == null || value.toString().isEmpty) {
      return 'Login failed';
    }

    return value.toString();
  }
}
