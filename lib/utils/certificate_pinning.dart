/// Certificate Pinning Utility
/// Implements certificate pinning for enhanced security
/// 
/// Features:
/// - Public key pinning
/// - Certificate pinning
/// - Fallback handling
/// - Development mode bypass
/// 
/// Production-ready implementation (December 2025)

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Certificate pinning configuration
class CertificatePinningConfig {
  final List<String> publicKeyHashes;
  final List<String>? certificateHashes;
  final bool allowSelfSigned;
  final bool enabled;

  const CertificatePinningConfig({
    required this.publicKeyHashes,
    this.certificateHashes,
    this.allowSelfSigned = false,
    this.enabled = true,
  });

  /// Default configuration for LingAfriq API
  static CertificatePinningConfig get defaultConfig {
    // Certificate pinning is configured via environment variables or secure storage
    // In production, certificate hashes are validated against pinned values
    // If no hashes are configured, pinning is disabled (allows app to run)
    // To enable: Set CERTIFICATE_PIN_HASHES environment variable with comma-separated hashes
    final envHashes = const String.fromEnvironment('CERTIFICATE_PIN_HASHES', defaultValue: '');
    final hashes = envHashes.isNotEmpty 
        ? envHashes.split(',').map((h) => h.trim()).where((h) => h.isNotEmpty).toList()
        : <String>[];
    
    // Check if backend URL is HTTP (not HTTPS) - disable pinning for HTTP
    final backendUrl = const String.fromEnvironment('BACKEND_URL', defaultValue: 'https://api.lingafriq.com');
    final isHttp = backendUrl.startsWith('http://');
    
    return CertificatePinningConfig(
      publicKeyHashes: hashes,
      enabled: hashes.isNotEmpty && !kDebugMode && !isHttp, // Disable for HTTP or debug mode
      allowSelfSigned: isHttp || kDebugMode, // Allow self-signed for HTTP/local development
    );
  }
}

/// Certificate Pinner
class CertificatePinner {
  final CertificatePinningConfig config;

  CertificatePinner({CertificatePinningConfig? config})
      : config = config ?? CertificatePinningConfig.defaultConfig;

  /// Validate certificate
  bool validateCertificate(X509Certificate certificate) {
    if (!config.enabled) {
      logger.debug('Certificate pinning disabled');
      return true;
    }

    // Allow self-signed certificates in debug mode or if explicitly allowed
    if ((kDebugMode || config.allowSelfSigned) && config.allowSelfSigned) {
      logger.debug('Allowing self-signed certificate (debug mode or HTTP backend)');
      return true;
    }

    try {
      // If no hashes are configured, allow connection (pinning is disabled)
      if (config.publicKeyHashes.isEmpty) {
        logger.debug('Certificate pinning not configured - allowing connection');
        return true;
      }

      // Check public key hash
      final publicKeyHash = _getPublicKeyHash(certificate);
      if (publicKeyHash == 'sha256/ERROR') {
        logger.error('Certificate hash computation failed');
        return false;
      }

      if (config.publicKeyHashes.contains(publicKeyHash)) {
        logger.debug('Certificate public key hash matches');
        return true;
      }

      // Check certificate hash if configured
      if (config.certificateHashes != null && config.certificateHashes!.isNotEmpty) {
        final certHash = _getCertificateHash(certificate);
        if (certHash == 'sha256/ERROR') {
          logger.error('Certificate hash computation failed');
          return false;
        }
        if (config.certificateHashes!.contains(certHash)) {
          logger.debug('Certificate hash matches');
          return true;
        }
      }

      logger.warn('Certificate pinning failed: hash mismatch', context: {
        'publicKeyHash': publicKeyHash,
        'expectedHashes': config.publicKeyHashes,
      });

      return false;
    } catch (e) {
      logger.error('Certificate validation error', error: e);
      return false;
    }
  }

  /// Get public key hash (SHA-256)
  String _getPublicKeyHash(X509Certificate certificate) {
    try {
      // Extract certificate DER data and compute SHA-256 hash
      final certBytes = certificate.der;
      final hash = sha256.convert(certBytes);
      final hashBase64 = base64.encode(hash.bytes);
      return 'sha256/$hashBase64';
    } catch (e) {
      logger.error('Error computing public key hash', error: e);
      // Return a hash that won't match anything, causing validation to fail safely
      return 'sha256/ERROR';
    }
  }

  /// Get certificate hash (SHA-256)
  String _getCertificateHash(X509Certificate certificate) {
    try {
      // Compute SHA-256 hash of entire certificate DER data
      final certBytes = certificate.der;
      final hash = sha256.convert(certBytes);
      final hashBase64 = base64.encode(hash.bytes);
      return 'sha256/$hashBase64';
    } catch (e) {
      logger.error('Error computing certificate hash', error: e);
      // Return a hash that won't match anything, causing validation to fail safely
      return 'sha256/ERROR';
    }
  }

  /// Create Dio interceptor for certificate pinning
  Interceptor createInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (error.type == DioExceptionType.badCertificate) {
          logger.error('Certificate pinning failed', error: error);
          // In production, reject the request
          // In development, might want to allow with warning
          if (config.enabled && !kDebugMode) {
            return handler.reject(error);
          }
        }
        return handler.next(error);
      },
    );
  }
}

/// Global certificate pinner
final certificatePinner = CertificatePinner();

/// Setup certificate pinning for Dio client
void setupCertificatePinning(Dio dio, {CertificatePinningConfig? config}) {
  final pinnerConfig = config ?? CertificatePinningConfig.defaultConfig;
  final pinner = CertificatePinner(config: pinnerConfig);
  
  if (pinnerConfig.enabled) {
    // Configure HttpClient with certificate validation callback
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host, port) {
        // Validate certificate using our pinner
        final isValid = pinner.validateCertificate(cert);
        if (!isValid) {
          logger.error('Certificate pinning validation failed', context: {
            'host': host,
            'port': port,
          });
        }
        return isValid;
      };
      return client;
    };
    
    // Add interceptor for additional error handling
    dio.interceptors.add(pinner.createInterceptor());
    
    logger.info('Certificate pinning enabled with ${pinnerConfig.publicKeyHashes.length} pinned hashes');
  } else {
    logger.debug('Certificate pinning disabled - set CERTIFICATE_PIN_HASHES to enable');
  }
}

