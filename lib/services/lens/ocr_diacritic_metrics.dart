import 'package:lingafriq/services/quiz/diacritic_grader.dart';

/// Per-mark diacritic accuracy for ML Kit Latin OCR verification (P7-944).
class OcrDiacriticMarkStats {
  const OcrDiacriticMarkStats({
    required this.referenceMarks,
    required this.matchedMarks,
    required this.perMarkErrorRate,
    required this.mismatchedClusters,
  });

  final int referenceMarks;
  final int matchedMarks;
  final double perMarkErrorRate;
  final List<String> mismatchedClusters;
}

final RegExp _combiningMarks = RegExp(r'[\u0300-\u036f\u0323-\u0331]');

const Map<int, String> _nfdExpansion = {
  0x00E1: 'a\u0301', // á
  0x1ECD: 'o\u0323', // ọ
  0x1ECB: 'i\u0323', // ị
};

String _toNfd(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final expanded = _nfdExpansion[rune];
    if (expanded != null) {
      buffer.write(expanded);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

List<String> _graphemeClusters(String text) {
  final normalized = _toNfd(nfc(text));
  final clusters = <String>[];
  final runes = normalized.runes.toList();
  var index = 0;
  while (index < runes.length) {
    final buffer = StringBuffer();
    buffer.writeCharCode(runes[index]);
    index += 1;
    while (index < runes.length) {
      final next = String.fromCharCode(runes[index]);
      if (!_combiningMarks.hasMatch(next)) {
        break;
      }
      buffer.write(next);
      index += 1;
    }
    clusters.add(buffer.toString());
  }
  return clusters;
}

String _stripMarks(String cluster) => cluster.replaceAll(_combiningMarks, '');

int _markCount(String cluster) => _combiningMarks.allMatches(cluster).length;

/// Compare [hypothesis] OCR text to [reference] gold sign text (NFC).
OcrDiacriticMarkStats compareOcrDiacriticMarks({
  required String reference,
  required String hypothesis,
}) {
  final refClusters = _graphemeClusters(reference);
  final hypClusters = _graphemeClusters(hypothesis);
  final refBases = refClusters.map(_stripMarks).toList();
  final hypBases = hypClusters.map(_stripMarks).toList();

  var referenceMarks = 0;
  var matchedMarks = 0;
  final mismatched = <String>[];
  var hypIndex = 0;

  for (final refCluster in refClusters) {
    final marks = _markCount(refCluster);
    referenceMarks += marks;
    if (marks == 0) {
      continue;
    }
    final base = _stripMarks(refCluster);
    while (hypIndex < hypBases.length && hypBases[hypIndex] != base) {
      hypIndex += 1;
    }
    if (hypIndex >= hypBases.length) {
      mismatched.add(refCluster);
      continue;
    }
    final hypCluster = hypClusters[hypIndex];
    hypIndex += 1;
    final hypMarks = _markCount(hypCluster);
    matchedMarks += hypMarks < marks ? hypMarks : marks;
    if (hypCluster != refCluster) {
      mismatched.add('$refCluster→$hypCluster');
    }
  }

  final perMarkErrorRate = referenceMarks == 0
      ? 0.0
      : 1.0 - (matchedMarks / referenceMarks);

  return OcrDiacriticMarkStats(
    referenceMarks: referenceMarks,
    matchedMarks: matchedMarks,
    perMarkErrorRate: perMarkErrorRate,
    mismatchedClusters: mismatched,
  );
}
