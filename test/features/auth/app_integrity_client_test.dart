import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/auth/data/app_integrity_client.dart';

void main() {
  test('uses stable sorted JSON for request hashes', () {
    final expected = sha256
        .convert(
          utf8.encode(
            '{"action":"email_register","code":"123456","email":"user@example.test","username":"new-user"}',
          ),
        )
        .toString();

    final actual = AppIntegrityClient.computeRequestHash('email_register', {
      'username': 'new-user',
      'email': 'user@example.test',
      'code': '123456',
    });

    expect(actual, expected);
  });

  test('serializes non-ascii request values as UTF-8', () {
    final first = AppIntegrityClient.computeRequestHash('email_register', {
      'email': '用户@example.test',
      'username': '玩家',
      'code': '123456',
    });
    final second = AppIntegrityClient.computeRequestHash('email_register', {
      'code': '123456',
      'username': '玩家',
      'email': '用户@example.test',
    });

    expect(first, second);
    expect(
      first,
      '857ea067194afe3b06ace4ea2196f28b8b4a8a5b5ae40b8d7ec4c94d6dc7d4c0',
    );
  });
}
