import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../customisation/slot_binding.dart';
import 'phoneme_viseme.dart';

class CastPose {
  const CastPose({
    required this.preset,
    this.activity = 'idle',
    this.expression = 'neutral',
    this.intensity = 0.6,
    this.energy = 0.5,
    this.gazeX = 0,
    this.gazeY = 0,
    this.headTilt = 0,
    this.blinkRate = 0.5,
    this.viseme = 'sil',
    this.jawOpen = 0,
    this.reducedMotion = false,
    this.wheelchair = false,
    this.bodyType = 'average',
    this.faceShape = 'oval',
    this.parts = const {},
  });

  final String preset;
  final String activity;
  final String expression;
  final double intensity;
  final double energy;
  final double gazeX;
  final double gazeY;
  final double headTilt;
  final double blinkRate;
  final String viseme;
  final double jawOpen;
  final bool reducedMotion;
  final bool wheelchair;
  final String bodyType;
  final String faceShape;
  final Map<String, String> parts;

  CastPose copyWith({
    String? activity,
    String? expression,
    double? intensity,
    double? energy,
    double? gazeX,
    double? gazeY,
    double? headTilt,
    double? blinkRate,
    String? viseme,
    double? jawOpen,
    bool? reducedMotion,
    bool? wheelchair,
    String? bodyType,
    String? faceShape,
    Map<String, String>? parts,
  }) {
    return CastPose(
      preset: preset,
      activity: activity ?? this.activity,
      expression: expression ?? this.expression,
      intensity: intensity ?? this.intensity,
      energy: energy ?? this.energy,
      gazeX: gazeX ?? this.gazeX,
      gazeY: gazeY ?? this.gazeY,
      headTilt: headTilt ?? this.headTilt,
      blinkRate: blinkRate ?? this.blinkRate,
      viseme: viseme ?? this.viseme,
      jawOpen: jawOpen ?? this.jawOpen,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      wheelchair: wheelchair ?? this.wheelchair,
      bodyType: bodyType ?? this.bodyType,
      faceShape: faceShape ?? this.faceShape,
      parts: parts ?? this.parts,
    );
  }
}

/// Writes CharacterVM. Screens never see this type.
class CastSession extends ChangeNotifier {
  CastSession({required String preset}) : pose = CastPose(preset: preset);

  CastPose pose;
  File? _file;
  AvatarPartCatalog? _partCatalog;
  Map<String, File> _streamedPartFiles = const {};
  ViewModelInstance? _bound;
  ViewModelInstanceTrigger? _tapped;
  VoidCallback? onTapped;
  LipSyncTrack? _track;
  Duration _audioPosition = Duration.zero;

  ViewModelInstance? get bound => _bound;
  File? get file => _file;

  void configurePartCatalog(
    AvatarPartCatalog catalog, {
    Map<String, File> streamedPartFiles = const {},
  }) {
    _partCatalog = catalog;
    _streamedPartFiles = streamedPartFiles;
    _writePose();
  }

  void bind(File file, ViewModelInstance instance) {
    _tapped?.removeListener(_onTapped);
    _file = file;
    _bound = instance;
    _tapped = instance.trigger('tapped');
    _tapped?.addListener(_onTapped);
    _writePose();
  }

  void unbind() {
    _tapped?.removeListener(_onTapped);
    _tapped = null;
    _bound = null;
  }

  void activity(String value) => _set(pose.copyWith(activity: value));

  void expression(String value, [double intensity = 0.6]) {
    _set(pose.copyWith(expression: value, intensity: intensity.clamp(0, 1)));
  }

  void gaze(double x, double y) {
    _set(pose.copyWith(gazeX: x.clamp(-1, 1), gazeY: y.clamp(-1, 1)));
  }

  void fire(String trigger) {
    _bound?.trigger(trigger)?.trigger();
  }

  void energy(double value) => _set(pose.copyWith(energy: value.clamp(0, 1)));

  void viseme(String value, double jaw) {
    _set(pose.copyWith(viseme: value, jawOpen: jaw.clamp(0, 1)));
  }

  void reducedMotion(bool on) => _set(pose.copyWith(reducedMotion: on));

  void wheelchair(bool on) => _set(pose.copyWith(wheelchair: on));

  void body(String bodyType, String faceShape) {
    _set(pose.copyWith(bodyType: bodyType, faceShape: faceShape));
  }

  /// Swap a nested part on the already-decoded file. Does not load another .riv.
  void wear(String slot, String artboardName) {
    final next = Map<String, String>.from(pose.parts);
    next[slot] = artboardName;
    _set(pose.copyWith(parts: next));
  }

  void playAlignment(LipSyncTrack track) {
    _track = track;
    _audioPosition = Duration.zero;
    activity('speaking');
  }

  /// [position] is the audio clock, not wall-clock guessing from letters.
  void syncTo(
    Duration position, {
    Duration delta = const Duration(milliseconds: 16),
  }) {
    _audioPosition = position;
    final track = _track;
    if (track == null) return;
    final sample = track.at(position, delta: delta);
    viseme(sample.viseme, sample.jawOpen);
  }

  Duration get audioPosition => _audioPosition;

  void stopAlignment() {
    _track = null;
    viseme('sil', 0);
    if (pose.activity == 'speaking') activity('idle');
  }

  void onGraded({required bool correct}) {
    fire(correct ? 'correct' : 'incorrect');
    if (correct) {
      expression('proud', 0.85);
      activity('encouraging');
    } else {
      expression('concerned', 0.7);
      activity('hinting');
    }
  }

  void onMic(bool open) => activity(open ? 'listening' : 'idle');

  void onAiStreaming(bool streaming) =>
      activity(streaming ? 'thinking' : 'idle');

  void onPersonaEmotion(String expressionName) => expression(expressionName);

  void onHint() => activity('hinting');

  void onLessonComplete() {
    fire('celebrate');
    activity('celebrating');
    expression('proud', 1);
  }

  void onLevelUp() {
    fire('levelUp');
    activity('celebrating');
    expression('proud', 1);
  }

  void _set(CastPose next) {
    pose = next;
    _writePose();
    notifyListeners();
  }

  void _writePose() {
    final bound = _bound;
    if (bound == null) return;
    bound.enumerator('activity')?.value = pose.activity;
    bound.enumerator('expression')?.value = pose.expression;
    bound.number('intensity')?.value = pose.intensity;
    bound.number('energy')?.value = pose.energy;
    bound.number('gazeX')?.value = pose.gazeX;
    bound.number('gazeY')?.value = pose.gazeY;
    bound.number('headTilt')?.value = pose.headTilt;
    bound.number('blinkRate')?.value = pose.blinkRate;
    bound.enumerator('viseme')?.value = pose.viseme;
    bound.number('jawOpen')?.value = pose.jawOpen;
    bound.boolean('reducedMotion')?.value = pose.reducedMotion;
    bound.boolean('wheelchair')?.value = pose.wheelchair;
    bound.enumerator('bodyType')?.value = pose.bodyType;
    bound.enumerator('faceShape')?.value = pose.faceShape;
    final file = _file;
    final catalog = _partCatalog;
    if (file == null || catalog == null || pose.parts.isEmpty) return;
    SlotBinding(
      catalog: catalog,
      streamedFiles: _streamedPartFiles,
    ).applyParts(instance: bound, mainFile: file, parts: pose.parts);
  }

  void _onTapped(bool fired) {
    if (fired) onTapped?.call();
  }

  @override
  void dispose() {
    _tapped?.removeListener(_onTapped);
    super.dispose();
  }
}
