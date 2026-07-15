class TierListSchemeSummary {
  const TierListSchemeSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.rows,
  });

  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final List<TierListSchemeRowSummary> rows;

  int get heroCount => rows.fold(0, (sum, row) => sum + row.heroCount);

  TierListSchemeSummary copyWith({
    String? id,
    String? name,
    String? createdAt,
    String? updatedAt,
    List<TierListSchemeRowSummary>? rows,
  }) {
    return TierListSchemeSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rows: rows ?? this.rows,
    );
  }

  String get heroCountText {
    if (heroCount == 1) {
      return '1 hero';
    }
    return '$heroCount heroes';
  }

  String get updatedDateText {
    if (updatedAt.length >= 10) {
      return updatedAt.substring(0, 10);
    }
    return 'Unknown date';
  }

  factory TierListSchemeSummary.fromJson(Object? value) {
    final json = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final rawRows = json['rows'];

    return TierListSchemeSummary(
      id: _readString(json['id'] ?? json['scheme_id']),
      name: _readString(json['name'], fallback: 'Untitled Tier List'),
      createdAt: _readString(json['createdAt'] ?? json['created_at']),
      updatedAt: _readString(json['updatedAt'] ?? json['updated_at']),
      rows: rawRows is List
          ? rawRows
                .map(TierListSchemeRowSummary.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class TierListSchemeRowSummary {
  const TierListSchemeRowSummary({
    required this.id,
    required this.label,
    required this.color,
    required this.heroCount,
    this.heroIds = const [],
  });

  final String id;
  final String label;
  final String color;
  final int heroCount;
  final List<int> heroIds;

  TierListSchemeRowSummary copyWith({
    String? id,
    String? label,
    String? color,
    int? heroCount,
    List<int>? heroIds,
  }) {
    return TierListSchemeRowSummary(
      id: id ?? this.id,
      label: label ?? this.label,
      color: color ?? this.color,
      heroCount: heroCount ?? this.heroCount,
      heroIds: heroIds ?? this.heroIds,
    );
  }

  Map<String, Object?> toUpdateJson() {
    return {'id': id, 'label': label, 'color': color, 'heroIds': heroIds};
  }

  factory TierListSchemeRowSummary.fromJson(Object? value) {
    final json = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final heroIds = json['heroIds'] ?? json['hero_ids'];

    return TierListSchemeRowSummary(
      id: _readString(json['id']),
      label: _readString(json['label'], fallback: 'Tier'),
      color: _readString(json['color']),
      heroCount: heroIds is List ? heroIds.length : 0,
      heroIds: heroIds is List
          ? heroIds
                .map((value) => int.tryParse(value.toString()))
                .whereType<int>()
                .toList(growable: false)
          : const [],
    );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.trim().isEmpty ? fallback : text;
}
