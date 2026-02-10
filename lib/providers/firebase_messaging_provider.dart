import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/utils.dart';

final firebaseMessagingProvider = Provider<FirebaseMessagingProvider>((ref) {
  return FirebaseMessagingProvider(ref);
});

class FirebaseMessagingProvider {
  FirebaseMessagingProvider(this.read);
  final Ref read;
  final messaging = FirebaseMessaging.instance;

  static final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );
  static Future<void> init() async {
    // flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
  }

  Future<void> disableForegroundNotification() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions();
  }

  Future<void> enableForegroundNotification() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> initFCM() async {
    final settings = await messaging.requestPermission();
    log(
      'User granted permission: ${settings.authorizationStatus}',
      name: 'FirebaseMessagingProvider',
    );

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log('Notification opened app', name: 'FirebaseMessagingProvider');
      log('Message data: ${message.data}', name: 'FirebaseMessagingProvider');
      _handleNotificationNavigation(message.data);
    });

    FirebaseMessaging.onMessage.listen((message) async {
      log('Got a message whilst in the foreground!', name: 'FirebaseMessagingProvider');
      log('Message data: ${message.data}', name: 'FirebaseMessagingProvider');

      if (message.notification != null) {
        'Message also contained a notification: ${message.notification}'.log();
      }
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              priority: Priority.max,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });

    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      log('App opened from terminated state via notification', name: 'FirebaseMessagingProvider');
      log('Initial message data: ${message.data}', name: 'FirebaseMessagingProvider');
      _handleNotificationNavigation(message.data);
    }

    log('FCM Device Token: ${await getToken()}', name: 'FirebaseMessagingProvider');
  }

  Future<String?> getToken() {
    return messaging.getToken();
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      final type = (data['type'] as String?) ?? '';
      final targetId = data['targetId'] as String?;

      switch (type) {
        case 'chat_message':
        case 'private_message':
          if (targetId != null) {
            _navigateTo('connections', arguments: {'chatId': targetId});
          } else {
            _navigateTo('connections');
          }
          break;
        case 'tribe_activity':
        case 'tribe_update':
          _navigateTo('tribe_vs_tribe');
          break;
        case 'badge_earned':
        case 'achievement':
          _navigateTo('achievements');
          break;
        case 'streak_reminder':
        case 'daily_reminder':
          _navigateTo('daily_goals');
          break;
        case 'lesson_available':
        case 'new_content':
          _navigateTo('curriculum');
          break;
        case 'leaderboard_update':
          _navigateTo('leaderboard');
          break;
        case 'game_challenge':
          _navigateTo('games');
          break;
        default:
          if (type.isNotEmpty) {
            log('Unhandled notification type: $type', name: 'FirebaseMessagingProvider');
          }
      }
    } catch (e) {
      log('Error handling notification navigation: $e', name: 'FirebaseMessagingProvider');
    }
  }

  void _navigateTo(String routeName, {Object? arguments}) {
    try {
      final nav = read.read(navigationProvider);
      nav.navigateToNamed(routeName, arguments: arguments);
    } catch (e) {
      log('Error navigating to $routeName: $e', name: 'FirebaseMessagingProvider');
    }
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log(
    'Background message: id=${message.messageId}, data=${message.data}, '
    'title=${message.notification?.title}, body=${message.notification?.body}',
    name: 'FirebaseMessagingProvider',
  );
}

// Once created, we can now update FCM to use our own channel rather than the default FCM one.
// To do this, open the android/app/src/main/AndroidManifest.xml file for your FlutterProject project.
// Add the following meta-data schema within the application component:

// <meta-data
//   android:name="com.google.firebase.messaging.default_notification_channel_id"
//   android:value="high_importance_channel" />
