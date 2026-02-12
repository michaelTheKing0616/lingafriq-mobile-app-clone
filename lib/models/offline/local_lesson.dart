class LocalLesson {
  String id;
  String title;
  String content;
  String language;
  String level;
  List<String> audioPaths;
  List<String> imagePaths;
  DateTime downloadedAt;
  DateTime? lastAccessedAt;
  int sizeBytes;
  Map<String, dynamic> metadata;
  bool isComplete;
  int orderIndex;
  String? moduleId;
  String? unitId;
  List<Map<String, dynamic>> exercises;

  LocalLesson({
    required this.id,
    required this.title,
    required this.content,
    required this.language,
    required this.level,
    this.audioPaths = const [],
    this.imagePaths = const [],
    required this.downloadedAt,
    this.lastAccessedAt,
    this.sizeBytes = 0,
    this.metadata = const {},
    this.isComplete = false,
    this.orderIndex = 0,
    this.moduleId,
    this.unitId,
    this.exercises = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'language': language,
      'level': level,
      'audioPaths': audioPaths,
      'imagePaths': imagePaths,
      'downloadedAt': downloadedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'sizeBytes': sizeBytes,
      'metadata': metadata,
      'isComplete': isComplete,
      'orderIndex': orderIndex,
      'moduleId': moduleId,
      'unitId': unitId,
      'exercises': exercises,
    };
  }

  factory LocalLesson.fromJson(Map<String, dynamic> json) {
    return LocalLesson(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      language: json['language'] as String,
      level: json['level'] as String,
      audioPaths: (json['audioPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imagePaths: (json['imagePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isComplete: json['isComplete'] as bool? ?? false,
      orderIndex: json['orderIndex'] as int? ?? 0,
      moduleId: json['moduleId'] as String?,
      unitId: json['unitId'] as String?,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  LocalLesson copyWith({
    String? id,
    String? title,
    String? content,
    String? language,
    String? level,
    List<String>? audioPaths,
    List<String>? imagePaths,
    DateTime? downloadedAt,
    DateTime? lastAccessedAt,
    int? sizeBytes,
    Map<String, dynamic>? metadata,
    bool? isComplete,
    int? orderIndex,
    String? moduleId,
    String? unitId,
    List<Map<String, dynamic>>? exercises,
  }) {
    return LocalLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      language: language ?? this.language,
      level: level ?? this.level,
      audioPaths: audioPaths ?? this.audioPaths,
      imagePaths: imagePaths ?? this.imagePaths,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      metadata: metadata ?? this.metadata,
      isComplete: isComplete ?? this.isComplete,
      orderIndex: orderIndex ?? this.orderIndex,
      moduleId: moduleId ?? this.moduleId,
      unitId: unitId ?? this.unitId,
      exercises: exercises ?? this.exercises,
    );
  }
}
