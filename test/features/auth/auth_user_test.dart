import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';

void main() {
  group('AuthUser', () {
    test('parses snake case and camel case profile fields', () {
      final snakeCaseUser = AuthUser.fromJson({
        'id': '12',
        'username': 'mulan',
        'email': 'mulan@example.test',
        'display_name': 'Mulan',
        'avatar': 'https://example.test/mulan.png',
      });
      final camelCaseUser = AuthUser.fromJson({
        'id': 13,
        'username': 'diaochan',
        'email': 'diaochan@example.test',
        'displayName': 'Diao Chan',
        'avatar_url': 'https://example.test/diaochan.png',
      });

      expect(snakeCaseUser.id, 12);
      expect(snakeCaseUser.displayName, 'Mulan');
      expect(snakeCaseUser.avatar, 'https://example.test/mulan.png');
      expect(camelCaseUser.id, 13);
      expect(camelCaseUser.displayName, 'Diao Chan');
      expect(camelCaseUser.avatar, 'https://example.test/diaochan.png');
    });
  });
}
