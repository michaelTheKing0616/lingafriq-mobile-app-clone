import 'dart:io';

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
  final Map<String, dynamic> rules;
  final List<PassportPrompt> prompts;

  PassportSessionStart({required this.sessionId, required this.rules, required this.prompts});
}

class PassportService {
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
      rules: (data['rules'] as Map?)?.cast<String, dynamic>() ?? const {},
      prompts: prompts,
    );
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
    required List<Map<String, dynamic>> recordings,
    required Map<String, dynamic> rubric,
    required Map<String, dynamic> integritySignals,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      '/api/v2/passport/sessions/$sessionId/submit',
      data: {
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

