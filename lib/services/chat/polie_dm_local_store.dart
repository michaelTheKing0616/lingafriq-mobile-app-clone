import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists Polie-only bubbles in private DMs locally (not sent over WA API).
class PolieDmLocalStore {
  PolieDmLocalStore._();

  static const String _prefix = 'polie_dm_overlay_v1_';
  static const int _maxEntries = 50;

  static String _key(int myUserId, int peerUserId) =>
      '$_prefix${myUserId}_$peerUserId';

  static Future<List<PolieDmStoredBubble>> load(int myUserId, int peerUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(myUserId, peerUserId));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <PolieDmStoredBubble>[];
      for (final e in decoded) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          final b = PolieDmStoredBubble.tryFromJson(m);
          if (b != null) out.add(b);
        }
      }
      out.sort((a, c) => a.atMs.compareTo(c.atMs));
      return out;
    } catch (e) {
      debugPrint('PolieDmLocalStore.load: $e');
      return const [];
    }
  }

  static Future<void> append(int myUserId, int peerUserId, PolieDmStoredBubble bubble) async {
    try {
      final existing = await load(myUserId, peerUserId);
      final next = [...existing, bubble];
      while (next.length > _maxEntries) {
        next.removeAt(0);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(myUserId, peerUserId),
        jsonEncode(next.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('PolieDmLocalStore.append: $e');
    }
  }

  /// Clears stored Polie bubbles for a thread (e.g. after future server-side support).
  static Future<void> clear(int myUserId, int peerUserId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(myUserId, peerUserId));
  }
}

class PolieDmStoredBubble {
  PolieDmStoredBubble({
    required this.id,
    required this.text,
    required this.timeLabel,
    required this.atMs,
  });

  final String id;
  final String text;
  final String timeLabel;
  final int atMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'timeLabel': timeLabel,
        'atMs': atMs,
      };

  static PolieDmStoredBubble? tryFromJson(Map<String, dynamic> m) {
    final id = m['id']?.toString();
    final text = m['text']?.toString();
    if (id == null || id.isEmpty || text == null) return null;
    final atMs = int.tryParse(m['atMs']?.toString() ?? '') ?? 0;
    return PolieDmStoredBubble(
      id: id,
      text: text,
      timeLabel: m['timeLabel']?.toString() ?? '',
      atMs: atMs,
    );
  }
}
