import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lens/diacritic_restorer.dart';

List<String> _lookup(String lang, String folded) {
  const table = <String, Map<String, List<String>>>{
    'yo': {
      'bawo': ['Báwo'],
      'oko': ['ọkọ́', 'ọkọ̀'],
    },
    'ig': {
      'ahia': ['Ahịa'],
      'adi': ['Adị'],
      'mma': ['mma'],
    },
    'ha': {
      'a': ['A'],
      'karshe': ['ƙarshe'],
    },
  };
  return table[lang]?[folded] ?? const [];
}

void main() {
  test('restores Bawo to Báwo from single lexicon hit', () {
    final out = restoreDiacriticsFromLexicon(
      ocrText: 'Bawo',
      languageCode: 'yo',
      lookupForms: _lookup,
      referenceGold: 'Báwo',
    );
    expect(out.text, 'Báwo');
    expect(out.unsure, isFalse);
    expect(out.restoredSpans, isNotEmpty);
  });

  test('oko with two tone candidates stays unsure', () {
    final out = restoreDiacriticsFromLexicon(
      ocrText: 'Oko',
      languageCode: 'yo',
      lookupForms: _lookup,
    );
    expect(out.text, 'Oko');
    expect(out.unsure, isTrue);
  });

  test('restores Igbo dot-below on Adi m mma', () {
    List<String> lookup(String lang, String folded) {
      if (lang == 'ig' && folded == 'adi') return ['Adị'];
      if (lang == 'ig' && folded == 'm') return ['m'];
      if (lang == 'ig' && folded == 'mma') return ['mma'];
      return _lookup(lang, folded);
    }

    final out = restoreDiacriticsFromLexicon(
      ocrText: 'Adi m mma',
      languageCode: 'ig',
      lookupForms: lookup,
      referenceGold: 'Adị m mma',
    );
    expect(out.text, 'Adị m mma');
    expect(out.unsure, isFalse);
  });

  test('restores Hausa implosive ƙ from Latin OCR', () {
    List<String> lookup(String lang, String folded) {
      if (lang == 'ha' && folded == 'a') return ['A'];
      if (lang == 'ha' && folded == 'karshe') return ['ƙarshe'];
      return _lookup(lang, folded);
    }

    final out = restoreDiacriticsFromLexicon(
      ocrText: 'A karshe',
      languageCode: 'ha',
      lookupForms: lookup,
      referenceGold: 'A ƙarshe',
    );
    expect(out.text, 'A ƙarshe');
    expect(out.unsure, isFalse);
  });

  test('unsure gate when per-mark error stays high', () {
    final out = restoreDiacriticsFromLexicon(
      ocrText: 'Oko',
      languageCode: 'yo',
      lookupForms: _lookup,
      referenceGold: 'ọkọ́',
    );
    expect(out.unsure, isTrue);
  });

  test('yo ig ha require server diacritic pass per P7-944 ledger', () {
    expect(lensLanguageRequiresServerDiacriticPass('yo'), isTrue);
    expect(lensLanguageRequiresServerDiacriticPass('sw'), isFalse);
  });
}
