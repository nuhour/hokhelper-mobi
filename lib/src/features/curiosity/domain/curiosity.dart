class CuriosityLocalizedLabel {
  const CuriosityLocalizedLabel({
    required this.zh,
    required this.en,
    required this.id,
  });

  factory CuriosityLocalizedLabel.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return CuriosityLocalizedLabel(
      zh: map['zh']?.toString() ?? '',
      en: map['en']?.toString() ?? '',
      id: map['id']?.toString() ?? '',
    );
  }

  final String zh;
  final String en;
  final String id;
}

class CuriosityEntity {
  const CuriosityEntity({
    required this.key,
    required this.name,
    required this.type,
    this.heroId,
    this.heroName,
    this.iconUrl,
    this.description,
    this.videoUrl,
  });

  factory CuriosityEntity.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return CuriosityEntity(
      key: map['key']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'custom',
      heroId: _readNullableInt(map['hero_id']),
      heroName: map['hero_name']?.toString(),
      iconUrl: map['icon_url']?.toString(),
      description: map['description']?.toString(),
      videoUrl: map['video_url']?.toString(),
    );
  }

  final String key;
  final String name;
  final String type;
  final int? heroId;
  final String? heroName;
  final String? iconUrl;
  final String? description;
  final String? videoUrl;

  Map<String, Object?> toJson() {
    return {
      'key': key,
      'name': name,
      'type': type,
      'hero_id': heroId,
      'hero_name': heroName,
      'icon_url': iconUrl,
      'description': description,
      'video_url': videoUrl,
    };
  }
}

class CuriosityVerb {
  const CuriosityVerb({
    required this.key,
    required this.zh,
    required this.en,
    required this.id,
  });

  factory CuriosityVerb.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return CuriosityVerb(
      key: map['key']?.toString() ?? '',
      zh: map['zh']?.toString() ?? map['label_zh']?.toString() ?? '',
      en: map['en']?.toString() ?? map['label_en']?.toString() ?? '',
      id: map['id']?.toString() ?? map['label_id']?.toString() ?? '',
    );
  }

  final String key;
  final String zh;
  final String en;
  final String id;
}

class CuriosityOptionResult {
  const CuriosityOptionResult({required this.rows, required this.verbs});

  factory CuriosityOptionResult.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final rows = map['rows'];
    final verbs = map['verbs'];
    return CuriosityOptionResult(
      rows: rows is List
          ? rows.map(CuriosityEntity.fromJson).toList(growable: false)
          : const [],
      verbs: verbs is List
          ? verbs.map(CuriosityVerb.fromJson).toList(growable: false)
          : const [],
    );
  }

  final List<CuriosityEntity> rows;
  final List<CuriosityVerb> verbs;
}

class CuriosityCondition {
  const CuriosityCondition({required this.id, required this.text});

  factory CuriosityCondition.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return CuriosityCondition(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
    );
  }

  final String id;
  final String text;
}

class CuriosityEvidence {
  const CuriosityEvidence({
    required this.id,
    required this.title,
    required this.sourceLabel,
    this.date,
    this.url,
  });

  factory CuriosityEvidence.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return CuriosityEvidence(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      sourceLabel: map['source_label']?.toString() ?? '',
      date: map['date']?.toString(),
      url: map['url']?.toString(),
    );
  }

  final String id;
  final String title;
  final String sourceLabel;
  final String? date;
  final String? url;
}

class CuriosityAskAnswer {
  const CuriosityAskAnswer({
    required this.queryId,
    required this.query,
    required this.matched,
    required this.answer,
    required this.result,
    required this.resultLabel,
    required this.summary,
    required this.reasoning,
    required this.conditions,
    required this.evidence,
    required this.confidenceScore,
    required this.confidenceLevel,
    required this.relatedQuestions,
    required this.allowSubmission,
    this.caseId,
  });

  factory CuriosityAskAnswer.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final confidence = map['confidence'] is Map
        ? map['confidence'] as Map
        : const <String, Object?>{};
    final conditions = map['conditions'];
    final evidence = map['evidence'];
    final relatedQuestions = map['related_questions'];
    return CuriosityAskAnswer(
      queryId: _readNullableInt(map['query_id']),
      query: map['query']?.toString() ?? '',
      matched: map['matched'] == true,
      answer: map['answer']?.toString() ?? '',
      result: map['result']?.toString() ?? 'unknown',
      resultLabel: CuriosityLocalizedLabel.fromJson(map['result_label']),
      summary: map['summary']?.toString() ?? '',
      reasoning: map['reasoning']?.toString() ?? '',
      conditions: conditions is List
          ? conditions.map(CuriosityCondition.fromJson).toList(growable: false)
          : const [],
      evidence: evidence is List
          ? evidence.map(CuriosityEvidence.fromJson).toList(growable: false)
          : const [],
      confidenceScore: _readInt(confidence['score']),
      confidenceLevel: confidence['level']?.toString() ?? 'low',
      relatedQuestions: relatedQuestions is List
          ? relatedQuestions
                .map((item) => item.toString())
                .toList(growable: false)
          : const [],
      allowSubmission: map['allow_submission'] == true,
      caseId: _readNullableInt(map['case_id']),
    );
  }

  final int? queryId;
  final String query;
  final bool matched;
  final String answer;
  final String result;
  final CuriosityLocalizedLabel resultLabel;
  final String summary;
  final String reasoning;
  final List<CuriosityCondition> conditions;
  final List<CuriosityEvidence> evidence;
  final int confidenceScore;
  final String confidenceLevel;
  final List<String> relatedQuestions;
  final bool allowSubmission;
  final int? caseId;
}

class CuriosityVideo {
  const CuriosityVideo({
    required this.id,
    required this.videoUrl,
    this.experimenterName,
    this.note,
    this.isPrimary = false,
  });

  factory CuriosityVideo.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return CuriosityVideo(
      id: map['id']?.toString() ?? '',
      videoUrl: map['video_url']?.toString() ?? '',
      experimenterName: map['experimenter_name']?.toString(),
      note: map['note']?.toString(),
      isPrimary: map['is_primary'] == true,
    );
  }

  final String id;
  final String videoUrl;
  final String? experimenterName;
  final String? note;
  final bool isPrimary;
}

class CuriosityCaseResult {
  const CuriosityCaseResult({
    required this.id,
    required this.source,
    required this.target,
    required this.verb,
    required this.result,
    required this.resultLabel,
    required this.verdictText,
    required this.reasoning,
    required this.confidenceScore,
    required this.dataSource,
    required this.videos,
    required this.allowSubmission,
  });

  factory CuriosityCaseResult.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final videos = map['videos'];
    return CuriosityCaseResult(
      id: _readNullableInt(map['id']),
      source: CuriosityEntity.fromJson(map['source']),
      target: CuriosityEntity.fromJson(map['target']),
      verb: CuriosityVerb.fromJson(map['verb']),
      result: map['result']?.toString() ?? 'unknown',
      resultLabel: CuriosityLocalizedLabel.fromJson(map['result_label']),
      verdictText: map['verdict_text']?.toString() ?? '',
      reasoning: map['reasoning']?.toString() ?? '',
      confidenceScore: _readInt(map['confidence_score']),
      dataSource: map['data_source']?.toString() ?? '',
      videos: videos is List
          ? videos.map(CuriosityVideo.fromJson).toList(growable: false)
          : const [],
      allowSubmission: map['allow_submission'] == true,
    );
  }

  final int? id;
  final CuriosityEntity source;
  final CuriosityEntity target;
  final CuriosityVerb verb;
  final String result;
  final CuriosityLocalizedLabel resultLabel;
  final String verdictText;
  final String reasoning;
  final int confidenceScore;
  final String dataSource;
  final List<CuriosityVideo> videos;
  final bool allowSubmission;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _readNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}
