import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/learning/dialect_preference_screen.dart';

void main() {
  group('DialectPreferenceScreen.umbrellaLanguageFromArgs', () {
    test('defaults to yo when arguments are null', () {
      expect(DialectPreferenceScreen.umbrellaLanguageFromArgs(null), 'yo');
    });

    test('reads umbrellaLanguage from map', () {
      expect(
        DialectPreferenceScreen.umbrellaLanguageFromArgs({'umbrellaLanguage': 'HA'}),
        'ha',
      );
    });

    test('ignores empty umbrellaLanguage', () {
      expect(
        DialectPreferenceScreen.umbrellaLanguageFromArgs({'umbrellaLanguage': '  '}),
        'yo',
      );
    });
  });
}
