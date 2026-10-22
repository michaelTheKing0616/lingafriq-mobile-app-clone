import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cast/cast_file_cache.dart';
import 'cast/cast_session.dart';
import 'cast/phoneme_viseme.dart';
import 'emotion_system.dart';
import 'personality_system.dart';

class AvatarState {
  final EmotionState emotionState;
  final bool isSpeaking;
  final bool isListening;
  final double confidence;
  final double energy;
  final String? currentActivity;

  const AvatarState({
    required this.emotionState,
    this.isSpeaking = false,
    this.isListening = false,
    this.confidence = 0.5,
    this.energy = 0.5,
    this.currentActivity,
  });

  AvatarState copyWith({
    EmotionState? emotionState,
    bool? isSpeaking,
    bool? isListening,
    double? confidence,
    double? energy,
    String? currentActivity,
  }) {
    return AvatarState(
      emotionState: emotionState ?? this.emotionState,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
      confidence: confidence ?? this.confidence,
      energy: energy ?? this.energy,
      currentActivity: currentActivity ?? this.currentActivity,
    );
  }
}

enum AvatarType {
  polie,
  elder,
  weaver,
  timekeeper,
  griot,
  pathfinder,
  rhythmMaster,
  malaika,
  baba,
  okonkwo,
  nneka,
  userCustom,
}

String presetForAvatar(AvatarType type) {
  switch (type) {
    case AvatarType.polie:
      return 'Polie';
    case AvatarType.elder:
      return 'PaLingAfriq';
    case AvatarType.weaver:
      return 'Adisa';
    case AvatarType.timekeeper:
      return 'Kofi';
    case AvatarType.griot:
      return 'Amara';
    case AvatarType.pathfinder:
      return 'Zuri';
    case AvatarType.rhythmMaster:
      return 'Learner';
    case AvatarType.malaika:
      return 'Tolu_Lagos';
    case AvatarType.baba:
      return 'Ayanwale';
    case AvatarType.okonkwo:
      return 'Otieno_Nairobi';
    case AvatarType.nneka:
      return 'Ama_Accra';
    case AvatarType.userCustom:
      return 'Learner';
  }
}

(String, String) avatarActivityFor(AvatarEmotion emotion) {
  switch (emotion) {
    case AvatarEmotion.idle:
      return ('idle', 'neutral');
    case AvatarEmotion.thinking:
      return ('thinking', 'focused');
    case AvatarEmotion.encouraging:
      return ('encouraging', 'happy');
    case AvatarEmotion.proud:
      return ('idle', 'proud');
    case AvatarEmotion.disappointed:
      return ('idle', 'concerned');
    case AvatarEmotion.happy:
      return ('idle', 'happy');
    case AvatarEmotion.excited:
      return ('celebrating', 'happy');
    case AvatarEmotion.curious:
      return ('idle', 'curious');
    case AvatarEmotion.focused:
      return ('idle', 'focused');
    case AvatarEmotion.sleepy:
      return ('sleeping', 'neutral');
    case AvatarEmotion.celebrating:
      return ('celebrating', 'proud');
    case AvatarEmotion.empathetic:
      return ('encouraging', 'concerned');
    case AvatarEmotion.playful:
      return ('idle', 'playful');
    case AvatarEmotion.listening:
      return ('listening', 'curious');
    case AvatarEmotion.speaking:
      return ('speaking', 'focused');
    case AvatarEmotion.surprised:
      return ('idle', 'surprised');
    case AvatarEmotion.confused:
      return ('hinting', 'concerned');
    case AvatarEmotion.determined:
      return ('idle', 'focused');
    case AvatarEmotion.relieved:
      return ('encouraging', 'happy');
  }
}

class AvatarController {
  final AvatarType type;
  final AvatarPersonality personality;
  final EmotionSystem emotionSystem;
  final CastSession session;

  AvatarState _state = const AvatarState(
    emotionState: EmotionState(primary: AvatarEmotion.idle),
  );
  final _stateController = StreamController<AvatarState>.broadcast();

  AvatarController({
    required this.type,
    required this.personality,
    EmotionSystem? emotionSystem,
    CastSession? session,
  }) : emotionSystem = emotionSystem ?? EmotionSystem(),
       session = session ?? CastSession(preset: presetForAvatar(type));

  AvatarState get state => _state;
  Stream<AvatarState> get stateStream => _stateController.stream;

  void setEmotion(
    AvatarEmotion emotion, {
    EmotionIntensity intensity = EmotionIntensity.moderate,
  }) {
    final transition = emotionSystem.setEmotion(emotion, intensity: intensity);
    final mapped = avatarActivityFor(emotion);
    session.activity(mapped.$1);
    session.expression(mapped.$2, _intensity(intensity));
    _updateState(emotionState: transition.to);
  }

  void setContextualEmotion(
    AvatarContext context, {
    double userConfidence = 0.5,
    bool userSucceeded = true,
  }) {
    final emotionState = emotionSystem.getContextualEmotion(
      context: context,
      userConfidence: userConfidence,
      userSucceeded: userSucceeded,
    );
    final mapped = avatarActivityFor(emotionState.primary);
    session.activity(mapped.$1);
    session.expression(mapped.$2, _intensity(emotionState.intensity));
    _updateState(emotionState: emotionState);
  }

  /// [text] is not a mouth source. Pass [phonemes] from forced alignment.
  void startSpeaking({
    String? text,
    Duration? duration,
    String language = 'default',
    List<AlignedPhoneme> phonemes = const [],
    List<RmsSample> rms = const [],
  }) {
    session.activity('speaking');
    _updateState(isSpeaking: true, currentActivity: 'speaking');
    if (text != null && phonemes.isEmpty && rms.isEmpty) {
      debugPrint(
        'Avatar: transcript ignored until forced alignment provides phonemes',
      );
    }
    if (phonemes.isNotEmpty || rms.isNotEmpty) {
      session.playAlignment(
        LipSyncTrack(language: language, phonemes: phonemes, rms: rms),
      );
    }
    if (duration != null) {
      Future<void>.delayed(duration, stopSpeaking);
    }
  }

  void stopSpeaking() {
    session.stopAlignment();
    _updateState(isSpeaking: false);
  }

  void startListening() {
    session.activity('listening');
    session.expression('curious');
    _updateState(
      isListening: true,
      emotionState: EmotionState.simple(AvatarEmotion.listening),
    );
  }

  void stopListening() {
    session.activity('idle');
    session.expression('neutral');
    _updateState(
      isListening: false,
      emotionState: EmotionState.simple(AvatarEmotion.idle),
    );
  }

  void setConfidence(double confidence) {
    final value = confidence.clamp(0.0, 1.0);
    session.energy(value);
    _updateState(confidence: value);
  }

  void celebrate() {
    session.fire('celebrate');
    setEmotion(AvatarEmotion.celebrating, intensity: EmotionIntensity.extreme);
  }

  void wave() {
    session.fire('wave');
    setEmotion(AvatarEmotion.happy);
  }

  void nod() => session.fire('nod');

  Future<void> playReactionSequence(AvatarReaction reaction) async {
    if (reaction == AvatarReaction.levelUp) session.fire('levelUp');
    if (reaction == AvatarReaction.encourageAfterFail) {
      session.fire('incorrect');
    }
    final sequence = emotionSystem.getReactionSequence(reaction);
    for (final emotionState in sequence) {
      final mapped = avatarActivityFor(emotionState.primary);
      session.activity(mapped.$1);
      session.expression(mapped.$2, _intensity(emotionState.intensity));
      _updateState(emotionState: emotionState);
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
  }

  String getGreeting() => personality.getGreeting();

  String getEncouragement(String context) =>
      personality.getEncouragement(context);

  void reset() {
    emotionSystem.reset();
    stopSpeaking();
    stopListening();
    setEmotion(AvatarEmotion.idle);
    session.energy(0.5);
  }

  void dispose() {
    session.dispose();
    _stateController.close();
  }

  void _updateState({
    EmotionState? emotionState,
    bool? isSpeaking,
    bool? isListening,
    double? confidence,
    double? energy,
    String? currentActivity,
  }) {
    _state = _state.copyWith(
      emotionState: emotionState,
      isSpeaking: isSpeaking,
      isListening: isListening,
      confidence: confidence,
      energy: energy,
      currentActivity: currentActivity,
    );
    if (!_stateController.isClosed) _stateController.add(_state);
  }
}

double _intensity(EmotionIntensity intensity) {
  switch (intensity) {
    case EmotionIntensity.subtle:
      return 0.3;
    case EmotionIntensity.moderate:
      return 0.6;
    case EmotionIntensity.strong:
      return 0.85;
    case EmotionIntensity.extreme:
      return 1;
  }
}

class AvatarEngine {
  static final AvatarEngine _instance = AvatarEngine._internal();
  factory AvatarEngine() => _instance;
  AvatarEngine._internal();

  final PersonalitySystem _personalitySystem = PersonalitySystem();
  final Map<String, AvatarController> _controllers = {};

  Future<AvatarController> getController(
    AvatarType type, {
    String? instanceId,
  }) async {
    final key = instanceId ?? type.name;
    final existing = _controllers[key];
    if (existing != null) return existing;

    final personalityId = _personalityId(type);
    final personality =
        _personalitySystem.getPersonality(personalityId) ??
        _personalitySystem.getPersonality('polie')!;
    await CastFileCache.instance.load();
    final controller = AvatarController(type: type, personality: personality);
    _controllers[key] = controller;
    return controller;
  }

  Future<AvatarController> getGameAvatar(GameCategory category) {
    return getController(_typeForGame(category));
  }

  Future<AvatarController> getOnboardingAvatar(OnboardingStep step) {
    return getController(
      _typeForOnboarding(step),
      instanceId: 'onboarding_${step.name}',
    );
  }

  void releaseController(String key) {
    _controllers.remove(key)?.dispose();
  }

  void releaseAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void clearCache() {}

  PersonalitySystem get personalitySystem => _personalitySystem;

  String _personalityId(AvatarType type) {
    switch (type) {
      case AvatarType.polie:
        return 'polie';
      case AvatarType.elder:
        return 'elder';
      case AvatarType.weaver:
        return 'weaver';
      case AvatarType.timekeeper:
        return 'timekeeper';
      case AvatarType.griot:
        return 'griot';
      case AvatarType.pathfinder:
        return 'pathfinder';
      case AvatarType.malaika:
        return 'malaika';
      case AvatarType.baba:
        return 'baba';
      case AvatarType.okonkwo:
        return 'okonkwo';
      case AvatarType.nneka:
        return 'nneka';
      case AvatarType.rhythmMaster:
      case AvatarType.userCustom:
        return 'polie';
    }
  }

  AvatarType _typeForGame(GameCategory category) {
    switch (category) {
      case GameCategory.vocabulary:
        return AvatarType.malaika;
      case GameCategory.cultural:
        return AvatarType.baba;
      case GameCategory.pronunciation:
        return AvatarType.okonkwo;
      case GameCategory.grammar:
        return AvatarType.nneka;
    }
  }

  AvatarType _typeForOnboarding(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
      case OnboardingStep.profile:
      case OnboardingStep.complete:
        return AvatarType.elder;
      case OnboardingStep.languageSelection:
        return AvatarType.weaver;
      case OnboardingStep.goals:
        return AvatarType.pathfinder;
      case OnboardingStep.learningStyle:
        return AvatarType.rhythmMaster;
      case OnboardingStep.schedule:
        return AvatarType.timekeeper;
      case OnboardingStep.story:
        return AvatarType.griot;
    }
  }
}
