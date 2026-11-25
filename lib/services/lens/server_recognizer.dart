import 'package:dio/dio.dart';

import 'package:lingafriq/services/lens/object_set_mapper.dart';

/// Copy keys: lens.recognize.unsure, lens.recognize.error (P7-904).
const String lensRecognizeUnsureCopy =
    'We are not confident about this object. Try another angle or tap to retry.';
const String lensRecognizeErrorCopy =
    'Server recognition is unavailable. You can retry when you are back online.';

const String kLensRecognizePath = '/api/ai/lens/recognize';

class LensServerRecognition {
  const LensServerRecognition({
    required this.objectSetId,
    required this.label,
    required this.confidence,
    required this.unsure,
    required this.modelId,
    required this.modelRevision,
  });

  final String objectSetId;
  final String label;
  final double confidence;
  final bool unsure;
  final String modelId;
  final String modelRevision;
}

class LensServerRecognizeOutcome {
  const LensServerRecognizeOutcome({
    required this.phase,
    this.recognition,
    this.errorMessage,
    this.retryable = false,
    this.modelDisclosure,
  });

  final LensRecognizePhase phase;
  final LensServerRecognition? recognition;
  final String? errorMessage;
  final bool retryable;
  final String? modelDisclosure;
}

enum LensRecognizePhase { recognized, unsure, error }

typedef LensRecognizePost = Future<Response<dynamic>> Function(
  String path,
  Map<String, dynamic> body,
);

/// Calls authenticated SigLIP recognition on the gateway (no provider keys in client).
class LensServerRecognizer {
  const LensServerRecognizer({this.recognizePath = kLensRecognizePath});

  final String recognizePath;

  List<Map<String, dynamic>> candidatesFromObjectSet(AfricanObjectSet set) {
    return set.entries
        .map(
          (e) => {
            'object_set_id': e.objectSetId,
            'labels': List<String>.from(e.mlKitLabels),
          },
        )
        .toList();
  }

  Future<LensServerRecognizeOutcome> recognizeCrop({
    required LensRecognizePost post,
    required String imageBase64,
    required List<Map<String, dynamic>> candidates,
    double? confidenceThreshold,
  }) async {
    try {
      final response = await post(
        recognizePath,
        {
          'imageOptIn': true,
          'imageBase64': imageBase64,
          'candidates': candidates,
          if (confidenceThreshold != null)
            'confidenceThreshold': confidenceThreshold,
        },
      );
      final statusCode = response.statusCode ?? 0;
      final raw = response.data;
      final body =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      if (statusCode == 401) {
        return const LensServerRecognizeOutcome(
          phase: LensRecognizePhase.error,
          errorMessage: lensRecognizeErrorCopy,
        );
      }
      if (statusCode == 429 ||
          body['code'] == 'mode_budget_exhausted' ||
          statusCode == 503) {
        return LensServerRecognizeOutcome(
          phase: LensRecognizePhase.error,
          errorMessage: lensRecognizeErrorCopy,
          retryable: body['retryable'] == true || statusCode == 429,
        );
      }
      if (statusCode != 200 || body['ok'] != true) {
        return LensServerRecognizeOutcome(
          phase: LensRecognizePhase.error,
          errorMessage: lensRecognizeErrorCopy,
          retryable: body['retryable'] == true,
        );
      }
      return parseRecognizeBody(body);
    } catch (_) {
      return const LensServerRecognizeOutcome(
        phase: LensRecognizePhase.error,
        errorMessage: lensRecognizeErrorCopy,
        retryable: true,
      );
    }
  }
}

LensServerRecognizeOutcome parseRecognizeBody(Map<String, dynamic> body) {
  final result = body['result'];
  if (result is! Map) {
    return const LensServerRecognizeOutcome(
      phase: LensRecognizePhase.error,
      errorMessage: lensRecognizeErrorCopy,
    );
  }
  final map = Map<String, dynamic>.from(result);
  final objectSetId = (map['object_set_id'] ?? '').toString();
  final label = (map['label'] ?? '').toString();
  final confidence = (map['confidence'] as num?)?.toDouble() ?? 0;
  final unsure = map['unsure'] == true;
  final modelRaw = map['model'];
  String modelId = '';
  String modelRevision = '';
  if (modelRaw is Map) {
    final model = Map<String, dynamic>.from(modelRaw);
    modelId = (model['id'] ?? '').toString();
    modelRevision = (model['revision'] ?? '').toString();
  }
  if (objectSetId.isEmpty || label.isEmpty) {
    return const LensServerRecognizeOutcome(
      phase: LensRecognizePhase.error,
      errorMessage: lensRecognizeErrorCopy,
    );
  }
  final recognition = LensServerRecognition(
    objectSetId: objectSetId,
    label: label,
    confidence: confidence,
    unsure: unsure,
    modelId: modelId,
    modelRevision: modelRevision,
  );
  final disclosure = modelId.isNotEmpty
      ? '$modelId@${modelRevision.isNotEmpty ? modelRevision : 'unknown'}'
      : null;
  return LensServerRecognizeOutcome(
    phase: unsure ? LensRecognizePhase.unsure : LensRecognizePhase.recognized,
    recognition: recognition,
    modelDisclosure: disclosure,
  );
}
