import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/services/local_schema_migrator.dart';

import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'my_app.dart';
import 'providers/firebase_messaging_provider.dart';
import 'providers/shared_preferences_provider.dart';
// Offline Services
import 'services/offline/persisted_outbox_service.dart';
import 'services/offline/conflict_resolution.dart';
import 'services/offline/cache_compression.dart';
import 'services/offline/cache_encryption.dart';
import 'services/offline/offline_analytics.dart';
import 'services/performance/low_bandwidth_mode.dart';
// Auth Services
import 'services/auth/credential_storage_service.dart';
// Localization & Features
import 'services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'services/advanced/smart_recommendations.dart';
import 'services/monitoring/crash_reporter.dart';
import 'services/monitoring/sentry_service.dart';
import 'services/monitoring/startup_schedule.dart';
import 'services/performance_monitor.dart';
import 'services/deep_link_service.dart';
import 'config/secrets_manager.dart';
import 'package:rive/rive.dart';
import 'avatars/runtime/rive_file_cache.dart';
import 'utils/performance_utils.dart';
import 'utils/structured_logger.dart';
import 'utils/polie_design_tokens.dart';

/// P12-012: process start → first rasterized frame → first [MyApp] frame (meaningful).
final ColdStartTelemetry coldStartTelemetry = ColdStartTelemetry();

class ColdStartTelemetry {
  final Stopwatch process = Stopwatch();
  int? firstFrameMs;
  int? firstMeaningfulFrameMs;
  StartupTrace? startupTrace;

  void emitTraceLine() {
    final trace = startupTrace;
    if (trace == null) return;
    // Logcat / CI harness parses `LingAfriqColdStart:` lines (AC2).
    debugPrint(
      'LingAfriqColdStart: trace=${trace.events.join(",")}',
    );
  }

  Map<String, dynamic> toJson() => {
        'first_frame_ms': firstFrameMs,
        'first_meaningful_frame_ms': firstMeaningfulFrameMs,
        'startup_trace': startupTrace?.events ?? const <String>[],
      };
}

/// Marks the first laid-out frame of the root app widget (meaningful UI shell).
class _ColdStartMeaningfulMarker extends StatefulWidget {
  const _ColdStartMeaningfulMarker({required this.child});

  final Widget child;

  @override
  State<_ColdStartMeaningfulMarker> createState() => _ColdStartMeaningfulMarkerState();
}

class _ColdStartMeaningfulMarkerState extends State<_ColdStartMeaningfulMarker> {
  var _marked = false;

  @override
  Widget build(BuildContext context) {
    if (!_marked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _marked = true;
        coldStartTelemetry.firstMeaningfulFrameMs =
            coldStartTelemetry.process.elapsedMilliseconds;
        debugPrint(
          'LingAfriqColdStart: first_meaningful_frame_ms=${coldStartTelemetry.firstMeaningfulFrameMs}',
        );
        coldStartTelemetry.emitTraceLine();
      });
    }
    return widget.child;
  }
}

void main() async {
  coldStartTelemetry.process.start();
  final coldStart = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    final report = CrashReporter.instance.report(
      details.exception,
      stackTrace: details.stack,
      context: {'library': details.library ?? 'flutter'},
    );
    logger.error('uncaught error', context: Map<String, dynamic>.from(report));
  };

  runZonedGuarded(() async {
    try {
      await dotenv.load(fileName: ".env");
      logger.info('Loaded .env file successfully');
    } catch (e) {
      logger.debug('Note: .env file not found. Using build-time variables or secure storage.');
    }

    final recovery = <SchemaMigrationFailure>[];
    SharedPreferences? prefs;
    final trace = StartupTrace();
    coldStartTelemetry.startupTrace = trace;
    await runStartup(
      sentry: _startCrashReporter,
      trace: trace,
      parallel: {
        'database': () => _openDatabase(recovery),
        'preferences': () async {
          prefs = await SharedPreferences.getInstance();
        },
        'firebase': () => Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        'rive': RiveNative.init,
      },
      deferred: {
        'offline': _startDeferredServices,
        'recommendations': () => SmartRecommendationsService().initialize(),
        'rive_cast': () => RiveFileCache.instance.load(RiveRuntimeAssets.cast),
      },
      onFirstFrame: (task) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(task());
        });
      },
    );

    final stored = prefs;
    if (stored == null) {
      throw StateError('preferences did not open');
    }
    ImageCacheManager.configureCache();
    PolieTypography.setUseSerifForLanguageText(stored.getBool('polie_serif_language_text') ?? false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessagingProvider.init();
    try {
      await CredentialStorageService().initialize();
      logger.info('Auth services initialized successfully');
    } catch (e) {
      logger.error('Error initializing auth services', error: e);
    }
    await _applyLanguage(stored);
    try {
      DeepLinkService().initialize();
      logger.info('Deep link service initialized successfully');
    } catch (e) {
      logger.error('Error initializing deep link service', error: e);
    }

    startupPerformance.recordTiming('cold_start', coldStart.elapsed);
    if (recovery.isNotEmpty) {
      runApp(SchemaRecoveryApp(failure: recovery.single));
      return;
    }

    runApp(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(SharedPreferencesProvider(stored)),
      ],
      child: const _ColdStartMeaningfulMarker(child: MyApp()),
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      coldStartTelemetry.firstFrameMs =
          coldStartTelemetry.process.elapsedMilliseconds;
      debugPrint(
        'LingAfriqColdStart: first_frame_ms=${coldStartTelemetry.firstFrameMs}',
      );
    });
  }, (error, stack) {
    logger.error('Unhandled error', error: error, stackTrace: stack);
  });
}

Future<void> _startCrashReporter() async {
  try {
    await SecretsManager().initialize();
    final sentryDsn = SecretsManager().sentryDsn;
    CrashReporter.instance.log = (message) => logger.error(message);
    final started = await CrashReporter.instance.initialize(
      device: Platform.operatingSystem,
      start: () async {
        if (sentryDsn != null && sentryDsn.isNotEmpty) {
          await SentryService().initialize(
            dsn: sentryDsn,
            environment: kDebugMode ? 'development' : 'production',
            enablePerformanceMonitoring: true,
          );
        }
      },
    );
    if (!started) {
      logger.error(CrashReporter.instance.diagnostic ?? 'crash reporter failed to start');
      return;
    }
    final previousAnrs = await CrashReporter.instance.collectPreviousAnrs();
    for (final anr in previousAnrs) {
      logger.error('previous anr', context: Map<String, dynamic>.from(anr));
    }
    if (sentryDsn == null || sentryDsn.isEmpty) {
      logger.debug('Sentry DSN not configured, skipping initialization');
    } else {
      logger.info('Sentry initialized successfully', context: {
        'environment': kDebugMode ? 'development' : 'production',
      });
    }
  } catch (e) {
    logger.error('Error initializing monitoring services', error: e);
  }
}

Future<void> _openDatabase(List<SchemaMigrationFailure> recovery) async {
  try {
    await LocalDatabaseService().init();
    logger.info('Local database initialized');
  } on SchemaMigrationFailure catch (failure) {
    recovery.add(failure);
    logger.warning('Local schema migration needs recovery', error: failure);
  } catch (e) {
    logger.warning('Failed to initialize local database: $e');
  }
}

Future<void> _startDeferredServices() async {
  try {
    await PersistedOutboxService.instance.start();
    await LowBandwidthMode.instance.refresh();
    await ConflictResolutionService().initialize();
    await CacheCompressionService().initialize();
    await CacheEncryptionService().initialize();
    await OfflineAnalyticsService().initialize();
    logger.info('Offline services initialized successfully');
  } catch (e) {
    logger.error('Error initializing offline services', error: e);
  }
}

Future<void> _applyLanguage(SharedPreferences prefs) async {
  try {
    await DynamicLocalizationService.initialize();
    final savedAppLang = prefs.getString('app_language');
    if (savedAppLang == null || savedAppLang.isEmpty) {
      final profLang = prefs.getString('proficiency_language');
      if (profLang != null && profLang.isNotEmpty) {
        await DynamicLocalizationService.setLanguage(profLang);
        logger.info('Applied onboarding UI language: $profLang');
      } else {
        final deviceLocale = Platform.localeName.split('_').first.toLowerCase();
        final detectedLanguage = _detectLanguageFromLocale(deviceLocale);
        if (detectedLanguage != null) {
          await DynamicLocalizationService.setLanguage(detectedLanguage.code);
          logger.info('First launch: device UI language ${detectedLanguage.code}');
        }
      }
    }
    logger.info('Localization and features initialized successfully');
  } catch (e) {
    logger.error('Error initializing localization services', error: e);
  }
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
