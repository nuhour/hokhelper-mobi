import 'package:country_code/country_code.dart';
import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:country_flags/country_flags.dart' as flags;
import 'package:flutter/material.dart';

class RegionCountry {
  const RegionCountry({required this.regionCode, required this.isoCode});

  final int regionCode;
  final String isoCode;

  /// 完整 ISO 目录来自 country_picker，同时合并后端选项以保留自定义/旧编码。
  static final List<RegionCountry> all = _buildCatalog();

  String get name => _countryByIso[isoCode]?.name ?? 'Country / region';

  String get label => name;

  String nameFor(Locale locale) {
    return country_picker.CountryLocalizations(
          locale,
        ).countryName(countryCode: isoCode) ??
        name;
  }

  String get phoneCode => _countryByIso[isoCode]?.phoneCode ?? '';

  static List<RegionCountry> _buildCatalog() {
    return _countryByIso.values
        .map((country) {
          final numeric = CountryCode.tryParse(country.countryCode)?.numeric;
          if (numeric == null || numeric <= 0) return null;
          return RegionCountry(
            regionCode: numeric,
            isoCode: country.countryCode,
          );
        })
        .whereType<RegionCountry>()
        .toList(growable: false);
  }

  static RegionCountry? fromRegionCode(int regionCode) {
    if (regionCode <= 0) return null;
    final country = CountryCode.tryParse('$regionCode');
    final isoCode = country?.alpha2 ?? _dialingCodeFallback[regionCode];
    if (isoCode == null ||
        isoCode.isEmpty ||
        !_countryByIso.containsKey(isoCode)) {
      return null;
    }
    return RegionCountry(regionCode: regionCode, isoCode: isoCode);
  }
}

final _countryByIso = <String, country_picker.Country>{
  for (final country in country_picker.CountryService().getAll())
    country.countryCode: country,
};

const _dialingCodeFallback = <int, String>{
  1: 'US',
  7: 'RU',
  20: 'EG',
  33: 'FR',
  34: 'ES',
  39: 'IT',
  44: 'GB',
  49: 'DE',
  52: 'MX',
  54: 'AR',
  55: 'BR',
  57: 'CO',
  60: 'MY',
  61: 'AU',
  62: 'ID',
  63: 'PH',
  64: 'NZ',
  65: 'SG',
  66: 'TH',
  81: 'JP',
  82: 'KR',
  84: 'VN',
  86: 'CN',
  90: 'TR',
  91: 'IN',
  95: 'MM',
  852: 'HK',
  853: 'MO',
  886: 'TW',
};

class RegionFlag extends StatelessWidget {
  const RegionFlag({required this.regionCode, this.width = 24, super.key});

  final int regionCode;
  final double width;

  @override
  Widget build(BuildContext context) {
    final country = RegionCountry.fromRegionCode(regionCode);
    if (country == null) {
      return Icon(
        Icons.public_rounded,
        size: width,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return flags.CountryFlag.fromCountryCode(
      country.isoCode,
      theme: flags.ImageTheme(
        width: width,
        height: width * 0.68,
        shape: const flags.RoundedRectangle(3),
      ),
    );
  }
}

class RegionCountryPicker extends StatelessWidget {
  const RegionCountryPicker({
    required this.value,
    required this.options,
    required this.onChanged,
    this.expanded = false,
    super.key,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final selected = RegionCountry.fromRegionCode(value);
    final locale = Localizations.localeOf(context);
    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        RegionFlag(regionCode: value, width: 23),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            selected?.nameFor(locale) ?? 'Global',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(Icons.expand_more_rounded, size: 18),
      ],
    );
    return OutlinedButton(
      onPressed: () async {
        final next = await showRegionCountryPicker(
          context,
          value: value,
          options: options,
        );
        if (next != null && next != value) onChanged(next);
      },
      style: OutlinedButton.styleFrom(
        minimumSize: expanded ? const Size.fromHeight(48) : const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
      ),
      child: content,
    );
  }
}

Future<int?> showRegionCountryPicker(
  BuildContext context, {
  required int value,
  required List<int> options,
}) async {
  final countriesByIso = <String, RegionCountry>{};
  for (final regionCode in <int>[value, ...options]) {
    final country = RegionCountry.fromRegionCode(regionCode);
    if (country != null) {
      countriesByIso[country.isoCode] = country;
    }
  }
  for (final country in RegionCountry.all) {
    countriesByIso.putIfAbsent(country.isoCode, () => country);
  }
  return showModalBottomSheet<int>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _RegionCountrySheet(
      value: value,
      countries: countriesByIso.values.toList(growable: false),
    ),
  );
}

class _RegionCountrySheet extends StatefulWidget {
  const _RegionCountrySheet({required this.value, required this.countries});

  final int value;
  final List<RegionCountry> countries;

  @override
  State<_RegionCountrySheet> createState() => _RegionCountrySheetState();
}

class _RegionCountrySheetState extends State<_RegionCountrySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toUpperCase();
    final locale = Localizations.localeOf(context);
    final countries = widget.countries
        .where(
          (country) =>
              query.isEmpty ||
              country.isoCode.contains(query) ||
              '${country.regionCode}'.contains(query) ||
              country.phoneCode.contains(query) ||
              country.nameFor(locale).toUpperCase().contains(query),
        )
        .toList(growable: false);
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  'Country / region',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _controller,
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Search ISO code or region code',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: countries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const RegionFlag(regionCode: 0),
                    title: const Text('Global'),
                    trailing: widget.value == 0
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(context, 0),
                  );
                }
                final country = countries[index - 1];
                return ListTile(
                  leading: RegionFlag(regionCode: country.regionCode),
                  title: Text(country.nameFor(locale)),
                  trailing: widget.value == country.regionCode
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(context, country.regionCode),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
