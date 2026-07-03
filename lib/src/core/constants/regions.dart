enum HokRegion {
  cn(1, 'zh', 'China'),
  en(2, 'en', 'English'),
  id(3, 'id', 'Indonesia');

  const HokRegion(this.regionId, this.languageCode, this.label);

  final int regionId;
  final String languageCode;
  final String label;
}

extension HokRegionId on HokRegion {
  int get id => regionId;
}

HokRegion hokRegionFromId(int regionId) {
  for (final region in HokRegion.values) {
    if (region.id == regionId) {
      return region;
    }
  }

  return HokRegion.en;
}
