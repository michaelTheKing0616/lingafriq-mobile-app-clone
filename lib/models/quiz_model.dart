import 'dart:convert';

import 'package:flutter/foundation.dart';

class QuizModel {
  final String question;
  final String answer;
  final double? score;
  final List<String> choices;
  QuizModel({
    this.score = 0,
    required this.question,
    required this.answer,
    required this.choices,
  });

  QuizModel copyWith({
    String? question,
    String? answer,
    List<String>? choices,
  }) {
    return QuizModel(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      choices: choices ?? this.choices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'choices': choices,
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      choices: List<String>.from(map['choices']),
    );
  }

  String toJson() => json.encode(toMap());

  factory QuizModel.fromJson(String source) => QuizModel.fromMap(json.decode(source));

  @override
  String toString() => 'QuizModel(question: $question, answer: $answer, choices: $choices)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QuizModel &&
        other.question == question &&
        other.answer == answer &&
        listEquals(other.choices, choices);
  }

  @override
  int get hashCode => question.hashCode ^ answer.hashCode ^ choices.hashCode;
  static List<QuizModel> test = [
    QuizModel(
      question: "How do you say “Hello” in pidgin.",
      answer: "How far",
      choices: [
        "I dey sad",
        "Ojoro man",
        "How far",
        "Inside am",
      ],
    ),
    QuizModel(
      question: "How do you say “Hello” in pidgin.",
      answer: "How far",
      choices: [
        "I dey sad",
        "Ojoro man",
        "How far",
        "Inside am",
      ],
    ),
    QuizModel(
      question: "How do you say “Hello” in pidgin.",
      answer: "How far",
      choices: [
        "I dey sad",
        "Ojoro man",
        "How far",
        "Inside am",
      ],
    ),
  ];
}
