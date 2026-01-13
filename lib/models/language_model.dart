import 'dart:convert';

class LanguageModel {
  final String title;
  final String image;
  final String level;
  final int lessonsCount;
  final String type;

  LanguageModel({
    required this.title,
    required this.image,
    required this.level,
    required this.lessonsCount,
    required this.type,
  });

  LanguageModel copyWith({
    String? title,
    String? image,
    String? level,
    int? lessonsCount,
    String? type,
  }) {
    return LanguageModel(
      title: title ?? this.title,
      image: image ?? this.image,
      level: level ?? this.level,
      lessonsCount: lessonsCount ?? this.lessonsCount,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
      'level': level,
      'lessonsCount': lessonsCount,
      'type': type,
    };
  }

  factory LanguageModel.fromMap(Map<String, dynamic> map) {
    return LanguageModel(
      title: map['title'] ?? '',
      image: map['image'] ?? '',
      level: map['level'] ?? '',
      lessonsCount: map['lessonsCount']?.toInt() ?? 0,
      type: map['type'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LanguageModel.fromJson(String source) => LanguageModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LanguageModel(title: $title, image: $image, level: $level, lessonsCount: $lessonsCount, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LanguageModel &&
        other.title == title &&
        other.image == image &&
        other.level == level &&
        other.lessonsCount == lessonsCount &&
        other.type == type;
  }

  @override
  int get hashCode {
    return title.hashCode ^ image.hashCode ^ level.hashCode ^ lessonsCount.hashCode ^ type.hashCode;
  }

  String get assetName => title[0].toLowerCase();

  static List<LanguageModel> languages = [
    LanguageModel(
      title: "Pidgin",
      image: "assets/images/pidgin.png",
      level: "Beginner",
      lessonsCount: 3,
      type: "Written & Oral",
    ),
    LanguageModel(
      title: "Hausa",
      image: "assets/images/hausa.png",
      level: "Beginner",
      lessonsCount: 5,
      type: "Written",
    ),
    LanguageModel(
      title: "Tiv",
      image: "assets/images/tiv.png",
      level: "Beginner",
      lessonsCount: 5,
      type: "Written & Oral",
    ),
    LanguageModel(
      title: "Igala",
      image: "assets/images/igala.png",
      level: "intermediate",
      lessonsCount: 6,
      type: "Oral",
    ),
  ];
}
