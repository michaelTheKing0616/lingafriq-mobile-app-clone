import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/content/vocab_audio_controls.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// MCQ built from flashcard strings (`word — meaning`) and lesson vocab.
class LessonMcqItem {
  final String prompt;
  final String correct;
  final List<String> options;

  const LessonMcqItem({
    required this.prompt,
    required this.correct,
    required this.options,
  });
}

List<LessonMcqItem> mcqsFromUnitQuiz(List<CurriculumMcqItem> unitQuiz) {
  return unitQuiz
      .where((q) => q.question.isNotEmpty && q.options.length >= 2 && q.answer.isNotEmpty)
      .map(
        (q) => LessonMcqItem(
          prompt: q.question,
          correct: q.answer,
          options: List<String>.from(q.options),
        ),
      )
      .toList();
}

List<LessonMcqItem> buildLessonMcqs(
  CurriculumLesson lesson, {
  List<CurriculumMcqItem> unitQuiz = const [],
  int max = 4,
}) {
  final fromUnit = mcqsFromUnitQuiz(unitQuiz);
  if (fromUnit.isNotEmpty) {
    return fromUnit.take(max).toList();
  }

  final rng = Random(lesson.id.hashCode);
  final meanings = lesson.vocabObjects.map((v) => v.meaning).where((m) => m.isNotEmpty).toList();
  final items = <LessonMcqItem>[];

  for (final raw in lesson.exercises
      .where((e) => e.type == 'flashcards')
      .expand((e) => e.items)
      .take(max)) {
    final parts = raw.split(' — ');
    if (parts.length < 2) continue;
    final word = parts.first.trim();
    final meaning = parts.sublist(1).join(' — ').trim();
    if (word.isEmpty || meaning.isEmpty) continue;
    final pool = meanings.where((m) => m != meaning).toList()..shuffle(rng);
    final distractors = pool.take(3).toList();
    while (distractors.length < 3) {
      distractors.add('—');
    }
    final options = [meaning, ...distractors]..shuffle(rng);
    items.add(LessonMcqItem(prompt: 'What does "$word" mean?', correct: meaning, options: options));
  }

  if (items.isEmpty && lesson.vocabObjects.isNotEmpty) {
    for (final v in lesson.vocabObjects.take(max)) {
      final pool = meanings.where((m) => m != v.meaning).toList()..shuffle(rng);
      final distractors = pool.take(3).toList();
      while (distractors.length < 3) {
        distractors.add('—');
      }
      final options = [v.meaning, ...distractors]..shuffle(rng);
      items.add(
        LessonMcqItem(
          prompt: 'What does "${v.word}" mean?',
          correct: v.meaning,
          options: options,
        ),
      );
    }
  }
  return items;
}

/// Guided practice: interactive MCQ from bundled lesson data.
class LessonGuidedPracticeStage extends StatefulWidget {
  const LessonGuidedPracticeStage({
    super.key,
    required this.lesson,
    required this.language,
    this.unitQuiz = const [],
  });

  final CurriculumLesson lesson;
  final String language;
  final List<CurriculumMcqItem> unitQuiz;

  @override
  State<LessonGuidedPracticeStage> createState() => _LessonGuidedPracticeStageState();
}

class _LessonGuidedPracticeStageState extends State<LessonGuidedPracticeStage> {
  late final List<LessonMcqItem> _items;
  int _index = 0;
  String? _selected;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _items = buildLessonMcqs(widget.lesson, unitQuiz: widget.unitQuiz);
  }

  void _check() {
    if (_selected == null) return;
    setState(() => _checked = true);
    final correct = _selected == _items[_index].correct;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LingAfriqUxVoice.quizFeedback(isCorrect: correct)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _next() {
    if (_index >= _items.length - 1) return;
    setState(() {
      _index++;
      _selected = null;
      _checked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Practice items will appear as you progress.',
          style: TextStyle(fontSize: 15.sp),
        ),
      );
    }
    final item = _items[_index];
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Text(
          'Guided practice (${_index + 1}/${_items.length})',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        PanAfricanCard(
          child: Text(item.prompt, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        ),
        SizedBox(height: 12.h),
        ...item.options.map((opt) {
          final selected = _selected == opt;
          final showResult = _checked;
          final isCorrect = opt == item.correct;
          Color? border;
          if (showResult && isCorrect) {
            border = PanAfricanColors.success;
          } else if (showResult && selected && !isCorrect) {
            border = PanAfricanColors.error;
          }
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: border ?? Colors.grey.withOpacity(0.3),
                  width: border != null ? 2 : 1,
                ),
              ),
              title: Text(opt),
              selected: selected,
              onTap: _checked ? null : () => setState(() => _selected = opt),
            ),
          );
        }),
        SizedBox(height: 8.h),
        if (!_checked)
          FilledButton(onPressed: _check, child: const Text('Check'))
        else if (_index < _items.length - 1)
          FilledButton(onPressed: _next, child: const Text('Next question')),
      ],
    );
  }
}

/// Retention flashcards with reveal + audio.
class LessonRetentionStage extends StatefulWidget {
  const LessonRetentionStage({
    super.key,
    required this.lesson,
    required this.language,
  });

  final CurriculumLesson lesson;
  final String language;

  @override
  State<LessonRetentionStage> createState() => _LessonRetentionStageState();
}

class _LessonRetentionStageState extends State<LessonRetentionStage> {
  final Set<int> _revealed = {};

  List<String> get _cards => widget.lesson.exercises
      .where((e) => e.type == 'flashcards')
      .expand((e) => e.items)
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Center(child: Text('Review your vocabulary in the next session.', style: TextStyle(fontSize: 15.sp)));
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _cards.length,
      itemBuilder: (_, i) {
        final raw = _cards[i];
        final parts = raw.split(' — ');
        final word = parts.isNotEmpty ? parts.first.trim() : raw;
        final meaning = parts.length > 1 ? parts.sublist(1).join(' — ').trim() : '';
        final show = _revealed.contains(i);
        return Card(
          margin: EdgeInsets.only(bottom: 10.h),
          child: ListTile(
            title: Text(show ? meaning : word, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            subtitle: show ? Text(word) : const Text('Tap to reveal meaning'),
            trailing: show
                ? VocabAudioControls(language: widget.language, text: word, compact: true)
                : const Icon(Icons.quiz_outlined),
            onTap: () => setState(() => _revealed.add(i)),
          ),
        );
      },
    );
  }
}
