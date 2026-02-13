// Security Headers Validator
// Validates security headers from API responses
// 
// Features:
// - Validates required security headers
// - Warns on missing headers
// - Enforces security policies
// 
// Production-ready implementation (December 2025)

import 'package:dio/dio.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Required security headers
class SecurityHeaders {
  static const String strictTransportSecurity = 'strict-transport-security';
  static const String contentSecurityPolicy = 'content-security-policy';
  static const String xContentTypeOptions = 'x-content-type-options';
  static const String xFrameOptions = 'x-frame-options';
  static const String xXssProtection = 'x-xss-protection';
  static const String referrerPolicy = 'referrer-policy';
  static const String permissionsPolicy = 'permissions-policy';
}

/// Security headers configuration
class SecurityHeadersConfig {
  final bool enforceStrictTransportSecurity;
  final bool enforceContentSecurityPolicy;
  final bool enforceXContentTypeOptions;
  final bool enforceXFrameOptions;
  final bool warnOnly; // If true, only warn instead of failing

  const SecurityHeadersConfig({
    this.enforceStrictTransportSecurity = true,
    this.enforceContentSecurityPolicy = false, // Often too strict
    this.enforceXContentTypeOptions = true,
    this.enforceXFrameOptions = true,
    this.warnOnly = false,
  });
}

/// Security Headers Validator
class SecurityHeadersValidator {
  final SecurityHeadersConfig config;

  SecurityHeadersValidator({SecurityHeadersConfig? config})
      : config = config ?? const SecurityHeadersConfig();

  /// Validate security headers from response
  bool validateHeaders(Response response) {
    final headers = response.headers.map;
    final issues = <String>[];

    // Check Strict-Transport-Security
    if (config.enforceStrictTransportSecurity) {
      if (!headers.containsKey(SecurityHeaders.strictTransportSecurity)) {
        issues.add('Missing Strict-Transport-Security header');
      } else {
        final hsts = headers[SecurityHeaders.strictTransportSecurity]?.first ?? '';
        if (!hsts.contains('max-age')) {
          issues.add('Invalid Strict-Transport-Security header');
        }
      }
    }

    // Check X-Content-Type-Options
    if (config.enforceXContentTypeOptions) {
      if (!headers.containsKey(SecurityHeaders.xContentTypeOptions)) {
        issues.add('Missing X-Content-Type-Options header');
      } else {
        final cto = headers[SecurityHeaders.xContentTypeOptions]?.first ?? '';
        if (cto.toLowerCase() != 'nosniff') {
          issues.add('Invalid X-Content-Type-Options header');
        }
      }
    }

    // Check X-Frame-Options
    if (config.enforceXFrameOptions) {
      if (!headers.containsKey(SecurityHeaders.xFrameOptions)) {
        issues.add('Missing X-Frame-Options header');
      }
    }

    // Log issues
    if (issues.isNotEmpty) {
      if (config.warnOnly) {
        logger.warn('Security headers validation issues', context: {
          'issues': issues,
          'url': response.requestOptions.uri.toString(),
        });
        return true; // Allow but warn
      } else {
        logger.error('Security headers validation failed', context: {
          'issues': issues,
          'url': response.requestOptions.uri.toString(),
        });
        return false; // Fail
      }
    }

    logger.debug('Security headers validation passed');
    return true;
  }

  /// Create Dio interceptor for security headers validation
  Interceptor createInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        if (!validateHeaders(response)) {
          // In strict mode, reject response
          if (!config.warnOnly) {
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: 'Security headers validation failed',
              ),
            );
          }
        }
        return handler.next(response);
      },
    );
  }
}

/// Global security headers validator
final securityHeadersValidator = SecurityHeadersValidator();

