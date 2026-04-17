import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists preferred dialect tag per umbrella language for offline reads (pack ordering, missions).
class DialectPreferenceService {
  static const _prefsKeyTagPrefix = 'learning_dialect_preferred_tag_v1_';

  static String _normUmbrella(String umbrellaLanguage) =>
      umbrellaLanguage.trim().toLowerCase();

  Future<void> _writeCachedTag(String umbrellaLanguage, String preferredDialectTag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKeyTagPrefix${_normUmbrella(umbrellaLanguage)}',
      preferredDialectTag.trim(),
    );
  }

  /// Last saved tag for this umbrella language, or null.
  Future<String?> readCachedPreferredTag(String umbrellaLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('$_prefsKeyTagPrefix${_normUmbrella(umbrellaLanguage)}');
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  Future<Map<String, dynamic>?> get({String? umbrellaLanguage}) async {
    Future<Map<String, dynamic>?> fromCache() async {
      final u = umbrellaLanguage?.trim();
      if (u == null || u.isEmpty) return null;
      final tag = await readCachedPreferredTag(u);
      if (tag == null) return null;
      return {
        'umbrellaLanguage': _normUmbrella(u),
        'preferredDialectTag': tag,
        'source': 'cache',
      };
    }

    try {
      await ApiService.initialize();
      final uri = umbrellaLanguage == null || umbrellaLanguage.trim().isEmpty
          ? Uri.parse(ApiContract.learningV2.dialectPreference)
          : Uri.parse(ApiContract.learningV2.dialectPreference).replace(
              queryParameters: {'umbrellaLanguage': umbrellaLanguage.trim().toLowerCase()},
            );
      final res = await ApiService.get(uri.toString());
      if (res.statusCode != 200 || res.data is! Map) {
        return fromCache();
      }
      final data = (res.data as Map).cast<String, dynamic>();
      if (data['success'] != true) return fromCache();
      final pref = data['preference'];
      if (pref is Map) {
        final m = Map<String, dynamic>.from(pref);
        final tag = m['preferredDialectTag']?.toString();
        final umb = m['umbrellaLanguage']?.toString() ?? umbrellaLanguage;
        if (tag != null && tag.trim().isNotEmpty && umb != null && umb.trim().isNotEmpty) {
          await _writeCachedTag(umb, tag);
        }
        return m;
      }
      return fromCache();
    } catch (_) {
      return fromCache();
    }
  }

  Future<void> put({
    required String umbrellaLanguage,
    required String preferredDialectTag,
    double confidence = 0.6,
    double exposureScore = 0,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.put(
      ApiContract.learningV2.dialectPreference,
      data: {
        'umbrellaLanguage': umbrellaLanguage,
        'preferredDialectTag': preferredDialectTag,
        'confidence': confidence,
        'exposureScore': exposureScore,
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Failed to update dialect preference');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Failed to update dialect preference');
    }
    await _writeCachedTag(umbrellaLanguage, preferredDialectTag);
  }
}

