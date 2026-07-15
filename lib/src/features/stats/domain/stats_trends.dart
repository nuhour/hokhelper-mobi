const _unsetTrendFilter = Object();

class StatsTrendQuery {
  const StatsTrendQuery({
    this.dimension = 'hero_rank',
    this.baseline = 'peak_1000',
    this.view = 'base',
    this.windowDays = 999,
    this.snapshotDate = '',
    this.region = '',
    this.equipType = '',
    this.lanePosition,
  });

  final String dimension;
  final String baseline;
  final String view;
  final int windowDays;
  final String snapshotDate;
  final String region;
  final String equipType;
  final int? lanePosition;

  StatsTrendQuery copyWith({
    String? dimension,
    String? baseline,
    String? view,
    int? windowDays,
    String? snapshotDate,
    String? region,
    String? equipType,
    Object? lanePosition = _unsetTrendFilter,
  }) {
    return StatsTrendQuery(
      dimension: dimension ?? this.dimension,
      baseline: baseline ?? this.baseline,
      view: view ?? this.view,
      windowDays: windowDays ?? this.windowDays,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      region: region ?? this.region,
      equipType: equipType ?? this.equipType,
      lanePosition: identical(lanePosition, _unsetTrendFilter)
          ? this.lanePosition
          : lanePosition as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StatsTrendQuery &&
        other.dimension == dimension &&
        other.baseline == baseline &&
        other.view == view &&
        other.windowDays == windowDays &&
        other.snapshotDate == snapshotDate &&
        other.region == region &&
        other.equipType == equipType &&
        other.lanePosition == lanePosition;
  }

  @override
  int get hashCode => Object.hash(
    dimension,
    baseline,
    view,
    windowDays,
    snapshotDate,
    region,
    equipType,
    lanePosition,
  );
}

class StatsTrendColumn {
  const StatsTrendColumn({
    required this.id,
    required this.label,
    required this.type,
    required this.sortable,
    required this.group,
  });

  final String id;
  final String label;
  final String type;
  final bool sortable;
  final String group;

  bool get isIdentity =>
      const {'hero', 'player', 'equip', 'team'}.contains(type);
  bool get isSparkline => type == 'sparkline';

  factory StatsTrendColumn.fromJson(Object? value) {
    final json = _map(value);
    return StatsTrendColumn(
      id: _string(json['id']),
      label: _string(json['label']),
      type: _string(json['type']),
      sortable: json['sortable'] == true,
      group: _string(json['group']),
    );
  }
}

class StatsTrendView {
  const StatsTrendView({required this.id, required this.label});

  final String id;
  final String label;

  factory StatsTrendView.fromJson(Object? value) {
    final json = _map(value);
    return StatsTrendView(
      id: _string(json['id']),
      label: _string(json['label']).isEmpty
          ? _string(json['id'])
          : _string(json['label']),
    );
  }
}

class StatsTrendTable {
  const StatsTrendTable({
    required this.dimension,
    required this.baseline,
    required this.view,
    required this.columns,
    required this.rows,
    required this.availableViews,
    required this.availableBaselines,
    required this.availableWindowDays,
    required this.availableSnapshotDates,
    required this.latestSnapshotDate,
    required this.dataRange,
    required this.patchVersion,
    required this.sampleSize,
  });

  final String dimension;
  final String baseline;
  final String view;
  final List<StatsTrendColumn> columns;
  final List<StatsTrendRow> rows;
  final List<StatsTrendView> availableViews;
  final List<String> availableBaselines;
  final List<int> availableWindowDays;
  final List<String> availableSnapshotDates;
  final String latestSnapshotDate;
  final String dataRange;
  final String patchVersion;
  final int sampleSize;

  List<String> get metricGroups {
    final groups = <String>[];
    for (final column in columns) {
      if (column.isIdentity || column.isSparkline || column.group.isEmpty) {
        continue;
      }
      if (!groups.contains(column.group)) {
        groups.add(column.group);
      }
    }
    return groups;
  }

  factory StatsTrendTable.fromJson(Object? value) {
    final json = _map(value);
    final meta = _map(json['meta']);
    return StatsTrendTable(
      dimension: _string(json['dimension']),
      baseline: _string(json['baseline']),
      view: _string(json['view']),
      columns: _list(json['columns'])
          .map(StatsTrendColumn.fromJson)
          .where((column) => column.id.isNotEmpty)
          .toList(growable: false),
      rows: _list(
        json['rows'],
      ).map(StatsTrendRow.fromJson).toList(growable: false),
      availableViews: _list(json['available_views'])
          .map(StatsTrendView.fromJson)
          .where((view) => view.id.isNotEmpty)
          .toList(growable: false),
      availableBaselines: _list(
        json['available_baselines'],
      ).map(_string).where((item) => item.isNotEmpty).toList(growable: false),
      availableWindowDays: _list(
        json['available_window_days'],
      ).map(_integer).where((item) => item > 0).toList(growable: false),
      availableSnapshotDates: _list(
        meta['available_snapshot_dates'],
      ).map(_string).where((item) => item.isNotEmpty).toList(growable: false),
      latestSnapshotDate: _string(meta['latest_snapshot_date']),
      dataRange: _string(meta['data_range']),
      patchVersion: _string(meta['patch_version']),
      sampleSize: _integer(meta['sample_size']),
    );
  }
}

class StatsTrendRow {
  const StatsTrendRow(this.raw);

  final Map<String, dynamic> raw;

  Map<String, dynamic> get hero => _map(raw['hero']);
  Map<String, dynamic> get equip => _map(raw['equip']);
  Map<String, dynamic> get player => _map(raw['player']);

  String get kind {
    if (hero.isNotEmpty) return 'hero';
    if (equip.isNotEmpty) return 'equip';
    if (player.isNotEmpty) return 'player';
    return 'object';
  }

  String get id {
    final object = switch (kind) {
      'hero' => hero,
      'equip' => equip,
      'player' => player,
      _ => raw,
    };
    return _string(object['id']).isNotEmpty
        ? _string(object['id'])
        : _string(raw['id']);
  }

  String get externalId {
    if (kind == 'hero') {
      return _string(hero['heroId']).isNotEmpty ? _string(hero['heroId']) : id;
    }
    if (kind == 'equip') {
      return _string(equip['equip_id']).isNotEmpty
          ? _string(equip['equip_id'])
          : id;
    }
    return id;
  }

  String get name {
    final object = switch (kind) {
      'hero' => hero,
      'equip' => equip,
      'player' => player,
      _ => raw,
    };
    return _string(object['name']).isNotEmpty
        ? _string(object['name'])
        : _string(raw['name']);
  }

  String get imageUrl {
    final object = switch (kind) {
      'hero' => hero,
      'equip' => equip,
      'player' => player,
      _ => raw,
    };
    for (final key in const ['avatar_url', 'icon_url', 'image_url']) {
      final value = _string(object[key]);
      if (value.isNotEmpty) return value;
    }
    if (kind == 'hero' && externalId.isNotEmpty) {
      return 'https://hokhelper.com/static/game/hero/$id.png';
    }
    if (kind == 'equip' && externalId.isNotEmpty) {
      return 'https://hokhelper.com/static/game/equip/$externalId.png';
    }
    return '';
  }

  int? get lanePosition {
    if (hero.isEmpty) return null;
    final value = hero['position'] ?? hero['postion'];
    final token = _string(value).split(RegExp(r'[,|/]')).first.trim();
    return int.tryParse(token);
  }

  List<double> get sparkline => _list(
    raw['trend_smoothed'],
  ).map(_number).where((value) => value.isFinite).toList(growable: false);

  List<Map<String, dynamic>> get coreTrendPoints =>
      _list(raw['core_trend_points']).map(_map).toList(growable: false);

  Object? value(String columnId) => raw[columnId];

  factory StatsTrendRow.fromJson(Object? value) => StatsTrendRow(_map(value));
}

class StatsTrendDetailRequest {
  const StatsTrendDetailRequest({required this.row, required this.query});

  final StatsTrendRow row;
  final StatsTrendQuery query;

  @override
  bool operator ==(Object other) {
    return other is StatsTrendDetailRequest &&
        other.row.id == row.id &&
        other.row.kind == row.kind &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(row.id, row.kind, query);
}

class StatsTrendDetail {
  const StatsTrendDetail(this.raw);

  final Map<String, dynamic> raw;

  Map<String, dynamic> get hero => _map(raw['hero']);
  Map<String, dynamic> get equip => _map(raw['equip']);
  List<Map<String, dynamic>> list(String key) =>
      _list(raw[key]).map(_map).toList(growable: false);
  Map<String, dynamic> map(String key) => _map(raw[key]);

  factory StatsTrendDetail.fromJson(Object? value) {
    return StatsTrendDetail(_map(value));
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Object?> _list(Object? value) {
  if (value is List) return List<Object?>.from(value);
  return const [];
}

String _string(Object? value) => value?.toString().trim() ?? '';

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(_string(value)) ?? 0;
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(_string(value)) ?? double.nan;
}
