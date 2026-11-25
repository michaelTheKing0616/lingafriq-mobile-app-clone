import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/persona_claim_chip.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

void main() {
  test('chip variant mapping', () {
    expect(
      personaClaimChipVariant(
        support: PersonaClaimSupport.documented,
        loading: false,
        sourceIds: ['card-1'],
      ),
      PersonaClaimChipVariant.source,
    );
    expect(
      personaClaimChipVariant(
        support: PersonaClaimSupport.documented,
        loading: false,
        sourceIds: [],
      ),
      PersonaClaimChipVariant.noSource,
    );
    expect(
      personaClaimChipVariant(
        support: PersonaClaimSupport.inferred,
        loading: false,
        sourceIds: [],
      ),
      PersonaClaimChipVariant.inferred,
    );
    expect(
      personaClaimChipVariant(
        support: PersonaClaimSupport.legend,
        loading: false,
        sourceIds: [],
      ),
      PersonaClaimChipVariant.legend,
    );
    expect(
      personaClaimChipVariant(
        support: PersonaClaimSupport.documented,
        loading: true,
        sourceIds: ['card-1'],
      ),
      PersonaClaimChipVariant.loading,
    );
    expect(personaClaimSupportFromString('inferred'), PersonaClaimSupport.inferred);
    expect(personaClaimSupportFromString('unknown'), isNull);
  });

  testWidgets('chip semantics label announces support level', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PersonaClaimRow(
            claimText: 'Ghana gained independence in 1957.',
            support: PersonaClaimSupport.inferred,
            onOpenSource: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp(r'Ghana gained independence in 1957\..*Inferred claim'),
      ),
      findsOneWidget,
    );
    semanticsHandle.dispose();
  });

  testWidgets('Source chip opens cited card', (tester) async {
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PersonaClaimRow(
            claimText: 'The Big Six led the independence movement.',
            support: PersonaClaimSupport.documented,
            sourceIds: const ['culture-card-big-six'],
            onOpenSource: (id) => opened = id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Source'));
    await tester.pumpAndSettle();
    expect(opened, 'culture-card-big-six');
  });
}
