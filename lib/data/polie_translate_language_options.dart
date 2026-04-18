part 'nllb_flores_languages.generated.dart';

/// Display labels and backend keys for Polie translation (hybrid API + NLLB).
///
/// [backendKey] is either a legacy short name (`english`) or a FLORES/NLLB code
/// (`eng_Latn`). The full list is generated into the part file.
class PolieTranslateLanguageOption {
  const PolieTranslateLanguageOption({
    required this.displayName,
    required this.backendKey,
  });

  final String displayName;
  final String backendKey;
}

/// Route / deep-link keys from older builds → FLORES codes in [kPolieTranslateLanguageOptions].
const Map<String, String> kPolieLegacyBackendToFlores = {
  'english': 'eng_Latn',
  'french': 'fra_Latn',
  'spanish': 'spa_Latn',
  'portuguese': 'por_Latn',
  'arabic': 'arb_Arab',
  'german': 'deu_Latn',
  'chinese': 'zho_Hans',
  'yoruba': 'yor_Latn',
  'hausa': 'hau_Latn',
  'igbo': 'ibo_Latn',
  'swahili': 'swh_Latn',
  'zulu': 'zul_Latn',
  'xhosa': 'xho_Latn',
  'amharic': 'amh_Ethi',
  'twi': 'twi_Latn',
  'afrikaans': 'afr_Latn',
  'pidgin': 'pcm_Latn',
  'wolof': 'wol_Latn',
  'somali': 'som_Latn',
};

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
  final mapped = kPolieLegacyBackendToFlores[t];
  if (mapped != null) {
    for (final o in kPolieTranslateLanguageOptions) {
      if (o.backendKey == mapped) return o;
    }
  }
  return null;
}

/// Maps Groq setup names (e.g. "Yoruba", "Nigerian Pidgin") to a known option.
PolieTranslateLanguageOption polieOptionFromGroqLabel(String label) {
  final direct = polieOptionForDisplayName(label);
  if (direct != null) return direct;
  final byKey = polieOptionForBackendKey(label);
  if (byKey != null) return byKey;
  final lower = label.trim().toLowerCase();
  if (lower == 'nigerian pidgin') {
    return kPolieTranslateLanguageOptions.firstWhere(
      (o) => o.backendKey == 'pcm_Latn',
    );
  }
  if (lower == 'english') {
    return kPolieTranslateLanguageOptions.firstWhere(
      (o) => o.backendKey == 'eng_Latn',
    );
  }
  return PolieTranslateLanguageOption(
    displayName: label,
    backendKey: lower.replaceAll(' ', '_'),
  );
}
