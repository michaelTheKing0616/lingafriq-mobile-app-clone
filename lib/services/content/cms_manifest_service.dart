import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/services/curriculum_service.dart';

/// Offline CMS manifests bundled under [assets/data/cms_manifests/{id}/].
class CmsManifestService {
  static const _bundledRoot = 'assets/data/cms_manifests';

  static const Map<String, String> languageIdByKey = {
    'yoruba': '1',
    'hausa': '2',
    'igbo': '3',
    'swahili': '4',
    'zulu': '5',
    'xhosa': '6',
    'wolof': '7',
    'nigerian_pidgin': '8',
    'pidgin': '8',
    'afrikaans': '9',
    'amharic': '10',
    'twi': '11',
    'somali': '12',
    'lingala': '13',
    'shona': '14',
  };

  String? languageIdFor(String language) {
    final key = CurriculumService.normalizeLanguageKey(language);
    return languageIdByKey[key] ?? languageIdByKey[language.toLowerCase()];
  }

  Future<Map<String, dynamic>?> loadBundledManifest(String language) async {
    final id = languageIdFor(language);
    if (id == null) return null;
    try {
      final raw = await rootBundle.loadString('$_bundledRoot/$id/manifest.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return (decoded['manifest'] as Map<String, dynamic>?) ?? decoded;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> lessonsForLanguage(String language) async {
    final manifest = await loadBundledManifest(language);
    final lessons = manifest?['lessons'];
    if (lessons is! List) return [];
    return lessons
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

final cmsManifestServiceProvider = Provider<CmsManifestService>((ref) {
  return CmsManifestService();
});
