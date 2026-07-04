import 'package:flutter/material.dart';

import 'hero_summary.dart';

class WorldMapRegion {
  const WorldMapRegion({
    required this.id,
    required this.areaId,
    required this.name,
    required this.description,
    required this.color,
    required this.heroCampIds,
    this.representativeHeroes = const [],
  });

  final String id;
  final int areaId;
  final String name;
  final String description;
  final Color color;
  final List<int> heroCampIds;
  final List<HeroSummary> representativeHeroes;

  WorldMapRegion copyWithHeroes(List<HeroSummary> heroes) {
    return WorldMapRegion(
      id: id,
      areaId: areaId,
      name: name,
      description: description,
      color: color,
      heroCampIds: heroCampIds,
      representativeHeroes: heroes,
    );
  }
}

const worldMapRegions = [
  WorldMapRegion(
    id: 'riluohai',
    areaId: 6,
    name: 'Sunset Sea',
    description:
        'A coastal domain shaped by islands, trade winds, and sea legends.',
    color: Color(0xFF22D3EE),
    heroCampIds: [166, 142, 146, 132],
  ),
  WorldMapRegion(
    id: 'yunzhongmodi',
    areaId: 9,
    name: 'Cloud Desert',
    description:
        'A vast desert frontier where caravans, ruins, and ancient powers meet.',
    color: Color(0xFFF59E0B),
    heroCampIds: [153, 542, 508, 534, 548],
  ),
  WorldMapRegion(
    id: 'beihuang',
    areaId: 2,
    name: 'Northern Wastes',
    description:
        'A cold northern realm of warriors, beasts, and borderland myths.',
    color: Color(0xFF818CF8),
    heroCampIds: [177, 152, 193, 154, 167],
  ),
  WorldMapRegion(
    id: 'heluo',
    areaId: 7,
    name: 'Heluo',
    description:
        'The cultural heartland where dynasties, scholars, and guardians gather.',
    color: Color(0xFFF43F5E),
    heroCampIds: [],
  ),
  WorldMapRegion(
    id: 'jianmu',
    areaId: 0,
    name: 'Jianmu',
    description:
        'An ancient sacred place tied to towering trees and old divine records.',
    color: Color(0xFF64748B),
    heroCampIds: [179],
  ),
  WorldMapRegion(
    id: 'daheliuyu',
    areaId: 3,
    name: 'Great River Basin',
    description:
        'A fertile river region that connects settlements, stories, and battles.',
    color: Color(0xFF10B981),
    heroCampIds: [131, 199],
  ),
  WorldMapRegion(
    id: 'zhulu',
    areaId: 1,
    name: 'Zhuolu',
    description:
        'A contested land remembered for campaigns, alliances, and rival clans.',
    color: Color(0xFF2563EB),
    heroCampIds: [187, 110, 116],
  ),
  WorldMapRegion(
    id: 'sanfenzhidi',
    areaId: 4,
    name: 'Three Kingdoms',
    description:
        'A strategic domain of competing powers, tacticians, and sworn heroes.',
    color: Color(0xFFA855F7),
    heroCampIds: [149, 135, 190, 113, 118, 137, 191],
  ),
  WorldMapRegion(
    id: 'dongfenghaiyu',
    areaId: 8,
    name: 'Eastern Wind Sea',
    description:
        'An eastern maritime region of storms, voyages, and distant legends.',
    color: Color(0xFFFB7185),
    heroCampIds: [130],
  ),
];

List<WorldMapRegion> attachWorldMapHeroes(List<HeroSummary> heroes) {
  final heroesByCampId = <String, HeroSummary>{};
  for (final hero in heroes) {
    final campId = hero.heroId.isNotEmpty ? hero.heroId : hero.id;
    if (campId.isNotEmpty) {
      heroesByCampId[campId] = hero;
    }
  }

  return worldMapRegions
      .map((region) {
        final representatives = region.heroCampIds
            .map((campId) => heroesByCampId['$campId'])
            .whereType<HeroSummary>()
            .toList(growable: false);
        return region.copyWithHeroes(representatives);
      })
      .toList(growable: false);
}
