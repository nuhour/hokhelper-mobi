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

  test('normalizes hokx web aliases to mobile shell routes', () {
    expect(
      normalizePortalLinkTarget('#/build-sim?hero_id=101&scheme=22'),
      '/tools/build-sim?hero_id=101&scheme=22',
    );
    expect(
      normalizePortalLinkTarget('https://hok.example/#/bp-simulator'),
      '/tools/bp-simulator',
    );
    expect(
      normalizePortalLinkTarget('/event-assistance'),
      '/content/event-assistance',
    );
    expect(
      normalizePortalLinkTarget('/patch-notes?note_id=31'),
      '/content/patch-notes?note_id=31',
    );
  });
}
