import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/text_scale.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/typography.dart';

const List<String> _tabKeys = <String>[
  'shellHome',
  'shellCourses',
  'shellAi',
  'shellSocial',
  'shellProfile',
];

const TextStyle _body = TextStyle(
  fontFamily: LingAfriqType.bodyFamily,
  fontSize: LingAfriqType.bodySize,
  height: LingAfriqType.targetHeight,
);

Future<Map<String, Map<String, String>>> _emit() async {
  final ProcessResult result = await Process.run('python3', <String>[
    'scripts/i18n/pseudo_locale.py',
    '--emit',
  ]);
  expect(
    result.exitCode,
    0,
    reason: '${result.stdout}\n${result.stderr}',
  );
  final Object? decoded = jsonDecode(result.stdout as String);
  final Map<String, dynamic> raw = decoded! as Map<String, dynamic>;
  return raw.map((String key, dynamic value) {
    final Map<String, dynamic> row = value as Map<String, dynamic>;
    return MapEntry(key, row.map((String field, dynamic item) {
      return MapEntry(field, item as String);
    }));
  });
}

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

Future<void> _bindSurface(WidgetTester tester, double width) async {
  final Size surface = Size(width, textScaleSurfaceHeight);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Paints [child] at normal text scale on a fixed phone width.
class _PseudoSurface extends StatelessWidget {
  const _PseudoSurface({required this.width, required this.child});

  final double width;
  final Widget child;

  static const Key surfaceKey = ValueKey<String>('pseudo-locale-surface');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: surfaceKey,
      width: width,
      height: textScaleSurfaceHeight,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: LingAfriqType.bodyFamily,
        ),
        home: Scaffold(body: child),
      ),
    );
  }
}

String _failure(String key, LingTextScaleReport report) {
  return '$key overflow ${report.overflows.join(', ')} '
      'clipped ${report.clipped.join(', ')}';
}

void _expectFits(WidgetTester tester, String key) {
  final LingTextScaleReport report = LingTextScale.report(
    tester.renderObject(find.byType(_PseudoSurface)),
  );
  final List<String> errors = <String>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    errors.add(error.toString());
  }
  if (report.isClean && errors.isEmpty) return;
  fail(<String>[_failure(key, report), ...errors].join(' '));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  test('pseudo strings grow by 40 percent with accents and brackets', () async {
    final ProcessResult result = await Process.run('python3', <String>[
      'scripts/i18n/pseudo_locale.py',
      '--self-test',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('passed'));

    final ProcessResult named = await Process.run('python3', <String>[
      'scripts/i18n/pseudo_locale.py',
      '--fail-key',
      'shellHome',
    ]);
    expect(named.exitCode, 1);
    expect(named.stdout, contains('shellHome'));
  });

  testWidgets('an overflow failure names the key', (WidgetTester tester) async {
    await _bindSurface(tester, textScaleCatalogueWidth);
    await tester.pumpWidget(
      const _PseudoSurface(
        width: textScaleCatalogueWidth,
        child: Row(
          children: <Widget>[
            SizedBox(width: 240, height: 24),
            SizedBox(width: 240, height: 24),
          ],
        ),
      ),
    );
    final LingTextScaleReport report = LingTextScale.report(
      tester.renderObject(find.byType(_PseudoSurface)),
    );
    expect(report.overflows, isNotEmpty);
    expect(_failure('probeKey', report), contains('probeKey'));
    expect(
      tester.takeException().toString(),
      contains('RenderFlex overflowed'),
    );
  });

  testWidgets('shell tabs and onboarding actions fit the pseudo locale', (
    WidgetTester tester,
  ) async {
    final Map<String, Map<String, String>> messages =
        (await tester.runAsync(_emit))!;
    for (final String key in _tabKeys) {
      expect(messages.containsKey(key), isTrue, reason: key);
      expect(messages[key]!['pseudo'], startsWith('['));
      expect(messages[key]!['pseudo'], endsWith(']'));
    }

    await _bindSurface(tester, textScaleNarrowWidth);
    await tester.pumpWidget(
      _PseudoSurface(
        width: textScaleNarrowWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              for (final String key in _tabKeys)
                Expanded(
                  child: Text(
                    messages[key]!['layout']!,
                    key: ValueKey<String>(key),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    _expectFits(tester, 'shellHome');

    await tester.pumpWidget(
      _PseudoSurface(
        width: textScaleNarrowWidth,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                messages['onboardingWhatYearWereYouBorn']!['layout']!,
                style: _body,
              ),
              const SizedBox(height: 12),
              Text(
                messages['onboardingWeUseThisToKeepLearners']!['layout']!,
                style: _body,
              ),
              const SizedBox(height: 12),
              LingButton(
                label: messages['onboardingContinue']!['layout']!,
                unavailableLabel: messages['onboardingContinue']!['layout']!,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    _expectFits(tester, 'onboardingWhatYearWereYouBorn');
  });

  test('every shell and onboarding line fits a narrow phone', () async {
    final Map<String, Map<String, String>> messages = await _emit();
    expect(messages.length, greaterThan(20));
    const TextStyle style = _body;
    final List<String> overflows = <String>[];
    for (final MapEntry<String, Map<String, String>> entry in messages.entries) {
      final String layout = entry.value['layout']!;
      final TextPainter painter = TextPainter(
        text: TextSpan(text: layout, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textScaleNarrowWidth - 32);
      final bool tooWide = painter.width > textScaleNarrowWidth - 32 + 1;
      painter.dispose();
      if (tooWide) overflows.add(entry.key);
    }
    expect(overflows, isEmpty, reason: overflows.join(' '));
  });
}
