import 'package:country_code/country_code.dart';
import 'package:country_flags/country_flags.dart' as flags;
import 'package:flutter/material.dart';

class RegionCountry {
  const RegionCountry({required this.regionCode, required this.isoCode});

  final int regionCode;
  final String isoCode;

  String get name => _countryNames[isoCode] ?? 'Country / region';

  String get label => name;

  String nameFor(Locale locale) {
    if (locale.languageCode == 'zh') {
      return _countryNamesZh[isoCode] ?? '国家/地区';
    }
    return name;
  }

  static RegionCountry? fromRegionCode(int regionCode) {
    if (regionCode <= 0) return null;
    final country = CountryCode.tryParse('$regionCode');
    final isoCode = country?.alpha2 ?? _dialingCodeFallback[regionCode];
    if (isoCode == null || isoCode.isEmpty) return null;
    return RegionCountry(regionCode: regionCode, isoCode: isoCode);
  }
}

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

const _countryNames = <String, String>{
  'AR': 'Argentina',
  'AU': 'Australia',
  'BR': 'Brazil',
  'BS': 'Bahamas',
  'CA': 'Canada',
  'CN': 'China',
  'CO': 'Colombia',
  'DE': 'Germany',
  'EG': 'Egypt',
  'ES': 'Spain',
  'FR': 'France',
  'GB': 'United Kingdom',
  'HN': 'Honduras',
  'HK': 'Hong Kong',
  'ID': 'Indonesia',
  'IN': 'India',
  'IT': 'Italy',
  'JP': 'Japan',
  'KR': 'South Korea',
  'MO': 'Macao',
  'MM': 'Myanmar',
  'MY': 'Malaysia',
  'MX': 'Mexico',
  'NZ': 'New Zealand',
  'PH': 'Philippines',
  'RU': 'Russia',
  'SG': 'Singapore',
  'TH': 'Thailand',
  'TR': 'Türkiye',
  'TW': 'Taiwan',
  'US': 'United States',
  'VN': 'Vietnam',
};

const _countryNamesZh = <String, String>{
  'AR': '阿根廷',
  'AU': '澳大利亚',
  'BR': '巴西',
  'BS': '巴哈马',
  'CA': '加拿大',
  'CN': '中国',
  'CO': '哥伦比亚',
  'DE': '德国',
  'EG': '埃及',
  'ES': '西班牙',
  'FR': '法国',
  'GB': '英国',
  'HN': '洪都拉斯',
  'HK': '中国香港',
  'ID': '印度尼西亚',
  'IN': '印度',
  'IT': '意大利',
  'JP': '日本',
  'KR': '韩国',
  'MO': '中国澳门',
  'MM': '缅甸',
  'MY': '马来西亚',
  'MX': '墨西哥',
  'NZ': '新西兰',
  'PH': '菲律宾',
  'RU': '俄罗斯',
  'SG': '新加坡',
  'TH': '泰国',
  'TR': '土耳其',
  'TW': '中国台湾',
  'US': '美国',
  'VN': '越南',
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
  final normalized = options.where((item) => item > 0).toSet().toList()..sort();
  return showModalBottomSheet<int>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _RegionCountrySheet(value: value, options: normalized),
  );
}

class _RegionCountrySheet extends StatefulWidget {
  const _RegionCountrySheet({required this.value, required this.options});

  final int value;
  final List<int> options;

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
    final countries = widget.options
        .map(RegionCountry.fromRegionCode)
        .whereType<RegionCountry>()
        .where(
          (country) =>
              query.isEmpty ||
              country.isoCode.contains(query) ||
              '${country.regionCode}'.contains(query) ||
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
