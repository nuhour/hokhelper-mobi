enum HokRegion {
  cn(1, 'zh', 'China'),
  en(2, 'en', 'English'),
  id(3, 'id', 'Indonesia'),
  fil(4, 'fil', 'Filipino'),
  pt(5, 'pt', 'Portuguese (Brazil)'),
  es(6, 'es', 'Spanish'),
  ar(7, 'ar', 'Arabic'),
  ru(8, 'ru', 'Russian'),
  ms(9, 'ms', 'Malay');

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

HokRegion hokRegionFromLanguageCode(String languageCode) {
  return switch (languageCode) {
    'zh' => HokRegion.cn,
    'id' => HokRegion.id,
    'fil' => HokRegion.fil,
    'pt' => HokRegion.pt,
    'es' => HokRegion.es,
    'ar' => HokRegion.ar,
    'ru' => HokRegion.ru,
    'ms' => HokRegion.ms,
    _ => HokRegion.en,
  };
}
