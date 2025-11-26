import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'base_provider.dart';

final ttsProvider = NotifierProvider<TTSProvider, BaseProviderState>(() {
  return TTSProvider();
});

class TTSProvider extends BaseProvider {
  final flutterTts = FlutterTts();

  // Language code mapping for African languages
  final Map<String, String> _languageCodes = {
    'Hausa': 'ha-NG', // Hausa (Nigeria)
    'Yoruba': 'yo-NG', // Yoruba (Nigeria)
    'Igbo': 'ig-NG', // Igbo (Nigeria)
    'Swahili': 'sw-KE', // Swahili (Kenya)
    'IsiZulu': 'zu-ZA', // Zulu (South Africa)
    'Zulu': 'zu-ZA', // Zulu (South Africa)
    'Pidgin English': 'en-NG', // English (Nigeria) - closest for Pidgin
    'Nigerian Pidgin': 'en-NG', // English (Nigeria) - closest for Pidgin
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
  }

  /// Set language for TTS based on language name
  Future<void> setLanguage(String languageName) async {
    final languageCode = _languageCodes[languageName] ?? 'en-US';
    await flutterTts.setLanguage(languageCode);
  }

  /// Speak a word with language-specific pronunciation
  Future<void> speak(String word, {String? languageName}) async {
    await flutterTts.stop();
    
    // Set language if provided
    if (languageName != null) {
      await setLanguage(languageName);
    }
    
    // Set speech rate for better pronunciation (slightly slower for learning)
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    
    var result = await flutterTts.speak(word);
    print('TTS speak result: $result');
  }

  Future stop() async {
    var result = await flutterTts.stop();
    print('TTS stop result: $result');
  }
}
