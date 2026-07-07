import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/routing/portal_link.dart';

void main() {
  test('normalizes legacy community post links to mobile content routes', () {
    expect(
      normalizePortalLinkTarget('/community/post/42'),
      '/content/community/post/42',
    );
    expect(
      normalizePortalLinkTarget('https://hok.example/#/community/post/42'),
      '/content/community/post/42',
    );
  });
}
