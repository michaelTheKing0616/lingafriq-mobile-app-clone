import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/config/bundled_fonts.dart';

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('font fetched from network');
}

const _weights = [
  FontWeight.w100,
  FontWeight.w200,
  FontWeight.w300,
  FontWeight.w400,
  FontWeight.w500,
  FontWeight.w600,
  FontWeight.w700,
  FontWeight.w800,
  FontWeight.w900,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    HttpOverrides.global = _NoNetwork();
    configureBundledFonts();
  });

  test('runtime fetching is off', () {
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  test('every family, weight and style loads from bundled assets', () async {
    // google_fonts reports a missing asset by printing, so capture output.
    final failures = <String>[];
    await runZoned(
      () async {
        for (final family in kBundledFontFamilies) {
          for (final w in _weights) {
            for (final s in FontStyle.values) {
              GoogleFonts.getFont(family, fontWeight: w, fontStyle: s);
            }
          }
          await GoogleFonts.pendingFonts();
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          if (line.contains('unable to load font')) failures.add(line);
        },
      ),
    );
    expect(failures, isEmpty);
  });

  test('lib uses only bundled Google Fonts families', () {
    final methods = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final m in RegExp(
        r'GoogleFonts\.([a-z]\w*)\(',
      ).allMatches(f.readAsStringSync())) {
        if (m[1] != 'getFont') methods.add(m[1]!);
      }
    }
    String method(String family) {
      final c = family.replaceAll(' ', '');
      return c[0].toLowerCase() + c.substring(1);
    }

    final bundled = {
      for (final f in kBundledFontFamilies)
        f == 'IM Fell English' ? 'imFellEnglish' : method(f),
    };
    expect(methods.difference(bundled), isEmpty);
  });

  test('each bundled family ships its OFL licence', () async {
    final entries = await LicenseRegistry.licenses.toList();
    for (final family in kBundledFontFamilies) {
      expect(
        entries.any((e) => e.packages.contains(family)),
        isTrue,
        reason: family,
      );
    }
  });
}
