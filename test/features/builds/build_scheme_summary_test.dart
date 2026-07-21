import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_scheme_summary.dart';

void main() {
  test('resolves build asset ids and backend count aliases', () {
    final scheme = BuildSchemeSummary.fromJson({
      'id': 7,
      'name': 'Anti-Tank',
      'equips': [101, 102],
      'runes': [201, 202],
      'summoner_skill_id': 80115,
      'likes_count': 4,
      'favorites_count': 3,
      'clones_count': 2,
    });

    expect(scheme.equipmentIcons, [
      '/static/game/equip/101.png',
      '/static/game/equip/102.png',
    ]);
    expect(scheme.runeIcons, [
      '/static/game/rune/201.png',
      '/static/game/rune/202.png',
    ]);
    expect(scheme.summonerSkillIcon, '/static/game/summoner_skill/80115.png');
    expect(scheme.likeCount, 4);
    expect(scheme.favoriteCount, 3);
    expect(scheme.cloneCount, 2);
  });

  test('prefers explicit equipment icons when the backend provides them', () {
    final scheme = BuildSchemeSummary.fromJson({
      'id': 8,
      'equips': [
        {'equip_id': 101, 'icon_url': 'https://cdn.test/equip.png'},
      ],
    });

    expect(scheme.equipmentIcons, ['https://cdn.test/equip.png']);
    expect(scheme.equipmentIds, [101]);
  });
}
