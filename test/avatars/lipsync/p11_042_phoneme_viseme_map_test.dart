import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/lipsync/phoneme_viseme_map.dart';

void main() {
  test('viseme enum covers sil through nasal N~ alias', () {
    expect(Viseme.values.length, 21);
    expect(Viseme.parseWire('N~'), Viseme.nasal);
    expect(Viseme.nasal.wireName, 'Nnasal');
    expect(Viseme.parseWire('GB'), Viseme.gb);
    expect(Viseme.parseWire('bogus'), isNull);
  });

  test('yoruba kp gb and nasal vowels map without letter guessing', () {
    expect(visemeWireForPhoneme('yo', 'kp'), 'KP');
    expect(visemeWireForPhoneme('yo', 'gb'), 'GB');
    expect(visemeWireForPhoneme('yo', 'ã'), 'Nnasal');
    expect(visemeWireForPhoneme('yo', 'hello'), isNull);
  });

  test('zulu clicks map to C Q X visemes', () {
    expect(visemeWireForPhoneme('zu', 'ǀ'), 'C');
    expect(visemeWireForPhoneme('zu', 'ǁ'), 'Q');
    expect(visemeWireForPhoneme('zu', 'ǃ'), 'X');
    expect(visemeWireForPhoneme('zu', 'x'), isNull);
  });
}
