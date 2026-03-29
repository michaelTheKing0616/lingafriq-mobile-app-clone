/// Shared normalization and device-TTS locale mapping for the voice pipeline.
/// Keeps backend TTS requests and on-device fallback aligned on language labels.
library voice_language_utils;

String normalizeVoiceLanguage(String language) {
  var key = language.trim().toLowerCase();
  key = key.replaceAll(RegExp(r'\(.*?\)'), '').trim();
  key = key
      .replaceAll('’', "'")
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ì', 'i')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ọ', 'o')
      .replaceAll('ṣ', 's')
      .replaceAll('ṅ', 'n')
      .replaceAll('ñ', 'n');
  key = key.replaceAll(RegExp(r'\s+'), ' ');
  final compact = key.replaceAll('-', '_').replaceAll(' ', '_');
  const aliases = {
    'yo': 'yoruba',
    'yoruba_language': 'yoruba',
    'yoruba_ng': 'yoruba',
    'yoruba_nigeria': 'yoruba',
    'yoruba_nigerian': 'yoruba',
    'ha': 'hausa',
    'hausa_language': 'hausa',
    'hausa_ng': 'hausa',
    'ig': 'igbo',
    'igbo_language': 'igbo',
    'igbo_ng': 'igbo',
    'sw': 'swahili',
    'kiswahili': 'swahili',
    'swahili_language': 'swahili',
    'zu': 'zulu',
    'xh': 'xhosa',
    'am': 'amharic',
    'so': 'somali',
    'af': 'afrikaans',
    'wo': 'wolof',
    'tw': 'twi',
    'akan': 'twi',
    'pcm': 'pidgin',
    'pidgin_english': 'pidgin',
    'nigerian_pidgin': 'pidgin',
    'nigerian_pidgin_english': 'pidgin',
    'en': 'english',
    'en_us': 'english',
    'en_gb': 'english',
    'fr': 'french',
    'fr_fr': 'french',
    'ar': 'arabic',
    'pt': 'portuguese',
    'pt_br': 'portuguese',
  };
  return aliases[compact] ?? compact;
}

/// Accent / locale hint for `/api/voice/tts/synthesize` (normalized keys).
String accentProfileForNormalized(String normalized) {
  const accents = {
    'yoruba': 'yo-NG',
    'hausa': 'ha-NG',
    'igbo': 'ig-NG',
    'swahili': 'sw-KE',
    'zulu': 'zu-ZA',
    'xhosa': 'xh-ZA',
    'amharic': 'am-ET',
    'somali': 'so-SO',
    'afrikaans': 'af-ZA',
    'wolof': 'wo-SN',
    'twi': 'tw-GH',
    'pidgin': 'pcm-NG',
    'english': 'en-AF',
    'french': 'fr-FR',
    'arabic': 'ar-SA',
    'portuguese': 'pt-BR',
  };
  return accents[normalized] ?? normalized;
}

/// BCP-47 locale for on-device [FlutterTts] after API normalization.
String systemTtsLocaleForNormalized(String normalized) {
  const map = {
    'yoruba': 'yo-NG',
    'hausa': 'ha-NG',
    'igbo': 'ig-NG',
    'swahili': 'sw-KE',
    'zulu': 'zu-ZA',
    'xhosa': 'xh-ZA',
    'amharic': 'am-ET',
    'somali': 'so-SO',
    'afrikaans': 'af-ZA',
    'wolof': 'wo-SN',
    'twi': 'ak-GH',
    'pidgin': 'en-NG',
    'english': 'en-US',
    'french': 'fr-FR',
    'arabic': 'ar-SA',
    'portuguese': 'pt-BR',
  };
  return map[normalized] ?? 'en-US';
}
