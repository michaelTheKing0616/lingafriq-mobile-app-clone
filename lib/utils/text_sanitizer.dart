/// Lightweight text normalization for reliable UI rendering across devices.
///
/// Why this exists:
/// - Some content includes smart quotes (e.g. “ ”, ‘ ’) and invisible Unicode
///   characters (e.g. zero-width spaces) that can render as odd glyphs on
///   devices/fonts with partial coverage.
/// - We keep diacritics (e.g. Yoruba tones) intact; we only normalize punctuation
///   and strip invisible formatting characters.
class TextSanitizer {
  TextSanitizer._();

  static String sanitize(String input) {
    if (input.isEmpty) return input;

    var s = input;

    // Replace non-breaking spaces with normal spaces.
    s = s.replaceAll('\u00A0', ' ');

    // Strip zero-width/invisible characters that can break rendering/layout.
    s = s.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Normalize “smart quotes” to ASCII quotes.
    s = s
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");

    // Normalize ellipsis to three dots (safer on limited fonts).
    s = s.replaceAll('…', '...');

    return s;
  }
}

