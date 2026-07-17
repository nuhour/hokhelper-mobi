import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/widgets/region_country_picker.dart';

void main() {
  test('maps ISO numeric regions before dialing-code fallbacks', () {
    expect(RegionCountry.fromRegionCode(826)?.isoCode, 'GB');
    expect(RegionCountry.fromRegionCode(840)?.isoCode, 'US');
    expect(RegionCountry.fromRegionCode(156)?.isoCode, 'CN');
    expect(RegionCountry.fromRegionCode(44)?.isoCode, 'BS');
    expect(RegionCountry.fromRegionCode(62)?.isoCode, 'ID');
  });
}
