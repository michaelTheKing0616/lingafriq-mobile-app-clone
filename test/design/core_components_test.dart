import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/catalogue/registry.dart';
import 'package:lingafriq/design/components/ling_bottom_sheet.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_card.dart';
import 'package:lingafriq/design/components/ling_chip.dart';
import 'package:lingafriq/design/components/ling_dialog.dart';
import 'package:lingafriq/design/components/ling_list_row.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/components/ling_text_field.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

const Set<String> _verbs = <String>{'continue', 'save', 'try', 'close', 'show'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('common action labels start with a verb', () {
    final Map<String, dynamic> arb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    final Map<String, String> actions = <String, String>{};
    for (final MapEntry<String, dynamic> entry in arb.entries) {
      if (entry.key.startsWith('@') || entry.value is! String) continue;
      if (!entry.key.startsWith('commonAction')) continue;
      actions[entry.key] = entry.value as String;
    }
    expect(
      actions.keys,
      containsAll(<String>[
        'commonActionContinue',
        'commonActionSave',
        'commonActionTryAgain',
        'commonActionClose',
        'commonActionShowMore',
      ]),
    );
    for (final MapEntry<String, String> entry in actions.entries) {
      final String word = entry.value.split(' ').first.toLowerCase();
      expect(_verbs, contains(word), reason: '${entry.key} ${entry.value}');
      final Object? meta = arb['@${entry.key}'];
      expect(meta, isA<Map<String, dynamic>>());
      expect(
        (meta as Map<String, dynamic>)['description'],
        'common.action.${_tail(entry.key)}',
      );
      expect(entry.value.contains('\u2014'), isFalse);
    }
    expect(arb['commonStateUnavailable'], 'Unavailable');
  });

  test('ramp surface is not the legacy cream', () {
    expect(LingAfriqTokens.roleLightSurface, isNot(LingAfriqTokens.surface));
    expect(LingAfriqTokens.roleDarkSurface, isNot(LingAfriqTokens.surface));
    expect(
      LingAfriqTokens.roleLightAccent,
      isNot(LingAfriqTokens.roleLightSurface),
    );
    expect(
      LingAfriqTokens.roleLightOnAccent,
      isNot(LingAfriqTokens.roleLightAccent),
    );
  });

  test('product motion stays within 300 ms and reduced motion is gentler', () {
    expect(lingSettle(false).inMilliseconds, inInclusiveRange(1, 300));
    expect(lingSettle(true).inMilliseconds, inInclusiveRange(1, 300));
    expect(
      lingSettle(true).inMilliseconds,
      greaterThan(lingSettle(false).inMilliseconds),
    );
    expect(lingPressAmount(true), lessThan(lingPressAmount(false)));
    expect(lingPressAmount(true), greaterThan(0));
    expect(LingAfriqTokens.motionProductSlow, lessThanOrEqualTo(300));
    expect(LingAfriqTokens.motionProductEasing, 'cubic-bezier(0.23,1,0.32,1)');
  });

  test('component sources do not hard-code a colour', () {
    final Directory root = Directory('lib/design/components');
    expect(root.existsSync(), isTrue);
    for (final FileSystemEntity entity in root.listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String text = entity.readAsStringSync();
      expect(text.contains('Color(0x'), isFalse, reason: entity.path);
      expect(
        RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(text),
        isFalse,
        reason: entity.path,
      );
      expect(
        text.contains('LingAfriqTokens.surface'),
        isFalse,
        reason: entity.path,
      );
    }
  });

  testWidgets('every core control is at least 48 dp', (
    WidgetTester tester,
  ) async {
    await _pumpCatalogue(tester);
    final Map<String, String> copy = _englishActions();
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LingButton(
              label: copy['commonActionContinue']!,
              unavailableLabel: 'Unavailable',
              onPressed: () {},
            ),
            LingChip(
              label: copy['commonActionShowMore']!,
              unavailableLabel: 'Unavailable',
              onPressed: () {},
            ),
            LingListRow(
              label: copy['commonActionSave']!,
              unavailableLabel: 'Unavailable',
              onPressed: () {},
            ),
            LingTextField(
              label: copy['commonActionSave']!,
              unavailableLabel: 'Unavailable',
            ),
            LingCard(
              semanticLabel: catalogueTargetSample,
              unavailableLabel: 'Unavailable',
              onPressed: () {},
              child: const TargetText(text: catalogueTargetSample),
            ),
            LingBottomSheet(
              label: copy['commonActionShowMore']!,
              actionLabel: copy['commonActionContinue']!,
              unavailableLabel: 'Unavailable',
              onAction: () {},
            ),
            LingDialog(
              title: copy['commonActionTryAgain']!,
              actionLabel: copy['commonActionClose']!,
              unavailableLabel: 'Unavailable',
              onAction: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    for (final Type type in <Type>[
      LingButton,
      LingChip,
      LingListRow,
      LingTextField,
      LingCard,
      LingBottomSheet,
      LingDialog,
    ]) {
      final Finder finder = find.byType(type);
      expect(finder, findsWidgets, reason: '$type');
      for (var index = 0; index < finder.evaluate().length; index++) {
        final Size size = tester.getSize(finder.at(index));
        expect(size.width, greaterThanOrEqualTo(48), reason: '$type $index');
        expect(size.height, greaterThanOrEqualTo(48), reason: '$type $index');
      }
    }
  });

  testWidgets('disabled is written and flagged, and loading keeps its label', (
    WidgetTester tester,
  ) async {
    final Map<String, String> copy = _englishActions();
    await _pumpSurface(tester);
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: LingButton(
          label: copy['commonActionContinue']!,
          unavailableLabel: 'Unavailable',
          forcedState: LingForcedState.disabled,
        ),
      ),
    );
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text(copy['commonActionContinue']!), findsOneWidget);
    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byType(LingButton)),
      isSemantics(isEnabled: false, hasEnabledState: true),
    );
    handle.dispose();

    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: LingButton(
          label: copy['commonActionContinue']!,
          unavailableLabel: 'Unavailable',
          forcedState: LingForcedState.loading,
          onPressed: () {},
        ),
      ),
    );
    expect(find.text(copy['commonActionContinue']!), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNotNull,
    );

    await tester.pumpWidget(
      _host(
        disableAnimations: false,
        child: LingChip(
          label: copy['commonActionShowMore']!,
          unavailableLabel: 'Unavailable',
          forcedState: LingForcedState.loading,
          onPressed: () {},
        ),
      ),
    );
    expect(find.text(copy['commonActionShowMore']!), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNull,
    );
  });

  testWidgets('200 percent text wraps inside 390 px', (
    WidgetTester tester,
  ) async {
    await _pumpSurface(tester);
    for (final CatalogueUseCase useCase in catalogueUseCases) {
      if (!useCase.id.startsWith('ling')) continue;
      for (final String state in useCase.states) {
        await tester.pumpWidget(useCase.build(Brightness.light, 2, state));
        expect(tester.takeException(), isNull, reason: '${useCase.id} $state');
        final Size surface = tester.getSize(find.byKey(catalogueSurfaceKey));
        expect(surface.width, 390, reason: useCase.id);
        for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
          expect(
            text.overflow,
            isNot(TextOverflow.clip),
            reason: '${useCase.id} $state',
          );
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason: '${useCase.id} $state',
          );
          expect(text.softWrap, isTrue, reason: '${useCase.id} $state');
        }
        expect(
          find.byType(TargetText),
          useCase.id == 'lingCard' ? findsOneWidget : findsNothing,
        );
      }
    }
  });
}

String _tail(String key) {
  final String raw = key.replaceFirst('commonAction', '');
  return raw[0].toLowerCase() + raw.substring(1);
}

Map<String, String> _englishActions() {
  final Map<String, dynamic> arb =
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  return <String, String>{
    for (final String key in <String>[
      'commonActionContinue',
      'commonActionSave',
      'commonActionTryAgain',
      'commonActionClose',
      'commonActionShowMore',
    ])
      key: arb[key] as String,
  };
}

Future<void> _pumpSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = catalogueSurface;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(catalogueSurface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpCatalogue(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1600);
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _host({required bool disableAnimations, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: catalogueTheme(Brightness.light),
    builder: (BuildContext context, Widget? built) {
      return MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: built ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(body: child),
  );
}
