// P11-019 — Historian note, mini-quiz, primary source card, vocabulary merge.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/ai/personas/quest_runner.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// copy_keys: quest.debrief.note, quest.quiz.title, quest.primary.source
abstract final class QuestDebriefCopy {
  static const debriefNoteTitle = 'Historian note';
  static const quizTitle = 'Quick history check';
  static const primarySourceTitle = 'Primary source';
  static const missingNoteTitle = 'Historian note not ready';
  static const missingNoteBody =
      'A human historian must sign this note before the quest can be released. EXT-15 review is still pending.';
  static const missingNoteHint =
      'You can replay earlier chapters anytime. We will notify you when the note is published.';
  static const quizIntro =
      'Three questions from what you explored — no trick questions, just care with the facts.';
  static const quizFail =
      'One answer needs another look. Re-read the historian note, then try again.';
  static const vocabularyAdded =
      'Quest words joined your review deck once. Replays will not duplicate them.';
  static const finishQuest = 'Finish quest';
  static const continueLabel = 'Continue';
}

const String kYaaQuestPrimarySourcePath =
    'lib/ai/personas/quests/yaa_asantewaa/primary_source.json';

/// Human-written note body (release gated on EXT-15 historian sign-off).
const String kYaaQuestHistorianNoteBody = '''
After the 1900 war, British authorities exiled Yaa Asantewaa and other Ashanti leaders.
She died in exile in 1921. Scholarship remembers her council leadership and mobilization;
popular retellings sometimes flatten a complex war into a single victory myth.
''';

const bool kYaaQuestHistorianNoteDefaultReleaseApproved = false;

@immutable
class QuestPrimarySourceCard {
  const QuestPrimarySourceCard({
    required this.sourceId,
    required this.title,
    required this.captionEn,
    required this.provenanceEn,
    required this.licenceId,
    required this.licenceLabel,
    this.year,
    this.imageUrl,
    this.imageAltEn,
  });

  final String sourceId;
  final String title;
  final String captionEn;
  final String provenanceEn;
  final String licenceId;
  final String licenceLabel;
  final int? year;
  final String? imageUrl;
  final String? imageAltEn;

  static QuestPrimarySourceCard fromJson(Map<String, dynamic> json) {
    return QuestPrimarySourceCard(
      sourceId: json['source_id'] as String,
      title: json['title'] as String,
      captionEn: json['caption_en'] as String,
      provenanceEn: json['provenance_en'] as String,
      licenceId: json['licence_id'] as String,
      licenceLabel: json['licence_label'] as String,
      year: json['year'] as int?,
      imageUrl: json['image_url'] as String?,
      imageAltEn: json['image_alt_en'] as String?,
    );
  }

  void validateForDisplay() {
    if (sourceId.isEmpty ||
        title.isEmpty ||
        captionEn.isEmpty ||
        provenanceEn.isEmpty ||
        licenceId.isEmpty ||
        licenceLabel.isEmpty) {
      throw StateError('primary_source_incomplete');
    }
    if (imageUrl != null && (imageAltEn == null || imageAltEn!.isEmpty)) {
      throw StateError('primary_source_image_alt_required');
    }
  }
}

Future<QuestPrimarySourceCard> loadYaaQuestPrimarySource() async {
  if (kIsWeb) {
    throw UnsupportedError('Persona quest primary source is not bundled for web.');
  }
  final file = File(kYaaQuestPrimarySourcePath);
  if (!file.existsSync()) {
    throw StateError('Missing primary source JSON at $kYaaQuestPrimarySourcePath');
  }
  final card = QuestPrimarySourceCard.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );
  card.validateForDisplay();
  return card;
}

QuestPrimarySourceCard parsePrimarySourceJson(String jsonText) {
  final card = QuestPrimarySourceCard.fromJson(
    jsonDecode(jsonText) as Map<String, dynamic>,
  );
  card.validateForDisplay();
  return card;
}

@immutable
class QuestMiniQuizQuestion {
  const QuestMiniQuizQuestion({
    required this.id,
    required this.promptEn,
    required this.correctOptionId,
    required this.options,
  });

  final String id;
  final String promptEn;
  final String correctOptionId;
  final List<QuestMiniQuizOption> options;
}

@immutable
class QuestMiniQuizOption {
  const QuestMiniQuizOption({required this.id, required this.labelEn});

  final String id;
  final String labelEn;
}

List<QuestMiniQuizQuestion> defaultYaaAftermathQuiz() => const [
  QuestMiniQuizQuestion(
    id: 'q1',
    promptEn: 'What happened to Yaa Asantewaa after the 1900 conflict?',
    correctOptionId: 'exile',
    options: [
      QuestMiniQuizOption(id: 'exile', labelEn: 'She was exiled by British authorities'),
      QuestMiniQuizOption(id: 'throne', labelEn: 'She immediately became British governor'),
      QuestMiniQuizOption(id: 'retire', labelEn: 'She retired quietly in Kumasi with no consequences'),
    ],
  ),
  QuestMiniQuizQuestion(
    id: 'q2',
    promptEn: 'The Golden Stool was defended in 1900 primarily as…',
    correctOptionId: 'sovereignty',
    options: [
      QuestMiniQuizOption(id: 'sovereignty', labelEn: 'A symbol of Ashanti sovereignty'),
      QuestMiniQuizOption(id: 'furniture', labelEn: 'Ordinary furniture for trade'),
      QuestMiniQuizOption(id: 'coin', labelEn: 'Currency to pay colonial taxes'),
    ],
  ),
  QuestMiniQuizQuestion(
    id: 'q3',
    promptEn: 'When did Yaa Asantewaa die?',
    correctOptionId: '1921',
    options: [
      QuestMiniQuizOption(id: '1921', labelEn: '1921, while still in exile'),
      QuestMiniQuizOption(id: '1900', labelEn: '1900, during the first week of fighting'),
      QuestMiniQuizOption(id: '1960', labelEn: '1960, at Ghanaian independence'),
    ],
  ),
];

@immutable
class QuestChapterQuizResult {
  const QuestChapterQuizResult({
    required this.questId,
    required this.chapterIndex,
    required this.correctCount,
    required this.questionCount,
    required this.passed,
    required this.recordedAtIso,
  });

  final String questId;
  final int chapterIndex;
  final int correctCount;
  final int questionCount;
  final bool passed;
  final String recordedAtIso;
}

QuestChapterQuizResult evaluateMiniQuiz({
  required String questId,
  required int chapterIndex,
  required List<QuestMiniQuizQuestion> questions,
  required Map<String, String?> answersByQuestionId,
  String recordedAtIso = '1970-01-01T00:00:00Z',
}) {
  var correct = 0;
  for (final q in questions) {
    if (answersByQuestionId[q.id] == q.correctOptionId) {
      correct += 1;
    }
  }
  final passed = correct == questions.length;
  return QuestChapterQuizResult(
    questId: questId,
    chapterIndex: chapterIndex,
    correctCount: correct,
    questionCount: questions.length,
    passed: passed,
    recordedAtIso: recordedAtIso,
  );
}

/// Quest vocabulary lexeme ids (English deck entries; Twi surfaces stay gated).
List<String> defaultYaaQuestVocabularyLexemeIds() => const [
  'yaa.quest.lex.golden_stool',
  'yaa.quest.lex.queen_mother',
  'yaa.quest.lex.exile',
  'yaa.quest.lex.kumasi',
];

/// Idempotent deck merge — adds each lexeme at most once (AC4).
PersonaQuestProgress mergeQuestVocabularyIdempotent(
  PersonaQuestProgress progress,
  Iterable<String> lexemeIds,
) {
  final pending = lexemeIds.where((id) => !progress.earnedVocabularyIds.contains(id));
  if (pending.isEmpty) {
    return progress;
  }
  return progress.recordVocabulary(pending);
}

bool historianNoteReadyForRelease({
  required bool approvedForRelease,
  required String noteBody,
}) {
  return approvedForRelease && noteBody.trim().isNotEmpty;
}

enum QuestDebriefPhase { historianNote, miniQuiz, primarySource, vocabularyDone }

class YaaQuestDebriefScene extends StatefulWidget {
  const YaaQuestDebriefScene({
    super.key,
    required this.chapter,
    required this.questId,
    required this.vocabularyDeckId,
    this.historianNoteApprovedForRelease = kYaaQuestHistorianNoteDefaultReleaseApproved,
    this.historianNoteBody = kYaaQuestHistorianNoteBody,
    this.primarySource,
    this.quizQuestions,
    this.initialProgress,
    this.onProgressChanged,
    this.onQuestComplete,
  });

  final PersonaQuestChapter chapter;
  final String questId;
  final String vocabularyDeckId;
  final bool historianNoteApprovedForRelease;
  final String historianNoteBody;
  final QuestPrimarySourceCard? primarySource;
  final List<QuestMiniQuizQuestion>? quizQuestions;
  final PersonaQuestProgress? initialProgress;
  final ValueChanged<PersonaQuestProgress>? onProgressChanged;
  final VoidCallback? onQuestComplete;

  @override
  State<YaaQuestDebriefScene> createState() => _YaaQuestDebriefSceneState();
}

class _YaaQuestDebriefSceneState extends State<YaaQuestDebriefScene> {
  QuestDebriefPhase _phase = QuestDebriefPhase.historianNote;
  late PersonaQuestProgress _progress;
  late final List<QuestMiniQuizQuestion> _questions;
  final Map<String, String?> _quizAnswers = {};
  int _quizIndex = 0;
  QuestChapterQuizResult? _quizResult;
  bool _quizFailed = false;
  bool _vocabularyMerged = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress ??
        PersonaQuestProgress.initial(widget.questId);
    _questions = widget.quizQuestions ?? defaultYaaAftermathQuiz();
  }

  bool get _noteReady => historianNoteReadyForRelease(
        approvedForRelease: widget.historianNoteApprovedForRelease,
        noteBody: widget.historianNoteBody,
      );

  void _emitProgress(PersonaQuestProgress next) {
    _progress = next;
    widget.onProgressChanged?.call(next);
  }

  void _advanceFromNote() {
    if (!_noteReady) return;
    setState(() => _phase = QuestDebriefPhase.miniQuiz);
  }

  void _submitQuizAnswer(String optionId) {
    final q = _questions[_quizIndex];
    if (optionId != q.correctOptionId) {
      setState(() => _quizFailed = true);
      SemanticsService.announce(QuestDebriefCopy.quizFail, TextDirection.ltr);
      return;
    }
    _quizAnswers[q.id] = optionId;
    if (_quizIndex < _questions.length - 1) {
      setState(() {
        _quizIndex += 1;
        _quizFailed = false;
      });
      return;
    }
    final result = evaluateMiniQuiz(
      questId: widget.questId,
      chapterIndex: widget.chapter.index,
      questions: _questions,
      answersByQuestionId: _quizAnswers,
    );
    setState(() {
      _quizResult = result;
      _quizFailed = false;
      _phase = QuestDebriefPhase.primarySource;
    });
  }

  void _advanceFromPrimarySource() {
    final merged = mergeQuestVocabularyIdempotent(
      _progress,
      defaultYaaQuestVocabularyLexemeIds(),
    );
    _emitProgress(merged.completeChapter(widget.chapter.index));
    setState(() {
      _vocabularyMerged = true;
      _phase = QuestDebriefPhase.vocabularyDone;
    });
  }

  void _finishQuest() {
    widget.onQuestComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_noteReady) {
      return _MissingHistorianNotePanel(theme: theme);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.chapter.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.chapter.objectiveEn,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: PanAfricanColors.neutralMedium,
            ),
          ),
          SizedBox(height: 24.h),
          if (_phase == QuestDebriefPhase.historianNote) ...[
            _HistorianNoteSection(body: widget.historianNoteBody),
            SizedBox(height: 20.h),
            PanAfricanButton(
              label: QuestDebriefCopy.continueLabel,
              onPressed: _advanceFromNote,
            ),
          ],
          if (_phase == QuestDebriefPhase.miniQuiz) ...[
            Text(
              QuestDebriefCopy.quizTitle,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(QuestDebriefCopy.quizIntro, style: theme.textTheme.bodyMedium),
            SizedBox(height: 16.h),
            _MiniQuizSection(
              question: _questions[_quizIndex],
              showFail: _quizFailed,
              onPick: _submitQuizAnswer,
            ),
          ],
          if (_phase == QuestDebriefPhase.primarySource &&
              widget.primarySource != null) ...[
            QuestPrimarySourceDisplay(card: widget.primarySource!),
            SizedBox(height: 20.h),
            PanAfricanButton(
              label: QuestDebriefCopy.continueLabel,
              onPressed: _advanceFromPrimarySource,
            ),
          ],
          if (_phase == QuestDebriefPhase.vocabularyDone) ...[
            PanAfricanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    QuestDebriefCopy.vocabularyAdded,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (_quizResult != null) ...[
                    SizedBox(height: 12.h),
                    Text(
                      'Quiz: ${_quizResult!.correctCount}/${_quizResult!.questionCount} correct (chapter ${widget.chapter.index}).',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (_vocabularyMerged) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Deck ${widget.vocabularyDeckId}: ${_progress.earnedVocabularyIds.length} quest words saved.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),
            PanAfricanButton(
              label: QuestDebriefCopy.finishQuest,
              onPressed: _finishQuest,
            ),
          ],
        ],
      ),
    );
  }
}

class _MissingHistorianNotePanel extends StatelessWidget {
  const _MissingHistorianNotePanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: QuestDebriefCopy.missingNoteTitle,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: PanAfricanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.history_edu, size: 40.sp, color: PanAfricanColors.primary),
              SizedBox(height: 12.h),
              Text(
                QuestDebriefCopy.missingNoteTitle,
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 8.h),
              Text(QuestDebriefCopy.missingNoteBody, style: theme.textTheme.bodyMedium),
              SizedBox(height: 12.h),
              Text(
                QuestDebriefCopy.missingNoteHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: PanAfricanColors.neutralMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorianNoteSection extends StatelessWidget {
  const _HistorianNoteSection({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: QuestDebriefCopy.debriefNoteTitle,
      child: PanAfricanCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              QuestDebriefCopy.debriefNoteTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(body.trim(), style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _MiniQuizSection extends StatelessWidget {
  const _MiniQuizSection({
    required this.question,
    required this.showFail,
    required this.onPick,
  });

  final QuestMiniQuizQuestion question;
  final bool showFail;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question.promptEn, style: theme.textTheme.titleSmall),
        SizedBox(height: 12.h),
        for (final opt in question.options)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: PanAfricanSecondaryButton(
              label: opt.labelEn,
              onPressed: () => onPick(opt.id),
            ),
          ),
        if (showFail)
          Text(
            QuestDebriefCopy.quizFail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: PanAfricanColors.error,
            ),
          ),
      ],
    );
  }
}

/// Primary source card with provenance and licence (AC3).
class QuestPrimarySourceDisplay extends StatelessWidget {
  const QuestPrimarySourceDisplay({super.key, required this.card});

  final QuestPrimarySourceCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${QuestDebriefCopy.primarySourceTitle}: ${card.title}',
      child: PanAfricanCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              QuestDebriefCopy.primarySourceTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            if (card.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  card.imageUrl!,
                  height: 180.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(card.imageAltEn),
                  semanticLabel: card.imageAltEn,
                ),
              )
            else
              _imagePlaceholder(card.imageAltEn),
            SizedBox(height: 12.h),
            Text(card.title, style: theme.textTheme.titleSmall),
            if (card.year != null)
              Text(
                '${card.year}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: PanAfricanColors.neutralMedium,
                ),
              ),
            SizedBox(height: 8.h),
            Text(card.captionEn, style: theme.textTheme.bodyMedium),
            SizedBox(height: 12.h),
            Text(
              'Provenance',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(card.provenanceEn, style: theme.textTheme.bodySmall),
            SizedBox(height: 8.h),
            Text(
              'Licence: ${card.licenceLabel} (${card.licenceId})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: PanAfricanColors.neutralMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(String? alt) {
    return Semantics(
      label: alt ?? 'Archival image unavailable',
      child: Container(
        height: 120.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PanAfricanColors.neutralLight,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.museum, size: 48.sp, color: PanAfricanColors.primary),
      ),
    );
  }
}
