// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';

class ChoiceQuestionModel {
  final List<Choice> choices;
  final Question question;
  ChoiceQuestionModel({
    required this.choices,
    required this.question,
  });

  ChoiceQuestionModel copyWith({
    List<Choice>? choices,
    Question? question,
  }) {
    return ChoiceQuestionModel(
      choices: choices ?? this.choices,
      question: question ?? this.question,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'choices': choices.map((x) => x.toMap()).toList()});
    result.addAll({'question': question.toMap()});

    return result;
  }

  factory ChoiceQuestionModel.fromMap(Map<String, dynamic> map) {
    return ChoiceQuestionModel(
      choices: List<Choice>.from(map['choices']?.map((x) => Choice.fromMap(x))),
      question: Question.fromMap(map['question']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ChoiceQuestionModel.fromJson(String source) =>
      ChoiceQuestionModel.fromMap(json.decode(source));

  @override
  String toString() => 'ChoiceQuestionModel(choices: $choices, question: $question)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChoiceQuestionModel &&
        listEquals(other.choices, choices) &&
        other.question == question;
  }

  @override
  int get hashCode => choices.hashCode ^ question.hashCode;
}

class Choice {
  final int id;
  final String text;
  final String? image;
  final bool correct_answer;
  final int lesson_question;
  Choice({
    required this.id,
    required this.text,
    required this.image,
    required this.correct_answer,
    required this.lesson_question,
  });

  Choice copyWith({
    int? id,
    String? text,
    String? image,
    bool? correct_answer,
    int? lesson_question,
  }) {
    return Choice(
      id: id ?? this.id,
      text: text ?? this.text,
      image: image ?? this.image,
      correct_answer: correct_answer ?? this.correct_answer,
      lesson_question: lesson_question ?? this.lesson_question,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'text': text});
    if (image != null) {
      result.addAll({'image': image});
    }
    result.addAll({'correct_answer': correct_answer});
    result.addAll({'lesson_question': lesson_question});

    return result;
  }

  factory Choice.fromMap(Map<String, dynamic> map) {
    return Choice(
      id: map['id']?.toInt() ?? 0,
      text: map['text'] ?? '',
      image: map['image'],
      correct_answer: map['correct_answer'] ?? false,
      lesson_question: map['lesson_question']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Choice.fromJson(String source) => Choice.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Choice(id: $id, text: $text, image: $image, correct_answer: $correct_answer, lesson_question: $lesson_question)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Choice &&
        other.id == id &&
        other.text == text &&
        other.image == image &&
        other.correct_answer == correct_answer &&
        other.lesson_question == lesson_question;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        text.hashCode ^
        image.hashCode ^
        correct_answer.hashCode ^
        lesson_question.hashCode;
  }
}

class Image {}

class Question {
  final int id;
  final String question;
  final String text;
  final String? image;
  final String? audio;
  final String? video;
  final String add_hint;
  final String fun_fact;
  final String score;
  final bool is_published;
  final bool completed;
  final String types;
  final int lesson_section;
  final String? completed_by;
  Question({
    required this.id,
    required this.question,
    required this.text,
    required this.image,
    required this.audio,
    required this.video,
    required this.add_hint,
    required this.fun_fact,
    required this.score,
    required this.is_published,
    required this.completed,
    required this.types,
    required this.lesson_section,
    required this.completed_by,
  });

  Question copyWith({
    int? id,
    String? question,
    String? text,
    String? image,
    String? audio,
    String? video,
    String? add_hint,
    String? fun_fact,
    String? score,
    bool? is_published,
    bool? completed,
    String? types,
    int? lesson_section,
    String? completed_by,
  }) {
    return Question(
      id: id ?? this.id,
      question: question ?? this.question,
      text: text ?? this.text,
      image: image ?? this.image,
      audio: audio ?? this.audio,
      video: video ?? this.video,
      add_hint: add_hint ?? this.add_hint,
      fun_fact: fun_fact ?? this.fun_fact,
      score: score ?? this.score,
      is_published: is_published ?? this.is_published,
      completed: completed ?? this.completed,
      types: types ?? this.types,
      lesson_section: lesson_section ?? this.lesson_section,
      completed_by: completed_by ?? this.completed_by,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'question': question});
    result.addAll({'text': text});
    if (image != null) {
      result.addAll({'image': image});
    }
    if (audio != null) {
      result.addAll({'audio': audio});
    }
    if (video != null) {
      result.addAll({'video': video});
    }
    result.addAll({'add_hint': add_hint});
    result.addAll({'fun_fact': fun_fact});
    result.addAll({'score': score});
    result.addAll({'is_published': is_published});
    result.addAll({'completed': completed});
    result.addAll({'types': types});
    result.addAll({'lesson_section': lesson_section});
    if (completed_by != null) {
      result.addAll({'completed_by': completed_by});
    }

    return result;
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id']?.toInt() ?? 0,
      question: map['question'] ?? '',
      text: map['text'] ?? '',
      image: map['image'],
      audio: map['audio'],
      video: map['video'],
      add_hint: map['add_hint'] ?? '',
      fun_fact: map['fun_fact'] ?? '',
      score: map['score'] ?? '',
      is_published: map['is_published'] ?? false,
      completed: map['completed'] ?? false,
      types: map['types'] ?? '',
      lesson_section: map['lesson_section']?.toInt() ?? 0,
      completed_by: map['completed_by'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Question.fromJson(String source) => Question.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Question(id: $id, question: $question, text: $text, image: $image, audio: $audio, video: $video, add_hint: $add_hint, fun_fact: $fun_fact, score: $score, is_published: $is_published, completed: $completed, types: $types, lesson_section: $lesson_section, completed_by: $completed_by)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Question &&
        other.id == id &&
        other.question == question &&
        other.text == text &&
        other.image == image &&
        other.audio == audio &&
        other.video == video &&
        other.add_hint == add_hint &&
        other.fun_fact == fun_fact &&
        other.score == score &&
        other.is_published == is_published &&
        other.completed == completed &&
        other.types == types &&
        other.lesson_section == lesson_section &&
        other.completed_by == completed_by;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        question.hashCode ^
        text.hashCode ^
        image.hashCode ^
        audio.hashCode ^
        video.hashCode ^
        add_hint.hashCode ^
        fun_fact.hashCode ^
        score.hashCode ^
        is_published.hashCode ^
        completed.hashCode ^
        types.hashCode ^
        lesson_section.hashCode ^
        completed_by.hashCode;
  }
}
