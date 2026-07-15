import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/world_map_region.dart';

void main() {
  test(
    'world map regions include web-compatible region ids and hero camps',
    () {
      expect(worldMapRegions, hasLength(9));
      expect(worldMapRegions.map((region) => region.id), contains('riluohai'));
      expect(
        worldMapRegions.map((region) => region.areaId),
        containsAll([0, 1, 2, 3, 4, 6, 7, 8, 9]),
      );

      final sunsetSea = worldMapRegions.firstWhere(
        (region) => region.id == 'riluohai',
      );
      expect(sunsetSea.name, 'Sunset Sea');
      expect(sunsetSea.heroCampIds, containsAll([166, 142, 146, 132]));
    },
  );

  test('attaches representative heroes by external hero id', () {
    final regions = attachWorldMapHeroes(const [
      HeroSummary(
        id: '1',
        heroId: '166',
        name: 'Yaria',
        avatar: 'https://example.test/yaria.png',
        title: 'Forest Child',
      ),
      HeroSummary(
        id: '2',
        heroId: '199',
        name: 'Lam',
        avatar: 'https://example.test/lam.png',
        title: 'Shark Blade',
      ),
    ]);

    final sunsetSea = regions.firstWhere((region) => region.id == 'riluohai');
    final greatRiver = regions.firstWhere((region) => region.id == 'daheliuyu');

    expect(sunsetSea.representativeHeroes.single.name, 'Yaria');
    expect(sunsetSea.representativeHeroes.single.heroId, '166');
    expect(greatRiver.representativeHeroes.single.name, 'Lam');
    expect(greatRiver.representativeHeroes.single.heroId, '199');
  });
}
