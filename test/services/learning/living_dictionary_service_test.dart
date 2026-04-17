import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/living_dictionary_list_cache.dart';
import 'package:lingafriq/services/learning/living_dictionary_list_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LivingDictionaryListParse.parsePageNextBefore', () {
    test('reads page.nextBefore when present', () {
      expect(
        LivingDictionaryListParse.parsePageNextBefore({
          'success': true,
          'entries': [],
          'page': {
            'limit': 200,
            'nextBefore': '2026-01-15T12:00:00.000Z',
          },
        }),
        '2026-01-15T12:00:00.000Z',
      );
    });

    test('returns null when page or nextBefore missing', () {
      expect(LivingDictionaryListParse.parsePageNextBefore({'success': true, 'entries': []}), isNull);
      expect(
        LivingDictionaryListParse.parsePageNextBefore({
          'success': true,
          'page': {},
        }),
        isNull,
      );
    });
  });

  group('LivingDictionaryListParse.listResultFromApiBody', () {
    test('maps entries and source', () {
      final r = LivingDictionaryListParse.listResultFromApiBody(
        {
          'success': true,
          'entries': [
            {'lemma': 'a', 'language': 'yo'},
          ],
          'page': {'nextBefore': '2026-01-01T00:00:00.000Z'},
        },
        source: 'cache',
      );
      expect(r.source, 'cache');
      expect(r.entries.length, 1);
      expect(r.entries.first['lemma'], 'a');
      expect(r.nextBefore, '2026-01-01T00:00:00.000Z');
    });
  });

  group('clearLivingDictionaryListCaches', () {
    test('removes only living dictionary list cache keys', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'living_dictionary_list_body_v1_abc': '{"success":true,"entries":[]}',
        'other_key': 'keep',
      });
      await clearLivingDictionaryListCaches();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('living_dictionary_list_body_v1_abc'), isNull);
      expect(prefs.getString('other_key'), 'keep');
    });
  });
}
