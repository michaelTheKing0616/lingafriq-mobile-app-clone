import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Client for `POST /api/v2/learning/code-switch/session` (learning v2 Phase 2).
class CodeSwitchSessionService {
  Future<Map<String, dynamic>> startSession({
    required String language,
    double targetStayRatio = 0.7,
    String topic = 'market_bargain',
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.learningV2.codeSwitchSession,
      data: {
        'language': language.trim().toLowerCase(),
        'targetStayRatio': targetStayRatio,
        'topic': topic.trim(),
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Code-switch session failed');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Code-switch session failed');
    }
    return data;
  }
}
