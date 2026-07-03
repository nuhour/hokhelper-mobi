import '../../../core/network/api_client.dart';

class HomeRepository {
  const HomeRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<HomeStats> loadHomeStats() async {
    final json = await apiClient.getJson('/home/stats');
    return HomeStats.fromJson(json);
  }
}

class HomeStats {
  const HomeStats({
    required this.success,
    required this.message,
    required this.result,
  });

  final bool success;
  final String message;
  final Map<String, dynamic> result;

  factory HomeStats.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    return HomeStats(
      success: json['success'] != false,
      message: (json['message'] ?? json['msg'] ?? 'Connected').toString(),
      result: result is Map ? Map<String, dynamic>.from(result) : const {},
    );
  }
}
