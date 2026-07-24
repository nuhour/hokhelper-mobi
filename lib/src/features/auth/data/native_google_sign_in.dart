import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

enum NativeGoogleSignInStatus { authenticated, cancelled, unavailable }

class NativeGoogleSignInResult {
  const NativeGoogleSignInResult._(this.status, this.idToken);

  const NativeGoogleSignInResult.authenticated(String idToken)
    : this._(NativeGoogleSignInStatus.authenticated, idToken);

  const NativeGoogleSignInResult.cancelled()
    : this._(NativeGoogleSignInStatus.cancelled, null);

  const NativeGoogleSignInResult.unavailable()
    : this._(NativeGoogleSignInStatus.unavailable, null);

  final NativeGoogleSignInStatus status;
  final String? idToken;
}

abstract class NativeGoogleSignIn {
  Future<NativeGoogleSignInResult> authenticate({
    required String serverClientId,
  });
}

class GoogleFrameworkSignIn implements NativeGoogleSignIn {
  String? _initializedServerClientId;

  @override
  Future<NativeGoogleSignInResult> authenticate({
    required String serverClientId,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const NativeGoogleSignInResult.unavailable();
    }

    final clientId = serverClientId.trim();
    if (clientId.isEmpty) {
      return const NativeGoogleSignInResult.unavailable();
    }

    final signIn = GoogleSignIn.instance;
    try {
      if (_initializedServerClientId != clientId) {
        await signIn.initialize(serverClientId: clientId);
        _initializedServerClientId = clientId;
      }
      if (!signIn.supportsAuthenticate()) {
        return const NativeGoogleSignInResult.unavailable();
      }

      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken?.trim();
      if (idToken == null || idToken.isEmpty) {
        return const NativeGoogleSignInResult.unavailable();
      }
      return NativeGoogleSignInResult.authenticated(idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const NativeGoogleSignInResult.cancelled();
      }
      return const NativeGoogleSignInResult.unavailable();
    } catch (_) {
      return const NativeGoogleSignInResult.unavailable();
    }
  }
}
