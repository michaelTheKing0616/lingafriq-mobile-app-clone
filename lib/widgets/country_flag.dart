import 'package:flutter/material.dart';
import 'package:lingafriq/utils/constants.dart';

/// ISO 3166 alpha-2 code decoded from a regional-indicator flag emoji
/// ("🇳🇬" -> "NG"), or null.
String? isoFromFlagEmoji(String emoji) {
  final r = emoji.runes.toList();
  if (r.length != 2) return null;
  const a = 0x1F1E6;
  if (r.any((c) => c < a || c > a + 25)) return null;
  return String.fromCharCodes(r.map((c) => c - a + 0x41));
}

// UK nations use tag-sequence emoji, not regional indicators.
const _subdivisions = {'England': 'ENG', 'Scotland': 'SCT', 'Wales': 'WLS'};

/// ISO code for a country name from [kCountries].
String? isoForCountry(String? name) => name == null
    ? null
    : _subdivisions[name] ?? isoFromFlagEmoji(kCountries[name] ?? '');

// Simplified three-band flags (no emblems) for common learner countries.
// (horizontal?, colours)
const Map<String, (bool, List<int>)> _bands = {
  'NG': (false, [0xFF008751, 0xFFFFFFFF, 0xFF008751]),
  'CI': (false, [0xFFF77F00, 0xFFFFFFFF, 0xFF009E60]),
  'ML': (false, [0xFF14B53A, 0xFFFCD116, 0xFFCE1126]),
  'GN': (false, [0xFFCE1126, 0xFFFCD116, 0xFF009460]),
  'SN': (false, [0xFF00853F, 0xFFFDEF42, 0xFFE31B23]),
  'CM': (false, [0xFF007A5E, 0xFFCE1126, 0xFFFCD116]),
  'TD': (false, [0xFF002664, 0xFFFECB00, 0xFFC60C30]),
  'FR': (false, [0xFF0055A4, 0xFFFFFFFF, 0xFFEF4135]),
  'BE': (false, [0xFF000000, 0xFFFDDA24, 0xFFEF3340]),
  'IT': (false, [0xFF009246, 0xFFFFFFFF, 0xFFCE2B37]),
  'IE': (false, [0xFF169B62, 0xFFFFFFFF, 0xFFFF883E]),
  'GH': (true, [0xFFCE1126, 0xFFFCD116, 0xFF006B3F]),
  'ET': (true, [0xFF078930, 0xFFFCDD09, 0xFFDA121A]),
  'SL': (true, [0xFF1EB53A, 0xFFFFFFFF, 0xFF0072C6]),
  'GA': (true, [0xFF009E60, 0xFFFCD116, 0xFF3A75C4]),
  'GM': (true, [0xFFCE1126, 0xFF0C1C8C, 0xFF3A7728]),
  'DE': (true, [0xFF000000, 0xFFDD0000, 0xFFFFCE00]),
  'NL': (true, [0xFFAE1C28, 0xFFFFFFFF, 0xFF21468B]),
  'EG': (true, [0xFFCE1126, 0xFFFFFFFF, 0xFF000000]),
  'SD': (true, [0xFFD21034, 0xFFFFFFFF, 0xFF000000]),
  'YE': (true, [0xFFCE1126, 0xFFFFFFFF, 0xFF000000]),
};

/// Emoji-free flag: painted bands for known countries, otherwise a badge
/// with the ISO code. Never depends on an emoji font, so it cannot render
/// as an empty box.
class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.country, this.height = 18});
  final String? country;
  final double height;

  @override
  Widget build(BuildContext context) {
    final code = isoForCountry(country);
    final w = height * 1.5;
    final band = code == null ? null : _bands[code];
    final Widget body;
    if (band != null) {
      final cells = [
        for (final c in band.$2)
          Expanded(
            child: ColoredBox(color: Color(c), child: const SizedBox.expand()),
          ),
      ];
      body = band.$1
          ? Column(children: cells)
          : Row(textDirection: TextDirection.ltr, children: cells);
    } else {
      body = ColoredBox(
        color: const Color(0xFF2E3A87),
        child: Center(
          child: Text(
            code ?? '—',
            textScaler: TextScaler.noScaling,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.55,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    return Semantics(
      excludeSemantics: true,
      child: Container(
        key: Key('flag-${code ?? 'none'}'),
        width: w,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0x33000000)),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}
