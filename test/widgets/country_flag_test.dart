import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/widgets/country_flag.dart';

void main() {
  test('decodes ISO codes from flag emoji', () {
    expect(isoFromFlagEmoji('🇳🇬'), 'NG');
    expect(isoFromFlagEmoji('x'), isNull);
    expect(isoForCountry('Nigeria'), 'NG');
    expect(isoForCountry('Atlantis'), isNull);
  });

  test('every country in the picker maps to a code', () {
    final missing = kCountries.keys.where((c) => isoForCountry(c) == null);
    expect(missing, isEmpty);
  });

  Future<void> pump(WidgetTester t, String? c) => t.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: CountryFlag(country: c)),
    ),
  );

  testWidgets('Nigeria paints green-white-green bands, no emoji text', (
    t,
  ) async {
    await pump(t, 'Nigeria');
    expect(find.byKey(const Key('flag-NG')), findsOneWidget);
    final colors = t
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .map((b) => b.color)
        .toList();
    expect(colors, [
      const Color(0xFF008751),
      const Color(0xFFFFFFFF),
      const Color(0xFF008751),
    ]);
    expect(find.byType(Text), findsNothing);
    // Bands must actually paint area (a childless ColoredBox collapses).
    for (final b in t.renderObjectList<RenderBox>(find.byType(ColoredBox))) {
      expect(b.size.height, greaterThan(5));
      expect(b.size.width, greaterThan(5));
    }
  });

  testWidgets('unknown band country falls back to an ISO badge', (t) async {
    await pump(t, 'Kenya');
    expect(find.text('KE'), findsOneWidget);
    await pump(t, null);
    expect(find.text('—'), findsOneWidget);
  });
}
