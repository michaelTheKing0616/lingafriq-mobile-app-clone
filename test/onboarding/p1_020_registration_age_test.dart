import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('computeRegistrationAgeBand matches server default thresholds', () {
    final now = DateTime.now().year;
    expect(computeRegistrationAgeBand(now - 10), 'child');
    expect(computeRegistrationAgeBand(now - 16), 'teen');
    expect(computeRegistrationAgeBand(now - 25), 'adult');
    expect(computeRegistrationAgeBand(now - 10, countryCode: 'DE'), 'child');
  });

  test(
    'onboarding provider persists registration birth year payload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            SharedPreferencesProvider(prefs),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(onboardingProvider.notifier)
          .persistRegistrationBirthYear(2012, 'teen');
      expect(
        container.read(onboardingProvider.notifier).registrationAgePayload(),
        {'birth_year': 2012, 'age_band': 'teen'},
      );
    },
  );
}
