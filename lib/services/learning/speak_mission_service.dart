import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

class SpeakMissionEvaluationResult {
  final Map<String, dynamic> scores;
  final Map<String, dynamic> rubric;
  final String model;

  SpeakMissionEvaluationResult({
    required this.scores,
    required this.rubric,
    required this.model,
  });
}

class SpeakMissionService {
  Future<SpeakMissionEvaluationResult> evaluate({
    required String language,
    String? dialectTag,
    required String scenarioId,
    required String transcript,
    required List<String> referenceKeywords,
    required String registerContext,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.learningV2.speakMissionEvaluate,
      data: {
        'language': language,
        if (dialectTag != null && dialectTag.trim().isNotEmpty) 'dialectTag': dialectTag.trim(),
        'scenarioId': scenarioId,
        'transcript': transcript,
        'referenceKeywords': referenceKeywords,
        'registerContext': registerContext,
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Evaluation failed');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Evaluation failed');
    }
    final scores = (data['scores'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rubric = (data['rubric'] as Map?)?.cast<String, dynamic>() ?? const {};
    final model = data['model']?.toString() ?? '';
    return SpeakMissionEvaluationResult(scores: scores, rubric: rubric, model: model);
  }
}

