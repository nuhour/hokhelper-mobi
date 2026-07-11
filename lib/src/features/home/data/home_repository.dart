import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';

class HomeRepository {
  const HomeRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<HomeStats> loadHomeStats() async {
    try {
      final json = await apiClient
          .getJson('/home/stats')
          .timeout(const Duration(seconds: 3));
      final stats = HomeStats.fromJson(json);
      if (stats.result.isNotEmpty) {
        return stats;
      }
    } catch (_) {
      // 开发统计任务未运行时使用内置数据，接口恢复后自动切回真实数据。
    }

    return _loadMockHomeStats();
  }

  Future<HomeStats> _loadMockHomeStats() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/mock/home_stats.json'),
    );
    if (json is! Map) {
      throw const FormatException('Invalid mock home stats payload');
    }
    return HomeStats.fromJson(Map<String, dynamic>.from(json));
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
    final result = json['result'] is Map ? json['result'] : json;

    return HomeStats(
      success: json['success'] != false,
      message: (json['message'] ?? json['msg'] ?? 'Home stats ready')
          .toString(),
      result: result is Map ? Map<String, dynamic>.from(result) : const {},
    );
  }
}
