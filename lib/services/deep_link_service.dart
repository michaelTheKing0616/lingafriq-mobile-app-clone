import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class DeepLinkService {
  static const String baseUrl = 'https://lingafriq.app';
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  NavigationProvider? _navigationProvider;

  static String? _pendingLessonId;

  /// Returns and clears the pending lesson ID from a lesson deep link, if any.
  static String? consumePendingLessonId() {
    final id = _pendingLessonId;
    _pendingLessonId = null;
    return id;
  }

  /// Initialize deep link handling. Pass [navigationProvider] to enable navigation.
  void initialize({NavigationProvider? navigationProvider}) {
    _navigationProvider = navigationProvider;
    _handleInitialLink();
    _handleIncomingLinks();
  }

  /// Handle initial link (when app is opened via deep link)
  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        logger.info('App opened with deep link', context: {'uri': initialLink.toString()});
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      logger.error('Error handling initial deep link', error: e);
    }
  }

  /// Handle incoming links (when app is already running)
  void _handleIncomingLinks() {
    _linkSubscription?.cancel();

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        logger.info('Received deep link', context: {'uri': uri.toString()});
        _handleDeepLink(uri);
      },
      onError: (err) {
        logger.error('Error in deep link stream', error: err);
      },
    );
  }

  /// Handle deep link routing
  Future<void> _handleDeepLink(Uri uri) async {
    try {
      final segments = uri.pathSegments;
      if (segments.isEmpty) {
        logger.warning('Deep link has no path segments', context: {'uri': uri.toString()});
        return;
      }

      // Note: Navigation will be handled by the app's navigation provider
      // This service just logs and routes to appropriate handlers

      switch (segments[0]) {
        case 'lesson':
          if (segments.length > 1) {
            final lessonId = segments[1];
            _navigateToLesson(lessonId);
          }
          break;

        case 'achievement':
          if (segments.length > 1) {
            final badgeId = segments[1];
            _navigateToAchievement(badgeId);
          }
          break;

        case 'invite':
          if (segments.length > 1) {
            final userId = segments[1];
            _handleInvite(userId);
          }
          break;

        case 'profile':
          if (segments.length > 1) {
            final userId = segments[1];
            _navigateToProfile(userId);
          }
          break;

        case 'quest':
          if (segments.length > 1) {
            final questId = segments[1];
            _navigateToQuest(questId);
          }
          break;

        default:
          logger.warning('Unknown deep link path', context: {'path': segments[0]});
      }
    } catch (e) {
      logger.error('Error handling deep link', error: e, context: {'uri': uri.toString()});
    }
  }

  /// Navigate to lesson screen
  void _navigateToLesson(String lessonId) {
    logger.info('Deep link: Navigate to lesson', context: {'lessonId': lessonId});
    _pendingLessonId = lessonId;
    _navigationProvider?.navigateToNamed('curriculum');
  }

  /// Navigate to achievement/badge screen
  void _navigateToAchievement(String badgeId) {
    logger.info('Deep link: Navigate to achievement', context: {'badgeId': badgeId});
    _navigationProvider?.navigateToNamed('achievements');
  }

  /// Handle friend invite
  void _handleInvite(String userId) {
    logger.info('Deep link: Handle friend invite', context: {'userId': userId});
    _navigationProvider?.navigateToNamed('connections');
  }

  /// Navigate to user profile
  void _navigateToProfile(String userId) {
    logger.info('Deep link: Navigate to profile', context: {'userId': userId});
    _navigationProvider?.navigateToNamed('/friend-profile', arguments: {'friendId': userId});
  }

  /// Navigate to friend quest
  void _navigateToQuest(String questId) {
    logger.info('Deep link: Navigate to quest', context: {'questId': questId});
    _navigationProvider?.navigateToNamed('quest');
  }

  /// Generate shareable links
  static String lessonLink(String lessonId) => '$baseUrl/lesson/$lessonId';
  static String achievementLink(String badgeId) => '$baseUrl/achievement/$badgeId';
  static String inviteLink(String userId) => '$baseUrl/invite/$userId';
  static String profileLink(String userId) => '$baseUrl/profile/$userId';
  static String questLink(String questId) => '$baseUrl/quest/$questId';

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
