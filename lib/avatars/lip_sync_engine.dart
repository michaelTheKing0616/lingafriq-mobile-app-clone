import 'dart:async';
import 'package:flutter/foundation.dart';

/// Viseme shapes for mouth animation
/// Based on standard viseme categories adapted for African languages
enum Viseme {
  neutral,     // Rest position
  aa,          // Open vowels (a, ah)
  ee,          // Front vowels (e, i)
  oo,          // Rounded vowels (o, u)
  oh,          // Mid-open rounded (ɔ)
  consonantBilabial,  // p, b, m
  consonantLabiodental, // f, v
  consonantDental,    // t, d, n, l
  consonantVelar,     // k, g, ng
  consonantSibilant,  // s, z, sh
  click,       // Click consonants (Zulu, Xhosa)
}

/// Phoneme to viseme mapping
class PhonemeVisemeMap {
  static const Map<String, Viseme> _standardMap = {
    // Vowels
    'a': Viseme.aa,
    'ɑ': Viseme.aa,
    'æ': Viseme.aa,
    'e': Viseme.ee,
    'ɛ': Viseme.ee,
    'i': Viseme.ee,
    'ɪ': Viseme.ee,
    'o': Viseme.oo,
    'ɔ': Viseme.oh,
    'u': Viseme.oo,
    'ʊ': Viseme.oo,
    
    // Bilabial consonants
    'p': Viseme.consonantBilabial,
    'b': Viseme.consonantBilabial,
    'm': Viseme.consonantBilabial,
    'w': Viseme.consonantBilabial,
    
    // Labiodental
    'f': Viseme.consonantLabiodental,
    'v': Viseme.consonantLabiodental,
    
    // Dental/Alveolar
    't': Viseme.consonantDental,
    'd': Viseme.consonantDental,
    'n': Viseme.consonantDental,
    'l': Viseme.consonantDental,
    'r': Viseme.consonantDental,
    'ɾ': Viseme.consonantDental,
    
    // Velar
    'k': Viseme.consonantVelar,
    'g': Viseme.consonantVelar,
    'ŋ': Viseme.consonantVelar,
    
    // Sibilants
    's': Viseme.consonantSibilant,
    'z': Viseme.consonantSibilant,
    'ʃ': Viseme.consonantSibilant,
    'ʒ': Viseme.consonantSibilant,
    'tʃ': Viseme.consonantSibilant,
    'dʒ': Viseme.consonantSibilant,
    
    // Click consonants (Southern African languages)
    'ǀ': Viseme.click,  // Dental click
    'ǁ': Viseme.click,  // Lateral click
    'ǂ': Viseme.click,  // Palatal click
    'ǃ': Viseme.click,  // Alveolar click
  };
  
  /// African language-specific mappings
  static const Map<String, Map<String, Viseme>> _languageSpecificMaps = {
    'yoruba': {
      'gb': Viseme.consonantVelar,
      'kp': Viseme.consonantVelar,
    },
    'igbo': {
      'gb': Viseme.consonantVelar,
      'kp': Viseme.consonantVelar,
      'gw': Viseme.consonantVelar,
      'kw': Viseme.consonantVelar,
    },
    'zulu': {
      'c': Viseme.click,
      'q': Viseme.click,
      'x': Viseme.click,
    },
    'xhosa': {
      'c': Viseme.click,
      'q': Viseme.click,
      'x': Viseme.click,
    },
    'hausa': {
      'ƙ': Viseme.consonantVelar,
      'ɓ': Viseme.consonantBilabial,
      'ɗ': Viseme.consonantDental,
    },
  };
  
  /// Get viseme for phoneme with language consideration
  static Viseme getViseme(String phoneme, {String? language}) {
    // Check language-specific mapping first
    if (language != null) {
      final langMap = _languageSpecificMaps[language.toLowerCase()];
      if (langMap != null && langMap.containsKey(phoneme)) {
        return langMap[phoneme]!;
      }
    }
    
    // Fall back to standard mapping
    return _standardMap[phoneme] ?? Viseme.neutral;
  }
}

/// Represents a single lip-sync frame
class LipSyncFrame {
  final Viseme viseme;
  final double mouthOpenness;  // 0.0 to 1.0
  final double lipRounding;    // 0.0 to 1.0
  final Duration timestamp;
  final Duration duration;
  
  const LipSyncFrame({
    required this.viseme,
    required this.mouthOpenness,
    required this.lipRounding,
    required this.timestamp,
    required this.duration,
  });
  
  /// Get Rive state machine values
  Map<String, double> toRiveInputs() {
    return {
      'mouthOpenness': mouthOpenness,
      'lipRounding': lipRounding,
      'mouthShape': viseme.index.toDouble(),
    };
  }
}

/// Lip-sync data for a complete utterance
class LipSyncData {
  final String text;
  final List<LipSyncFrame> frames;
  final Duration totalDuration;
  
  const LipSyncData({
    required this.text,
    required this.frames,
    required this.totalDuration,
  });
  
  /// Get frame at specific time
  LipSyncFrame? getFrameAt(Duration time) {
    for (final frame in frames) {
      final frameEnd = frame.timestamp + frame.duration;
      if (time >= frame.timestamp && time < frameEnd) {
        return frame;
      }
    }
    return null;
  }
}

/// Callback for lip-sync frame updates
typedef LipSyncCallback = void Function(LipSyncFrame frame);

/// Lip-Sync Engine - generates and plays lip-sync animations
class LipSyncEngine {
  Timer? _playbackTimer;
  LipSyncData? _currentData;
  int _currentFrameIndex = 0;
  LipSyncCallback? _onFrame;
  VoidCallback? _onComplete;
  bool _isPlaying = false;
  
  /// Whether the engine is currently playing
  bool get isPlaying => _isPlaying;
  
  /// Generate lip-sync data from text
  /// This is a simplified version - production would use phoneme analysis
  LipSyncData generateFromText(String text, {
    Duration averagePhoneDuration = const Duration(milliseconds: 80),
    String? language,
  }) {
    final frames = <LipSyncFrame>[];
    var currentTime = Duration.zero;
    
    // Simple text-to-viseme mapping
    // In production, this would use proper phoneme transcription
    final chars = text.toLowerCase().split('');
    
    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      
      // Skip spaces and punctuation (but add neutral frame)
      if (char == ' ' || RegExp(r'[^\w]').hasMatch(char)) {
        frames.add(LipSyncFrame(
          viseme: Viseme.neutral,
          mouthOpenness: 0.1,
          lipRounding: 0.0,
          timestamp: currentTime,
          duration: averagePhoneDuration ~/ 2,
        ));
        currentTime += averagePhoneDuration ~/ 2;
        continue;
      }
      
      // Get viseme for character
      final viseme = PhonemeVisemeMap.getViseme(char, language: language);
      final (openness, rounding) = _getVisemeParams(viseme);
      
      frames.add(LipSyncFrame(
        viseme: viseme,
        mouthOpenness: openness,
        lipRounding: rounding,
        timestamp: currentTime,
        duration: averagePhoneDuration,
      ));
      
      currentTime += averagePhoneDuration;
    }
    
    // Add closing neutral frame
    frames.add(LipSyncFrame(
      viseme: Viseme.neutral,
      mouthOpenness: 0.0,
      lipRounding: 0.0,
      timestamp: currentTime,
      duration: const Duration(milliseconds: 100),
    ));
    
    return LipSyncData(
      text: text,
      frames: frames,
      totalDuration: currentTime + const Duration(milliseconds: 100),
    );
  }
  
  /// Get mouth parameters for viseme
  (double openness, double rounding) _getVisemeParams(Viseme viseme) {
    switch (viseme) {
      case Viseme.neutral:
        return (0.0, 0.0);
      case Viseme.aa:
        return (0.9, 0.1);
      case Viseme.ee:
        return (0.5, 0.0);
      case Viseme.oo:
        return (0.6, 0.9);
      case Viseme.oh:
        return (0.7, 0.7);
      case Viseme.consonantBilabial:
        return (0.1, 0.3);
      case Viseme.consonantLabiodental:
        return (0.2, 0.1);
      case Viseme.consonantDental:
        return (0.3, 0.0);
      case Viseme.consonantVelar:
        return (0.4, 0.2);
      case Viseme.consonantSibilant:
        return (0.2, 0.0);
      case Viseme.click:
        return (0.3, 0.4);
    }
  }
  
  /// Generate lip-sync from audio waveform (simplified)
  /// In production, this would analyze actual audio amplitude
  LipSyncData generateFromDuration(Duration audioDuration, {
    int wordsPerSecond = 3,
  }) {
    final frames = <LipSyncFrame>[];
    final frameRate = 24; // frames per second
    final frameCount = (audioDuration.inMilliseconds / 1000 * frameRate).ceil();
    final frameDuration = Duration(milliseconds: (1000 / frameRate).round());
    
    var currentTime = Duration.zero;
    
    for (int i = 0; i < frameCount; i++) {
      // Simulate speech pattern with varying openness
      final progress = i / frameCount;
      final speechCycle = (progress * wordsPerSecond * 2 * 3.14159).toInt() % 10;
      
      double openness;
      Viseme viseme;
      
      if (speechCycle < 3) {
        openness = 0.7 + (speechCycle * 0.1);
        viseme = Viseme.aa;
      } else if (speechCycle < 5) {
        openness = 0.5;
        viseme = Viseme.ee;
      } else if (speechCycle < 7) {
        openness = 0.3;
        viseme = Viseme.consonantDental;
      } else {
        openness = 0.4;
        viseme = Viseme.oo;
      }
      
      frames.add(LipSyncFrame(
        viseme: viseme,
        mouthOpenness: openness,
        lipRounding: viseme == Viseme.oo ? 0.8 : 0.2,
        timestamp: currentTime,
        duration: frameDuration,
      ));
      
      currentTime += frameDuration;
    }
    
    return LipSyncData(
      text: '',
      frames: frames,
      totalDuration: audioDuration,
    );
  }
  
  /// Play lip-sync animation
  void play(
    LipSyncData data, {
    LipSyncCallback? onFrame,
    VoidCallback? onComplete,
  }) {
    stop();
    
    _currentData = data;
    _currentFrameIndex = 0;
    _onFrame = onFrame;
    _onComplete = onComplete;
    _isPlaying = true;
    
    _scheduleNextFrame();
  }
  
  void _scheduleNextFrame() {
    if (!_isPlaying || _currentData == null) return;
    
    if (_currentFrameIndex >= _currentData!.frames.length) {
      _isPlaying = false;
      _onComplete?.call();
      return;
    }
    
    final frame = _currentData!.frames[_currentFrameIndex];
    _onFrame?.call(frame);
    
    _currentFrameIndex++;
    
    _playbackTimer = Timer(frame.duration, _scheduleNextFrame);
  }
  
  /// Stop playback
  void stop() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _isPlaying = false;
    _currentData = null;
    _currentFrameIndex = 0;
  }
  
  /// Pause playback
  void pause() {
    _playbackTimer?.cancel();
    _isPlaying = false;
  }
  
  /// Resume playback
  void resume() {
    if (_currentData != null && _currentFrameIndex < _currentData!.frames.length) {
      _isPlaying = true;
      _scheduleNextFrame();
    }
  }
  
  /// Dispose resources
  void dispose() {
    stop();
    _onFrame = null;
    _onComplete = null;
  }
}

/// Lip-sync integration with Rive controller
mixin LipSyncRiveIntegration {
  /// Apply lip-sync frame to Rive inputs
  void applyLipSyncFrame(
    LipSyncFrame frame, {
    required Function(String name, double value) setInput,
  }) {
    final inputs = frame.toRiveInputs();
    inputs.forEach((name, value) {
      setInput(name, value);
    });
  }
}
