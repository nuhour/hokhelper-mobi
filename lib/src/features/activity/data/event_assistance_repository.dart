import '../../../core/network/api_client.dart';
import '../domain/event_assistance_record.dart';

class EventAssistanceRepository {
  const EventAssistanceRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<EventAssistanceRecord>> loadRecords({
    required int regionId,
  }) async {
    final json = await apiClient.getJson(
      '/activity/records',
      query: {'page': 1, 'pageSize': 50, 'region_id': regionId},
    );
    return _readRows(json).map(EventAssistanceRecord.fromJson).toList();
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
}
