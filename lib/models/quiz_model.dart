import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lingafriq/models/item.dart';

class QuizModel {
  final String question;
  final String answer;
  final double? score;
  final List<String> choices;
  final ContentItem? bankItem;
  QuizModel({
    this.score = 0,
    required this.question,
    required this.answer,
    required this.choices,
    this.bankItem,
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
    final built = QuizModel.fromChoice(
      system: map['system'] as String? ?? 'unit_quiz',
      id: '${map['id'] ?? map['question'] ?? 'item'}',
      prompt: '${map['question'] ?? ''}',
      language: '${map['language'] ?? 'und'}',
      choices: [
        for (final choice in List<String>.from(map['choices'] ?? const <String>[]))
          {'text': choice, 'correct_answer': choice == map['answer']},
      ],
    );
    if (built == null) throw ArgumentError('quiz question is not servable');
    return built;
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

  static final placeholder = RegExp(r'word\d|example|sample|lorem', caseSensitive: false);

  static bool isPlaceholder(String value) => placeholder.hasMatch(value);

  /// A legacy choice question becomes one bank item. A placeholder is not imported.
  static QuizModel? fromChoice({
    required String system,
    required String id,
    required String prompt,
    required List choices,
    String language = 'und',
    String? hint,
    String? funFact,
    double? score,
    List<String> refs = const [],
  }) {
    final item = _choiceItem(
      system: system,
      id: id,
      prompt: prompt,
      choices: choices,
      language: language,
      hint: hint,
      funFact: funFact,
      refs: refs,
    );
    if (item == null) return null;
    final ordered = <String>[];
    for (final choice in choices) {
      if (choice is! Map) continue;
      final text = choice['text'];
      if (text is String && text.trim().isNotEmpty) ordered.add(text);
    }
    return QuizModel(
      question: item.stimulusText ?? prompt,
      answer: item.correct,
      choices: ordered.isEmpty ? [item.correct] : ordered,
      score: score,
      bankItem: item,
    );
  }

  /// A bracketed word question stays a sentence task on the bank.
  static ContentItem? sentenceItem({
    required String system,
    required String id,
    required String prompt,
    String language = 'und',
  }) {
    if (prompt.trim().isEmpty || isPlaceholder(prompt)) return null;
    final answers = RegExp(r'\[(.*?)\]').allMatches(prompt).map((match) {
      final body = (match.group(1) ?? '').trim();
      if (body.isEmpty) return '';
      final parts = body.split('/');
      return (parts.length > 1 ? parts.last : parts.first).trim();
    }).where((answer) => answer.isNotEmpty).toList();
    final stripped = prompt.replaceAll(RegExp(r'\[(.*?)\]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final correct = answers.isEmpty ? stripped : answers.join(' | ');
    if (correct.isEmpty || isPlaceholder(correct)) return null;
    return ContentItem(
      id: _bankId(system, id),
      language: _language(language),
      type: 'sentence_building',
      stimulusRefs: [_ref(id)],
      stimulusText: prompt,
      correct: correct,
      variants: answers,
      diacriticInsensitive: true,
      distractors: const [],
      irtA: 1,
      irtB: 0,
      skillTags: [system],
      reviewStatus: 'approved',
    );
  }

  static ContentItem? _choiceItem({
    required String system,
    required String id,
    required String prompt,
    required List choices,
    required String language,
    required String? hint,
    required String? funFact,
    required List<String> refs,
  }) {
    if (prompt.trim().isEmpty || isPlaceholder(prompt)) return null;
    final options = <Map>[];
    for (final choice in choices) {
      if (choice is Map && choice['text'] is String && (choice['text'] as String).trim().isNotEmpty) {
        options.add(choice);
      }
    }
    if (options.any((option) => isPlaceholder(option['text'] as String))) return null;
    final correct = options.where((option) => option['correct_answer'] == true).toList();
    if (correct.length != 1 || isPlaceholder(correct.first['text'] as String)) return null;
    final wrong = options.where((option) => option['correct_answer'] != true).toList();
    final distractors = wrong.map((option) {
      return ItemDistractor(text: option['text'] as String, rationale: _rationale(option, hint, funFact));
    }).toList();
    final stimulus = refs.where((ref) => ref.trim().isNotEmpty).toList();
    return ContentItem(
      id: _bankId(system, id),
      language: _language(language),
      type: distractors.isEmpty ? 'dictation' : 'multiple_choice',
      stimulusRefs: stimulus.isEmpty ? [_ref(id)] : stimulus,
      stimulusText: prompt,
      correct: correct.first['text'] as String,
      variants: const [],
      diacriticInsensitive: true,
      distractors: distractors,
      irtA: 1,
      irtB: 0,
      skillTags: [system],
      reviewStatus: 'approved',
    );
  }

  static String _rationale(Map option, String? hint, String? funFact) {
    for (final key in ['rationale', 'fun_fact', 'add_hint']) {
      final value = option[key];
      if (value is String && value.trim().isNotEmpty && !isPlaceholder(value)) return value.trim();
    }
    if (funFact != null && funFact.trim().isNotEmpty && !isPlaceholder(funFact)) return funFact.trim();
    if (hint != null && hint.trim().isNotEmpty && !isPlaceholder(hint)) return hint.trim();
    return option['text'] as String;
  }

  static String _language(String value) {
    final lower = value.toLowerCase();
    if (RegExp(r'^[a-z]{2,8}$').hasMatch(lower)) return lower;
    return 'und';
  }

  static String _bankId(String system, String id) {
    final cleaned = '$system.$id'.replaceAll(RegExp(r'[^A-Za-z0-9._:-]'), '.');
    final collapsed = cleaned.replaceAll(RegExp(r'\.+'), '.');
    if (collapsed.length < 3) return 'quiz.$system.item';
    return collapsed.length > 80 ? collapsed.substring(0, 80) : collapsed;
  }

  static String _ref(String id) {
    final cleaned = id.replaceAll(RegExp(r'[^A-Za-z0-9._:-]'), '.');
    return cleaned.length < 3 ? 'ref.quiz.item' : 'ref.$cleaned';
  }
}
