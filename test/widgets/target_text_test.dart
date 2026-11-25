import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/content/gloss_lookup.dart';
import 'package:lingafriq/widgets/target_text.dart';
import 'package:lingafriq/widgets/tone_lens.dart';

import '../helpers/test_utils.dart';

bool _surfaceUsesTargetText(String source) {
  return source.contains('TargetText(') ||
      source.contains('widgets/target_text.dart');
}

List<String> enforcedTargetTextSurfaceViolations(String packageRoot) {
  final violations = <String>[];
  for (final entry in TargetTextSurfaceContract.entries) {
    if (!entry.enforced) continue;
    final path = entry.relativePath;
    if (path.endsWith('/')) continue;
    final file = File('$packageRoot/$path');
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    if (!_surfaceUsesTargetText(content)) {
      violations.add(path);
    }
  }
  return violations;
}

void main() {
  group('GlossLookup', () {
    test('fromLexemeJson reads gloss and pairs', () {
      final gloss = GlossLookup.fromLexemeJson({
        'senses': [
          {'gloss_en': 'vehicle'},
        ],
        'ipa': '/ɔ̄kɔ̀/',
        'minimal_pairs': ['yo.lex.ọkọ.husband'],
      });
      expect(gloss?.glossEn, 'vehicle');
      expect(gloss?.ipa, '/ɔ̄kɔ̀/');
      expect(gloss?.minimalPairs, hasLength(1));
    });
  });

  group('ToneLens', () {
    test('parse maps rising aliases', () {
      expect(ToneContourKind.parse('R'), ToneContourKind.rising);
      expect(ToneContourKind.parse('rising'), ToneContourKind.rising);
    });
  });

  group('TargetText surfaces (EP-§6.7-02)', () {
    test('contract lists every learner surface category', () {
      final categories = TargetTextSurfaceContract.entries.map((e) => e.category).toSet();
      expect(categories, containsAll(['lessons', 'chat', 'polie', 'personas', 'games', 'magazine', 'dictionary']));
    });

    test('enforced surfaces use TargetText when present on disk', () {
      final root = Directory.current.path;
      expect(enforcedTargetTextSurfaceViolations(root), isEmpty);
    });
  });

  group('TargetText', () {
    testWidgets('tap without audio shows no-audio snackbar', (tester) async {
      await pumpWidgetWithMaterial(
        tester,
        const TargetText(
          text: 'ọkọ̀',
          debugFontFamily: 'Roboto',
        ),
      );
      await tester.tap(find.text('ọkọ̀'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Audio not available'), findsNWidgets(2));
      expect(find.byIcon(Icons.volume_off_outlined), findsOneWidget);
    });

    testWidgets('tap with audio invokes onHear', (tester) async {
      var heard = false;
      await pumpWidgetWithMaterial(
        tester,
        TargetText(
          text: 'ọkọ̀',
          hasAudio: true,
          debugFontFamily: 'Roboto',
          onHear: () async {
            heard = true;
          },
        ),
      );
      await tester.tap(find.text('ọkọ̀'));
      await tester.pumpAndSettle();
      expect(heard, isTrue);
    });

    testWidgets('long press without gloss shows not-available sheet', (tester) async {
      await pumpWidgetWithMaterial(
        tester,
        const TargetText(
          text: 'ọkọ̀',
          debugFontFamily: 'Roboto',
        ),
      );
      await tester.longPress(find.text('ọkọ̀'));
      await tester.pumpAndSettle();
      expect(find.text('Gloss not available'), findsOneWidget);
      expect(find.text('ọkọ̀'), findsWidgets);
    });

    testWidgets('long press with inline gloss shows gloss', (tester) async {
      await pumpWidgetWithMaterial(
        tester,
        const TargetText(
          text: 'ọkọ̀',
          inlineGloss: 'vehicle',
          ipa: '/ɔ̄kɔ̀/',
          debugFontFamily: 'Roboto',
        ),
      );
      await tester.longPress(find.text('ọkọ̀'));
      await tester.pumpAndSettle();
      expect(find.text('vehicle'), findsOneWidget);
      expect(find.text('/ɔ̄kɔ̀/'), findsOneWidget);
    });

    testWidgets('semantics exposes word label', (tester) async {
      await pumpWidgetWithMaterial(
        tester,
        const TargetText(
          text: 'bàbá',
          debugFontFamily: 'Roboto',
        ),
      );
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp(r'bàbá')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('renders tone lens row when pattern provided', (tester) async {
      await pumpWidgetWithMaterial(
        tester,
        const TargetText(
          text: 'ọkọ̀',
          tonePattern: ['M', 'L'],
          debugFontFamily: 'Roboto',
        ),
      );
      expect(find.byType(ToneLens), findsNWidgets(2));
    });
  });
}
