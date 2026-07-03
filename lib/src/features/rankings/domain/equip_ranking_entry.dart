class EquipRankingEntry {
  const EquipRankingEntry({
    required this.equipId,
    required this.name,
    required this.pickRate,
    required this.winRate,
  });

  final int equipId;
  final String name;
  final double pickRate;
  final double winRate;

  factory EquipRankingEntry.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final stats = map['stats'] is Map ? map['stats'] as Map : map;

    return EquipRankingEntry(
      equipId: _readInt(map['equip_id']),
      name: _readString(map['equip_name'], fallback: 'Equipment'),
      pickRate: _readRate(stats['pick_rate']),
      winRate: _readRate(stats['win_rate']),
    );
  }
}

double _readRate(Object? value) {
  final rate = _readDouble(value);
  return rate > 1 ? rate / 100 : rate;
}

double _readDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
