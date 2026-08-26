import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

enum NativeGoogleSignInStatus { authenticated, cancelled, unavailable }

class NativeGoogleSignInResult {
  const NativeGoogleSignInResult._(this.status, this.idToken, this.error);

  const NativeGoogleSignInResult.authenticated(String idToken)
    : this._(NativeGoogleSignInStatus.authenticated, idToken, null);

  const NativeGoogleSignInResult.cancelled([String? error])
    : this._(NativeGoogleSignInStatus.cancelled, null, error);

  const NativeGoogleSignInResult.unavailable([String? error])
    : this._(NativeGoogleSignInStatus.unavailable, null, error);

  final NativeGoogleSignInStatus status;
  final String? idToken;
  final String? error;
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
        return const NativeGoogleSignInResult.unavailable(
          'Google returned no ID token; check the Android OAuth client and signing certificate.',
        );
      }
      return NativeGoogleSignInResult.authenticated(idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        // Credential Manager reports a provider-configuration failure as
        // "canceled" on some Android versions. Preserve the detail so the
        // login screen can fall back to web OAuth instead of ending silently.
        final detail = error.description?.trim();
        return NativeGoogleSignInResult.cancelled(
          detail == null || detail.isEmpty
              ? 'Google account selection was cancelled or the Android OAuth client is not configured.'
              : 'Google sign-in returned canceled: $detail',
        );
      }
      return NativeGoogleSignInResult.unavailable(
        'Google sign-in failed (${error.code.name}): '
        '${error.description ?? 'check the Android OAuth client configuration'}',
      );
    } catch (error) {
      return NativeGoogleSignInResult.unavailable(
        'Google sign-in failed: $error',
      );
    }
  }
}
