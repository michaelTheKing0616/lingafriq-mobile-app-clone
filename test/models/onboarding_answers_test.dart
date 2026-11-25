import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/onboarding_answers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const original = OnboardingAnswers({
    'proficiency_language': 'en',
    'learning_language': 'yo',
    'age_category': 'adult',
    'learning_reasons': ['heritage', 'travel'],
    'primary_goal': 'travel',
    'learning_style': 'audio',
    'daily_duration_minutes': 10,
    'preferred_time_of_day': 'sunset',
    'reminders_enabled': true,
    'app_tone': 'encouraging',
    'gamification_level': 'medium',
  });

  test('P1-034_AC4_round_trip_keeps_every_answer_type', () {
    final loaded = OnboardingAnswers.read(original.encode());
    expect(loaded.answers, original);
    expect(loaded.reask, isEmpty);
  });

  test('P1-034_AC2_map_to_string_keeps_parseable_values_and_flags_the_rest', () {
    const raw =
        '{age_category: adult, learning_reasons: [heritage, travel], reminders_enabled: true, daily_duration_minutes: no}';
    final loaded = OnboardingAnswers.read(raw);
    expect(loaded.migrated, isTrue);
    expect(loaded.answers.values['age_category'], 'adult');
    expect(loaded.answers.values['learning_reasons'], ['heritage', 'travel']);
    expect(loaded.answers.values['reminders_enabled'], true);
    expect(loaded.reask, ['daily_duration_minutes']);
    expect(loaded.answers.encode().contains('adult'), isTrue);
    expect(loaded.answers.encode().startsWith('{'), isTrue);
  });

  test('P1-034_AC2_startup_migration_rewrites_map_to_string_before_reask', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'onboarding_data':
          '{age_category: adult, learning_reasons: [heritage], daily_duration_minutes: no}',
    });
    final prefs = await SharedPreferences.getInstance();
    final migration = await OnboardingAnswers.migrate(prefs);
    expect(migration.reask, ['daily_duration_minutes']);
    expect(prefs.getString('onboarding_data'), contains('"age_category"'));
    expect(prefs.getStringList('onboarding_reask'), ['daily_duration_minutes']);
  });

  test('P1-034_AC3_invalid_json_raises_a_typed_error_for_the_affected_fields', () {
    expect(
      () => OnboardingAnswers.read('{"age_category":'),
      throwsA(
        isA<OnboardingDecodeException>()
            .having((error) => error.code, 'code', 'onboarding_decode_failed')
            .having((error) => error.fields, 'fields', contains('age_category'))
            .having((error) => error.fields, 'fields', isNot(contains('not_a_field'))),
      ),
    );
  });
}
