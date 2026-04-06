/// Display labels and backend keys for Polie translation (hybrid API + prompts).
class PolieTranslateLanguageOption {
  const PolieTranslateLanguageOption({
    required this.displayName,
    required this.backendKey,
  });

  final String displayName;
  final String backendKey;
}

/// Languages users can pick as source or target. [backendKey] matches
/// [TranslationService] / NLLB-style naming where applicable.
const List<PolieTranslateLanguageOption> kPolieTranslateLanguageOptions = [
  PolieTranslateLanguageOption(displayName: 'English', backendKey: 'english'),
  PolieTranslateLanguageOption(displayName: 'French', backendKey: 'french'),
  PolieTranslateLanguageOption(displayName: 'Spanish', backendKey: 'spanish'),
  PolieTranslateLanguageOption(displayName: 'Portuguese', backendKey: 'portuguese'),
  PolieTranslateLanguageOption(displayName: 'Arabic', backendKey: 'arabic'),
  PolieTranslateLanguageOption(displayName: 'German', backendKey: 'german'),
  PolieTranslateLanguageOption(displayName: 'Chinese', backendKey: 'chinese'),
  PolieTranslateLanguageOption(displayName: 'Yoruba', backendKey: 'yoruba'),
  PolieTranslateLanguageOption(displayName: 'Hausa', backendKey: 'hausa'),
  PolieTranslateLanguageOption(displayName: 'Igbo', backendKey: 'igbo'),
  PolieTranslateLanguageOption(displayName: 'Swahili', backendKey: 'swahili'),
  PolieTranslateLanguageOption(displayName: 'Zulu', backendKey: 'zulu'),
  PolieTranslateLanguageOption(displayName: 'Xhosa', backendKey: 'xhosa'),
  PolieTranslateLanguageOption(displayName: 'Amharic', backendKey: 'amharic'),
  PolieTranslateLanguageOption(displayName: 'Twi', backendKey: 'twi'),
  PolieTranslateLanguageOption(displayName: 'Afrikaans', backendKey: 'afrikaans'),
  PolieTranslateLanguageOption(
    displayName: 'Nigerian Pidgin',
    backendKey: 'pidgin',
  ),
  PolieTranslateLanguageOption(displayName: 'Wolof', backendKey: 'wolof'),
  PolieTranslateLanguageOption(displayName: 'Somali', backendKey: 'somali'),
];

PolieTranslateLanguageOption? polieOptionForDisplayName(String name) {
  final t = name.trim();
  for (final o in kPolieTranslateLanguageOptions) {
    if (o.displayName.toLowerCase() == t.toLowerCase()) return o;
  }
  return null;
}

PolieTranslateLanguageOption? polieOptionForBackendKey(String key) {
  final t = key.trim().toLowerCase();
  for (final o in kPolieTranslateLanguageOptions) {
    if (o.backendKey.toLowerCase() == t) return o;
  }
  return null;
}

/// Maps Groq setup names (e.g. "Yoruba", "Nigerian Pidgin") to a known option.
PolieTranslateLanguageOption polieOptionFromGroqLabel(String label) {
  final direct = polieOptionForDisplayName(label);
  if (direct != null) return direct;
  final lower = label.trim().toLowerCase();
  if (lower == 'nigerian pidgin') {
    return kPolieTranslateLanguageOptions.firstWhere((o) => o.backendKey == 'pidgin');
  }
  if (lower == 'english') {
    return kPolieTranslateLanguageOptions.firstWhere((o) => o.backendKey == 'english');
  }
  return PolieTranslateLanguageOption(
    displayName: label,
    backendKey: lower.replaceAll(' ', '_'),
  );
}
