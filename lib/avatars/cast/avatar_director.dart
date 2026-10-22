import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cast_contract.dart';
import 'cast_session.dart';

final castDirectorProvider =
    NotifierProvider.family<CastDirector, CastPose, String>(CastDirector.new);

/// Riverpod owner of one character. Widgets bind a controller to [session].
class CastDirector extends Notifier<CastPose> {
  CastDirector(this.preset);

  final String preset;
  late final CastSession session = CastSession(preset: preset);

  @override
  CastPose build() {
    session.addListener(_publish);
    ref.onDispose(() {
      session.removeListener(_publish);
      session.dispose();
    });
    return session.pose;
  }

  void onGraded({required bool correct}) => session.onGraded(correct: correct);

  void onMic(bool open) => session.onMic(open);

  void onAiStreaming(bool streaming) => session.onAiStreaming(streaming);

  void onPersonaEmotion(String expression) =>
      session.onPersonaEmotion(expression);

  void onHint() => session.onHint();

  void onLessonComplete() => session.onLessonComplete();

  void onLevelUp() => session.onLevelUp();

  void wear(String slot, String artboardName) =>
      session.wear(slot, artboardName);

  String get semanticsLabel => castSemanticsLabel(
    name: castSpokenName(preset),
    expression: session.pose.expression,
    activity: session.pose.activity,
  );

  void _publish() {
    if (state == session.pose) return;
    state = session.pose;
  }
}
