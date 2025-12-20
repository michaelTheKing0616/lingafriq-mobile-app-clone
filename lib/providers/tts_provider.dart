import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'base_provider.dart';

final ttsProvider = NotifierProvider<TTSProvider, BaseProviderState>(() {
  return TTSProvider();
});

class TTSProvider extends BaseProvider {
  final flutterTts = FlutterTts();
  List<dynamic> _availableVoices = [];
  bool _voicesLoaded = false;

  // Language code mapping for African languages
  final Map<String, String> _languageCodes = {
    'Hausa': 'ha-NG', // Hausa (Nigeria)
    'Yoruba': 'yo-NG', // Yoruba (Nigeria)
    'Igbo': 'ig-NG', // Igbo (Nigeria)
    'Swahili': 'sw-KE', // Swahili (Kenya)
    'IsiZulu': 'zu-ZA', // Zulu (South Africa)
    'Zulu': 'zu-ZA', // Zulu (South Africa)
    'Pidgin': 'en-NG', // English (Nigeria) - closest for Pidgin
    'Pidgin English': 'en-NG', // English (Nigeria) - closest for Pidgin
    'Nigerian Pidgin': 'en-NG', // English (Nigeria) - closest for Pidgin
    'Afrikaans': 'af-ZA', // Afrikaans (South Africa)
    'Amharic': 'am-ET', // Amharic (Ethiopia)
    'Twi': 'tw-GH', // Twi (Ghana)
    'Xhosa': 'xh-ZA', // Xhosa (South Africa)
  };

  // Preferred voice names for African languages (device-specific)
  final Map<String, List<String>> _preferredVoices = {
    'ha-NG': ['ha-NG', 'hausa', 'nigerian'],
    'yo-NG': ['yo-NG', 'yoruba', 'nigerian'],
    'ig-NG': ['ig-NG', 'igbo', 'nigerian'],
    'sw-KE': ['sw-KE', 'sw-TZ', 'swahili', 'kenyan', 'tanzanian'],
    'zu-ZA': ['zu-ZA', 'zulu', 'south african'],
    'en-NG': ['en-NG', 'nigerian', 'en-ZA', 'south african', 'en-KE', 'kenyan'],
    'af-ZA': ['af-ZA', 'afrikaans', 'south african'],
    'am-ET': ['am-ET', 'amharic', 'ethiopian'],
    'xh-ZA': ['xh-ZA', 'xhosa', 'south african'],
  };

  init() async {
    await flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.ambient,
      [
        IosTextToSpeechAudioCategoryOptions.allowAirPlay,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers
      ],
      IosTextToSpeechAudioMode.spokenAudio,
    );
    
    // Load available voices
    await _loadVoices();
  }

  /// Load available voices from device
  Future<void> _loadVoices() async {
    try {
      _availableVoices = await flutterTts.getVoices ?? [];
      _voicesLoaded = true;
      print('TTS: Loaded ${_availableVoices.length} voices');
    } catch (e) {
      print('TTS: Error loading voices: $e');
      _availableVoices = [];
      _voicesLoaded = true;
    }
  }

  /// Find best matching voice for a language with African accent priority
  String? _findBestVoice(String languageCode) {
    if (_availableVoices.isEmpty) return null;

    final preferred = _preferredVoices[languageCode] ?? [];
    
    print('TTS: Searching for voice for $languageCode from ${_availableVoices.length} available voices');
    
    // Step 1: Try to find exact locale match
    for (var voice in _availableVoices) {
      final voiceName = (voice['name'] ?? '').toString().toLowerCase();
      final voiceLocale = (voice['locale'] ?? '').toString().toLowerCase();
      
      // Exact locale match
      if (voiceLocale == languageCode.toLowerCase()) {
        print('TTS: ✓ Found exact voice match: $voiceName ($voiceLocale)');
        return voice['name'];
      }
    }
    
    // Step 2: Try preferred voice patterns (African-specific)
    for (var pattern in preferred) {
      for (var voice in _availableVoices) {
        final voiceName = (voice['name'] ?? '').toString().toLowerCase();
        final voiceLocale = (voice['locale'] ?? '').toString().toLowerCase();
        
        if (voiceLocale.contains(pattern.toLowerCase()) || 
            voiceName.contains(pattern.toLowerCase())) {
          print('TTS: ✓ Found preferred voice: $voiceName ($voiceLocale)');
          return voice['name'];
        }
      }
    }
    
    // Step 3: For Nigerian languages, try any Nigerian English voice
    if (languageCode.contains('NG')) {
      for (var voice in _availableVoices) {
        final voiceName = (voice['name'] ?? '').toString().toLowerCase();
        final voiceLocale = (voice['locale'] ?? '').toString().toLowerCase();
        
        if (voiceLocale.contains('en-ng') || voiceLocale.contains('nigeria') || 
            voiceName.contains('nigeria')) {
          print('TTS: ✓ Found Nigerian fallback voice: $voiceName ($voiceLocale)');
          return voice['name'];
        }
      }
    }
    
    // Step 4: For South African languages, try any South African voice
    if (languageCode.contains('ZA')) {
      for (var voice in _availableVoices) {
        final voiceName = (voice['name'] ?? '').toString().toLowerCase();
        final voiceLocale = (voice['locale'] ?? '').toString().toLowerCase();
        
        if (voiceLocale.contains('za') || voiceLocale.contains('south africa') || 
            voiceName.contains('south africa')) {
          print('TTS: ✓ Found South African fallback voice: $voiceName ($voiceLocale)');
          return voice['name'];
        }
      }
    }
    
    print('TTS: ✗ No specific voice found for $languageCode, using system default');
    return null;
  }

  /// Set language for TTS based on language name with voice selection
  Future<void> setLanguage(String languageName) async {
    final languageCode = _languageCodes[languageName] ?? 'en-US';
    
    // Ensure voices are loaded
    if (!_voicesLoaded) {
      await _loadVoices();
    }
    
    // Set language
    await flutterTts.setLanguage(languageCode);
    
    // Try to set a specific voice for African accent
    final bestVoice = _findBestVoice(languageCode);
    if (bestVoice != null) {
      try {
        await flutterTts.setVoice({"name": bestVoice, "locale": languageCode});
        print('TTS: Set voice to $bestVoice for $languageName');
      } catch (e) {
        print('TTS: Could not set voice: $e');
      }
    }
  }

  /// Speak text with African language-specific pronunciation and accent
  Future<void> speak(String text, {String? languageName}) async {
    try {
      // Always stop any ongoing speech first
      await flutterTts.stop();
      
      // Ensure voices are loaded
      if (!_voicesLoaded) {
        await _loadVoices();
      }
      
      // Set language and voice if provided
      if (languageName != null && languageName.isNotEmpty) {
        await setLanguage(languageName);
        print('TTS: 🔊 Speaking in $languageName with African accent');
      } else {
        // Default to English if no language specified
        await flutterTts.setLanguage('en-US');
        print('TTS: 🔊 Speaking in default English');
      }
      
      // Set speech parameters for natural pronunciation
      // Adjusted for African language learning - clear and natural
      await flutterTts.setSpeechRate(0.48); // Slightly slower for clarity
      await flutterTts.setPitch(1.0); // Natural pitch
      await flutterTts.setVolume(1.0); // Full volume
      
      // Speak the text
      var result = await flutterTts.speak(text);
      print('TTS: ✓ Speech initiated for: ${languageName ?? "default"}');
    } catch (e) {
      print('TTS: ✗ Error speaking: $e');
      // Fallback to default voice if African voice fails
      try {
        await flutterTts.setLanguage('en-US');
        await flutterTts.speak(text);
        print('TTS: ⚠ Using fallback English voice');
      } catch (fallbackError) {
        print('TTS: ✗ Fallback also failed: $fallbackError');
      }
    }
  }
  
  /// Check if African voices are available for a language
  Future<bool> hasAfricanVoice(String languageName) async {
    if (!_voicesLoaded) {
      await _loadVoices();
    }
    
    final languageCode = _languageCodes[languageName];
    if (languageCode == null) return false;
    
    return _findBestVoice(languageCode) != null;
  }
  
  /// Get list of available African voices for debugging
  Future<List<Map<String, String>>> getAfricanVoices() async {
    if (!_voicesLoaded) {
      await _loadVoices();
    }
    
    final africanVoices = <Map<String, String>>[];
    
    for (var voice in _availableVoices) {
      final locale = (voice['locale'] ?? '').toString().toLowerCase();
      // Filter for African country codes
      if (locale.contains('ng') || // Nigeria
          locale.contains('za') || // South Africa
          locale.contains('ke') || // Kenya
          locale.contains('tz') || // Tanzania
          locale.contains('et') || // Ethiopia
          locale.contains('gh')) { // Ghana
        africanVoices.add({
          'name': voice['name']?.toString() ?? 'Unknown',
          'locale': voice['locale']?.toString() ?? 'Unknown',
        });
      }
    }
    
    return africanVoices;
  }

  Future stop() async {
    var result = await flutterTts.stop();
    print('TTS stop result: $result');
  }
}
