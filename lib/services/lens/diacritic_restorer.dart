/// Lexicon-anchored diacritic restoration after Latin OCR (P7-912).
library;

import 'package:lingafriq/services/lens/ocr_diacritic_metrics.dart';
import 'package:lingafriq/services/quiz/diacritic_grader.dart';

/// Copy key: lens.ocr.unsure
const String lensOcrUnsureCopy =
    'We are not sure about these marks. A native speaker should check.';

const double kLensOcrUnsurePerMarkErrorThreshold = 0.35;

final RegExp _combiningMarks = RegExp(r'[\u0300-\u036f\u0323-\u0331]');

const Map<String, String> _hausaImplosiveFold = {
  'ɓ': 'b',
  'ɗ': 'd',
  'ƙ': 'k',
  'ƴ': 'y',
  'Ɓ': 'B',
  'Ɗ': 'D',
  'Ƙ': 'K',
  'Ƴ': 'Y',
};

typedef LexiconFormLookup = List<String> Function(
  String languageCode,
  String foldedToken,
);

class RestoredCharacterSpan {
  const RestoredCharacterSpan({
    required this.start,
    required this.end,
    required this.restored,
  });

  final int start;
  final int end;
  final bool restored;
}

class DiacriticRestoreOutcome {
  const DiacriticRestoreOutcome({
    required this.text,
    required this.unsure,
    required this.restoredSpans,
    this.perMarkErrorRate = 0.0,
  });

  final String text;
  final bool unsure;
  final List<RestoredCharacterSpan> restoredSpans;
  final double perMarkErrorRate;
}

String foldAsciiForOcrMatch(String input) {
  var working = nfc(input);
  for (final entry in _hausaImplosiveFold.entries) {
    working = working.replaceAll(entry.key, entry.value);
  }
  working = working.replaceAll(_combiningMarks, '');
  return working.toLowerCase();
}

bool lensLanguageRequiresServerDiacriticPass(String languageCode) {
  final lang = languageCode.trim().toLowerCase();
  return lang == 'yo' || lang == 'ig' || lang == 'ha';
}

List<RestoredCharacterSpan> diffRestoredSpans({
  required String before,
  required String after,
}) {
  if (before == after) {
    return const [];
  }
  final spans = <RestoredCharacterSpan>[];
  final maxLen = before.length > after.length ? before.length : after.length;
  for (var i = 0; i < maxLen; i++) {
    final b = i < before.length ? before[i] : '';
    final a = i < after.length ? after[i] : '';
    if (b != a) {
      spans.add(RestoredCharacterSpan(start: i, end: i + 1, restored: true));
    }
  }
  return spans;
}

DiacriticRestoreOutcome restoreDiacriticsFromLexicon({
  required String ocrText,
  required String languageCode,
  required LexiconFormLookup lookupForms,
  String? referenceGold,
}) {
  final trimmed = ocrText.trim();
  if (trimmed.isEmpty) {
    return const DiacriticRestoreOutcome(
      text: '',
      unsure: false,
      restoredSpans: [],
    );
  }

  final tokens = trimmed.split(RegExp(r'\s+'));
  final rebuilt = <String>[];
  final spans = <RestoredCharacterSpan>[];
  var offset = 0;
  var anyAmbiguous = false;
  var anyRestored = false;

  for (var t = 0; t < tokens.length; t++) {
    final token = tokens[t];
    final folded = foldAsciiForOcrMatch(token);
    final candidates = lookupForms(languageCode, folded)
        .map(nfc)
        .where((c) => c.isNotEmpty)
        .toList();

    String chosen = token;
    if (candidates.isEmpty) {
      chosen = token;
    } else if (candidates.length == 1) {
      chosen = candidates.first;
      if (chosen != token) {
        anyRestored = true;
        spans.addAll(
          diffRestoredSpans(before: token, after: chosen)
              .map(
                (s) => RestoredCharacterSpan(
                  start: s.start + offset,
                  end: s.end + offset,
                  restored: true,
                ),
              )
              .toList(),
        );
      }
    } else {
      final exact = candidates.where((c) => foldAsciiForOcrMatch(c) == folded);
      if (exact.length == 1) {
        chosen = exact.first;
        if (chosen != token) {
          anyRestored = true;
        }
      } else {
        anyAmbiguous = true;
        chosen = token;
      }
    }

    rebuilt.add(chosen);
    offset += chosen.length;
    if (t < tokens.length - 1) {
      offset += 1;
    }
  }

  final restoredText = rebuilt.join(' ');
  var perMarkError = 0.0;
  if (referenceGold != null && referenceGold.trim().isNotEmpty) {
    final stats = compareOcrDiacriticMarks(
      reference: referenceGold,
      hypothesis: restoredText,
    );
    perMarkError = stats.perMarkErrorRate;
  } else if (anyRestored && languageCode.toLowerCase() != 'sw') {
    perMarkError = anyAmbiguous ? 1.0 : 0.0;
  }

  final unsure =
      anyAmbiguous || perMarkError > kLensOcrUnsurePerMarkErrorThreshold;

  return DiacriticRestoreOutcome(
    text: nfc(restoredText),
    unsure: unsure,
    restoredSpans: spans,
    perMarkErrorRate: perMarkError,
  );
}

DiacriticRestoreOutcome applyServerDiacriticPass({
  required DiacriticRestoreOutcome local,
  required String? serverText,
  required bool serverUnsure,
}) {
  if (serverText == null || serverText.trim().isEmpty) {
    return local;
  }
  final merged = nfc(serverText.trim());
  if (merged == local.text) {
    return DiacriticRestoreOutcome(
      text: local.text,
      unsure: local.unsure || serverUnsure,
      restoredSpans: local.restoredSpans,
      perMarkErrorRate: local.perMarkErrorRate,
    );
  }
  return DiacriticRestoreOutcome(
    text: merged,
    unsure: serverUnsure || local.unsure,
    restoredSpans: diffRestoredSpans(before: local.text, after: merged),
    perMarkErrorRate: local.perMarkErrorRate,
  );
}
