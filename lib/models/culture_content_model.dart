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

  String toJson() => jsonEncode(toMap());
  factory CultureContent.fromJson(String json) => CultureContent.fromMap(jsonDecode(json));
}

