// Polie Voice Input Service
//
// Thin wrapper over the `speech_to_text` plugin that maps Polie display-name
// languages (e.g. "Yoruba") to BCP-47 locales and exposes a Stream of partial
// + final transcriptions for the AI Chat mic button.
//
// Lifecycle:
//   final svc = PolieVoiceInputService();
//   final ok = await svc.initialize();
//   svc.transcripts.listen((event) { ... });
//   await svc.start(language: 'Yoruba');
//   await svc.stop();
//   svc.dispose();

import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class PolieVoiceTranscript {
  final String text;
  final bool isFinal;
  final double confidence;
  const PolieVoiceTranscript({
    required this.text,
    required this.isFinal,
    required this.confidence,
  });
}

class PolieVoiceInputService {
  PolieVoiceInputService();

  final SpeechToText _speech = SpeechToText();
  final StreamController<PolieVoiceTranscript> _ctrl =
      StreamController<PolieVoiceTranscript>.broadcast();
  bool _initialized = false;
  bool _isListening = false;

  Stream<PolieVoiceTranscript> get transcripts => _ctrl.stream;
  bool get isListening => _isListening;
  bool get isInitialized => _initialized;

  /// Display-name → BCP-47 locale lookup for `speech_to_text`. Maps the
  /// Polie/LingAfriq supported language display names to the closest available
  /// on-device locale. When no exact match exists, falls back to a related
  /// regional variant so STT still functions.
  static String sttLocaleFor(String displayLanguage) {
    final norm = displayLanguage.trim().toLowerCase();
    const map = <String, String>{
      'english': 'en-US',
      'yoruba': 'yo-NG',
      'hausa': 'ha-NG',
      'igbo': 'ig-NG',
      'swahili': 'sw-KE',
      'zulu': 'zu-ZA',
      'xhosa': 'xh-ZA',
      'amharic': 'am-ET',
      'afrikaans': 'af-ZA',
      'somali': 'so-SO',
      'wolof': 'wo-SN',
      'twi': 'tw-GH',
      'akan': 'ak-GH',
      'pidgin': 'en-NG',
      'nigerian pidgin': 'en-NG',
      'pidgin english': 'en-NG',
      'french': 'fr-FR',
      'spanish': 'es-ES',
      'portuguese': 'pt-BR',
      'arabic': 'ar-SA',
      'german': 'de-DE',
      'tigrinya': 'ti-ET',
      'shona': 'sn-ZW',
      'lingala': 'ln-CD',
      'kinyarwanda': 'rw-RW',
      'sesotho': 'st-ZA',
      'setswana': 'tn-ZA',
      'malagasy': 'mg-MG',
      'fula': 'ff-SN',
      'fulani': 'ff-SN',
      'oromo': 'om-ET',
    };
    return map[norm] ?? 'en-US';
  }

  /// Initializes the underlying STT engine and requests microphone
  /// permission. Returns true when ready to listen.
  Future<bool> initialize() async {
    if (_initialized) return true;
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      return false;
    }
    _initialized = await _speech.initialize(
      onError: (err) {
        if (!_ctrl.isClosed) {
          _ctrl.addError(err.errorMsg);
        }
        _isListening = false;
      },
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          _isListening = false;
        }
      },
    );
    return _initialized;
  }

  /// Starts listening for the given language. Emits partial transcripts via
  /// [transcripts]. Caller MUST call [stop] (or rely on auto-stop) to finalize.
  Future<void> start({
    required String language,
    Duration listenFor = const Duration(minutes: 2),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        throw StateError('Speech recognition unavailable on this device.');
      }
    }
    if (_isListening) return;
    _isListening = true;
    await _speech.listen(
      localeId: sttLocaleFor(language),
      listenFor: listenFor,
      pauseFor: pauseFor,
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
      onResult: (result) {
        if (_ctrl.isClosed) return;
        _ctrl.add(
          PolieVoiceTranscript(
            text: result.recognizedWords.trim(),
            isFinal: result.finalResult,
            confidence: result.confidence,
          ),
        );
        if (result.finalResult) {
          _isListening = false;
        }
      },
    );
  }

  Future<void> stop() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  Future<void> cancel() async {
    if (!_isListening) return;
    await _speech.cancel();
    _isListening = false;
  }

  void dispose() {
    if (_isListening) {
      _speech.cancel();
    }
    if (!_ctrl.isClosed) _ctrl.close();
  }
}
