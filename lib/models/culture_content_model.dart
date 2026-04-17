import 'dart:convert';

enum ContentType {
  article,
  story,
  music,
  festival,
  lore,
  recipe,
}

class CultureContent {
  final String id;
  final String title;
  final String description;
  final ContentType type;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  /// Extra images from scraper/CMS (hero remains [imageUrl] when set).
  final List<String> imageGallery;
  final List<String> highlights;
  final List<String> relatedTopics;
  final int? readingTimeMinutes;
  final String? license;
  final String? attribution;
  final String content;
  final String language;
  final String? country;
  final DateTime publishDate;
  final List<String> tags;
  final int views;
  final bool isFeatured;

  CultureContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.imageGallery = const [],
    this.highlights = const [],
    this.relatedTopics = const [],
    this.readingTimeMinutes,
    this.license,
    this.attribution,
    required this.content,
    required this.language,
    this.country,
    required this.publishDate,
    this.tags = const [],
    this.views = 0,
    this.isFeatured = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'videoUrl': videoUrl,
    'imageGallery': imageGallery,
    'highlights': highlights,
    'relatedTopics': relatedTopics,
    'readingTimeMinutes': readingTimeMinutes,
    'license': license,
    'attribution': attribution,
    'content': content,
    'language': language,
    'country': country,
    'publishDate': publishDate.toIso8601String(),
    'tags': tags,
    'views': views,
    'isFeatured': isFeatured,
  };

  factory CultureContent.fromMap(Map<String, dynamic> map) => CultureContent(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    type: ContentType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => ContentType.article,
    ),
    imageUrl: map['imageUrl'],
    audioUrl: map['audioUrl'],
    videoUrl: map['videoUrl'],
    imageGallery: List<String>.from(map['imageGallery'] ?? []),
    highlights: List<String>.from(map['highlights'] ?? []),
    relatedTopics: List<String>.from(map['relatedTopics'] ?? []),
    readingTimeMinutes: map['readingTimeMinutes'] as int?,
    license: map['license'] as String?,
    attribution: map['attribution'] as String?,
    content: map['content'] ?? '',
    language: map['language'] ?? '',
    country: map['country'],
    publishDate: DateTime.parse(map['publishDate']),
    tags: List<String>.from(map['tags'] ?? []),
    views: map['views'] ?? 0,
    isFeatured: map['isFeatured'] ?? false,
  );

  /// Factory constructor to parse backend API response
  /// Maps backend category to ContentType enum
  factory CultureContent.fromBackendMap(Map<String, dynamic> map) {
    // Map backend category to ContentType
    final category = (map['category'] ?? '').toString().toLowerCase();
    ContentType contentType;
    
    switch (category) {
      case 'music':
        contentType = ContentType.music;
        break;
      case 'festivals':
        contentType = ContentType.festival;
        break;
      case 'tradition':
      case 'history':
        contentType = ContentType.lore;
        break;
      case 'cuisine':
        contentType = ContentType.recipe;
        break;
      case 'art':
      case 'literature':
        contentType = ContentType.story;
        break;
      case 'language':
      default:
        contentType = ContentType.article;
        break;
    }

    // Parse publish date
    DateTime publishDate;
    try {
      if (map['published_date'] != null) {
        publishDate = DateTime.parse(map['published_date'].toString());
      } else if (map['created_at'] != null) {
        publishDate = DateTime.parse(map['created_at'].toString());
      } else {
        publishDate = DateTime.now();
      }
    } catch (e) {
      publishDate = DateTime.now();
    }

    final hero = map['featured_image'] ?? map['imageUrl']?.toString();
    final rawImages = map['images'];
    var gallery = <String>[];
    if (rawImages is List) {
      gallery = rawImages.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (hero != null && hero.toString().isNotEmpty) {
      gallery = gallery.where((u) => u != hero.toString()).toList();
    }

    final rawHigh = map['highlights'];
    final highlights = rawHigh is List
        ? rawHigh.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final rawRel = map['related_topics'];
    final related = rawRel is List
        ? rawRel.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final rt = map['reading_time_minutes'];
    final readingMins = rt is num ? rt.round() : null;

    return CultureContent(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['excerpt'] ?? map['description'] ?? '',
      type: contentType,
      imageUrl: hero?.toString(),
      audioUrl: map['audio_url'] ?? map['audioUrl'],
      videoUrl: map['video_url'] ?? map['videoUrl'],
      imageGallery: gallery,
      highlights: highlights,
      relatedTopics: related,
      readingTimeMinutes: readingMins,
      license: map['license']?.toString(),
      attribution: map['attribution']?.toString(),
      content: map['content'] ?? '',
      language: map['language'] ?? 'English',
      country: map['country'] ?? map['region'],
      publishDate: publishDate,
      tags: List<String>.from(map['tags'] ?? []),
      views: map['views'] ?? 0,
      isFeatured: map['featured'] ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory CultureContent.fromJson(String json) => CultureContent.fromMap(jsonDecode(json));

  CultureContent copyWith({
    String? id,
    String? title,
    String? description,
    ContentType? type,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
    List<String>? imageGallery,
    List<String>? highlights,
    List<String>? relatedTopics,
    int? readingTimeMinutes,
    String? license,
    String? attribution,
    String? content,
    String? language,
    String? country,
    DateTime? publishDate,
    List<String>? tags,
    int? views,
    bool? isFeatured,
  }) {
    return CultureContent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      imageGallery: imageGallery ?? this.imageGallery,
      highlights: highlights ?? this.highlights,
      relatedTopics: relatedTopics ?? this.relatedTopics,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      license: license ?? this.license,
      attribution: attribution ?? this.attribution,
      content: content ?? this.content,
      language: language ?? this.language,
      country: country ?? this.country,
      publishDate: publishDate ?? this.publishDate,
      tags: tags ?? this.tags,
      views: views ?? this.views,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}

