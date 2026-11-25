import 'package:flutter/material.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

/// What the keyboard is showing. [noLayout] is a widget state: the field stays
/// a normal system-keyboard field, and nothing is thrown.
enum DiacriticKeyboardStatus { ready, noLayout }

/// One base letter and the long-press forms for that letter.
class DiacriticBaseKey {
  const DiacriticBaseKey(this.base, this.variants);

  final String base;
  final List<String> variants;
}

/// Orthography row for one language id.
class DiacriticLanguageLayout {
  const DiacriticLanguageLayout(this.languageId, this.keys);

  final String languageId;
  final List<DiacriticBaseKey> keys;

  Iterable<String> get variants => keys.expand((key) => key.variants);
}

/// Layouts for the six Latin orthographies this keyboard knows.
///
/// Anything else, including Akan/Twi (ɛ ɔ), Ge'ez, N'Ko, Tifinagh and Adlam,
/// has no row. Those scripts are not a Latin long-press map. Tone marks are
/// left off Igbo, Hausa, Zulu, Xhosa and Swahili because those standard
/// orthographies do not write tone. Yoruba mid tone is the unmarked letter.
abstract final class DiacriticLayouts {
  // Yoruba (yo). Standard Yoruba orthography (Bamgbose, Yoruba Orthography,
  // 1965): underdots ẹ ọ ṣ, acute for high, grave for low, mid unmarked.
  static const yo = DiacriticLanguageLayout('yo', [
    DiacriticBaseKey('a', ['\u00E1', '\u00E0']),
    DiacriticBaseKey('e', ['\u1EB9', '\u1EB9\u0301', '\u1EB9\u0300', '\u00E9', '\u00E8']),
    DiacriticBaseKey('i', ['\u00ED', '\u00EC']),
    DiacriticBaseKey('o', ['\u1ECD', '\u1ECD\u0301', '\u1ECD\u0300', '\u00F3', '\u00F2']),
    DiacriticBaseKey('u', ['\u00FA', '\u00F9']),
    DiacriticBaseKey('s', ['\u1E63']),
    DiacriticBaseKey('n', ['\u0144', '\u01F9']),
  ]);

  // Igbo (ig). Ọnwụ orthography (1961): ị ọ ụ and ṅ. Tone is not written.
  static const ig = DiacriticLanguageLayout('ig', [
    DiacriticBaseKey('i', ['\u1ECB']),
    DiacriticBaseKey('o', ['\u1ECD']),
    DiacriticBaseKey('u', ['\u1EE5']),
    DiacriticBaseKey('n', ['\u1E45']),
  ]);

  // Hausa (ha). Nigerian Boko: hooked ɓ ɗ ƙ ƴ. Tone is not written.
  // (Niger writes the palatal as ʼy; this row follows Boko.)
  static const ha = DiacriticLanguageLayout('ha', [
    DiacriticBaseKey('b', ['\u0253']),
    DiacriticBaseKey('d', ['\u0257']),
    DiacriticBaseKey('k', ['\u0199']),
    DiacriticBaseKey('y', ['\u01B4']),
  ]);

  // Zulu (zu). Standard isiZulu spelling (Doke, school orthography) writes
  // clicks on c, q and x: plain, aspirated (h), voiced (g), nasal (n),
  // prenasalised voiced (ng). Tone is not written. No nkc/nkq/nkx series.
  static const zu = DiacriticLanguageLayout('zu', [
    DiacriticBaseKey('c', ['ch', 'gc', 'nc', 'ngc']),
    DiacriticBaseKey('q', ['qh', 'gq', 'nq', 'ngq']),
    DiacriticBaseKey('x', ['xh', 'gx', 'nx', 'ngx']),
  ]);

  // Xhosa (xh). Standard isiXhosa orthography uses the same click manners as
  // Zulu plus the nasal-ejective series nkc, nkq, nkx (inkcukacha, inkqubo,
  // inkxaso). Tone is not written.
  static const xh = DiacriticLanguageLayout('xh', [
    DiacriticBaseKey('c', ['ch', 'gc', 'nc', 'ngc', 'nkc']),
    DiacriticBaseKey('q', ['qh', 'gq', 'nq', 'ngq', 'nkq']),
    DiacriticBaseKey('x', ['xh', 'gx', 'nx', 'ngx', 'nkx']),
  ]);

  // Swahili (sw). Inter-Territorial Language Committee Roman orthography
  // (1930) is plain Latin. ng' is the velar nasal /ŋ/ (ng'ombe), distinct
  // from ng /ŋg/ (ngoma). No accented vowels.
  static const sw = DiacriticLanguageLayout('sw', [
    DiacriticBaseKey('n', ["ng'"]),
  ]);

  static const Map<String, DiacriticLanguageLayout> byLanguage = {
    'yo': yo,
    'ig': ig,
    'ha': ha,
    'zu': zu,
    'xh': xh,
    'sw': sw,
  };

  static DiacriticLanguageLayout? forLanguage(String languageId) {
    return byLanguage[languageId.trim().toLowerCase()];
  }
}

/// Shown when [DiacriticLayouts.forLanguage] has no row. The message is passed
/// in so this file does not own a user-visible sentence.
class DiacriticKeyboardNoLayout extends StatelessWidget {
  const DiacriticKeyboardNoLayout({
    required this.languageId,
    required this.message,
    super.key,
  });

  final String languageId;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: message,
      child: ColoredBox(
        key: const ValueKey<DiacriticKeyboardStatus>(DiacriticKeyboardStatus.noLayout),
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LingAfriqTokens.spacing16,
            vertical: LingAfriqTokens.spacing8,
          ),
          child: ExcludeSemantics(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: LingAfriqType.bodyFamily,
                fontFamilyFallback: LingAfriqType.scriptFallback,
                fontSize: LingAfriqType.bodySize,
                height: LingAfriqType.targetHeight,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Long-press keyboard for African Latin orthographies, above a normal field.
///
/// The field is always an editable [TextField], so the system keyboard stays
/// available. A language with no row shows [DiacriticKeyboardNoLayout].
class DiacriticKeyboard extends StatefulWidget {
  const DiacriticKeyboard({
    required this.languageId,
    required this.controller,
    required this.noLayoutMessage,
    this.focusNode,
    super.key,
  });

  final String languageId;
  final TextEditingController controller;
  final String noLayoutMessage;
  final FocusNode? focusNode;

  DiacriticKeyboardStatus get status => DiacriticLayouts.forLanguage(languageId) == null
      ? DiacriticKeyboardStatus.noLayout
      : DiacriticKeyboardStatus.ready;

  /// The long-press strip does not wait on a long animation. Reduced motion
  /// uses no duration. Otherwise the product instant token, which is under
  /// the fast product motion.
  static Duration popupDuration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return const Duration(milliseconds: LingAfriqTokens.motionProductInstant);
  }

  @override
  State<DiacriticKeyboard> createState() => _DiacriticKeyboardState();
}

class _DiacriticKeyboardState extends State<DiacriticKeyboard> {
  String? _openBase;

  @override
  void didUpdateWidget(DiacriticKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languageId != widget.languageId) {
      _openBase = null;
    }
  }

  void _insert(String grapheme) {
    insertDiacritic(widget.controller, grapheme);
    setState(() => _openBase = null);
  }

  @override
  Widget build(BuildContext context) {
    final layout = DiacriticLayouts.forLanguage(widget.languageId);
    final scheme = Theme.of(context).colorScheme;
    final open = layout?.keys.where((key) => key.base == _openBase).firstOrNull;
    return Material(
      color: scheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey<String>('diacritic-field'),
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: LingAfriqType.target,
            ),
            const SizedBox(height: LingAfriqTokens.spacing8),
            if (layout == null)
              DiacriticKeyboardNoLayout(
                languageId: widget.languageId,
                message: widget.noLayoutMessage,
              )
            else ...[
              if (open != null)
                _VariantStrip(
                  base: open.base,
                  variants: open.variants,
                  duration: DiacriticKeyboard.popupDuration(context),
                  onInsert: _insert,
                ),
              Wrap(
                spacing: LingAfriqTokens.spacing8,
                runSpacing: LingAfriqTokens.spacing8,
                children: [
                  for (final key in layout.keys)
                    _DiacriticKey(
                      grapheme: key.base,
                      onTap: () => _insert(key.base),
                      onLongPress: () => setState(() => _openBase = key.base),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VariantStrip extends StatelessWidget {
  const _VariantStrip({
    required this.base,
    required this.variants,
    required this.duration,
    required this.onInsert,
  });

  final String base;
  final List<String> variants;
  final Duration duration;
  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: duration,
      child: Padding(
        padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
        child: Wrap(
          key: ValueKey<String>('diacritic-variants-$base'),
          spacing: LingAfriqTokens.spacing8,
          runSpacing: LingAfriqTokens.spacing8,
          children: [
            for (final variant in variants)
              _DiacriticKey(
                grapheme: variant,
                onTap: () => onInsert(variant),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiacriticKey extends StatelessWidget {
  const _DiacriticKey({
    required this.grapheme,
    required this.onTap,
    this.onLongPress,
  });

  final String grapheme;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final elevation = dark ? LingAfriqTokens.elevationDarksm : LingAfriqTokens.elevationLightsm;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Semantics(
      button: true,
      label: grapheme,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: elevation,
        borderRadius: const BorderRadius.all(Radius.circular(LingAfriqTokens.radiussm)),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: const BorderRadius.all(Radius.circular(LingAfriqTokens.radiussm)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: LingAfriqTokens.spacing48,
              minHeight: LingAfriqTokens.spacing48,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.all(LingAfriqTokens.spacing4),
                child: ExcludeSemantics(
                  child: TargetText(
                    text: grapheme,
                    textAlign: TextAlign.center,
                    openWordCard: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Inserts [chunk] at the selection and rewrites the field to NFC.
void insertDiacritic(TextEditingController controller, String chunk) {
  final text = controller.text;
  final selection = controller.selection;
  final start = selection.isValid ? selection.start : text.length;
  final end = selection.isValid ? selection.end : text.length;
  final safeStart = start.clamp(0, text.length);
  final safeEnd = end.clamp(safeStart, text.length);
  final before = text.substring(0, safeStart);
  final after = text.substring(safeEnd);
  final normalized = normalizeDiacritics('$before$chunk$after');
  final caret = normalizeDiacritics('$before$chunk').length.clamp(0, normalized.length);
  controller.value = TextEditingValue(
    text: normalized,
    selection: TextSelection.collapsed(offset: caret),
  );
}

/// Canonical composition for the Latin letters this keyboard inserts.
///
/// Keys are the starter. Values map a combining mark to the primary composite.
/// Stacked Yoruba tones have no single code point, so ẹ + acute stays ẹ́.
const Map<int, Map<int, int>> _composition = {
  0x41: {0x0300: 0x00C0, 0x0301: 0x00C1, 0x0304: 0x0100},
  0x45: {0x0300: 0x00C8, 0x0301: 0x00C9, 0x0304: 0x0112, 0x0323: 0x1EB8},
  0x49: {0x0300: 0x00CC, 0x0301: 0x00CD, 0x0304: 0x012A, 0x0323: 0x1ECA},
  0x4E: {0x0300: 0x01F8, 0x0301: 0x0143, 0x0303: 0x00D1, 0x0307: 0x1E44},
  0x4F: {0x0300: 0x00D2, 0x0301: 0x00D3, 0x0304: 0x014C, 0x0323: 0x1ECC},
  0x53: {0x0323: 0x1E62},
  0x55: {0x0300: 0x00D9, 0x0301: 0x00DA, 0x0304: 0x016A, 0x0323: 0x1EE4},
  0x61: {0x0300: 0x00E0, 0x0301: 0x00E1, 0x0304: 0x0101},
  0x65: {0x0300: 0x00E8, 0x0301: 0x00E9, 0x0304: 0x0113, 0x0323: 0x1EB9},
  0x69: {0x0300: 0x00EC, 0x0301: 0x00ED, 0x0304: 0x012B, 0x0323: 0x1ECB},
  0x6E: {0x0300: 0x01F9, 0x0301: 0x0144, 0x0303: 0x00F1, 0x0307: 0x1E45},
  0x6F: {0x0300: 0x00F2, 0x0301: 0x00F3, 0x0304: 0x014D, 0x0323: 0x1ECD},
  0x73: {0x0323: 0x1E63},
  0x75: {0x0300: 0x00F9, 0x0301: 0x00FA, 0x0304: 0x016B, 0x0323: 0x1EE5},
};

Map<int, List<int>>? _decomposition;

Map<int, List<int>> get _decomp {
  final cached = _decomposition;
  if (cached != null) return cached;
  final built = <int, List<int>>{};
  _composition.forEach((base, marks) {
    marks.forEach((mark, composed) {
      built[composed] = <int>[base, mark];
    });
  });
  _decomposition = built;
  return built;
}

/// Combining class for the marks this normaliser reorders. Dot below sits
/// under a tone mark, matching Unicode canonical order.
int _combiningClass(int rune) {
  return switch (rune) {
    0x0323 => 220,
    0x0300 || 0x0301 || 0x0303 || 0x0304 || 0x0307 => 230,
    _ => 0,
  };
}

void _decomposeRune(int rune, List<int> into) {
  final parts = _decomp[rune];
  if (parts == null) {
    into.add(rune);
    return;
  }
  for (final part in parts) {
    _decomposeRune(part, into);
  }
}

List<int> _reorder(List<int> runes) {
  final out = <int>[];
  var index = 0;
  while (index < runes.length) {
    if (_combiningClass(runes[index]) == 0) {
      out.add(runes[index]);
      index += 1;
      continue;
    }
    final start = index;
    while (index < runes.length && _combiningClass(runes[index]) != 0) {
      index += 1;
    }
    final marks = <(int, int)>[
      for (var offset = 0; offset < index - start; offset += 1) (offset, runes[start + offset]),
    ];
    marks.sort((a, b) {
      final byClass = _combiningClass(a.$2).compareTo(_combiningClass(b.$2));
      if (byClass != 0) return byClass;
      return a.$1.compareTo(b.$1);
    });
    for (final mark in marks) {
      out.add(mark.$2);
    }
  }
  return out;
}

List<int> _recompose(List<int> runes) {
  final out = <int>[];
  int? starterIndex;
  var lastClass = 0;
  for (final rune in runes) {
    final markClass = _combiningClass(rune);
    if (starterIndex != null && markClass != 0) {
      final composed = _composition[out[starterIndex]]?[rune];
      if (composed != null && lastClass < markClass) {
        out[starterIndex] = composed;
        continue;
      }
    }
    if (markClass == 0) {
      starterIndex = out.length;
      lastClass = 0;
    } else {
      lastClass = markClass;
    }
    out.add(rune);
  }
  return out;
}

/// NFC for text inserted by the diacritic keyboard.
String normalizeDiacritics(String value) {
  final decomposed = <int>[];
  for (final rune in value.runes) {
    _decomposeRune(rune, decomposed);
  }
  return String.fromCharCodes(_recompose(_reorder(decomposed)));
}
