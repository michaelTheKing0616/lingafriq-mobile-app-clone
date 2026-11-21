import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/text_scale.dart';
import 'package:lingafriq/design/catalogue/registry.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

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

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required Widget child,
}) async {
  await tester.pumpWidget(LingTextScale(width: width, child: child));
}

void _expectFits(WidgetTester tester, String useCaseId) {
  final LingTextScaleReport report = LingTextScale.report(
    tester.renderObject(find.byType(LingTextScale)),
  );
  final List<String> errors = <String>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    errors.add(error.toString());
  }
  if (report.isClean && errors.isEmpty) return;
  fail(<String>[report.failure(useCaseId), ...errors].join(' '));
}

void _expectOnScreen(WidgetTester tester, String useCaseId) {
  final Rect surface = tester.getRect(find.byKey(LingTextScale.surfaceKey));
  final Rect button = tester.getRect(find.byType(LingButton));
  const double slack = 1;
  expect(
    button.width,
    greaterThanOrEqualTo(LingAfriqTokens.spacing48),
    reason: useCaseId,
  );
  expect(
    button.height,
    greaterThanOrEqualTo(LingAfriqTokens.spacing48),
    reason: useCaseId,
  );
  expect(
    button.left,
    greaterThanOrEqualTo(surface.left - slack),
    reason: useCaseId,
  );
  expect(
    button.top,
    greaterThanOrEqualTo(surface.top - slack),
    reason: useCaseId,
  );
  expect(
    button.right,
    lessThanOrEqualTo(surface.right + slack),
    reason: useCaseId,
  );
  expect(
    button.bottom,
    lessThanOrEqualTo(surface.bottom + slack),
    reason: useCaseId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.targetFamily,
      'assets/google_fonts/Andika-Regular.ttf',
    );
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  testWidgets('overflow failure names the use-case id', (
    WidgetTester tester,
  ) async {
    await _bindSurface(tester, textScaleCatalogueWidth);
    await _pump(
      tester,
      width: textScaleCatalogueWidth,
      child: const Row(
        children: <Widget>[
          SizedBox(width: 240, height: 24),
          SizedBox(width: 240, height: 24),
        ],
      ),
    );
    final LingTextScaleReport report = LingTextScale.report(
      tester.renderObject(find.byType(LingTextScale)),
    );
    expect(report.overflows, isNotEmpty);
    expect(report.failure('probeRow'), contains('probeRow'));
    expect(
      tester.takeException().toString(),
      contains('RenderFlex overflowed'),
    );
  });

  testWidgets('clipped text failure names the use-case id', (
    WidgetTester tester,
  ) async {
    await _bindSurface(tester, textScaleCatalogueWidth);
    await _pump(
      tester,
      width: textScaleCatalogueWidth,
      child: const SizedBox(
        width: 48,
        child: Text(
          'Clipped sample',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    final LingTextScaleReport report = LingTextScale.report(
      tester.renderObject(find.byType(LingTextScale)),
    );
    expect(report.clipped, isNotEmpty);
    expect(report.failure('probeClip'), contains('probeClip'));
    expect(tester.takeException(), isNull);
  });

  for (final CatalogueUseCase useCase in catalogueUseCases) {
    testWidgets('${useCase.id} at 200 percent', (WidgetTester tester) async {
      await _bindSurface(tester, textScaleCatalogueWidth);
      for (final String state in useCase.states) {
        await _pump(
          tester,
          width: textScaleCatalogueWidth,
          child: useCase.build(Brightness.light, 2, state),
        );
        _expectFits(tester, useCase.id);
      }
    });
  }

  testWidgets('primary actions stay on screen at 360', (
    WidgetTester tester,
  ) async {
    await _bindSurface(tester, textScaleNarrowWidth);

    await _pump(
      tester,
      width: textScaleNarrowWidth,
      child: Builder(
        builder: (BuildContext context) {
          final AppLocalizations copy = AppLocalizations.of(context)!;
          return Padding(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            child: LingButton(
              label: copy.commonActionContinue,
              unavailableLabel: copy.commonStateUnavailable,
              onPressed: () {},
            ),
          );
        },
      ),
    );
    _expectFits(tester, 'lingButton');
    _expectOnScreen(tester, 'lingButton');

    await _pump(
      tester,
      width: textScaleNarrowWidth,
      child: Builder(
        builder: (BuildContext context) {
          final AppLocalizations copy = AppLocalizations.of(context)!;
          return Padding(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            child: LingEmptyState(
              title: LingEmptyStateCopy.title,
              whatHappened: LingEmptyStateCopy.whatHappened,
              why: LingEmptyStateCopy.why,
              whatToDo: LingEmptyStateCopy.whatToDo,
              actionLabel: LingEmptyStateCopy.actionLabel,
              unavailableLabel: copy.commonStateUnavailable,
              onAction: () {},
            ),
          );
        },
      ),
    );
    _expectFits(tester, 'lingEmptyState');
    _expectOnScreen(tester, 'lingEmptyState');
  });
}
