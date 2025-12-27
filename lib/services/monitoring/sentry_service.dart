/// Sentry Error Tracking Service
/// World-class error tracking and crash reporting
/// 
/// Features:
/// - Automatic crash reporting
/// - Error tracking with context
/// - Performance monitoring
/// - User feedback collection
/// - Release tracking
/// 
/// Uses Sentry SDK for Flutter (December 2025)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Sentry Service
/// 
/// Provides comprehensive error tracking and crash reporting
class SentryService {
  static final SentryService _instance = SentryService._internal();
  factory SentryService() => _instance;
  SentryService._internal();

  bool _initialized = false;
  String? _dsn;
  String? _environment;
  String? _release;

  /// Initialize Sentry
  /// 
  /// [dsn] - Sentry DSN (Data Source Name)
  /// [environment] - Environment (production, staging, development)
  /// [enablePerformanceMonitoring] - Enable performance monitoring
  Future<void> initialize({
    required String dsn,
    String? environment,
    bool enablePerformanceMonitoring = true,
  }) async {
    if (_initialized) {
      debugPrint('Sentry already initialized');
      return;
    }

    _dsn = dsn;
    _environment = environment ?? (kDebugMode ? 'development' : 'production');

    try {
      // Get package info for release tracking
      final packageInfo = await PackageInfo.fromPlatform();
      _release = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Initialize Sentry
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.environment = _environment;
          options.release = _release;
          options.tracesSampleRate = enablePerformanceMonitoring ? 1.0 : 0.0;
          options.profilesSampleRate = enablePerformanceMonitoring ? 1.0 : 0.0;
          
          // Enable additional features
          options.enableAutoSessionTracking = true;
          options.attachScreenshot = true;
          options.attachViewHierarchy = true;
          
          // Set user context
          options.beforeSend = (event, {hint}) {
            // Add custom context
            event.contexts['app'] = {
              'name': 'LingAfriq',
              'version': packageInfo.version,
              'build': packageInfo.buildNumber,
            };
            
            return event;
          };
        },
        appRunner: () {
          // App initialization would happen here
          // For now, we just mark as initialized
          _initialized = true;
          debugPrint('Sentry initialized successfully');
        },
      );

      _initialized = true;
      debugPrint('Sentry initialized: $_environment / $_release');
    } catch (e) {
      debugPrint('Failed to initialize Sentry: $e');
      // Don't throw - app should continue even if Sentry fails
    }
  }

  /// Capture exception
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    Map<String, dynamic>? context,
    String? level,
  }) async {
    if (!_initialized) {
      debugPrint('Sentry not initialized, cannot capture exception');
      return;
    }

    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: context != null ? Hint.withMap(context) : null,
        withScope: (scope) {
          if (level != null) {
            // Map string level to SentryLevel enum
            SentryLevel? sentryLevel;
            switch (level.toLowerCase()) {
              case 'debug':
                sentryLevel = SentryLevel.debug;
                break;
              case 'info':
                sentryLevel = SentryLevel.info;
                break;
              case 'warning':
                sentryLevel = SentryLevel.warning;
                break;
              case 'error':
                sentryLevel = SentryLevel.error;
                break;
              case 'fatal':
                sentryLevel = SentryLevel.fatal;
                break;
              default:
                sentryLevel = SentryLevel.error;
            }
            scope.level = sentryLevel;
          }
          
          if (context != null) {
            scope.setContexts('custom', context);
          }
        },
      );
    } catch (e) {
      debugPrint('Failed to capture exception in Sentry: $e');
    }
  }

  /// Capture message
  Future<void> captureMessage(
    String message, {
    String level = 'info',
    Map<String, dynamic>? context,
  }) async {
    if (!_initialized) return;

    try {
      // Map string level to SentryLevel enum
      SentryLevel sentryLevel;
      switch (level.toLowerCase()) {
        case 'debug':
          sentryLevel = SentryLevel.debug;
          break;
        case 'info':
          sentryLevel = SentryLevel.info;
          break;
        case 'warning':
          sentryLevel = SentryLevel.warning;
          break;
        case 'error':
          sentryLevel = SentryLevel.error;
          break;
        case 'fatal':
          sentryLevel = SentryLevel.fatal;
          break;
        default:
          sentryLevel = SentryLevel.info;
      }
      
      await Sentry.captureMessage(
        message,
        level: sentryLevel,
        hint: context != null ? Hint.withMap(context) : null,
      );
    } catch (e) {
      debugPrint('Failed to capture message in Sentry: $e');
    }
  }

  /// Set user context
  Future<void> setUser({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_initialized) return;

    try {
      await Sentry.configureScope((scope) {
        scope.setUser(
          SentryUser(
            id: id,
            email: email,
            username: username,
            data: additionalData,
          ),
        );
      });
    } catch (e) {
      debugPrint('Failed to set user in Sentry: $e');
    }
  }

  /// Clear user context
  Future<void> clearUser() async {
    if (!_initialized) return;

    try {
      await Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    } catch (e) {
      debugPrint('Failed to clear user in Sentry: $e');
    }
  }

  /// Add breadcrumb
  void addBreadcrumb({
    required String message,
    String? category,
    String? level,
    Map<String, dynamic>? data,
  }) {
    if (!_initialized) return;

    try {
      Sentry.addBreadcrumb(
        // Map string level to SentryLevel enum
        SentryLevel sentryLevel;
        switch ((level ?? 'info').toLowerCase()) {
          case 'debug':
            sentryLevel = SentryLevel.debug;
            break;
          case 'info':
            sentryLevel = SentryLevel.info;
            break;
          case 'warning':
            sentryLevel = SentryLevel.warning;
            break;
          case 'error':
            sentryLevel = SentryLevel.error;
            break;
          case 'fatal':
            sentryLevel = SentryLevel.fatal;
            break;
          default:
            sentryLevel = SentryLevel.info;
        }
        
        Breadcrumb(
          message: message,
          category: category,
          level: sentryLevel,
          data: data,
        ),
      );
    } catch (e) {
      debugPrint('Failed to add breadcrumb in Sentry: $e');
    }
  }

  /// Set tag
  void setTag(String key, String value) {
    if (!_initialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setTag(key, value);
      });
    } catch (e) {
      debugPrint('Failed to set tag in Sentry: $e');
    }
  }

  /// Set context
  void setContext(String key, Map<String, dynamic> value) {
    if (!_initialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setContexts(key, value);
      });
    } catch (e) {
      debugPrint('Failed to set context in Sentry: $e');
    }
  }

  /// Start performance transaction
  ITransaction? startTransaction(
    String name,
    String operation, {
    Map<String, dynamic>? data,
  }) {
    if (!_initialized) return null;

    try {
      return Sentry.startTransaction(
        name,
        operation,
        bindToScope: true,
      );
    } catch (e) {
      debugPrint('Failed to start transaction in Sentry: $e');
      return null;
    }
  }

  /// Capture user feedback
  Future<void> captureUserFeedback({
    required String name,
    required String email,
    required String comments,
    String? eventId,
  }) async {
    if (!_initialized) return;

    try {
      await Sentry.captureUserFeedback(
        SentryUserFeedback(
          eventId: eventId != null ? SentryId.fromId(eventId) : null,
          name: name,
          email: email,
          comments: comments,
        ),
      );
    } catch (e) {
      debugPrint('Failed to capture user feedback in Sentry: $e');
    }
  }

  /// Flush events (useful before app termination)
  Future<void> flush({Duration? timeout}) async {
    if (!_initialized) return;

    try {
      await Sentry.flush(timeout: timeout);
    } catch (e) {
      debugPrint('Failed to flush Sentry: $e');
    }
  }

  /// Check if Sentry is initialized
  bool get isInitialized => _initialized;
}

