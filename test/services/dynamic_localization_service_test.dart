import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DynamicLocalizationService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DynamicLocalizationService.initialize();
    });

    test('initialize with no saved preference uses English', () {
      expect(DynamicLocalizationService.currentLanguage, AppLanguage.english);
      expect(DynamicLocalizationService.currentLocale, const Locale('en'));
    });

    test('setLanguage persists ISO code and updates current locale', () async {
      await DynamicLocalizationService.setLanguage('sw');
      expect(DynamicLocalizationService.currentLanguage, AppLanguage.swahili);
      expect(DynamicLocalizationService.currentLocale, const Locale('sw'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'sw');
    });

    test('unknown language code falls back to English and stores resolved en', () async {
      await DynamicLocalizationService.setLanguage('xx-not-a-locale');
      expect(DynamicLocalizationService.currentLanguage, AppLanguage.english);
      expect(DynamicLocalizationService.currentLocale, const Locale('en'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'en');
    });

    test('isRTL is true for Arabic', () {
      expect(DynamicLocalizationService.isRTL('ar'), isTrue);
      expect(DynamicLocalizationService.isRTL('en'), isFalse);
    });

    test('getSupportedLanguages includes African languages used in onboarding', () {
      final codes = DynamicLocalizationService.getSupportedLanguages().map((l) => l.code).toSet();
      expect(codes, containsAll(['yo', 'ha', 'ig', 'sw', 'pcm']));
    });
  });
}
