import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'base_provider.dart';

final ttsProvider = NotifierProvider<TTSProvider, BaseProviderState>(() {
  return TTSProvider();
});

class TTSProvider extends BaseProvider {
  final flutterTts = FlutterTts();

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

  Future speak(String word) async {
    await flutterTts.stop();
    var result = await flutterTts.speak(word);
    print(result);
    // if (result == 1)// setState(() => ttsState = TtsState.playing);
  }

  Future stop() async {
    var result = await flutterTts.stop();
    print(result);
    // if (result == 1) //setState(() => ttsState = TtsState.stopped);
  }
}
