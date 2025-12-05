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

    return CultureContent(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['excerpt'] ?? map['description'] ?? '',
      type: contentType,
      imageUrl: map['featured_image'] ?? map['imageUrl'],
      audioUrl: map['audioUrl'],
      videoUrl: map['videoUrl'],
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
}

