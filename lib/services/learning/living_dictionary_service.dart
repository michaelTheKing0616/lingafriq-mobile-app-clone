import 'dart:convert';

import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/learning/living_dictionary_list_cache.dart';
import 'package:lingafriq/services/learning/living_dictionary_list_result.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'living_dictionary_list_result.dart';

class LivingDictionaryService {
  Future<void> _saveListCache(String requestUrl, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(livingDictionaryListCacheKeyForUrl(requestUrl), jsonEncode(data));
    } catch (_) {}
  }

  Future<LivingDictionaryListResult?> _readListCache(String requestUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(livingDictionaryListCacheKeyForUrl(requestUrl));
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return LivingDictionaryListParse.listResultFromApiBody(Map<String, dynamic>.from(decoded), source: 'cache');
    } catch (_) {
      return null;
    }
  }

  /// Drops all stored list responses so the next [listEntries] reflects server state (e.g. after [addEntry]).
  Future<void> clearListCaches() => clearLivingDictionaryListCaches();

  Future<LivingDictionaryListResult> listEntries({
    String? sourceMediaId,
    String? language,
    String? query,
    String? before,
    int limit = 200,
  }) async {
    await ApiService.initialize();
    final uri = Uri.parse(ApiContract.learningV2.livingDictionaryEntries).replace(
      queryParameters: {
        if (sourceMediaId != null && sourceMediaId.trim().isNotEmpty) 'sourceMediaId': sourceMediaId.trim(),
        if (language != null && language.trim().isNotEmpty) 'language': language.trim(),
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (before != null && before.trim().isNotEmpty) 'before': before.trim(),
        'limit': '$limit',
      },
    );
    final requestUrl = uri.toString();
    try {
      final res = await ApiService.get(requestUrl);
      if (res.statusCode != 200 || res.data is! Map) {
        throw Exception('Failed to load living dictionary');
      }
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Failed to load living dictionary');
      }
      await _saveListCache(requestUrl, data);
      return LivingDictionaryListParse.listResultFromApiBody(data, source: 'live');
    } catch (_) {
      final cached = await _readListCache(requestUrl);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addEntry({
    required String language,
    required String lemma,
    String? translation,
    String? sourceMediaId,
    int? startMs,
    int? endMs,
    String? context,
    bool idiom = false,
    /// Must be true for manual adds — server records [consentRecordedAt] when set.
    bool consentAcknowledged = true,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.learningV2.livingDictionaryEntries,
      data: {
        'language': language,
        'lemma': lemma,
        if (translation != null) 'translation': translation,
        if (sourceMediaId != null) 'sourceMediaId': sourceMediaId,
        if (startMs != null) 'startMs': startMs,
        if (endMs != null) 'endMs': endMs,
        if (context != null) 'context': context,
        'idiom': idiom,
        if (consentAcknowledged) 'consentAcknowledged': true,
      },
    );
    if (res.statusCode != 201 || res.data is! Map) {
      throw Exception('Failed to add entry');
    }
    final data = Map<String, dynamic>.from(res.data as Map);
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Failed to add entry');
    }
    final entry = data['entry'];
    if (entry is Map) {
      await clearListCaches();
      return Map<String, dynamic>.from(entry);
    }
    throw Exception('Invalid entry response');
  }

  /// Permanently removes a lexeme row owned by the signed-in user.
  Future<void> deleteEntry(String entryId) async {
    final id = entryId.trim();
    if (id.isEmpty) {
      throw Exception('Entry id required');
    }
    await ApiService.initialize();
    final res = await ApiService.delete(ApiContract.learningV2.livingDictionaryEntry(id));
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Failed to delete entry (${res.statusCode})');
    }
    final data = Map<String, dynamic>.from(res.data as Map);
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Failed to delete entry');
    }
    await clearListCaches();
  }
}
