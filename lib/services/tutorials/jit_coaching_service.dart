/// Just-in-time coaching when a grammar pattern appears for the first time (P7-943).
library;

import 'package:lingafriq/models/coaching_pattern.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum JitCoachingVisibility { hidden, tip, dismissed }

class JitCoachingTipSession {
  const JitCoachingTipSession({
    required this.pattern,
    required this.visibility,
    required this.fromHelp,
  });

  final CoachingPattern pattern;
  final JitCoachingVisibility visibility;
  final bool fromHelp;
}

String _seenKey(String patternId) => 'jit_coaching_seen_$patternId';

String _dismissedKey(String patternId) => 'jit_coaching_dismissed_$patternId';

/// Persists first-hit and dismiss state per pattern id.
class JitCoachingStorage {
  JitCoachingStorage(
    this._seen,
    this._dismissed, {
    SharedPreferences? prefs,
    required bool persist,
  })  : _prefs = prefs,
        _persist = persist;

  final Map<String, bool> _seen;
  final Map<String, bool> _dismissed;
  SharedPreferences? _prefs;
  final bool _persist;

  factory JitCoachingStorage.inMemory({
    Map<String, bool>? seen,
    Map<String, bool>? dismissed,
  }) {
    return JitCoachingStorage(
      seen ?? {},
      dismissed ?? {},
      persist: false,
    );
  }

  factory JitCoachingStorage.sharedPreferences(SharedPreferences prefs) {
    final seen = <String, bool>{};
    final dismissed = <String, bool>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('jit_coaching_seen_') && (prefs.getBool(key) ?? false)) {
        seen[key] = true;
      }
      if (key.startsWith('jit_coaching_dismissed_') &&
          (prefs.getBool(key) ?? false)) {
        dismissed[key] = true;
      }
    }
    return JitCoachingStorage(seen, dismissed, prefs: prefs, persist: true);
  }

  bool hasSeen(String patternId) => _seen[_seenKey(patternId)] ?? false;

  bool isDismissed(String patternId) =>
      _dismissed[_dismissedKey(patternId)] ?? false;

  void markSeen(String patternId) {
    final key = _seenKey(patternId);
    _seen[key] = true;
    _write(key, true);
  }

  void markDismissed(String patternId) {
    final key = _dismissedKey(patternId);
    _dismissed[key] = true;
    _write(key, true);
  }

  void clearDismissed(String patternId) {
    final key = _dismissedKey(patternId);
    _dismissed.remove(key);
    if (_persist && _prefs != null) {
      _prefs!.remove(key);
    }
  }

  void _write(String key, bool value) {
    if (!_persist) return;
    if (_prefs != null) {
      _prefs!.setBool(key, value);
      return;
    }
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      prefs.setBool(key, value);
    });
  }
}

class JitCoachingService {
  JitCoachingService(this._storage);

  final JitCoachingStorage _storage;

  static JitCoachingService? _default;

  static JitCoachingService get defaultInstance {
    return _default ??= JitCoachingService(
      JitCoachingStorage.inMemory(),
    );
  }

  factory JitCoachingService.inMemory({
    Map<String, bool>? seen,
    Map<String, bool>? dismissed,
  }) {
    return JitCoachingService(
      JitCoachingStorage.inMemory(seen: seen, dismissed: dismissed),
    );
  }

  /// AC3: fresh install must not schedule tips at launch.
  bool hasPendingLaunchTour() => false;

  /// AC1: first encounter shows a tip; AC2: repeats stay hidden after dismiss.
  JitCoachingTipSession? onPatternEncountered(CoachingPattern pattern) {
    final id = pattern.id;
    final firstHit = !_storage.hasSeen(id);
    if (firstHit) {
      _storage.markSeen(id);
    } else if (_storage.isDismissed(id)) {
      return null;
    } else if (!firstHit) {
      return null;
    }

    return JitCoachingTipSession(
      pattern: pattern,
      visibility: JitCoachingVisibility.tip,
      fromHelp: false,
    );
  }

  /// AC2: learner reopens from help — show even when dismissed.
  JitCoachingTipSession reopenFromHelp(CoachingPattern pattern) {
    _storage.clearDismissed(pattern.id);
    if (!_storage.hasSeen(pattern.id)) {
      _storage.markSeen(pattern.id);
    }
    return JitCoachingTipSession(
      pattern: pattern,
      visibility: JitCoachingVisibility.tip,
      fromHelp: true,
    );
  }

  void dismiss(CoachingPattern pattern) {
    _storage.markDismissed(pattern.id);
  }

  JitCoachingVisibility visibilityFor(CoachingPattern pattern) {
    if (!_storage.hasSeen(pattern.id)) {
      return JitCoachingVisibility.hidden;
    }
    if (_storage.isDismissed(pattern.id)) {
      return JitCoachingVisibility.dismissed;
    }
    return JitCoachingVisibility.tip;
  }
}
