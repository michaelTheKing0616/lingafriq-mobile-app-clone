// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/user_provider.dart';

class MannerismTutorialModel {
  final int id;
  final String name;
  final String title;
  final String? text;
  final String? audio;
  final String? video;
  final String? image;
  final int score;
  final bool? completed;
  final String? date_time;
  final int mannerism_section;
  final int? completed_by;
  MannerismTutorialModel({
    required this.id,
    required this.name,
    required this.title,
    required this.text,
    required this.audio,
    required this.video,
    required this.image,
    required this.score,
    required this.completed,
    required this.date_time,
    required this.mannerism_section,
    required this.completed_by,
  });

  MannerismTutorialModel copyWith({
    int? id,
    String? name,
    String? title,
    String? text,
    String? audio,
    String? video,
    String? image,
    int? score,
    bool? completed,
    String? date_time,
    int? mannerism_section,
    int? completed_by,
  }) {
    return MannerismTutorialModel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      text: text ?? this.text,
      audio: audio ?? this.audio,
      video: video ?? this.video,
      image: image ?? this.image,
      score: score ?? this.score,
      completed: completed ?? this.completed,
      date_time: date_time ?? this.date_time,
      mannerism_section: mannerism_section ?? this.mannerism_section,
      completed_by: completed_by ?? this.completed_by,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'name': name});
    result.addAll({'title': title});
    if (text != null) {
      result.addAll({'text': text});
    }
    if (audio != null) {
      result.addAll({'audio': audio});
    }
    if (video != null) {
      result.addAll({'video': video});
    }
    if (image != null) {
      result.addAll({'image': image});
    }
    result.addAll({'score': score});
    if (completed != null) {
      result.addAll({'completed': completed});
    }
    if (date_time != null) {
      result.addAll({'date_time': date_time});
    }
    result.addAll({'mannerism_section': mannerism_section});
    if (completed_by != null) {
      result.addAll({'completed_by': completed_by});
    }

    return result;
  }

  factory MannerismTutorialModel.fromMap(Map<String, dynamic> map) {
    return MannerismTutorialModel(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      text: map['text'],
      audio: map['audio'],
      video: map['video'],
      image: map['image'],
      score: map['score']?.toInt() ?? 0,
      completed: map['completed'],
      date_time: map['date_time'],
      mannerism_section: map['mannerism_section']?.toInt() ?? 0,
      completed_by: map['completed_by']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory MannerismTutorialModel.fromJson(String source) =>
      MannerismTutorialModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'MannerismTutorialModel(id: $id, name: $name, title: $title, text: $text, audio: $audio, video: $video, image: $image, score: $score, completed: $completed, date_time: $date_time, mannerism_section: $mannerism_section, completed_by: $completed_by)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MannerismTutorialModel &&
        other.id == id &&
        other.name == name &&
        other.title == title &&
        other.text == text &&
        other.audio == audio &&
        other.video == video &&
        other.image == image &&
        other.score == score &&
        other.completed == completed &&
        other.date_time == date_time &&
        other.mannerism_section == mannerism_section &&
        other.completed_by == completed_by;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        title.hashCode ^
        text.hashCode ^
        audio.hashCode ^
        video.hashCode ^
        image.hashCode ^
        score.hashCode ^
        completed.hashCode ^
        date_time.hashCode ^
        mannerism_section.hashCode ^
        completed_by.hashCode;
  }

  bool isCompleted(WidgetRef ref) {
    final id = ref.watch(userProvider)?.id;
    return completed_by == id;
  }
}
