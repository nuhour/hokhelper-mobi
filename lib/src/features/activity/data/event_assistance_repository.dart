import '../../../core/network/api_client.dart';
import '../domain/event_assistance_record.dart';

/// 与网页端 EventAssistancePage 一致的每页条数。
const eventAssistancePageSize = 80;

class EventAssistancePage {
  const EventAssistancePage({required this.records, required this.total});

  final List<EventAssistanceRecord> records;
  final int total;
}

class EventAssistanceRepository {
  const EventAssistanceRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<EventAssistancePage> loadRecords({
    required int regionId,
    int page = 1,
    int pageSize = eventAssistancePageSize,
  }) async {
    final json = await apiClient.getJson(
      '/activity/records',
      query: {'page': page, 'pageSize': pageSize, 'region_id': regionId},
    );
    return EventAssistancePage(
      records: _readRows(
        json,
      ).map(EventAssistanceRecord.fromJson).toList(growable: false),
      total: _readTotal(json),
    );
  }

  Future<EventAssistanceRecord> submitText({
    required String text,
    required int regionId,
  }) async {
    final json = await apiClient.postJson(
      '/activity/records',
      body: {'text': text, 'region_id': regionId},
    );
    final result = json['result'];
    return EventAssistanceRecord.fromJson(result);
  }

  Future<void> reportRecord(String recordId) async {
    await apiClient.postJson('/activity/records/$recordId/report', body: {});
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];
    final rows = result is Map
        ? result['rows'] ?? result['data']
        : json['rows'] ?? json['data'];
    if (rows is! List) {
      return const [];
    }
    return rows;
  }

  int _readTotal(Map<String, dynamic> json) {
    final result = json['result'];
    final total = result is Map ? result['total'] : json['total'];
    if (total is int) {
      return total;
    }
    return int.tryParse(total?.toString() ?? '') ?? 0;
  }
}
