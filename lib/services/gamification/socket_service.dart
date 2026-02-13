import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:lingafriq/config/api_contract.dart';
class GamificationSocketService {
  IO.Socket? _socket;
  final String _baseUrl;

  GamificationSocketService({String? baseUrl})
      : _baseUrl = baseUrl ??
            ApiContract.baseUrl
                .replaceFirst(RegExp(r'^https?://'), '');

  /// Initialize socket connection
  void initialize(String? token) {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket = IO.io(
      'http://$_baseUrl',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
    });

    _socket!.onError((error) {
      print('❌ Socket error: $error');
    });
  }

  /// Subscribe to user inbox
  void subscribeToUserInbox(String userId) {
    _socket?.emit('subscribe', 'user:$userId:inbox');
  }

  /// Subscribe to tribe activity
  void subscribeToTribeActivity(String tribeId) {
    _socket?.emit('subscribe', 'tribe:$tribeId:activity');
  }

  /// Subscribe to village feed
  void subscribeToVillageFeed(String lang) {
    _socket?.emit('subscribe', 'village:$lang:feed');
  }

  /// Subscribe to leaderboard
  void subscribeToLeaderboard(String leaderboardId) {
    _socket?.emit('subscribe', 'leaderboard:$leaderboardId');
  }

  /// Subscribe to competition
  void subscribeToCompetition(String competitionId) {
    _socket?.emit('subscribe', 'competition:$competitionId:updates');
  }

  /// Listen to notifications
  void onNotification(Function(Map<String, dynamic>) callback) {
    _socket?.on('notification', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen to badge awards
  void onBadgeAwarded(Function(Map<String, dynamic>) callback) {
    _socket?.on('badges_awarded', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen to leaderboard updates
  void onLeaderboardUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('leaderboard_update', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen to competition updates
  void onCompetitionUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('competition_update', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

