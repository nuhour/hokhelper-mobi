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
    expect(normalizePortalLinkTarget('/hero-gallery'), '/heroes');
    expect(
      normalizePortalLinkTarget('/hero-gallery?hero_id=101'),
      '/heroes/101',
    );
    expect(
      normalizePortalLinkTarget('/hero-gallery/101?tab=history'),
      '/heroes/101?tab=history',
    );
    expect(
      normalizePortalLinkTarget('/builds?hero_id=166'),
      '/tools/builds?hero_id=166',
    );
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
    expect(
      normalizePortalLinkTarget('/community/leaks?q=Lam'),
      '/content/community?tab=leaks&q=Lam',
    );
    expect(
      normalizePortalLinkTarget('/stats?entry=equip_rank&equip_id=88'),
      '/tools/stats?entry=equip_rank&equip_id=88',
    );
    expect(
      normalizePortalLinkTarget('/stats?entry=hero_trend&hero_id=101'),
      '/trends?hero_id=101',
    );
    expect(
      normalizePortalLinkTarget('/rankings?lane=mid'),
      '/tools/rankings?lane=mid',
    );
    expect(
      normalizePortalLinkTarget('/prompts?tab=favorites'),
      '/tools/prompts?tab=favorites',
    );
  });

  test('normalizes media gallery detail query links', () {
    expect(
      normalizePortalLinkTarget('/skin-gallery?skin_id=1001&q=Lam'),
      '/skin-gallery/1001?q=Lam',
    );
    expect(
      normalizePortalLinkTarget('https://hok.example/#/cg?cg_id=501'),
      '/cg/501',
    );
  });

  test('normalizes absolute hokx portal URLs to mobile internal routes', () {
    expect(
      normalizePortalLinkTarget(
        'https://www.hok-helper.com/hero-gallery/101?tab=history',
      ),
      '/heroes/101?tab=history',
    );
    expect(
      normalizePortalLinkTarget(
        'https://www.hok-helper.com/stats?entry=hero_trend&hero_id=101',
      ),
      '/trends?hero_id=101',
    );
    expect(
      normalizePortalLinkTarget('https://external.example/hero-gallery/101'),
      'https://external.example/hero-gallery/101',
    );
  });

  test('normalizes localized hokx portal paths to mobile routes', () {
    expect(
      normalizePortalLinkTarget('/en/hero-gallery/101?tab=history'),
      '/heroes/101?tab=history',
    );
    expect(
      normalizePortalLinkTarget('/zh/community/post/42'),
      '/content/community/post/42',
    );
    expect(
      normalizePortalLinkTarget(
        'https://www.hok-helper.com/id/stats?entry=hero_trend&hero_id=101',
      ),
      '/trends?hero_id=101',
    );
    expect(
      normalizePortalLinkTarget('https://external.example/en/hero-gallery/101'),
      'https://external.example/en/hero-gallery/101',
    );
  });

  test('normalizes hok world topic aliases to article routes', () {
    expect(
      normalizePortalLinkTarget('/honor-of-kings-world-tier-list'),
      '/hok-world/hok-world-tier-list',
    );
    expect(
      normalizePortalLinkTarget('/zh/hok-world-tier-list'),
      '/hok-world/hok-world-tier-list',
    );
    expect(
      normalizePortalLinkTarget(
        'https://www.hok-helper.com/en/honor-of-kings-world-tier-list',
      ),
      '/hok-world/hok-world-tier-list',
    );
  });
}
