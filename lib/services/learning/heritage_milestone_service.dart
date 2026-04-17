import 'dart:convert';

import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Learning v2 heritage milestones — same HTTP pattern as [DialectPreferenceService].
/// Persists last successful API payload and optional pack-manifest list for offline UI.
class HeritageMilestoneService {
  static const _prefsKeyApiSnapshot = 'learning_heritage_milestones_api_snapshot_v1';
  static const _prefsKeyPackManifest = 'learning_heritage_milestones_pack_v1';

  /// Called when a content-pack manifest includes [heritageMilestones] (e.g. after download).
  static Future<void> cacheMilestonesFromPackManifest(List<dynamic> raw) async {
    if (raw.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyPackManifest, jsonEncode(raw));
    } catch (_) {}
  }

  Future<void> _saveApiSnapshot(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyApiSnapshot, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _loadApiSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyApiSnapshot);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return null;
  }

  /// JSON array (as stored from a content-pack manifest) → same shape as [fetchMilestones] pack fallback.
  static Map<String, dynamic>? milestonesPayloadFromPackManifestJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final milestones = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        m['completed'] = m['completed'] == true;
        milestones.add(m);
      }
      if (milestones.isEmpty) return null;
      return {
        'success': true,
        'milestones': milestones,
        'source': 'pack_manifest',
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _milestonesFromPackCache() async {
    final prefs = await SharedPreferences.getInstance();
    return milestonesPayloadFromPackManifestJson(prefs.getString(_prefsKeyPackManifest));
  }

  Future<Map<String, dynamic>> fetchMilestones() async {
    await ApiService.initialize();
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.learningV2.heritageMilestones));
      if (res.statusCode == 200 && res.data is Map) {
        final data = (res.data as Map).cast<String, dynamic>();
        if (data['success'] == true) {
          await _saveApiSnapshot(data);
          return data;
        }
      }
    } catch (_) {
      // Fall through to offline sources.
    }

    final snap = await _loadApiSnapshot();
    if (snap != null && snap['success'] == true) {
      final out = Map<String, dynamic>.from(snap);
      out['source'] = 'cache';
      return out;
    }

    final fromPack = await _milestonesFromPackCache();
    if (fromPack != null) return fromPack;

    throw Exception('Failed to load heritage milestones');
  }

  Future<void> completeMilestone(String milestoneId) async {
    final id = milestoneId.trim();
    if (id.isEmpty) return;
    await ApiService.initialize();
    final res = await ApiService.post(
      ApiContract.url(ApiContract.learningV2.heritageMilestoneComplete),
      data: {'milestoneId': id},
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Failed to complete milestone');
    }
    final data = Map<String, dynamic>.from(res.data as Map);
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Failed to complete milestone');
    }
    await _markCompletedInLocalSnapshot(id);
  }

  /// Keeps [fetchMilestones] offline snapshot aligned after a successful server write.
  Future<void> _markCompletedInLocalSnapshot(String milestoneId) async {
    final snap = await _loadApiSnapshot();
    if (snap == null || snap['success'] != true) return;
    final raw = snap['milestones'];
    if (raw is! List) return;
    final next = <dynamic>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      if (m['id']?.toString() == milestoneId) {
        m['completed'] = true;
      }
      next.add(m);
    }
    final out = Map<String, dynamic>.from(snap);
    out['milestones'] = next;
    await _saveApiSnapshot(out);
  }
}
