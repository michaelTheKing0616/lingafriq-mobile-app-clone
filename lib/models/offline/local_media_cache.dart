class LocalMediaCache {
  String url;
  String localPath;
  String mimeType;
  int sizeBytes;
  DateTime cachedAt;
  DateTime lastAccessedAt;
  int accessCount;
  DateTime? expiresAt;
  String? checksum;
  String? language;
  String? lessonId;

  LocalMediaCache({
    required this.url,
    required this.localPath,
    required this.mimeType,
    this.sizeBytes = 0,
    required this.cachedAt,
    DateTime? lastAccessedAt,
    this.accessCount = 0,
    this.expiresAt,
    this.checksum,
    this.language,
    this.lessonId,
  }) : lastAccessedAt = lastAccessedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'localPath': localPath,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'cachedAt': cachedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'accessCount': accessCount,
      'expiresAt': expiresAt?.toIso8601String(),
      'checksum': checksum,
      'language': language,
      'lessonId': lessonId,
    };
  }

  factory LocalMediaCache.fromJson(Map<String, dynamic> json) {
    return LocalMediaCache(
      url: json['url'] as String,
      localPath: json['localPath'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : DateTime.now(),
      accessCount: json['accessCount'] as int? ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      checksum: json['checksum'] as String?,
      language: json['language'] as String?,
      lessonId: json['lessonId'] as String?,
    );
  }

  LocalMediaCache copyWith({
    String? url,
    String? localPath,
    String? mimeType,
    int? sizeBytes,
    DateTime? cachedAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    DateTime? expiresAt,
    String? checksum,
    String? language,
    String? lessonId,
  }) {
    return LocalMediaCache(
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
      expiresAt: expiresAt ?? this.expiresAt,
      checksum: checksum ?? this.checksum,
      language: language ?? this.language,
      lessonId: lessonId ?? this.lessonId,
    );
  }
}
