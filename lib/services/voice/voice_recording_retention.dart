import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local raw-voice retention (compliance #4). Raw practice audio written to
/// the device temp dir is auto-deleted after a user-chosen period; default 24h.
class VoiceRecordingRetention {
  VoiceRecordingRetention({Future<Directory> Function()? dir})
    : _dir = dir ?? getTemporaryDirectory;

  final Future<Directory> Function() _dir;

  static const String prefKey = 'voice_recording_retention_hours';
  static const int defaultHours = 24;

  /// 0 = delete at next app start / sweep (immediately after processing).
  static const List<int> options = [0, 24, 168, 720];

  /// Raw learner recordings written by the app (never lesson/UGC assets).
  static final RegExp rawPattern = RegExp(
    r'^(voice_recording_|shadowing_|quest_greet|audio|pronunciation|speech)[\w-]*\.(wav|m4a|aac)$',
  );

  static Future<int> hours() async {
    final p = await SharedPreferences.getInstance();
    final h = p.getInt(prefKey);
    return options.contains(h) ? h! : defaultHours;
  }

  static Future<void> setHours(int h) async {
    if (!options.contains(h)) throw ArgumentError.value(h, 'hours');
    final p = await SharedPreferences.getInstance();
    await p.setInt(prefKey, h);
  }

  Iterable<File> _raw(Directory d) => d.existsSync()
      ? d.listSync().whereType<File>().where(
          (f) => rawPattern.hasMatch(f.uri.pathSegments.last),
        )
      : const [];

  /// Deletes raw recordings older than the configured retention.
  Future<int> sweep({DateTime? now, int? hoursOverride}) async {
    final h = hoursOverride ?? await hours();
    final cutoff = (now ?? DateTime.now()).subtract(Duration(hours: h));
    var n = 0;
    for (final f in _raw(await _dir())) {
      if (h == 0 || f.lastModifiedSync().isBefore(cutoff)) {
        f.deleteSync();
        n++;
      }
    }
    return n;
  }

  /// User-initiated "delete my recordings now".
  Future<int> deleteAll() => sweep(hoursOverride: 0);
}
