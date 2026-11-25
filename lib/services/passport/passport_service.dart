
import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

class PassportPrompt {
  final String promptId;
  final String type;
  final int seconds;
  final String text;

  PassportPrompt({
    required this.promptId,
    required this.type,
    required this.seconds,
    required this.text,
  });

  factory PassportPrompt.fromJson(Map<String, dynamic> json) => PassportPrompt(
        promptId: json['promptId']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        seconds: (json['seconds'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
      );
}

class PassportSessionStart {
  final String sessionId;
  final String sessionToken;
  final Map<String, dynamic> rules;
  final List<PassportPrompt> prompts;

  PassportSessionStart({
    required this.sessionId,
    required this.sessionToken,
    required this.rules,
    required this.prompts,
  });
}

class PassportPortfolioEntry {
  final String taskId;
  final String canDoId;
  final String cefrLevel;
  final String scorerAttemptId;
  final double? scorerConfidence;
  final DateTime passedAt;

  PassportPortfolioEntry({
    required this.taskId,
    required this.canDoId,
    required this.cefrLevel,
    required this.scorerAttemptId,
    required this.scorerConfidence,
    required this.passedAt,
  });

  factory PassportPortfolioEntry.fromJson(Map<String, dynamic> json) => PassportPortfolioEntry(
        taskId: json['taskId']?.toString() ?? '',
        canDoId: json['canDoId']?.toString() ?? '',
        cefrLevel: json['cefrLevel']?.toString() ?? '',
        scorerAttemptId: json['scorerAttemptId']?.toString() ?? '',
        scorerConfidence: (json['scorerConfidence'] as num?)?.toDouble(),
        passedAt: DateTime.tryParse(json['passedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class PassportPortfolioResult {
  final bool prereqBlocked;
  final List<PassportPortfolioEntry> entries;

  const PassportPortfolioResult({required this.prereqBlocked, required this.entries});
}

class PassportService {
  Future<PassportPortfolioResult> fetchPortfolio() async {
    await ApiService.initialize();
    try {
      final res = await ApiService.get('/api/v2/passport/portfolio');
      final data = (res.data as Map).cast<String, dynamic>();
      if (res.statusCode == 403 && data['code'] == 'PASSPORT_PREREQ_NOT_MET') {
        return const PassportPortfolioResult(prereqBlocked: true, entries: []);
      }
      if (res.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Failed to load portfolio');
      }
      final raw = (data['entries'] as List?) ?? const [];
      final entries = raw
          .whereType<Map>()
          .map((m) => PassportPortfolioEntry.fromJson(m.cast<String, dynamic>()))
          .where((e) => e.taskId.isNotEmpty && e.canDoId.isNotEmpty)
          .toList();
      return PassportPortfolioResult(prereqBlocked: false, entries: entries);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 403 && data is Map && data['code'] == 'PASSPORT_PREREQ_NOT_MET') {
        return const PassportPortfolioResult(prereqBlocked: true, entries: []);
      }
      rethrow;
    }
  }

  Future<PassportSessionStart> startSession({
    required String language,
    required String proctorMode,
    required Map<String, dynamic> integritySignals,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.learningV2.passportSessions,
      data: {
        'language': language,
        'proctorMode': proctorMode,
        'integritySignals': integritySignals,
      },
    );
    final data = (res.data as Map).cast<String, dynamic>();
    if (res.statusCode != 201 || data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Failed to start session');
    }
    final promptsRaw = (data['prompts'] as List?) ?? const [];
    final prompts = promptsRaw
        .whereType<Map>()
        .map((m) => PassportPrompt.fromJson(m.cast<String, dynamic>()))
        .where((p) => p.promptId.isNotEmpty)
        .toList();
    return PassportSessionStart(
      sessionId: data['sessionId']?.toString() ?? '',
      sessionToken: data['sessionToken']?.toString() ?? '',
      rules: (data['rules'] as Map?)?.cast<String, dynamic>() ?? const {},
      prompts: prompts,
    );
  }

  Future<PassportSessionStart> resumeSession(String sessionId) async {
    await ApiService.initialize();
    final res = await ApiService.get('/api/v2/passport/sessions/$sessionId/resume');
    final data = (res.data as Map).cast<String, dynamic>();
    if (res.statusCode == 410 && data['code'] == 'CAT_SESSION_EXPIRED') {
      throw PassportCatException('CAT_SESSION_EXPIRED');
    }
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Resume failed');
    }
    final promptsRaw = (data['prompts'] as List?) ?? const [];
    final prompts = promptsRaw
        .whereType<Map>()
        .map((m) => PassportPrompt.fromJson(m.cast<String, dynamic>()))
        .where((p) => p.promptId.isNotEmpty)
        .toList();
    return PassportSessionStart(
      sessionId: data['sessionId']?.toString() ?? sessionId,
      sessionToken: data['sessionToken']?.toString() ?? '',
      rules: (data['rules'] as Map?)?.cast<String, dynamic>() ?? const {},
      prompts: prompts,
    );
  }

  Future<void> reportIntegrityViolation({
    required String sessionId,
    required String sessionToken,
    required String reason,
  }) async {
    await ApiService.initialize();
    await ApiService.post(
      '/api/v2/passport/sessions/$sessionId/integrity',
      data: {'sessionToken': sessionToken, 'reason': reason},
    );
  }

  Future<PassportPrompt?> advanceCatStep({
    required String sessionId,
    required String sessionToken,
    required String promptId,
    required double itemScore,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      '/api/v2/passport/sessions/$sessionId/cat-step',
      data: {
        'sessionToken': sessionToken,
        'promptId': promptId,
        'itemScore': itemScore,
      },
    );
    final data = (res.data as Map).cast<String, dynamic>();
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'CAT step failed');
    }
    if (data['complete'] == true) return null;
    final next = data['nextPrompt'];
    if (next is Map) {
      return PassportPrompt.fromJson(next.cast<String, dynamic>());
    }
    return null;
  }

  Future<Map<String, dynamic>> uploadRecording({
    required String sessionId,
    required String promptId,
    required String filePath,
    required int durationSec,
  }) async {
    await ApiService.initialize();
    final formData = FormData.fromMap({
      'promptId': promptId,
      'durationSec': durationSec,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'passport_prompt_$promptId.wav',
      ),
    });
    final res = await ApiService.post(
      '/api/v2/passport/sessions/$sessionId/recordings',
      data: formData,
      options: Options(contentType: 'multipart/form-data', receiveTimeout: const Duration(seconds: 90)),
    );
    if (res.statusCode != 201 || res.data is! Map) {
      throw Exception('Upload failed');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Upload failed');
    }
    return data;
  }

  Future<Map<String, dynamic>> submit({
    required String sessionId,
    required String sessionToken,
    required List<Map<String, dynamic>> recordings,
    required Map<String, dynamic> rubric,
    required Map<String, dynamic> integritySignals,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      '/api/v2/passport/sessions/$sessionId/submit',
      data: {
        'sessionToken': sessionToken,
        'recordings': recordings,
        'rubric': rubric,
        'integritySignals': integritySignals,
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Submit failed');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Submit failed');
    }
    return data;
  }

  Future<Map<String, dynamic>> verifyPublic(String token) async {
    final res = await Dio().get(
      ApiContract.url(ApiContract.learningV2.passportVerify(token)),
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Verify failed');
    }
    return (res.data as Map).cast<String, dynamic>();
  }
}

class PassportCatException implements Exception {
  PassportCatException(this.code);
  final String code;
  @override
  String toString() => code;
}

