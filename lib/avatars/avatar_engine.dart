import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart';
import 'emotion_system.dart';
import 'personality_system.dart';
import 'lip_sync_engine.dart';

/// Avatar state representing current avatar condition
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

/// Avatar type enumeration
enum AvatarType {
  polie,          // AI assistant
  elder,          // Pa LingAfriq
  weaver,         // Adisa
  timekeeper,     // Kofi
  griot,          // Amara
  pathfinder,     // Zuri
  rhythmMaster,   // Nuru (learning style guide)
  malaika,        // Vocabulary games
  baba,           // Cultural games
  okonkwo,        // Pronunciation games
  nneka,          // Grammar games
  userCustom,     // User's custom avatar
}

/// Rive asset paths for avatars
class AvatarAssets {
  static const String basePath = 'assets/rive/avatars/';
  
  static String getAssetPath(AvatarType type) {
    switch (type) {
      case AvatarType.polie:
        return '${basePath}polie_avatar.riv';
      case AvatarType.elder:
        return '${basePath}elder.riv';
      case AvatarType.weaver:
        return '${basePath}weaver.riv';
      case AvatarType.timekeeper:
        return '${basePath}timekeeper.riv';
      case AvatarType.griot:
        return '${basePath}griot.riv';
      case AvatarType.pathfinder:
        return '${basePath}pathfinder.riv';
      case AvatarType.malaika:
        return '${basePath}malaika.riv';
      case AvatarType.baba:
        return '${basePath}baba.riv';
      case AvatarType.okonkwo:
        return '${basePath}okonkwo.riv';
      case AvatarType.nneka:
        return '${basePath}nneka.riv';
      case AvatarType.rhythmMaster:
        return '${basePath}rhythm_master.riv';
      case AvatarType.userCustom:
        return '${basePath}user_avatar_base.riv';
    }
  }
  
  /// Fallback asset when specific avatar isn't available
  static const String fallbackAsset = '${basePath}game_guide.riv';
}

/// Controller for a single avatar instance
class AvatarController {
  final AvatarType type;
  final AvatarPersonality personality;
  final EmotionSystem emotionSystem;
  final LipSyncEngine lipSyncEngine;
  
  Artboard? _artboard;
  StateMachineController? _stateMachineController;
  
  // State machine inputs
  SMINumber? _emotionInput;
  SMIBool? _isSpeakingInput;
  SMIBool? _isListeningInput;
  SMINumber? _confidenceInput;
  SMINumber? _energyInput;
  SMINumber? _mouthOpennessInput;
  SMINumber? _lipRoundingInput;
  SMINumber? _mouthShapeInput;
  SMITrigger? _celebrateTrigger;
  SMITrigger? _waveTrigger;
  SMITrigger? _nodTrigger;
  
  AvatarState _state = const AvatarState(
    emotionState: EmotionState(primary: AvatarEmotion.idle),
  );
  
  final _stateController = StreamController<AvatarState>.broadcast();
  
  AvatarController({
    required this.type,
    required this.personality,
    EmotionSystem? emotionSystem,
    LipSyncEngine? lipSyncEngine,
  })  : emotionSystem = emotionSystem ?? EmotionSystem(),
        lipSyncEngine = lipSyncEngine ?? LipSyncEngine();
  
  /// Current avatar state
  AvatarState get state => _state;
  
  /// Stream of state changes
  Stream<AvatarState> get stateStream => _stateController.stream;
  
  /// The Rive artboard for rendering
  Artboard? get artboard => _artboard;
  
  /// Initialize with Rive file
  Future<void> initialize(RiveFile riveFile, {String? artboardName}) async {
    try {
      _artboard = artboardName != null 
          ? riveFile.artboardByName(artboardName) 
          : riveFile.mainArtboard;
      
      if (_artboard == null) {
        debugPrint('Avatar: Could not load artboard');
        return;
      }
      
      // Find and attach state machine
      final stateMachine = _artboard!.stateMachines.isNotEmpty
          ? _artboard!.stateMachines.first
          : null;
      
      if (stateMachine != null) {
        _stateMachineController = StateMachineController.fromArtboard(
          _artboard!,
          stateMachine.name,
        );
        
        if (_stateMachineController != null) {
          _artboard!.addController(_stateMachineController!);
          _bindInputs();
        }
      }
      
      // Set initial state based on personality
      _applyPersonalityDefaults();
      
      debugPrint('Avatar: Initialized ${type.name} successfully');
    } catch (e) {
      debugPrint('Avatar: Error initializing - $e');
    }
  }
  
  /// Bind to state machine inputs
  void _bindInputs() {
    if (_stateMachineController == null) return;
    
    for (final input in _stateMachineController!.inputs) {
      switch (input.name) {
        case 'emotion':
          _emotionInput = input as SMINumber?;
          break;
        case 'isSpeaking':
          _isSpeakingInput = input as SMIBool?;
          break;
        case 'isListening':
          _isListeningInput = input as SMIBool?;
          break;
        case 'confidence':
          _confidenceInput = input as SMINumber?;
          break;
        case 'energy':
          _energyInput = input as SMINumber?;
          break;
        case 'mouthOpenness':
          _mouthOpennessInput = input as SMINumber?;
          break;
        case 'lipRounding':
          _lipRoundingInput = input as SMINumber?;
          break;
        case 'mouthShape':
          _mouthShapeInput = input as SMINumber?;
          break;
        case 'celebrate':
          _celebrateTrigger = input as SMITrigger?;
          break;
        case 'wave':
          _waveTrigger = input as SMITrigger?;
          break;
        case 'nod':
          _nodTrigger = input as SMITrigger?;
          break;
      }
    }
  }
  
  /// Apply personality defaults to avatar
  void _applyPersonalityDefaults() {
    final traits = personality.traits;
    _energyInput?.value = traits.energy;
    _confidenceInput?.value = 0.5;
  }
  
  /// Set emotion
  void setEmotion(
    AvatarEmotion emotion, {
    EmotionIntensity intensity = EmotionIntensity.moderate,
  }) {
    final transition = emotionSystem.setEmotion(emotion, intensity: intensity);
    _emotionInput?.value = transition.to.primaryValue;
    _updateState(emotionState: transition.to);
  }
  
  /// Set emotion from context
  void setContextualEmotion(AvatarContext context, {
    double userConfidence = 0.5,
    bool userSucceeded = true,
  }) {
    final emotionState = emotionSystem.getContextualEmotion(
      context: context,
      userConfidence: userConfidence,
      userSucceeded: userSucceeded,
    );
    _emotionInput?.value = emotionState.primaryValue;
    _updateState(emotionState: emotionState);
  }
  
  /// Start speaking (with optional lip-sync)
  void startSpeaking({String? text, Duration? duration}) {
    _isSpeakingInput?.value = true;
    _updateState(isSpeaking: true);
    
    if (text != null) {
      final lipSyncData = lipSyncEngine.generateFromText(text);
      lipSyncEngine.play(
        lipSyncData,
        onFrame: _applyLipSyncFrame,
        onComplete: stopSpeaking,
      );
    } else if (duration != null) {
      final lipSyncData = lipSyncEngine.generateFromDuration(duration);
      lipSyncEngine.play(
        lipSyncData,
        onFrame: _applyLipSyncFrame,
        onComplete: stopSpeaking,
      );
    }
  }
  
  /// Stop speaking
  void stopSpeaking() {
    _isSpeakingInput?.value = false;
    lipSyncEngine.stop();
    _mouthOpennessInput?.value = 0.0;
    _lipRoundingInput?.value = 0.0;
    _updateState(isSpeaking: false);
  }
  
  /// Apply lip-sync frame
  void _applyLipSyncFrame(LipSyncFrame frame) {
    _mouthOpennessInput?.value = frame.mouthOpenness;
    _lipRoundingInput?.value = frame.lipRounding;
    _mouthShapeInput?.value = frame.viseme.index.toDouble();
  }
  
  /// Start listening
  void startListening() {
    _isListeningInput?.value = true;
    setEmotion(AvatarEmotion.listening);
    _updateState(isListening: true);
  }
  
  /// Stop listening
  void stopListening() {
    _isListeningInput?.value = false;
    setEmotion(AvatarEmotion.idle);
    _updateState(isListening: false);
  }
  
  /// Set confidence level
  void setConfidence(double confidence) {
    _confidenceInput?.value = confidence.clamp(0.0, 1.0);
    _updateState(confidence: confidence);
  }
  
  /// Trigger celebration animation
  void celebrate() {
    _celebrateTrigger?.fire();
    setEmotion(AvatarEmotion.celebrating, intensity: EmotionIntensity.extreme);
  }
  
  /// Trigger wave animation
  void wave() {
    _waveTrigger?.fire();
    setEmotion(AvatarEmotion.happy, intensity: EmotionIntensity.moderate);
  }
  
  /// Trigger nod animation
  void nod() {
    _nodTrigger?.fire();
  }
  
  /// Play reaction sequence
  Future<void> playReactionSequence(AvatarReaction reaction) async {
    final sequence = emotionSystem.getReactionSequence(reaction);
    
    for (final emotionState in sequence) {
      _emotionInput?.value = emotionState.primaryValue;
      _updateState(emotionState: emotionState);
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }
  
  /// Get greeting based on personality and time
  String getGreeting() => personality.getGreeting();
  
  /// Get encouragement based on context
  String getEncouragement(String context) => personality.getEncouragement(context);
  
  /// Update internal state and notify listeners
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
    _stateController.add(_state);
  }
  
  /// Reset to idle state
  void reset() {
    emotionSystem.reset();
    stopSpeaking();
    stopListening();
    setEmotion(AvatarEmotion.idle);
    _confidenceInput?.value = 0.5;
    _applyPersonalityDefaults();
  }
  
  /// Dispose resources
  void dispose() {
    lipSyncEngine.dispose();
    _stateController.close();
    _stateMachineController?.dispose();
  }
}

/// Avatar Engine - central management for all avatars
class AvatarEngine {
  static final AvatarEngine _instance = AvatarEngine._internal();
  factory AvatarEngine() => _instance;
  AvatarEngine._internal();
  
  final PersonalitySystem _personalitySystem = PersonalitySystem();
  final Map<String, AvatarController> _controllers = {};
  final Map<String, RiveFile> _cachedRiveFiles = {};
  
  /// Get or create an avatar controller
  Future<AvatarController> getController(
    AvatarType type, {
    String? instanceId,
  }) async {
    final key = instanceId ?? type.name;
    
    if (_controllers.containsKey(key)) {
      return _controllers[key]!;
    }
    
    // Get personality for this avatar type
    final personalityId = _getPersonalityId(type);
    final personality = _personalitySystem.getPersonality(personalityId) ??
        _personalitySystem.getPersonality('polie')!;
    
    // Create controller
    final controller = AvatarController(
      type: type,
      personality: personality,
    );
    
    // Load Rive file
    final riveFile = await _loadRiveFile(type);
    if (riveFile != null) {
      await controller.initialize(riveFile);
    }
    
    _controllers[key] = controller;
    return controller;
  }
  
  /// Get personality ID for avatar type
  String _getPersonalityId(AvatarType type) {
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
      case AvatarType.userCustom:
        return 'polie'; // Default personality for custom avatars
    }
  }
  
  /// Load Rive file with caching
  Future<RiveFile?> _loadRiveFile(AvatarType type) async {
    final assetPath = AvatarAssets.getAssetPath(type);
    
    if (_cachedRiveFiles.containsKey(assetPath)) {
      return _cachedRiveFiles[assetPath];
    }
    
    try {
      final riveFile = await RiveFile.asset(assetPath);
      _cachedRiveFiles[assetPath] = riveFile;
      return riveFile;
    } catch (e) {
      debugPrint('Avatar: Could not load $assetPath - $e');
      
      // Try fallback asset
      try {
        if (!_cachedRiveFiles.containsKey(AvatarAssets.fallbackAsset)) {
          final fallbackFile = await RiveFile.asset(AvatarAssets.fallbackAsset);
          _cachedRiveFiles[AvatarAssets.fallbackAsset] = fallbackFile;
        }
        return _cachedRiveFiles[AvatarAssets.fallbackAsset];
      } catch (e2) {
        debugPrint('Avatar: Could not load fallback asset - $e2');
        return null;
      }
    }
  }
  
  /// Get avatar for game category
  Future<AvatarController> getGameAvatar(GameCategory category) async {
    final type = _getAvatarTypeForGameCategory(category);
    return getController(type);
  }
  
  /// Get avatar for onboarding step
  Future<AvatarController> getOnboardingAvatar(OnboardingStep step) async {
    final type = _getAvatarTypeForOnboardingStep(step);
    return getController(type, instanceId: 'onboarding_${step.name}');
  }
  
  AvatarType _getAvatarTypeForGameCategory(GameCategory category) {
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
  
  AvatarType _getAvatarTypeForOnboardingStep(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
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
      case OnboardingStep.profile:
        return AvatarType.elder;
      case OnboardingStep.complete:
        return AvatarType.elder;
    }
  }
  
  /// Release a specific controller
  void releaseController(String key) {
    _controllers[key]?.dispose();
    _controllers.remove(key);
  }
  
  /// Release all controllers
  void releaseAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
  
  /// Clear Rive file cache
  void clearCache() {
    _cachedRiveFiles.clear();
  }
  
  /// Get personality system for customization
  PersonalitySystem get personalitySystem => _personalitySystem;
}
