// Social Learning Group Models
// For study groups and friend challenges
// 
// Production-ready implementation

class StudyGroup {
  final String id;
  final String name;
  final String description;
  final String language;
  final int maxMembers;
  final List<String> memberIds;
  final String creatorId;
  final DateTime createdAt;
  final Map<String, dynamic> settings;
  final List<GroupChallenge> activeChallenges;
  final int level; // Group difficulty level

  StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    this.maxMembers = 50,
    required this.memberIds,
    required this.creatorId,
    required this.createdAt,
    this.settings = const {},
    this.activeChallenges = const [],
    this.level = 1,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      maxMembers: json['max_members'] as int? ?? 50,
      memberIds: List<String>.from(json['member_ids'] as List? ?? []),
      creatorId: json['creator_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      activeChallenges: (json['active_challenges'] as List?)
              ?.map((e) => GroupChallenge.fromJson(e))
              .toList() ??
          [],
      level: json['level'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'language': language,
      'max_members': maxMembers,
      'member_ids': memberIds,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'settings': settings,
      'active_challenges': activeChallenges.map((e) => e.toJson()).toList(),
      'level': level,
    };
  }
}

class GroupChallenge {
  final String id;
  final String groupId;
  final String name;
  final String description;
  final ChallengeType type;
  final DateTime startDate;
  final DateTime endDate;
  final int targetScore;
  final List<ChallengeParticipant> participants;
  final Map<String, dynamic> rules;
  final ChallengeReward? reward;

  GroupChallenge({
    required this.id,
    required this.groupId,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.targetScore,
    required this.participants,
    this.rules = const {},
    this.reward,
  });

  factory GroupChallenge.fromJson(Map<String, dynamic> json) {
    return GroupChallenge(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.toString() == 'ChallengeType.${json['type']}',
        orElse: () => ChallengeType.xpRace,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      targetScore: json['target_score'] as int,
      participants: (json['participants'] as List?)
              ?.map((e) => ChallengeParticipant.fromJson(e))
              .toList() ??
          [],
      rules: json['rules'] as Map<String, dynamic>? ?? {},
      reward: json['reward'] != null
          ? ChallengeReward.fromJson(json['reward'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_score': targetScore,
      'participants': participants.map((e) => e.toJson()).toList(),
      'rules': rules,
      'reward': reward?.toJson(),
    };
  }
}

enum ChallengeType {
  xpRace,           // Race to collect most XP
  streakBattle,     // Maintain longest streak
  lessonMarathon,   // Complete most lessons
  vocabularyDuel,   // Learn most words
  perfectWeek,      // 7 days in a row
  speedRun,         // Complete lessons fastest
}

class ChallengeParticipant {
  final String userId;
  final String username;
  final int currentScore;
  final int rank;
  final DateTime lastActivity;
  final Map<String, dynamic> stats;

  ChallengeParticipant({
    required this.userId,
    required this.username,
    required this.currentScore,
    required this.rank,
    required this.lastActivity,
    this.stats = const {},
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      currentScore: json['current_score'] as int,
      rank: json['rank'] as int,
      lastActivity: DateTime.parse(json['last_activity'] as String),
      stats: json['stats'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'current_score': currentScore,
      'rank': rank,
      'last_activity': lastActivity.toIso8601String(),
      'stats': stats,
    };
  }
}

class ChallengeReward {
  final int xp;
  final int coins;
  final List<String> badges;
  final String? specialItem;

  ChallengeReward({
    required this.xp,
    required this.coins,
    this.badges = const [],
    this.specialItem,
  });

  factory ChallengeReward.fromJson(Map<String, dynamic> json) {
    return ChallengeReward(
      xp: json['xp'] as int,
      coins: json['coins'] as int,
      badges: List<String>.from(json['badges'] as List? ?? []),
      specialItem: json['special_item'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'xp': xp,
      'coins': coins,
      'badges': badges,
      'special_item': specialItem,
    };
  }
}

class FriendConnection {
  final String id;
  final String userId1;
  final String userId2;
  final ConnectionStatus status;
  final DateTime connectedAt;
  final Map<String, dynamic> stats;

  FriendConnection({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.connectedAt,
    this.stats = const {},
  });

  factory FriendConnection.fromJson(Map<String, dynamic> json) {
    return FriendConnection(
      id: json['id'] as String,
      userId1: json['user_id_1'] as String,
      userId2: json['user_id_2'] as String,
      status: ConnectionStatus.values.firstWhere(
        (e) => e.toString() == 'ConnectionStatus.${json['status']}',
        orElse: () => ConnectionStatus.pending,
      ),
      connectedAt: DateTime.parse(json['connected_at'] as String),
      stats: json['stats'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id_1': userId1,
      'user_id_2': userId2,
      'status': status.toString().split('.').last,
      'connected_at': connectedAt.toIso8601String(),
      'stats': stats,
    };
  }
}

enum ConnectionStatus {
  pending,
  accepted,
  blocked,
}

