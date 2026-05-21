import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads bundled Polie personality snippets for conversation/tutor modes.
class PoliePromptService {
  static const _assetPath = 'assets/data/polie_prompt_snippets.json';

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> loadSnippets() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    _cache = jsonDecode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  Future<Map<String, dynamic>> persona(String key) async {
    final data = await loadSnippets();
    final personas = data['personas'] as Map<String, dynamic>? ?? {};
    return (personas[key] as Map<String, dynamic>?) ?? {};
  }

  Future<String> feedbackLine(
    String personaKey, {
    required String tier,
  }) async {
    final p = await persona(personaKey);
    final list = p['feedback_$tier'] as List<dynamic>?;
    if (list == null || list.isEmpty) return '';
    return list.first.toString();
  }
}

final poliePromptServiceProvider = Provider<PoliePromptService>((ref) {
  return PoliePromptService();
});
