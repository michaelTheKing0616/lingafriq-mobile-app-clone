/// API Versioning Utility
/// Provides version-aware API endpoint management
/// 
/// Features:
/// - API version routing
/// - Version negotiation
/// - Deprecation warnings
/// - Backward compatibility
/// 
/// Production-ready implementation (December 2025)

import 'package:lingafriq/services/env_config.dart';

/// API Version Manager
class ApiVersioning {
  static const String currentVersion = 'v1';
  static const String defaultVersion = 'v1';
  
  /// Supported API versions
  static const List<String> supportedVersions = ['v1'];
  
  /// Minimum supported version (for deprecation)
  static const String minimumVersion = 'v1';

  /// Get versioned API base URL
  static String getBaseUrl({String? version}) {
    final apiVersion = version ?? currentVersion;
    final baseUrl = EnvConfig.backendBaseUrl;
    
    // Ensure base URL doesn't end with slash
    final cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    
    // Return versioned URL
    return '$cleanBaseUrl/api/$apiVersion';
  }

  /// Build versioned endpoint
  static String endpoint(String path, {String? version}) {
    final baseUrl = getBaseUrl(version: version);
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  /// Check if version is supported
  static bool isVersionSupported(String version) {
    return supportedVersions.contains(version);
  }

  /// Check if version is deprecated
  static bool isVersionDeprecated(String version) {
    // Compare version numbers (e.g., 'v1' < 'v2')
    final versionNum = _extractVersionNumber(version);
    final minVersionNum = _extractVersionNumber(minimumVersion);
    return versionNum < minVersionNum;
  }

  /// Extract version number from version string
  static int _extractVersionNumber(String version) {
    // Remove 'v' prefix and parse number
    final cleaned = version.replaceAll('v', '').replaceAll('V', '');
    return int.tryParse(cleaned) ?? 0;
  }

  /// Get latest version
  static String getLatestVersion() {
    return supportedVersions.last;
  }

  /// Validate API version from response headers
  static String? validateVersionFromHeaders(Map<String, dynamic> headers) {
    final apiVersion = headers['api-version'] as String?;
    if (apiVersion != null && isVersionSupported(apiVersion)) {
      return apiVersion;
    }
    return null;
  }

  /// Get deprecation warning message
  static String? getDeprecationWarning(String version) {
    if (isVersionDeprecated(version)) {
      return 'API version $version is deprecated. Please upgrade to $currentVersion.';
    }
    return null;
  }
}

/// Versioned API endpoint builder
class VersionedEndpoint {
  final String path;
  final String? version;

  VersionedEndpoint(this.path, {this.version});

  String get url => ApiVersioning.endpoint(path, version: version);

  @override
  String toString() => url;
}

/// Convenience extension for versioned endpoints
extension ApiVersioningExtension on String {
  /// Create versioned endpoint
  VersionedEndpoint v1() => VersionedEndpoint(this, version: 'v1');
  
  /// Create versioned endpoint with custom version
  VersionedEndpoint versioned(String version) => VersionedEndpoint(this, version: version);
}

