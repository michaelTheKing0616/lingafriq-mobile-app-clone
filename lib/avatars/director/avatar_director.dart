import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cast/cast_contract.dart';
import '../cast/cast_file_cache.dart';
import '../cast/cast_session.dart';
import '../cast/phoneme_viseme.dart';
import '../contract/character_vm.dart';
import '../personality_system.dart';

// --- Learning events → CharacterVM (P11-049) ---

enum AvatarLearningEvent {
  answerGraded,
  micOpen,
  micClosed,
  aiStreaming,
  aiIdle,
  hint,
  lessonComplete,
  levelUp,
  personaExpression,
}

CharacterVmState characterVmForLearningEvent(
  AvatarLearningEvent event, {
  bool correct = true,
  String personaExpression = 'neutral',
}) {
  switch (event) {
    case AvatarLearningEvent.answerGraded:
      if (correct) {
        return const CharacterVmState(
          activity: CharacterVmActivity.encouraging,
          expression: CharacterVmExpression.proud,
          intensity: 0.85,
        );
      }
      return const CharacterVmState(
        activity: CharacterVmActivity.hinting,
        expression: CharacterVmExpression.concerned,
        intensity: 0.7,
      );
    case AvatarLearningEvent.micOpen:
      return const CharacterVmState(
        activity: CharacterVmActivity.listening,
        expression: CharacterVmExpression.curious,
      );
    case AvatarLearningEvent.micClosed:
      return const CharacterVmState(activity: CharacterVmActivity.idle);
    case AvatarLearningEvent.aiStreaming:
      return const CharacterVmState(
        activity: CharacterVmActivity.thinking,
        expression: CharacterVmExpression.focused,
      );
    case AvatarLearningEvent.aiIdle:
      return const CharacterVmState(activity: CharacterVmActivity.idle);
    case AvatarLearningEvent.hint:
      return const CharacterVmState(activity: CharacterVmActivity.hinting);
    case AvatarLearningEvent.lessonComplete:
      return const CharacterVmState(
        activity: CharacterVmActivity.celebrating,
        expression: CharacterVmExpression.proud,
        intensity: 1,
      );
    case AvatarLearningEvent.levelUp:
      return const CharacterVmState(
        activity: CharacterVmActivity.celebrating,
        expression: CharacterVmExpression.proud,
        intensity: 1,
      );
    case AvatarLearningEvent.personaExpression:
      final expr = _personaToVmExpression(personaExpression);
      return CharacterVmState(expression: expr);
  }
}

CharacterVmExpression _personaToVmExpression(String raw) {
  final key = raw.trim().toLowerCase();
  for (final v in CharacterVmExpression.values) {
    if (v.riveName == key) return v;
  }
  return CharacterVmExpression.neutral;
}

/// Maps learning events to [CastSession] writes and optional [CharacterVmWriter].
class AvatarDirector {
  AvatarDirector(this.session);

  final CastSession session;
  CharacterVmWriter? _writer;

  void bindWriter(CharacterVmWriter writer) => _writer = writer;

  void handle(
    AvatarLearningEvent event, {
    bool correct = true,
    String? expression,
  }) {
    final vm = characterVmForLearningEvent(
      event,
      correct: correct,
      personaExpression: expression ?? 'neutral',
    );
    _writer?.apply(vm);
    switch (event) {
      case AvatarLearningEvent.answerGraded:
        session.onGraded(correct: correct);
      case AvatarLearningEvent.micOpen:
        session.onMic(true);
      case AvatarLearningEvent.micClosed:
        session.onMic(false);
      case AvatarLearningEvent.aiStreaming:
        session.onAiStreaming(true);
      case AvatarLearningEvent.aiIdle:
        session.onAiStreaming(false);
      case AvatarLearningEvent.hint:
        session.onHint();
      case AvatarLearningEvent.lessonComplete:
        session.onLessonComplete();
      case AvatarLearningEvent.levelUp:
        session.onLevelUp();
      case AvatarLearningEvent.personaExpression:
        session.onPersonaEmotion(expression ?? 'neutral');
    }
  }
}

final castDirectorProvider =
    NotifierProvider.family<CastDirector, CastPose, String>(CastDirector.new);

/// Riverpod owner of one character. Widgets bind a controller to [session].
class CastDirector extends Notifier<CastPose> {
  CastDirector(this.preset);

  final String preset;
  late final CastSession session = CastSession(preset: preset);
  late final AvatarDirector director = AvatarDirector(session);

  @override
  CastPose build() {
    session.addListener(_publish);
    ref.onDispose(() {
      session.removeListener(_publish);
      session.dispose();
    });
    return session.pose;
  }

  void onGraded({required bool correct}) =>
      director.handle(AvatarLearningEvent.answerGraded, correct: correct);

  void onMic(bool open) => director.handle(
        open ? AvatarLearningEvent.micOpen : AvatarLearningEvent.micClosed,
      );

  void onAiStreaming(bool streaming) => director.handle(
        streaming ? AvatarLearningEvent.aiStreaming : AvatarLearningEvent.aiIdle,
      );

  void onPersonaEmotion(String expression) => director.handle(
        AvatarLearningEvent.personaExpression,
        expression: expression,
      );

  void onHint() => director.handle(AvatarLearningEvent.hint);

  void onLessonComplete() => director.handle(AvatarLearningEvent.lessonComplete);

  void onLevelUp() => director.handle(AvatarLearningEvent.levelUp);

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

// --- Emotion vocabulary (formerly emotion_system.dart) ---

/// Extended emotion states for avatars
/// Goes beyond basic emotions to create nuanced, believable character reactions
enum AvatarEmotion {
  // Core emotions (indices 0-5)
  idle,
  thinking,
  encouraging,
  proud,
  disappointed,
  happy,
  
  // Extended emotions (indices 6-12)
  excited,
  curious,
  focused,
  sleepy,
  celebrating,
  empathetic,
  playful,
  
  // Additional nuanced emotions (indices 13-18)
  listening,
  speaking,
  surprised,
  confused,
  determined,
  relieved,
}

/// Emotion intensity levels
enum EmotionIntensity {
  subtle,    // 0.3
  moderate,  // 0.6
  strong,    // 0.85
  extreme,   // 1.0
}

/// Represents a blended emotion state for natural transitions
class EmotionState {
  final AvatarEmotion primary;
  final AvatarEmotion? secondary;
  final double primaryWeight;
  final EmotionIntensity intensity;
  final Duration? duration;
  
  const EmotionState({
    required this.primary,
    this.secondary,
    this.primaryWeight = 1.0,
    this.intensity = EmotionIntensity.moderate,
    this.duration,
  });
  
  /// Create a simple single emotion state
  factory EmotionState.simple(AvatarEmotion emotion, {
    EmotionIntensity intensity = EmotionIntensity.moderate,
  }) {
    return EmotionState(primary: emotion, intensity: intensity);
  }
  
  /// Create a blended emotion state
  factory EmotionState.blended({
    required AvatarEmotion primary,
    required AvatarEmotion secondary,
    double blend = 0.5,
    EmotionIntensity intensity = EmotionIntensity.moderate,
  }) {
    return EmotionState(
      primary: primary,
      secondary: secondary,
      primaryWeight: 1.0 - blend,
      intensity: intensity,
    );
  }
  
  /// Get the numeric value for Rive state machine
  double get primaryValue => primary.index.toDouble();
  double? get secondaryValue => secondary?.index.toDouble();
  
  /// Get intensity as a numeric value
  double get intensityValue {
    switch (intensity) {
      case EmotionIntensity.subtle:
        return 0.3;
      case EmotionIntensity.moderate:
        return 0.6;
      case EmotionIntensity.strong:
        return 0.85;
      case EmotionIntensity.extreme:
        return 1.0;
    }
  }
  
  @override
  String toString() => 'EmotionState($primary${secondary != null ? ' + $secondary' : ''}, intensity: $intensity)';
}

/// Emotion transition configuration
class EmotionTransition {
  final EmotionState from;
  final EmotionState to;
  final Duration duration;
  final Curve curve;
  
  const EmotionTransition({
    required this.from,
    required this.to,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });
}

/// Emotion System - manages avatar emotional states with natural transitions
class EmotionSystem {
  EmotionState _currentState = const EmotionState(primary: AvatarEmotion.idle);
  final List<EmotionTransition> _transitionHistory = [];
  
  /// Current emotion state
  EmotionState get currentState => _currentState;
  
  /// Set emotion with optional transition
  EmotionTransition setEmotion(
    AvatarEmotion emotion, {
    EmotionIntensity intensity = EmotionIntensity.moderate,
    Duration? transitionDuration,
    AvatarEmotion? blendWith,
    double blendAmount = 0.3,
  }) {
    final newState = blendWith != null
        ? EmotionState.blended(
            primary: emotion,
            secondary: blendWith,
            blend: blendAmount,
            intensity: intensity,
          )
        : EmotionState.simple(emotion, intensity: intensity);
    
    final transition = EmotionTransition(
      from: _currentState,
      to: newState,
      duration: transitionDuration ?? _getDefaultTransitionDuration(emotion),
    );
    
    _currentState = newState;
    _transitionHistory.add(transition);
    
    // Keep history manageable
    if (_transitionHistory.length > 50) {
      _transitionHistory.removeRange(0, 25);
    }
    
    return transition;
  }
  
  /// Get context-aware emotion based on situation
  EmotionState getContextualEmotion({
    required AvatarContext context,
    double userConfidence = 0.5,
    bool userSucceeded = true,
  }) {
    switch (context) {
      case AvatarContext.greeting:
        return EmotionState.simple(AvatarEmotion.happy, intensity: EmotionIntensity.moderate);
        
      case AvatarContext.teaching:
        return EmotionState.simple(AvatarEmotion.focused, intensity: EmotionIntensity.moderate);
        
      case AvatarContext.waitingForInput:
        return EmotionState.blended(
          primary: AvatarEmotion.curious,
          secondary: AvatarEmotion.listening,
          intensity: EmotionIntensity.subtle,
        );
        
      case AvatarContext.processingAnswer:
        return EmotionState.simple(AvatarEmotion.thinking, intensity: EmotionIntensity.moderate);
        
      case AvatarContext.correctAnswer:
        final intensity = userConfidence > 0.8 
            ? EmotionIntensity.extreme 
            : EmotionIntensity.strong;
        return EmotionState.simple(AvatarEmotion.proud, intensity: intensity);
        
      case AvatarContext.incorrectAnswer:
        return EmotionState.blended(
          primary: AvatarEmotion.empathetic,
          secondary: AvatarEmotion.encouraging,
          blend: 0.4,
          intensity: EmotionIntensity.moderate,
        );
        
      case AvatarContext.celebration:
        return EmotionState.simple(AvatarEmotion.celebrating, intensity: EmotionIntensity.extreme);
        
      case AvatarContext.encouragement:
        return EmotionState.simple(AvatarEmotion.encouraging, intensity: EmotionIntensity.strong);
        
      case AvatarContext.hint:
        return EmotionState.blended(
          primary: AvatarEmotion.thinking,
          secondary: AvatarEmotion.playful,
          intensity: EmotionIntensity.moderate,
        );
        
      case AvatarContext.idle:
        return EmotionState.simple(AvatarEmotion.idle, intensity: EmotionIntensity.subtle);
    }
  }
  
  /// Get default transition duration based on emotion type
  Duration _getDefaultTransitionDuration(AvatarEmotion emotion) {
    switch (emotion) {
      case AvatarEmotion.celebrating:
      case AvatarEmotion.excited:
        return const Duration(milliseconds: 200); // Quick, energetic
      case AvatarEmotion.thinking:
      case AvatarEmotion.focused:
        return const Duration(milliseconds: 400); // Thoughtful transition
      case AvatarEmotion.sleepy:
        return const Duration(milliseconds: 600); // Slow, drowsy
      default:
        return const Duration(milliseconds: 300); // Standard
    }
  }
  
  /// Reset to idle state
  void reset() {
    _currentState = const EmotionState(primary: AvatarEmotion.idle);
  }
  
  /// Get emotion sequence for complex reactions
  List<EmotionState> getReactionSequence(AvatarReaction reaction) {
    switch (reaction) {
      case AvatarReaction.perfectScore:
        return [
          EmotionState.simple(AvatarEmotion.surprised, intensity: EmotionIntensity.strong),
          EmotionState.simple(AvatarEmotion.celebrating, intensity: EmotionIntensity.extreme),
          EmotionState.simple(AvatarEmotion.proud, intensity: EmotionIntensity.strong),
        ];
        
      case AvatarReaction.levelUp:
        return [
          EmotionState.simple(AvatarEmotion.excited, intensity: EmotionIntensity.extreme),
          EmotionState.simple(AvatarEmotion.celebrating, intensity: EmotionIntensity.extreme),
          EmotionState.simple(AvatarEmotion.happy, intensity: EmotionIntensity.strong),
        ];
        
      case AvatarReaction.streakMilestone:
        return [
          EmotionState.simple(AvatarEmotion.proud, intensity: EmotionIntensity.strong),
          EmotionState.simple(AvatarEmotion.celebrating, intensity: EmotionIntensity.strong),
        ];
        
      case AvatarReaction.encourageAfterFail:
        return [
          EmotionState.simple(AvatarEmotion.empathetic, intensity: EmotionIntensity.moderate),
          EmotionState.simple(AvatarEmotion.encouraging, intensity: EmotionIntensity.strong),
          EmotionState.simple(AvatarEmotion.determined, intensity: EmotionIntensity.moderate),
        ];
        
      case AvatarReaction.thinking:
        return [
          EmotionState.simple(AvatarEmotion.curious, intensity: EmotionIntensity.subtle),
          EmotionState.simple(AvatarEmotion.thinking, intensity: EmotionIntensity.moderate),
        ];
        
      case AvatarReaction.greeting:
        return [
          EmotionState.simple(AvatarEmotion.happy, intensity: EmotionIntensity.strong),
          EmotionState.simple(AvatarEmotion.idle, intensity: EmotionIntensity.subtle),
        ];
    }
  }
}

/// Context for emotion selection
enum AvatarContext {
  greeting,
  teaching,
  waitingForInput,
  processingAnswer,
  correctAnswer,
  incorrectAnswer,
  celebration,
  encouragement,
  hint,
  idle,
}

/// Complex reaction sequences
enum AvatarReaction {
  perfectScore,
  levelUp,
  streakMilestone,
  encourageAfterFail,
  thinking,
  greeting,
}


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

  AvatarType _typeForOnboarding(OnboardingStep step) =>
      onboardingAvatarType(step);

}

/// The cast member who guides each onboarding step.
AvatarType onboardingAvatarType(OnboardingStep step) {
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
