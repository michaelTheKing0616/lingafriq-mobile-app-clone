import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/gamification/tribes_service.dart';
import 'package:lingafriq/services/gamification/badges_service.dart';
import 'package:lingafriq/services/gamification/leaderboards_service.dart';
import 'package:lingafriq/services/gamification/journey_service.dart';
import 'package:lingafriq/services/gamification/competitions_service.dart';
import 'package:lingafriq/services/gamification/items_service.dart';
import 'package:lingafriq/services/gamification/events_service.dart';
import 'package:lingafriq/services/gamification/socket_service.dart';
import 'package:lingafriq/services/classroom/classroom_service.dart';
import 'package:lingafriq/providers/dio_provider.dart';

// Tribes Service Provider
final tribesServiceProvider = Provider<TribesService>((ref) {
  return TribesService(ref.read(client));
});

// Badges Service Provider
final badgesServiceProvider = Provider<BadgesService>((ref) {
  return BadgesService(ref.read(client));
});

// Leaderboards Service Provider
final leaderboardsServiceProvider = Provider<LeaderboardsService>((ref) {
  return LeaderboardsService(ref.read(client));
});

// Journey Service Provider
final journeyServiceProvider = Provider<JourneyService>((ref) {
  return JourneyService(ref.read(client));
});

// Competitions Service Provider
final competitionsServiceProvider = Provider<CompetitionsService>((ref) {
  return CompetitionsService(ref.read(client));
});

// Items Service Provider
final itemsServiceProvider = Provider<ItemsService>((ref) {
  return ItemsService(ref.read(client));
});

// Events Service Provider
final eventsServiceProvider = Provider<EventsService>((ref) {
  return EventsService(ref.read(client));
});

// Socket Service Provider
final gamificationSocketServiceProvider = Provider<GamificationSocketService>((ref) {
  return GamificationSocketService();
});

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  return ClassroomService(ref.read(client));
});

