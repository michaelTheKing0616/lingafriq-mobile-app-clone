import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'firebase_options.dart';
import 'my_app.dart';
import 'providers/firebase_messaging_provider.dart';
import 'providers/shared_preferences_provider.dart';
// Offline Services
import 'services/offline/offline_service.dart';
import 'services/offline/background_sync_service.dart';
import 'services/offline/conflict_resolution.dart';
import 'services/offline/selective_sync.dart';
import 'services/offline/cache_compression.dart';
import 'services/offline/cache_encryption.dart';
import 'services/offline/offline_analytics.dart';
// Auth Services
import 'services/auth/credential_storage_service.dart';
import 'services/auth/biometric_auth_service.dart';
// Auth Services
import 'services/auth/credential_storage.dart';
import 'services/auth/biometric_auth.dart';
// Localization & Features
import 'services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'services/advanced/smart_recommendations.dart';
import 'services/monitoring/sentry_service.dart';
import 'config/secrets_manager.dart';
import 'utils/performance_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure image cache for optimal performance
  ImageCacheManager.configureCache();
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await FirebaseMessagingProvider.init();

  // Initialize Offline Services
  try {
    await OfflineService().initialize();
    await BackgroundSyncService().initialize();
    await ConflictResolutionService().initialize();
    await SelectiveSyncService().initialize();
    await CacheCompressionService().initialize();
    await CacheEncryptionService().initialize();
    await OfflineAnalyticsService().initialize();
  } catch (e) {
    print('Error initializing offline services: $e');
  }

  // Initialize Auth Services
  try {
    await CredentialStorageService().initialize();
    // BiometricAuthService doesn't need initialization
  } catch (e) {
    print('Error initializing auth services: $e');
  }

  // Initialize Localization & Features
  try {
    final localizationService = DynamicLocalizationService();
    await localizationService.initialize();
    
    // Detect device language and set as default
    final deviceLocale = Platform.localeName.split('_').first.toLowerCase();
    final detectedLanguage = _detectLanguageFromLocale(deviceLocale);
    if (detectedLanguage != null) {
      await localizationService.setLanguage(detectedLanguage);
    }
    
    await SmartRecommendationsService().initialize();
  } catch (e) {
    print('Error initializing localization services: $e');
  }

  // Initialize Secrets Manager and Sentry
  try {
    await SecretsManager().initialize();
    
    // Initialize Sentry for error tracking
    final sentryDsn = SecretsManager().sentryDsn;
    if (sentryDsn != null && sentryDsn.isNotEmpty) {
      await SentryService().initialize(
        dsn: sentryDsn,
        environment: kDebugMode ? 'development' : 'production',
        enablePerformanceMonitoring: true,
      );
      print('Sentry initialized successfully');
    } else {
      print('Sentry DSN not configured, skipping initialization');
    }
  } catch (e) {
    print('Error initializing monitoring services: $e');
    // Don't fail app startup if monitoring fails
  }

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(SharedPreferencesProvider(prefs)),
    ],
    child: const MyApp(),
  ));
}

/// Detect AppLanguage from device locale
AppLanguage? _detectLanguageFromLocale(String locale) {
  final localeMap = {
    'en': AppLanguage.english,
    'yo': AppLanguage.yoruba,
    'ha': AppLanguage.hausa,
    'ig': AppLanguage.igbo,
    'sw': AppLanguage.swahili,
    'zu': AppLanguage.zulu,
    'xh': AppLanguage.xhosa,
    'am': AppLanguage.amharic,
    'tw': AppLanguage.twi,
    'af': AppLanguage.afrikaans,
    'pcm': AppLanguage.pidgin,
    'wo': AppLanguage.wolof,
    'so': AppLanguage.somali,
  };
  
  return localeMap[locale.toLowerCase()];
}
