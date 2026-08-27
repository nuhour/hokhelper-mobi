import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';

class AppIntegrityProof {
  const AppIntegrityProof({
    required this.provider,
    required this.token,
    required this.requestHash,
  });

  final String provider;
  final String token;
  final String requestHash;

  Map<String, String> toJson() => {
    'provider': provider,
    'token': token,
    'request_hash': requestHash,
  };
}

class AppIntegrityException implements Exception {
  const AppIntegrityException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppIntegrityClient {
  AppIntegrityClient({MethodChannel? channel, this.config = AppConfig.current})
    : _channel = channel ?? const MethodChannel('hokhelper/integrity');

  static final instance = AppIntegrityClient();

  final MethodChannel _channel;
  final AppConfig config;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> prepare() async {
    if (!isSupported) {
      return;
    }
    final projectNumber = _projectNumber;
    if (projectNumber == null) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('prepare', {
        'cloudProjectNumber': projectNumber,
      });
    } catch (_) {
      // 预热失败不阻断页面启动；真正请求令牌时会重新尝试并返回明确错误。
    }
  }

  Future<AppIntegrityProof?> getProof({
    required String action,
    required Map<String, String> values,
  }) async {
    if (!isSupported) {
      return null;
    }

    final projectNumber = _projectNumber;
    if (projectNumber == null) {
      throw const AppIntegrityException(
        'App integrity is not configured for this build',
      );
    }

    final requestHash = computeRequestHash(action, values);
    try {
      final raw = await _channel.invokeMethod<Object?>('getToken', {
        'cloudProjectNumber': projectNumber,
        'requestHash': requestHash,
      });
      if (raw is! Map) {
        throw const AppIntegrityException('App integrity token is missing');
      }

      final provider = raw['provider']?.toString().trim() ?? '';
      final token = raw['token']?.toString().trim() ?? '';
      final nativeRequestHash = raw['requestHash']?.toString().trim() ?? '';
      if (provider.isEmpty || token.isEmpty || nativeRequestHash.isEmpty) {
        throw const AppIntegrityException('App integrity token is incomplete');
      }
      if (nativeRequestHash != requestHash) {
        throw const AppIntegrityException(
          'App integrity request hash mismatch',
        );
      }

      return AppIntegrityProof(
        provider: provider,
        token: token,
        requestHash: nativeRequestHash,
      );
    } on PlatformException catch (error) {
      throw AppIntegrityException(
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'App integrity verification is unavailable',
      );
    } on MissingPluginException {
      throw const AppIntegrityException(
        'App integrity verification is unavailable',
      );
    }
  }

  static String computeRequestHash(String action, Map<String, String> values) {
    final payload = <String, Object?>{'action': action, ...values};
    final serialized = jsonEncode(_sortJsonValue(payload));
    return sha256.convert(utf8.encode(serialized)).toString();
  }

  static Object? _sortJsonValue(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _sortJsonValue(value[key]),
      };
    }
    if (value is Iterable) {
      return value.map(_sortJsonValue).toList(growable: false);
    }
    return value;
  }

  int? get _projectNumber {
    final value = int.tryParse(config.playIntegrityProjectNumber.trim());
    return value == null || value <= 0 ? null : value;
  }
}
