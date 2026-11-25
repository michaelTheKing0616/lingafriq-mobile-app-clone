import 'package:shared_preferences/shared_preferences.dart';

import '../../models/micro_lesson.dart';

class MicroLessonSessionState {
  const MicroLessonSessionState({
    required this.lessonId,
    required this.stepIndex,
    this.paused = false,
  });

  final String lessonId;
  final int stepIndex;
  final bool paused;

  Map<String, dynamic> toJson() => {
        'lesson_id': lessonId,
        'step_index': stepIndex,
        'paused': paused,
      };

  factory MicroLessonSessionState.fromJson(Map<String, dynamic> json) {
    return MicroLessonSessionState(
      lessonId: (json['lesson_id'] ?? '').toString(),
      stepIndex: (json['step_index'] as num?)?.toInt() ?? 0,
      paused: json['paused'] == true,
    );
  }
}

typedef MicroLessonMediaLoader = Future<void> Function(
  MicroLessonStepContent step,
);

/// Validates content, persists resume position, and loads step media.
class MicroLessonService {
  MicroLessonService({
    Future<SharedPreferences> Function()? prefsLoader,
    MicroLessonMediaLoader? mediaLoader,
  })  : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance,
        _mediaLoader = mediaLoader ?? _defaultMediaLoader;

  final Future<SharedPreferences> Function() _prefsLoader;
  final MicroLessonMediaLoader _mediaLoader;

  static String _prefsKey(String lessonId) => 'micro_lesson_session_v1_$lessonId';

  void validateContent(MicroLesson lesson) => assertMicroLessonContentValid(lesson);

  Future<void> saveSession(MicroLessonSessionState state) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_prefsKey(state.lessonId), _encode(state));
  }

  Future<MicroLessonSessionState?> loadSession(String lessonId) async {
    final prefs = await _prefsLoader();
    final raw = prefs.getString(_prefsKey(lessonId));
    if (raw == null || raw.isEmpty) return null;
    return MicroLessonSessionState.fromJson(_decode(raw));
  }

  Future<void> clearSession(String lessonId) async {
    final prefs = await _prefsLoader();
    await prefs.remove(_prefsKey(lessonId));
  }

  Future<void> loadStepMedia(MicroLessonStepContent step) => _mediaLoader(step);

  static Future<void> _defaultMediaLoader(MicroLessonStepContent step) async {
    if (step.mediaKind == MicroLessonMediaKind.none) return;
    final uri = step.mediaUri?.trim();
    if (uri == null || uri.isEmpty) {
      throw MicroLessonMediaException(MicroLessonMediaCodes.missing);
    }
    // Network/asset resolution is delegated to the screen widgets; service only
    // enforces that a URI exists when media is required.
  }

  static String _encode(MicroLessonSessionState state) {
    return '${state.lessonId}|${state.stepIndex}|${state.paused}';
  }

  static Map<String, dynamic> _decode(String raw) {
    final parts = raw.split('|');
    if (parts.length < 3) {
      return {'lesson_id': '', 'step_index': 0, 'paused': false};
    }
    return {
      'lesson_id': parts[0],
      'step_index': int.tryParse(parts[1]) ?? 0,
      'paused': parts[2] == 'true',
    };
  }
}
