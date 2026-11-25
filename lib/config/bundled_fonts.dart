import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Google Fonts families the app uses, keyed by family name as passed to
/// [GoogleFonts.getFont]. Every variant ships in assets/google_fonts/ with its
/// OFL licence, so no font request ever leaves the device (audit #5:
/// LG München I, 3 O 17493/20 — a font fetch discloses the user's IP).
const List<String> kBundledFontFamilies = [
  'Andika',
  'Cinzel',
  'Cormorant Garamond',
  'IM Fell English',
  'JetBrains Mono',
  'Libre Baskerville',
  'Philosopher',
  'Playfair Display',
  'Plus Jakarta Sans',
];

/// Families bundled under assets/fonts/lingafriq/ (typography SPEC.md),
/// keyed to their OFL licence file in assets/fonts/lingafriq/licenses/.
const Map<String, String> kLingAfriqFontLicences = {
  'Nunito': 'nunito',
  'Noto Sans': 'notosans',
  'Noto Sans Arabic': 'notosansarabic',
  'Noto Sans Ethiopic': 'notosansethiopic',
  'Noto Sans Tifinagh': 'notosanstifinagh',
  'Noto Sans NKo': 'notosansnko',
  'Noto Sans Vai': 'notosansvai',
  'Noto Sans Adlam': 'notosansadlam',
  'Noto Sans Osmanya': 'notosansosmanya',
  'Noto Sans Bamum': 'notosansbamum',
};

/// Call once before [runApp].
void configureBundledFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(_fontLicences);
}

Stream<LicenseEntry> _fontLicences() async* {
  for (final family in kBundledFontFamilies) {
    final file = family.replaceAll(' ', '');
    final text = await rootBundle.loadString(
      'assets/google_fonts/OFL-$file.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>[family], text);
  }
  for (final e in kLingAfriqFontLicences.entries) {
    final text = await rootBundle.loadString(
      'assets/fonts/lingafriq/licenses/OFL-${e.value}.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>[e.key], text);
  }
}
