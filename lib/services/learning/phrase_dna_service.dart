import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class PhraseDnaService {
  static const String _templatesBoxName = 'lingafriq_phrase_dna_templates_v1';
  Box<String>? _box;

  Future<void> _ensureOpen() async {
    _box ??= await Hive.openBox<String>(_templatesBoxName);
  }

  String _templatesKey(String language) => 'templates:${language.trim().toLowerCase()}';

  Future<List<Map<String, dynamic>>> _readCachedTemplates(String? language) async {
    final lang = (language ?? '').trim().toLowerCase();
    if (lang.isEmpty) return const [];
    await _ensureOpen();
    final raw = _box?.get(_templatesKey(lang));
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCachedTemplates(String language, List<Map<String, dynamic>> templates) async {
    final lang = language.trim().toLowerCase();
    if (lang.isEmpty) return;
    await _ensureOpen();
    await _box?.put(_templatesKey(lang), jsonEncode(templates));
    await _box?.put('templates_updated_at:$lang', DateTime.now().toUtc().toIso8601String());
  }

  Future<List<Map<String, dynamic>>> listTemplates({String? language}) async {
    final lang = language?.trim().toLowerCase();
    try {
      await ApiService.initialize();
      final uri = Uri.parse(ApiContract.learningV2.phraseDnaTemplates).replace(
        queryParameters: {
          if (lang != null && lang.isNotEmpty) 'language': lang,
        },
      );
      final res = await ApiService.get(uri.toString());
      if (res.statusCode != 200) {
        throw Exception('Failed to load templates');
      }
      final data = res.data;
      if (data is! Map) return [];
      final templates = data['templates'];
      if (templates is! List) return [];
      final parsed = templates.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      if (lang != null && lang.isNotEmpty) {
        await _writeCachedTemplates(lang, parsed);
      }
      return parsed;
    } catch (_) {
      // Offline-first fallback: return cached templates when the network fetch fails.
      final cached = await _readCachedTemplates(lang);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCachedTemplate({
    required String language,
    required String templateId,
  }) async {
    final templates = await _readCachedTemplates(language);
    for (final t in templates) {
      final id = (t['_id'] ?? t['id'] ?? '').toString();
      if (id == templateId) return t;
    }
    return null;
  }

  Future<Map<String, dynamic>> start({
    required String templateId,
    required String language,
    String? dialectTag,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.learningV2.phraseDnaStart,
      data: {
        'templateId': templateId,
        'language': language.trim().toLowerCase(),
        if (dialectTag != null && dialectTag.trim().isNotEmpty) 'dialectTag': dialectTag.trim(),
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to start session');
    }
    final data = res.data;
    if (data is! Map) throw Exception('Invalid response');
    final session = data['session'];
    if (session is! Map) throw Exception('Invalid session');
    return session.cast<String, dynamic>();
  }

  /// Submits for grading. If request fails (offline/transient), it enqueues an outbox op
  /// so the server will grade when connectivity returns.
  Future<Map<String, dynamic>> submit({
    required String language,
    required String built,
    required Map<String, String> slots,
    String? templateId,
    String? dialectTag,
  }) async {
    await ApiService.initialize();
    final payload = {
      'language': language.trim().toLowerCase(),
      'built': built,
      'slots': slots,
      if (templateId != null && templateId.trim().isNotEmpty) 'templateId': templateId.trim(),
      if (dialectTag != null && dialectTag.trim().isNotEmpty) 'dialectTag': dialectTag.trim(),
    };

    try {
      final res = await ApiService.post(
        ApiContract.learningV2.phraseDnaSubmit,
        data: payload,
      );
      if (res.statusCode == 200 && res.data is Map) {
        return (res.data as Map).cast<String, dynamic>();
      }
      throw Exception('Submit failed');
    } catch (_) {
      await PersistedOutboxService.instance.enqueue(
        type: 'phrase_dna_attempt_submit',
        payload: payload.cast<String, dynamic>(),
      );
      return {
        'success': true,
        'queued': true,
        'wellFormed': built.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length >= 2,
        'feedback': 'Saved offline. Will submit for grading when you’re back online.',
        'corrections': <String>[],
      };
    }
  }
}

