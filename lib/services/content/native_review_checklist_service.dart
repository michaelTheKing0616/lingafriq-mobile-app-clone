import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final nativeReviewChecklistServiceProvider =
    Provider<NativeReviewChecklistService>((ref) {
  return NativeReviewChecklistService();
});

/// Loads bundled [review_checklist.json] and persists reviewer updates locally.
class NativeReviewChecklistService {
  static const _assetPath = 'assets/data/review_checklist.json';
  static const _localFileName = 'review_checklist_overrides.json';

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> load() async {
    if (_cache != null) return _cache!;
    final bundled = await rootBundle.loadString(_assetPath);
    final base = jsonDecode(bundled) as Map<String, dynamic>;
    final overrides = await _readOverrides();
    if (overrides == null) {
      _cache = base;
      return base;
    }
    _cache = _merge(base, overrides);
    return _cache!;
  }

  Future<void> updateLanguage({
    required String languageKey,
    required String status,
    String? reviewer,
    String? signedAt,
  }) async {
    _cache = null;
    final data = await load();
    final languages = Map<String, dynamic>.from(
      data['languages'] as Map<String, dynamic>,
    );
    final entry = Map<String, dynamic>.from(
      (languages[languageKey] as Map<String, dynamic>?) ?? {},
    );
    entry['status'] = status;
    if (reviewer != null) entry['reviewer'] = reviewer;
    if (signedAt != null) entry['signed_at'] = signedAt;
    languages[languageKey] = entry;
    data['languages'] = languages;
    _cache = data;
    await _writeOverrides(data);
  }

  Future<Map<String, dynamic>?> _readOverrides() async {
    final file = await _localFile();
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeOverrides(Map<String, dynamic> data) async {
    final file = await _localFile();
    final payload = <String, dynamic>{
      'languages': data['languages'],
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localFileName');
  }

  Map<String, dynamic> _merge(
    Map<String, dynamic> base,
    Map<String, dynamic> overrides,
  ) {
    final merged = Map<String, dynamic>.from(base);
    if (overrides['languages'] is Map) {
      final baseLangs = Map<String, dynamic>.from(
        merged['languages'] as Map<String, dynamic>,
      );
      final overrideLangs = overrides['languages'] as Map<String, dynamic>;
      for (final entry in overrideLangs.entries) {
        final existing = Map<String, dynamic>.from(
          (baseLangs[entry.key] as Map<String, dynamic>?) ?? {},
        );
        existing.addAll(entry.value as Map<String, dynamic>);
        baseLangs[entry.key] = existing;
      }
      merged['languages'] = baseLangs;
    }
    return merged;
  }
}
