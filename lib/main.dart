import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';

import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
// Localization & Features
import 'services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'services/advanced/smart_recommendations.dart';
import 'services/monitoring/sentry_service.dart';
import 'services/deep_link_service.dart';
import 'config/secrets_manager.dart';
import 'utils/performance_utils.dart';
import 'utils/structured_logger.dart';
import 'utils/polie_design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    logger.error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
      context: {'library': details.library},
    );
  };

  runZonedGuarded(() async {
  // Initialize local database for offline mode
  try {
    await LocalDatabaseService().init();
    logger.info('Local database initialized');
  } catch (e) {
    logger.warning('Failed to initialize local database: $e');
  }

  // Load .env file if it exists (for development/local configuration)
  // In production, use --dart-define or secure storage
  try {
    await dotenv.load(fileName: ".env");
    logger.info('Loaded .env file successfully');
  } catch (e) {
    // .env file not found - this is OK, we'll use --dart-define or secure storage
    logger.debug('Note: .env file not found. Using build-time variables or secure storage.');
  }
  
  // Configure image cache for optimal performance
  ImageCacheManager.configureCache();
  final prefs = await SharedPreferences.getInstance();

  // Polie: apply serif language text preference from settings
  final polieSerif = prefs.getBool('polie_serif_language_text') ?? false;
  PolieTypography.setUseSerifForLanguageText(polieSerif);
  
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
    logger.info('Offline services initialized successfully');
  } catch (e) {
    logger.error('Error initializing offline services', error: e);
  }

  // Initialize Auth Services
  try {
    await CredentialStorageService().initialize();
    // BiometricAuthService doesn't need initialization
    logger.info('Auth services initialized successfully');
  } catch (e) {
    logger.error('Error initializing auth services', error: e);
  }

  // Initialize Localization & Features
  try {
    await DynamicLocalizationService.initialize();
    
    // Detect device language and set as default
    final deviceLocale = Platform.localeName.split('_').first.toLowerCase();
    final detectedLanguage = _detectLanguageFromLocale(deviceLocale);
    if (detectedLanguage != null) {
      await DynamicLocalizationService.setLanguage(detectedLanguage.code);
      logger.info('Detected device language: ${detectedLanguage.code}');
    }
    
    await SmartRecommendationsService().initialize();
    logger.info('Localization and features initialized successfully');
  } catch (e) {
    logger.error('Error initializing localization services', error: e);
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
      logger.info('Sentry initialized successfully', context: {
        'environment': kDebugMode ? 'development' : 'production',
      });
    } else {
      logger.debug('Sentry DSN not configured, skipping initialization');
    }
  } catch (e) {
    logger.error('Error initializing monitoring services', error: e);
    // Don't fail app startup if monitoring fails
  }

  // Initialize Deep Link Service
  try {
    DeepLinkService().initialize();
    logger.info('Deep link service initialized successfully');
  } catch (e) {
    logger.error('Error initializing deep link service', error: e);
  }

    runApp(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(SharedPreferencesProvider(prefs)),
      ],
      child: const MyApp(),
    ));
  }, (error, stack) {
    logger.error('Unhandled error', error: error, stackTrace: stack);
  });
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
