import 'package:lingafriq/services/monitoring/performance_analytics.dart';

/// Helper utility for easy performance tracking
/// Simplifies adding performance tracking to critical paths
class PerformanceTrackingHelper {
  static final PerformanceAnalytics _analytics = PerformanceAnalytics();

  /// Track screen rendering performance
  static String trackScreenRender(String screenName) {
    return _analytics.startTracking(
      operationName: 'screen_render',
      metadata: {'screen': screenName},
    );
  }

  /// Stop tracking screen rendering
  static void stopScreenRender(String trackingId, String screenName) {
    _analytics.stopTracking(
      trackingId: trackingId,
      operationName: 'screen_render',
      additionalMetadata: {'screen': screenName},
    );
  }

  /// Track data loading operation
  static String trackDataLoad(String dataType) {
    return _analytics.startTracking(
      operationName: 'data_load',
      metadata: {'data_type': dataType},
    );
  }

  /// Stop tracking data loading
  static void stopDataLoad(String trackingId, String dataType, {bool success = true}) {
    _analytics.stopTracking(
      trackingId: trackingId,
      operationName: 'data_load',
      additionalMetadata: {
        'data_type': dataType,
        'success': success,
      },
    );
  }

  /// Track user interaction
  static String trackUserInteraction(String interactionType, {Map<String, dynamic>? metadata}) {
    return _analytics.startTracking(
      operationName: 'user_interaction',
      metadata: {
        'interaction_type': interactionType,
        ...?metadata,
      },
    );
  }

  /// Stop tracking user interaction
  static void stopUserInteraction(String trackingId, String interactionType) {
    _analytics.stopTracking(
      trackingId: trackingId,
      operationName: 'user_interaction',
      additionalMetadata: {'interaction_type': interactionType},
    );
  }

  /// Track image loading
  static String trackImageLoad(String imageUrl) {
    return _analytics.startTracking(
      operationName: 'image_load',
      metadata: {'image_url': imageUrl},
    );
  }

  /// Stop tracking image loading
  static void stopImageLoad(String trackingId, String imageUrl, {bool success = true}) {
    _analytics.stopTracking(
      trackingId: trackingId,
      operationName: 'image_load',
      additionalMetadata: {
        'image_url': imageUrl,
        'success': success,
      },
    );
  }

  /// Track list rendering
  static String trackListRender(String listType, {int? itemCount}) {
    return _analytics.startTracking(
      operationName: 'list_render',
      metadata: {
        'list_type': listType,
        if (itemCount != null) 'item_count': itemCount,
      },
    );
  }

  /// Stop tracking list rendering
  static void stopListRender(String trackingId, String listType) {
    _analytics.stopTracking(
      trackingId: trackingId,
      operationName: 'list_render',
      additionalMetadata: {'list_type': listType},
    );
  }

  /// Track form submission
  static String trackFormSubmission(String formName) {
    return _analytics.startTracking(
      operationName: 'form_submission',
      metadata: {'form_name': formName},
    );
  }

  /// Stop tracking form submission
  static void stopFormSubmission(String trackingId, String formName, {bool success = true}) {
    _analytics.stopTracking(
      trackingId: trackingId,
      operationName: 'form_submission',
      additionalMetadata: {
        'form_name': formName,
        'success': success,
      },
    );
  }

  /// Track navigation
  static String trackNavigation(String fromScreen, String toScreen) {
    return _analytics.startTracking(
      operationName: 'navigation',
      metadata: {
        'from_screen': fromScreen,
        'to_screen': toScreen,
      },
    );
  }

  /// Stop tracking navigation
  static void stopNavigation(String trackingId, String fromScreen, String toScreen) {
    _analytics.stopTracking(
      trackingId: trackingId,
      operationName: 'navigation',
      additionalMetadata: {
        'from_screen': fromScreen,
        'to_screen': toScreen,
      },
    );
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return _analytics.getAllPerformanceStats().map(
      (key, value) => MapEntry(key, value.toJson()),
    );
  }

  /// Get slow operations
  static List<Map<String, dynamic>> getSlowOperations({
    Duration threshold = const Duration(milliseconds: 1000),
    int limit = 10,
  }) {
    return _analytics.getSlowOperations(threshold: threshold, limit: limit)
        .map((m) => m.toJson())
        .toList();
  }
}

