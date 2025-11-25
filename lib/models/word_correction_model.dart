import 'dart:convert';

import 'package:flutter/foundation.dart';

class WordCorrectionModel {
  final List<String> choices;
  final String answer;
  final String question;
  final String description;

  WordCorrectionModel({
    required this.choices,
    required this.answer,
    required this.question,
    required this.description,
  });

  WordCorrectionModel copyWith({
    List<String>? choices,
    String? answer,
    String? question,
    String? description,
  }) {
    return WordCorrectionModel(
      choices: choices ?? this.choices,
      answer: answer ?? this.answer,
      question: question ?? this.question,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choices': choices,
      'answer': answer,
      'question': question,
      'description': description,
    };
  }

  factory WordCorrectionModel.fromMap(Map<String, dynamic> map) {
    return WordCorrectionModel(
      choices: List<String>.from(map['choices']),
      answer: map['answer'] ?? '',
      question: map['question'] ?? '',
      description: map['description'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory WordCorrectionModel.fromJson(String source) =>
      WordCorrectionModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'WordCorrectionModel(choices: $choices, answer: $answer, question: $question, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WordCorrectionModel &&
        listEquals(other.choices, choices) &&
        other.answer == answer &&
        other.question == question &&
        other.description == description;
  }

  @override
  int get hashCode {
    return choices.hashCode ^ answer.hashCode ^ question.hashCode ^ description.hashCode;
  }

  static List<WordCorrectionModel> test = [
    WordCorrectionModel(
      choices: [
        "Wehdone",
        "Only a little",
        "I don't know",
        "I am fine",
        "Yes",
        "No",
      ],
      answer: "Wehdone",
      question: "Wehdone",
      description: "My name is Jonny. I travelled to Nigeria last week. Before my trip, ",
    ),
    WordCorrectionModel(
      choices: [
        "na small Pidgin I dey speak",
        "Only a little",
        "I don't know",
        "I am fine",
        "Yes",
        "No",
      ],
      answer: "I don't know",
      question: "na small Pidgin I dey speak",
      description:
          "because I learnt a little from listening to Afrobeats. I heard a lot of people also speak Yoruba, but ",
    ),
    WordCorrectionModel(
      choices: [
        "I no dey",
        "speak Yoruba",
        "I don't know",
        "I am fine",
        "Yes",
        "No",
      ],
      answer: "I am fine",
      question: "I no dey",
      description:
          ". I hope to learn one day. Amaka, my good friend, was so happy to see me, and shouted \"",
    ),
    WordCorrectionModel(
      choices: [
        "I no dey ",
        "speak Yoruba",
        "How far Jonny",
        "I am fine",
        "Yes",
        "No",
      ],
      answer: "How far Jonny",
      question: "How far Jonny",
      description: "\" upon seeing me. I laughed and said, ",
    ),
    WordCorrectionModel(
      choices: [
        "I no dey ",
        "I dey o Amaka",
        "How far Jonny",
        "I am fine",
        "Yes",
        "No",
      ],
      answer: "How far Jonny",
      question: "I dey o Amaka",
      description: "She then asked, \"Abeg\" did you buy ",
    ),
  ];
}
