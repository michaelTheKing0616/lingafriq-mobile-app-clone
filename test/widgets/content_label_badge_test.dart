import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/content/label_state.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/widgets/content_label_badge.dart';

import '../helpers/test_utils.dart';

const _betaCopy =
    'AI-assisted, machine-checked. Spotted a problem? Tell us.';

Widget _localized(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('contentLabelBadgeSpec', () {
    test('maps beta to amber copy', () {
      final spec = contentLabelBadgeSpec(
        label: ContentQualityLabel.beta,
        betaCopy: _betaCopy,
        nativeLabel: 'Native-verified',
        expertLabel: 'Expert-reviewed',
      );
      expect(spec!.visibleText, _betaCopy);
      expect(spec.background, ContentLabelColors.beta);
    });

    test('maps native and expert to green and blue', () {
      final native = contentLabelBadgeSpec(
        label: ContentQualityLabel.nativeVerified,
        betaCopy: _betaCopy,
        nativeLabel: 'Native-verified',
        expertLabel: 'Expert-reviewed',
      );
      final expert = contentLabelBadgeSpec(
        label: ContentQualityLabel.expertReviewed,
        betaCopy: _betaCopy,
        nativeLabel: 'Native-verified',
        expertLabel: 'Expert-reviewed',
      );
      expect(native!.background, ContentLabelColors.native);
      expect(expert!.background, ContentLabelColors.expert);
    });
  });

  group('audioKindShowsSyntheticTag', () {
    test('tts kinds show tag; human does not', () {
      expect(audioKindShowsSyntheticTag('tts'), isTrue);
      expect(audioKindShowsSyntheticTag('tts_synthetic'), isTrue);
      expect(audioKindShowsSyntheticTag('human'), isFalse);
      expect(audioKindShowsSyntheticTag(null), isFalse);
    });
  });

  group('ContentHonestyLabels', () {
    testWidgets('beta shows exact copy', (tester) async {
      await tester.pumpWidget(
        _localized(
          ContentHonestyLabels(
            label: ContentQualityLabel.beta,
            audioKind: 'human',
            onReportMistake: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_betaCopy), findsOneWidget);
      expect(find.text('Synthetic voice'), findsNothing);
    });

    testWidgets('tts shows synthetic tag only', (tester) async {
      await tester.pumpWidget(
        _localized(
          ContentHonestyLabels(
            label: ContentQualityLabel.expertReviewed,
            audioKind: 'tts',
            onReportMistake: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Expert-reviewed'), findsOneWidget);
      expect(find.text('Synthetic voice'), findsOneWidget);
    });

    testWidgets('tap label invokes report callback', (tester) async {
      var reported = false;
      await tester.pumpWidget(
        _localized(
          ContentHonestyLabels(
            label: ContentQualityLabel.nativeVerified,
            audioKind: null,
            onReportMistake: () => reported = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Native-verified'));
      expect(reported, isTrue);
    });

    testWidgets('chip meets 48dp touch target', (tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        _localized(
          ContentHonestyLabels(
            label: ContentQualityLabel.beta,
            audioKind: 'human',
            onReportMistake: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getSize(find.text(_betaCopy));
      expect(box.height, lessThanOrEqualTo(48));
      final chip = tester.getSize(find.byType(InkWell).first);
      expect(chip.height, greaterThanOrEqualTo(48));
    });
  });
}
