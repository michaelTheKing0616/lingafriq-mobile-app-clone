import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

class SyntheticVoiceStyleService {
  Future<List<Map<String, dynamic>>> listStyles() async {
    await ApiService.initialize();
    final res = await ApiService.get(ApiContract.learningV2.syntheticVoiceStyles);
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Failed to load styles');
    }
    final styles = (res.data as Map)['styles'];
    if (styles is! List) return [];
    return styles.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> getPreference({required String language}) async {
    await ApiService.initialize();
    final uri = Uri.parse(ApiContract.learningV2.syntheticVoicePreference).replace(
      queryParameters: {'language': language.trim().toLowerCase()},
    );
    final res = await ApiService.get(uri.toString());
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Failed to load preference');
    }
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> setPreference({
    required String language,
    required bool enabled,
    required String styleId,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.put(
      ApiContract.learningV2.syntheticVoicePreference,
      data: {
        'language': language.trim().toLowerCase(),
        'enabled': enabled,
        'styleId': styleId,
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Failed to update preference');
    }
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> resolveForText({
    required String language,
    required String text,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.learningV2.syntheticVoiceResolve,
      data: {
        'language': language.trim().toLowerCase(),
        'text': text,
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Failed to resolve voice');
    }
    return (res.data as Map).cast<String, dynamic>();
  }
}

