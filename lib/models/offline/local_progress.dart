class LocalProgress {
  String id;
  String type;
  String language;
  int xpEarned;
  double completionPercentage;
  int score;
  int timeSpentSeconds;
  DateTime completedAt;
  bool isSynced;
  DateTime? syncedAt;
  Map<String, dynamic> details;
  int attempts;
  String? sessionId;

  LocalProgress({
    required this.id,
    required this.type,
    required this.language,
    this.xpEarned = 0,
    this.completionPercentage = 0.0,
    this.score = 0,
    this.timeSpentSeconds = 0,
    required this.completedAt,
    this.isSynced = false,
    this.syncedAt,
    this.details = const {},
    this.attempts = 1,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'language': language,
      'xpEarned': xpEarned,
      'completionPercentage': completionPercentage,
      'score': score,
      'timeSpentSeconds': timeSpentSeconds,
      'completedAt': completedAt.toIso8601String(),
      'isSynced': isSynced,
      'syncedAt': syncedAt?.toIso8601String(),
      'details': details,
      'attempts': attempts,
      'sessionId': sessionId,
    };
  }

  factory LocalProgress.fromJson(Map<String, dynamic> json) {
    return LocalProgress(
      id: json['id'] as String,
      type: json['type'] as String,
      language: json['language'] as String,
      xpEarned: json['xpEarned'] as int? ?? 0,
      completionPercentage:
          (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      score: json['score'] as int? ?? 0,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      completedAt: DateTime.parse(json['completedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
      details: json['details'] as Map<String, dynamic>? ?? {},
      attempts: json['attempts'] as int? ?? 1,
      sessionId: json['sessionId'] as String?,
    );
  }

  LocalProgress copyWith({
    String? id,
    String? type,
    String? language,
    int? xpEarned,
    double? completionPercentage,
    int? score,
    int? timeSpentSeconds,
    DateTime? completedAt,
    bool? isSynced,
    DateTime? syncedAt,
    Map<String, dynamic>? details,
    int? attempts,
    String? sessionId,
  }) {
    return LocalProgress(
      id: id ?? this.id,
      type: type ?? this.type,
      language: language ?? this.language,
      xpEarned: xpEarned ?? this.xpEarned,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      score: score ?? this.score,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      completedAt: completedAt ?? this.completedAt,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      details: details ?? this.details,
      attempts: attempts ?? this.attempts,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}
