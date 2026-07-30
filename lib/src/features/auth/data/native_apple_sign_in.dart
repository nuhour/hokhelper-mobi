import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum NativeAppleSignInStatus { authenticated, cancelled, unavailable }

class NativeAppleSignInResult {
  const NativeAppleSignInResult._({
    required this.status,
    this.identityToken,
    this.rawNonce,
    this.name,
    this.error,
  });

  const NativeAppleSignInResult.authenticated({
    required String identityToken,
    required String rawNonce,
    String? name,
  }) : this._(
         status: NativeAppleSignInStatus.authenticated,
         identityToken: identityToken,
         rawNonce: rawNonce,
         name: name,
       );

  const NativeAppleSignInResult.cancelled()
    : this._(status: NativeAppleSignInStatus.cancelled);

  const NativeAppleSignInResult.unavailable([String? error])
    : this._(status: NativeAppleSignInStatus.unavailable, error: error);

  final NativeAppleSignInStatus status;
  final String? identityToken;
  final String? rawNonce;
  final String? name;
  final String? error;
}

abstract class NativeAppleSignIn {
  Future<NativeAppleSignInResult> authenticate();
}

class AppleFrameworkSignIn implements NativeAppleSignIn {
  @override
  Future<NativeAppleSignInResult> authenticate() async {
    if (!Platform.isIOS || !await SignInWithApple.isAvailable()) {
      return const NativeAppleSignInResult.unavailable();
    }

    final rawNonce = generateNonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final identityToken = credential.identityToken?.trim();
      if (identityToken == null || identityToken.isEmpty) {
        return const NativeAppleSignInResult.unavailable(
          'Apple did not return an identity token',
        );
      }
      final name = [
        credential.givenName?.trim(),
        credential.familyName?.trim(),
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
      return NativeAppleSignInResult.authenticated(
        identityToken: identityToken,
        rawNonce: rawNonce,
        name: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const NativeAppleSignInResult.cancelled();
      }
      return NativeAppleSignInResult.unavailable(error.message);
    } on SignInWithAppleException catch (error) {
      return NativeAppleSignInResult.unavailable(error.toString());
    }
  }
}
