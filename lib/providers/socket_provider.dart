import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/gamification/socket_service.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';

/// Socket service provider for real-time updates
final socketServiceProvider = Provider<GamificationSocketService>((ref) {
  final service = GamificationSocketService();
  
  // Initialize when user is available
  ref.listen(userProvider, (previous, next) {
    if (next != null) {
      final token = ref.read(apiProvider.notifier).token;
      service.initialize(token);
      
      // Subscribe to user inbox
      final inboxUserId = next.globalId ?? next.id.toString();
      service.subscribeToUserInbox(inboxUserId);
    } else {
      service.disconnect();
    }
  });
  
  return service;
});

/// Provider for listening to badge awards
final badgeAwardedProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final controller = StreamController<Map<String, dynamic>>();
  
  socketService.onBadgeAwarded((data) {
    controller.add(data);
  });
  
  ref.onDispose(() {
    controller.close();
  });
  
  return controller.stream;
});

/// Provider for listening to leaderboard updates
final leaderboardUpdateProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final controller = StreamController<Map<String, dynamic>>();
  
  socketService.onLeaderboardUpdate((data) {
    controller.add(data);
  });
  
  ref.onDispose(() {
    controller.close();
  });
  
  return controller.stream;
});

/// Provider for listening to competition updates
final competitionUpdateProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final controller = StreamController<Map<String, dynamic>>();
  
  socketService.onCompetitionUpdate((data) {
    controller.add(data);
  });
  
  ref.onDispose(() {
    controller.close();
  });
  
  return controller.stream;
});
