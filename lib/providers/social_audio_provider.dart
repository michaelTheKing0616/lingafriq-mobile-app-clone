import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/social_audio/social_audio_room_model.dart';
import '../services/social_audio/social_audio_service.dart';
import '../services/social_audio/social_audio_cache.dart';
import '../services/social_audio/social_audio_learning_tracker.dart';
import '../providers/api_provider.dart';
import '../providers/dio_provider.dart';
import '../providers/user_provider.dart';
import '../utils/structured_logger.dart';

final socialAudioServiceProvider = Provider<SocialAudioService>((ref) {
  final api = ref.read(apiProvider.notifier);
  final dio = ref.read(client);
  return SocialAudioService(api, dio);
});

final socialAudioLearningTrackerProvider = Provider<SocialAudioLearningTracker>((ref) {
  final api = ref.read(apiProvider.notifier);
  final dio = ref.read(client);
  return SocialAudioLearningTracker(api, dio);
});

final socialAudioProvider = NotifierProvider<SocialAudioNotifier, SocialAudioState>(() {
  return SocialAudioNotifier();
});

class SocialAudioState {
  final List<SocialAudioRoom> discoveredRooms;
  final List<SocialAudioRoom> scheduledRooms;
  final List<SocialAudioRoom> myRooms;
  final SocialAudioRoom? currentRoom;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? selectedLanguage;
  final RoomType? selectedType;

  SocialAudioState({
    this.discoveredRooms = const [],
    this.scheduledRooms = const [],
    this.myRooms = const [],
    this.currentRoom,
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.selectedLanguage,
    this.selectedType,
  });

  SocialAudioState copyWith({
    List<SocialAudioRoom>? discoveredRooms,
    List<SocialAudioRoom>? scheduledRooms,
    List<SocialAudioRoom>? myRooms,
    SocialAudioRoom? currentRoom,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedLanguage,
    RoomType? selectedType,
  }) =>
      SocialAudioState(
        discoveredRooms: discoveredRooms ?? this.discoveredRooms,
        scheduledRooms: scheduledRooms ?? this.scheduledRooms,
        myRooms: myRooms ?? this.myRooms,
        currentRoom: currentRoom ?? this.currentRoom,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
        selectedLanguage: selectedLanguage ?? this.selectedLanguage,
        selectedType: selectedType ?? this.selectedType,
      );
}

class SocialAudioNotifier extends Notifier<SocialAudioState> {
  @override
  SocialAudioState build() => SocialAudioState();

  SocialAudioService get _service => ref.read(socialAudioServiceProvider);
  SocialAudioLearningTracker get _learningTracker => ref.read(socialAudioLearningTrackerProvider);

  /// Discover rooms with retry logic and caching
  Future<void> discoverRooms({
    String? language,
    RoomType? type,
    RoomStatus? status,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Load from cache first if not forcing refresh
    if (!forceRefresh) {
      try {
        final cachedRooms = await SocialAudioCache.getDiscoveredRooms();
        if (cachedRooms.isNotEmpty) {
          state = state.copyWith(
            discoveredRooms: cachedRooms,
            isLoading: false,
          );
        }
      } catch (e) {
        logger.error('Error loading cached rooms', tag: 'social-audio', error: e);
      }
    }

    // Retry logic
    int retries = 3;
    while (retries > 0) {
      try {
        final rooms = await _service.discoverRooms(
          language: language ?? state.selectedLanguage,
          type: type ?? state.selectedType,
          status: status,
          searchQuery: searchQuery ?? state.searchQuery,
          useCache: !forceRefresh,
        );
        state = state.copyWith(
          discoveredRooms: rooms,
          isLoading: false,
          error: null,
          searchQuery: searchQuery,
          selectedLanguage: language ?? state.selectedLanguage,
          selectedType: type ?? state.selectedType,
        );
        return; // Success
      } catch (e) {
        retries--;
        if (retries == 0) {
          state = state.copyWith(
            isLoading: false,
            error: e.toString(),
          );
          // Keep cached data if available
          if (state.discoveredRooms.isEmpty) {
            try {
              final cachedRooms = await SocialAudioCache.getDiscoveredRooms();
              if (cachedRooms.isNotEmpty) {
                state = state.copyWith(discoveredRooms: cachedRooms);
              }
            } catch (_) {}
          }
        } else {
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * (4 - retries)));
        }
      }
    }
  }

  /// Get scheduled rooms with caching
  Future<void> loadScheduledRooms({String? language, bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Load from cache first
    if (!forceRefresh) {
      try {
        final cachedRooms = await SocialAudioCache.getScheduledRooms();
        if (cachedRooms.isNotEmpty) {
          state = state.copyWith(
            scheduledRooms: cachedRooms,
            isLoading: false,
          );
        }
      } catch (e) {
        logger.error('Error loading cached scheduled rooms', tag: 'social-audio', error: e);
      }
    }

    try {
      final rooms = await _service.getScheduledRooms(
        language: language ?? state.selectedLanguage,
        after: DateTime.now(),
        useCache: !forceRefresh,
      );
      state = state.copyWith(
        scheduledRooms: rooms,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      // Keep cached data if available
      if (state.scheduledRooms.isEmpty) {
        try {
          final cachedRooms = await SocialAudioCache.getScheduledRooms();
          if (cachedRooms.isNotEmpty) {
            state = state.copyWith(scheduledRooms: cachedRooms);
          }
        } catch (_) {}
      }
    }
  }

  /// Get user's rooms with caching
  Future<void> loadMyRooms({bool hostedOnly = false, bool forceRefresh = false}) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    // Load from cache first
    if (!forceRefresh) {
      try {
        final cachedRooms = await SocialAudioCache.getMyRooms();
        if (cachedRooms.isNotEmpty) {
          state = state.copyWith(
            myRooms: cachedRooms,
            isLoading: false,
          );
        }
      } catch (e) {
        logger.error('Error loading cached my rooms', tag: 'social-audio', error: e);
      }
    }

    try {
      final rooms = await _service.getUserRooms(
        userId: user.id.toString(),
        hostedOnly: hostedOnly,
        useCache: !forceRefresh,
      );
      state = state.copyWith(
        myRooms: rooms,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      // Keep cached data if available
      if (state.myRooms.isEmpty) {
        try {
          final cachedRooms = await SocialAudioCache.getMyRooms();
          if (cachedRooms.isNotEmpty) {
            state = state.copyWith(myRooms: cachedRooms);
          }
        } catch (_) {}
      }
    }
  }

  /// Create room
  Future<SocialAudioRoom?> createRoom({
    required String name,
    required String description,
    required String language,
    RoomType type = RoomType.practice,
    int maxParticipants = 50,
    bool isPrivate = false,
    List<String> tags = const [],
    DateTime? scheduledStartTime,
    int? durationMinutes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final room = await _service.createRoom(
        name: name,
        description: description,
        language: language,
        type: type,
        maxParticipants: maxParticipants,
        isPrivate: isPrivate,
        tags: tags,
        scheduledStartTime: scheduledStartTime,
        durationMinutes: durationMinutes,
      );
      state = state.copyWith(
        isLoading: false,
        currentRoom: room,
      );
      // Refresh rooms list (force refresh after creation)
      await discoverRooms(forceRefresh: true);
      await loadMyRooms(forceRefresh: true);
      return room;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Join room with learning tracking
  Future<Map<String, dynamic>?> joinRoom({
    required String roomId,
    ParticipantRole role = ParticipantRole.listener,
  }) async {
    final user = ref.read(userProvider);
    if (user == null) return null;

    state = state.copyWith(isLoading: true, error: null);
    final joinedAt = DateTime.now();
    
    try {
      final result = await _service.joinRoom(
        roomId: roomId,
        userId: user.id.toString(),
        role: role,
      );
      
      final room = result['room'] as SocialAudioRoom;
      state = state.copyWith(
        isLoading: false,
        currentRoom: room,
      );
      
      // Track learning participation
      _learningTracker.trackParticipation(
        userId: user.id.toString(),
        roomId: roomId,
        language: room.language,
        joinedAt: joinedAt,
        role: role,
      ).catchError((e) => logger.error('Error tracking participation', tag: 'social-audio', error: e));
      
      // Refresh rooms list (force refresh after join)
      await discoverRooms(forceRefresh: true);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Leave room with learning tracking
  Future<void> leaveRoom(String roomId) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    final leftAt = DateTime.now();
    final currentRoom = state.currentRoom;
    
    try {
      await _service.leaveRoom(
        roomId: roomId,
        userId: user.id.toString(),
      );
      
      // Track learning participation end
      if (currentRoom != null) {
        final joinedAt = currentRoom.startedAt ?? currentRoom.createdAt;
        final duration = leftAt.difference(joinedAt).inMinutes;
        
        _learningTracker.trackParticipation(
          userId: user.id.toString(),
          roomId: roomId,
          language: currentRoom.language,
          joinedAt: joinedAt,
          leftAt: leftAt,
          durationMinutes: duration,
        ).catchError((e) => logger.error('Error tracking participation end', tag: 'social-audio', error: e));
      }
      
      state = state.copyWith(
        isLoading: false,
        currentRoom: null,
      );
      // Refresh rooms list (force refresh after leave)
      await discoverRooms(forceRefresh: true);
      await loadMyRooms(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set current room
  void setCurrentRoom(SocialAudioRoom? room) {
    state = state.copyWith(currentRoom: room);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

