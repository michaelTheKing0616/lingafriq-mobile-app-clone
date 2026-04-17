import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/dialect_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DialectPreferenceService.readCachedPreferredTag', () {
    test('returns trimmed tag using lowercase umbrella key', () async {
      SharedPreferences.setMockInitialValues({
        'learning_dialect_preferred_tag_v1_yo': ' yo-lagos ',
      });
      final svc = DialectPreferenceService();
      expect(await svc.readCachedPreferredTag('YO'), 'yo-lagos');
    });

    test('returns null when no value stored', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = DialectPreferenceService();
      expect(await svc.readCachedPreferredTag('ig'), isNull);
    });
  });
}
