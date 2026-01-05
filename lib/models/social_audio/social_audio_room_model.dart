/// Social Audio Room Model - Spaces-like room for language practice
class SocialAudioRoom {
  final String id;
  final String name;
  final String description;
  final String language;
  final String? hostId;
  final String? hostName;
  final String? hostAvatar;
  final RoomType type;
  final RoomStatus status;
  final int currentParticipants;
  final int maxParticipants;
  final List<String> speakerIds;
  final List<String> listenerIds;
  final DateTime createdAt;
  final DateTime? scheduledStartTime;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic> metadata;
  final bool isPrivate;
  final List<String> tags;
  final String? coverImageUrl;
  final int? durationMinutes;

  SocialAudioRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    this.hostId,
    this.hostName,
    this.hostAvatar,
    required this.type,
    required this.status,
    this.currentParticipants = 0,
    this.maxParticipants = 50,
    this.speakerIds = const [],
    this.listenerIds = const [],
    required this.createdAt,
    this.scheduledStartTime,
    this.startedAt,
    this.endedAt,
    this.metadata = const {},
    this.isPrivate = false,
    this.tags = const [],
    this.coverImageUrl,
    this.durationMinutes,
  });

  bool get isLive => status == RoomStatus.live;
  bool get isScheduled => status == RoomStatus.scheduled;
  bool get isEnded => status == RoomStatus.ended;
  bool get hasSpace => currentParticipants < maxParticipants;
  bool get isFull => currentParticipants >= maxParticipants;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'language': language,
        'host_id': hostId,
        'host_name': hostName,
        'host_avatar': hostAvatar,
        'type': type.name,
        'status': status.name,
        'current_participants': currentParticipants,
        'max_participants': maxParticipants,
        'speaker_ids': speakerIds,
        'listener_ids': listenerIds,
        'created_at': createdAt.toIso8601String(),
        'scheduled_start_time': scheduledStartTime?.toIso8601String(),
        'started_at': startedAt?.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'metadata': metadata,
        'is_private': isPrivate,
        'tags': tags,
        'cover_image_url': coverImageUrl,
        'duration_minutes': durationMinutes,
      };

  factory SocialAudioRoom.fromJson(Map<String, dynamic> json) => SocialAudioRoom(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        language: json['language'] as String,
        hostId: json['host_id'] as String?,
        hostName: json['host_name'] as String?,
        hostAvatar: json['host_avatar'] as String?,
        type: RoomType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RoomType.practice,
        ),
        status: RoomStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => RoomStatus.scheduled,
        ),
        currentParticipants: json['current_participants'] as int? ?? 0,
        maxParticipants: json['max_participants'] as int? ?? 50,
        speakerIds: (json['speaker_ids'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        listenerIds: (json['listener_ids'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        createdAt: DateTime.parse(json['created_at'] as String),
        scheduledStartTime: json['scheduled_start_time'] != null
            ? DateTime.parse(json['scheduled_start_time'] as String)
            : null,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        isPrivate: json['is_private'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        coverImageUrl: json['cover_image_url'] as String?,
        durationMinutes: json['duration_minutes'] as int?,
      );

  SocialAudioRoom copyWith({
    String? id,
    String? name,
    String? description,
    String? language,
    String? hostId,
    String? hostName,
    String? hostAvatar,
    RoomType? type,
    RoomStatus? status,
    int? currentParticipants,
    int? maxParticipants,
    List<String>? speakerIds,
    List<String>? listenerIds,
    DateTime? createdAt,
    DateTime? scheduledStartTime,
    DateTime? startedAt,
    DateTime? endedAt,
    Map<String, dynamic>? metadata,
    bool? isPrivate,
    List<String>? tags,
    String? coverImageUrl,
    int? durationMinutes,
  }) =>
      SocialAudioRoom(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        language: language ?? this.language,
        hostId: hostId ?? this.hostId,
        hostName: hostName ?? this.hostName,
        hostAvatar: hostAvatar ?? this.hostAvatar,
        type: type ?? this.type,
        status: status ?? this.status,
        currentParticipants: currentParticipants ?? this.currentParticipants,
        maxParticipants: maxParticipants ?? this.maxParticipants,
        speakerIds: speakerIds ?? this.speakerIds,
        listenerIds: listenerIds ?? this.listenerIds,
        createdAt: createdAt ?? this.createdAt,
        scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        metadata: metadata ?? this.metadata,
        isPrivate: isPrivate ?? this.isPrivate,
        tags: tags ?? this.tags,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );
}

enum RoomType {
  practice, // Casual language practice
  lesson, // Structured learning session
  discussion, // Topic-based discussion
  pronunciation, // Pronunciation practice
  storytelling, // Story sharing
  qa, // Q&A session
  cultural, // Cultural exchange
}

enum RoomStatus {
  scheduled, // Upcoming
  live, // Currently active
  ended, // Finished
  cancelled, // Cancelled
}

/// Room Participant Model
class RoomParticipant {
  final String userId;
  final String userName;
  final String? userAvatar;
  final ParticipantRole role;
  final bool isMuted;
  final bool isSpeaking;
  final DateTime joinedAt;
  final String? language; // User's target language

  RoomParticipant({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.role,
    this.isMuted = false,
    this.isSpeaking = false,
    required this.joinedAt,
    this.language,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'user_avatar': userAvatar,
        'role': role.name,
        'is_muted': isMuted,
        'is_speaking': isSpeaking,
        'joined_at': joinedAt.toIso8601String(),
        'language': language,
      };

  factory RoomParticipant.fromJson(Map<String, dynamic> json) => RoomParticipant(
        userId: json['user_id'] as String,
        userName: json['user_name'] as String,
        userAvatar: json['user_avatar'] as String?,
        role: ParticipantRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => ParticipantRole.listener,
        ),
        isMuted: json['is_muted'] as bool? ?? false,
        isSpeaking: json['is_speaking'] as bool? ?? false,
        joinedAt: DateTime.parse(json['joined_at'] as String),
        language: json['language'] as String?,
      );
}

enum ParticipantRole {
  host, // Room creator/host
  speaker, // Can speak
  listener, // Listen only
  moderator, // Can moderate
}

