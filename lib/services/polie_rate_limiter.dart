import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client-side sliding-window limit for @Polie calls (abuse / cost control).
///
/// Default: at most [maxPerWindow] successful checks per [windowMs] per [scope].
class PolieRateLimiter {
  PolieRateLimiter._();

  static const String _prefsPrefix = 'polie_rl_v1_';
  static const int maxPerWindow = 10;
  static const int windowMs = 60000;

  /// Returns true if this request may proceed (and records it). False if over limit.
  static Future<bool> allow(String scope) async {
    final safe = _sanitizeScope(scope);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefsPrefix$safe';
      final now = DateTime.now().millisecondsSinceEpoch;
      final raw = prefs.getString(key);
      var stamps = <int>[];
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            stamps = decoded.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
          }
        } catch (_) {}
      }
      stamps = stamps.where((t) => now - t < windowMs).toList();
      if (stamps.length >= maxPerWindow) {
        return false;
      }
      stamps.add(now);
      await prefs.setString(key, jsonEncode(stamps));
      return true;
    } catch (e) {
      debugPrint('PolieRateLimiter.allow failed: $e');
      return true;
    }
  }

  static String _sanitizeScope(String scope) {
    var s = scope.trim();
    if (s.isEmpty) return 'default';
    s = s.replaceAll(RegExp(r'[^a-zA-Z0-9_.\-]'), '_');
    if (s.length > 120) return s.substring(0, 120);
    return s;
  }
}
