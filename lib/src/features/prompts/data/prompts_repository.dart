import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/prompt_summary.dart';

class PromptsRepository {
  const PromptsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PromptSummary>> loadExplorePrompts() async {
    final json = await apiClient.getJson(
      '/prompt',
      query: {
        'action': 'explore',
        'page': 1,
        'pageSize': 20,
        'sort': '-hot',
        'order': 'desc',
        'filterRules': jsonEncode([
          {'field': 'is_public', 'op': 'eq', 'value': true},
        ]),
      },
    );
    final result = json['result'];
    final rows = result is Map ? result['prompts'] : json['prompts'];
    if (rows is! List) {
      return const [];
    }

    return rows.map(PromptSummary.fromJson).toList(growable: false);
  }
}
