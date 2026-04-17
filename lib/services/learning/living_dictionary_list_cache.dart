import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _livingDictionaryListBodyKeyPrefix = 'living_dictionary_list_body_v1_';

String livingDictionaryListCacheKeyForUrl(String requestUrl) {
  final digest = sha256.convert(utf8.encode(requestUrl));
  return '$_livingDictionaryListBodyKeyPrefix${digest.toString()}';
}

/// Drops all stored list responses so the next list fetch reflects server state.
Future<void> clearLivingDictionaryListCaches() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = prefs.getKeys().where((k) => k.startsWith(_livingDictionaryListBodyKeyPrefix)).toList();
    for (final k in toRemove) {
      await prefs.remove(k);
    }
  } catch (_) {}
}
