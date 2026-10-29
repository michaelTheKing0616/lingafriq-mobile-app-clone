// Environment Configuration
// Centralized access to environment variables and API keys
// Keys are injected via GitHub Actions secrets during build
// Production defaults avoid localhost; override via --dart-define during build.

import 'package:flutter/foundation.dart';

class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  /// Backend API base URL (alias for backendBaseUrl)
  static String get baseUrl => backendBaseUrl;

  /// CDN/base URL for static assets (e.g. media served via nginx)
  static String get cdnUrl {
    const url = String.fromEnvironment(
      'CDN_URL',
      defaultValue: 'https://admin.lingafriq.com',
    );
    return url;
  }

  /// WebSocket base URL for real-time connections
  static String get wsUrl {
    const url = String.fromEnvironment(
      'WS_URL',
      defaultValue: 'wss://admin.lingafriq.com',
    );
    return url;
  }

  /// App/website base URL for legal, support, and magazine links
  static String get appWebUrl {
    const url = String.fromEnvironment(
      'APP_WEB_URL',
      defaultValue: 'https://lingafriq.com',
    );
    return url;
  }

  // No AI provider keys live in the client: every model call goes through
  // the backend AI gateway (ApiContract.ai.chatCompletion), which owns them.

  /// MFA (Montreal Forced Aligner) Service URL for pronunciation scoring
  /// Set via: --dart-define=MFA_SERVICE_URL=xxx during build
  /// Optional - falls back to basic scoring if not configured
  static String? get mfaServiceUrl {
    const url = String.fromEnvironment('MFA_SERVICE_URL', defaultValue: '');
    return url.isNotEmpty ? url : null;
  }

  /// Check if MFA service is configured
  static bool get isMFAConfigured =>
      mfaServiceUrl != null && mfaServiceUrl!.isNotEmpty;

  /// Backend base URL
  /// Set via --dart-define=BACKEND_URL=https://your-api.com during build.
  /// Production: https://admin.lingafriq.com (nginx → localhost:4000).
  static String get backendBaseUrl {
    const url = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'https://admin.lingafriq.com',
    );
    final trimmed = url.trim();
    if (kReleaseMode && trimmed.startsWith('http://')) {
      throw StateError(
        'Insecure BACKEND_URL in release build (http://). Use https:// or change build config.',
      );
    }
    return trimmed;
  }

  /// Prefer bundled CMS manifests over API (offline-first / QA).
  /// Set via: --dart-define=LINGAFRIQ_USE_BUNDLED_CMS=true
  static bool get useBundledCmsFirst {
    const flag = String.fromEnvironment(
      'LINGAFRIQ_USE_BUNDLED_CMS',
      defaultValue: 'false',
    );
    return flag.toLowerCase() == 'true' || flag == '1';
  }

  /// Get all configuration status for debugging
  static Map<String, bool> get configurationStatus => {'mfa': isMFAConfigured};
}
