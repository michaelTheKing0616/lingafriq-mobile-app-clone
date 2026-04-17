import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Client for `POST /api/v2/learning/register-coach` (learning v2 Phase 2).
class RegisterCoachService {
  Future<Map<String, dynamic>> evaluate({
    required String utterance,
    required String language,
    String context = 'peer',
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.learningV2.registerCoach,
      data: {
        'utterance': utterance.trim(),
        'language': language.trim().toLowerCase(),
        'context': context.trim(),
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Register coach failed');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Register coach failed');
    }
    return data;
  }
}
