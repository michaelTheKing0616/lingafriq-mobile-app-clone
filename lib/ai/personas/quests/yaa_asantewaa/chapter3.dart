// P11-018 — Bilingual demand dialogue, comprehension checkpoint, council builders.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/ai/personas/quest_runner.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/sentence_builder.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/ai/personas/persona_claim_chip.dart';

/// copy_keys: quest.subtitles.toggle, quest.checkpoint.replay
abstract final class QuestChapter3Copy {
  static const subtitlesToggleLabel = 'Show English subtitles';
  static const subtitlesOnHint =
      'Subtitles stay on for earlier levels; you can turn them off anytime.';
  static const subtitlesOffHint = 'Listen first — turn subtitles on if you need help.';
  static const governorDemand =
      'The governor reads aloud: Britain demands the surrender of the Golden Stool for safekeeping.';
  static const yaaReplyLocked =
      'Yaa Asantewaa’s Twi reply is awaiting native sign-off. You will hear her voice here once reviewers publish the lines.';
  static const checkpointTitle = 'Three sentences to understand';
  static const checkpointIntro =
      'Before the council debates, confirm you caught the heart of what was said.';
  static const checkpointReplay = 'Replay this sentence';
  static const checkpointFail =
      'Not quite — replay the line, then try again.';
  static const councilTitle = 'The council debate';
  static const councilPersonaReply =
      'The Golden Stool is our sovereignty. We will not trade it for orders from abroad.';
  static const councilInferredNote =
      'Inferred from dossier yaa.card.golden_stool — not a verbatim quote.';
}

enum QuestChapter3Phase { demandDialogue, comprehensionCheckpoint, councilDebate }

@immutable
class QuestKeySentence {
  const QuestKeySentence({
    required this.id,
    required this.englishGloss,
    required this.comprehensionPromptEn,
    required this.correctOptionId,
    required this.options,
  });

  final String id;
  final String englishGloss;
  final String comprehensionPromptEn;
  final String correctOptionId;
  final List<QuestCheckpointOption> options;
}

@immutable
class QuestCheckpointOption {
  const QuestCheckpointOption({required this.id, required this.labelEn});

  final String id;
  final String labelEn;
}

/// Subtitle default: on for A1–A2, off from B1 upward (learner may override).
bool questSubtitlesDefaultOn(String learnerCefr) {
  switch (learnerCefr.toUpperCase()) {
    case 'A1':
    case 'A2':
      return true;
    default:
      return false;
  }
}

List<QuestKeySentence> defaultYaaDemandKeySentences() => const [
  QuestKeySentence(
    id: 'ks1',
    englishGloss:
        'The Golden Stool is the soul of the Ashanti nation, not an object to hand over.',
    comprehensionPromptEn: 'What is the Golden Stool compared to?',
    correctOptionId: 'soul',
    options: [
      QuestCheckpointOption(id: 'soul', labelEn: 'The soul of the nation'),
      QuestCheckpointOption(id: 'coin', labelEn: 'A trade coin'),
      QuestCheckpointOption(id: 'gift', labelEn: 'A gift for the governor'),
    ],
  ),
  QuestKeySentence(
    id: 'ks2',
    englishGloss:
        'Leaders will not let outsiders dictate Ashanti customs.',
    comprehensionPromptEn: 'Who must not control Ashanti customs?',
    correctOptionId: 'outsiders',
    options: [
      QuestCheckpointOption(id: 'outsiders', labelEn: 'Outsiders'),
      QuestCheckpointOption(id: 'drummers', labelEn: 'Market drummers'),
      QuestCheckpointOption(id: 'children', labelEn: 'Young messengers only'),
    ],
  ),
  QuestKeySentence(
    id: 'ks3',
    englishGloss:
        'The Queen Mother will lead the people to defend what is sacred.',
    comprehensionPromptEn: 'Who leads the defense of what is sacred?',
    correctOptionId: 'queen_mother',
    options: [
      QuestCheckpointOption(id: 'queen_mother', labelEn: 'The Queen Mother'),
      QuestCheckpointOption(id: 'governor', labelEn: 'The British governor'),
      QuestCheckpointOption(id: 'merchant', labelEn: 'A market merchant'),
    ],
  ),
];

@immutable
class QuestCheckpointEvaluation {
  const QuestCheckpointEvaluation({
    required this.passed,
    this.failedSentenceId,
  });

  final bool passed;
  final String? failedSentenceId;
}

QuestCheckpointEvaluation evaluateComprehensionCheckpoint({
  required List<QuestKeySentence> sentences,
  required Map<String, String?> answersBySentenceId,
}) {
  for (final sentence in sentences) {
    final picked = answersBySentenceId[sentence.id];
    if (picked == null || picked != sentence.correctOptionId) {
      return QuestCheckpointEvaluation(
        passed: false,
        failedSentenceId: sentence.id,
      );
    }
  }
  return const QuestCheckpointEvaluation(passed: true);
}

/// Chapters 2–3 beats: demand dialogue, 3-sentence checkpoint, council sentence builder.
class YaaQuestChapter3Scene extends StatefulWidget {
  const YaaQuestChapter3Scene({
    super.key,
    required this.demandChapter,
    required this.councilChapter,
    this.learnerCefr = 'A2',
    this.twiSurfaceLocked = true,
    this.keySentences,
    this.scaffold,
    this.onChapterComplete,
  });

  final PersonaQuestChapter demandChapter;
  final PersonaQuestChapter councilChapter;
  final String learnerCefr;
  final bool twiSurfaceLocked;
  final List<QuestKeySentence>? keySentences;
  final QuestSentenceScaffold? scaffold;
  final VoidCallback? onChapterComplete;

  @override
  State<YaaQuestChapter3Scene> createState() => _YaaQuestChapter3SceneState();
}

class _YaaQuestChapter3SceneState extends State<YaaQuestChapter3Scene> {
  QuestChapter3Phase _phase = QuestChapter3Phase.demandDialogue;
  late bool _subtitlesOn;
  int _dialogueBeat = 0;

  late final List<QuestKeySentence> _sentences;
  final Map<String, String?> _checkpointAnswers = {};
  String? _checkpointFailId;
  int _checkpointIndex = 0;

  late final QuestSentenceScaffold _scaffold;
  late List<String?> _filledSlots;
  QuestBuilderValidation? _builderStatus;

  @override
  void initState() {
    super.initState();
    _subtitlesOn = questSubtitlesDefaultOn(widget.learnerCefr);
    _sentences = widget.keySentences ?? defaultYaaDemandKeySentences();
    _scaffold = widget.scaffold ?? kYaaCouncilDefendScaffold;
    _filledSlots = List<String?>.filled(_scaffold.slotCount, null);
  }

  void _advanceDialogue() {
    if (_dialogueBeat < 1) {
      setState(() => _dialogueBeat += 1);
      return;
    }
    setState(() => _phase = QuestChapter3Phase.comprehensionCheckpoint);
  }

  void _submitCheckpointAnswer(String optionId) {
    final sentence = _sentences[_checkpointIndex];
    _checkpointAnswers[sentence.id] = optionId;
    final eval = evaluateComprehensionCheckpoint(
      sentences: _sentences.sublist(0, _checkpointIndex + 1),
      answersBySentenceId: _checkpointAnswers,
    );
    if (!eval.passed) {
      setState(() => _checkpointFailId = eval.failedSentenceId);
      SemanticsService.announce(
        QuestChapter3Copy.checkpointFail,
        TextDirection.ltr,
      );
      return;
    }
    if (_checkpointIndex < _sentences.length - 1) {
      setState(() {
        _checkpointIndex += 1;
        _checkpointFailId = null;
      });
      return;
    }
    setState(() {
      _checkpointFailId = null;
      _phase = QuestChapter3Phase.councilDebate;
    });
  }

  void _replayFailedSentence() {
    setState(() {
      final id = _checkpointFailId;
      if (id != null) {
        _checkpointAnswers.remove(id);
        _checkpointIndex = _sentences.indexWhere((s) => s.id == id);
        if (_checkpointIndex < 0) _checkpointIndex = 0;
      }
      _checkpointFailId = null;
      _phase = QuestChapter3Phase.comprehensionCheckpoint;
    });
  }

  void _pickToken(String tokenId) {
    final emptyIndex = _filledSlots.indexWhere((s) => s == null);
    if (emptyIndex < 0) return;
    setState(() {
      _filledSlots[emptyIndex] = tokenId;
      _builderStatus = validateScaffoldSelection(
        scaffold: _scaffold,
        filledTokenIds: _filledSlots,
      );
    });
  }

  void _clearLastToken() {
    final lastFilled = _filledSlots.lastIndexWhere((s) => s != null);
    if (lastFilled < 0) return;
    setState(() {
      _filledSlots[lastFilled] = null;
      _builderStatus = validateScaffoldSelection(
        scaffold: _scaffold,
        filledTokenIds: _filledSlots,
      );
    });
  }

  void _submitBuilder() {
    final status = validateScaffoldSelection(
      scaffold: _scaffold,
      filledTokenIds: _filledSlots,
    );
    setState(() => _builderStatus = status);
    if (status == QuestBuilderValidation.complete) {
      widget.onChapterComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_phase == QuestChapter3Phase.demandDialogue) ...[
            Text(
              widget.demandChapter.title,
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Text(
              widget.demandChapter.objectiveEn,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 16.h),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(QuestChapter3Copy.subtitlesToggleLabel),
              subtitle: Text(
                _subtitlesOn
                    ? QuestChapter3Copy.subtitlesOnHint
                    : QuestChapter3Copy.subtitlesOffHint,
              ),
              value: _subtitlesOn,
              onChanged: (v) => setState(() => _subtitlesOn = v),
            ),
            SizedBox(height: 12.h),
            _DialogueBubble(
              speaker: 'Governor’s messenger',
              englishLine: QuestChapter3Copy.governorDemand,
              showSubtitle: true,
            ),
            if (_dialogueBeat >= 1)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: _DialogueBubble(
                  speaker: 'Yaa Asantewaa',
                  englishLine: widget.twiSurfaceLocked
                      ? QuestChapter3Copy.yaaReplyLocked
                      : _sentences.first.englishGloss,
                  showSubtitle: _subtitlesOn,
                  emphasized: true,
                ),
              ),
            SizedBox(height: 20.h),
            PanAfricanButton(
              label: _dialogueBeat < 1 ? 'Continue' : 'Start comprehension',
              onPressed: _advanceDialogue,
            ),
          ],
          if (_phase == QuestChapter3Phase.comprehensionCheckpoint) ...[
            Text(
              QuestChapter3Copy.checkpointTitle,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              QuestChapter3Copy.checkpointIntro,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 16.h),
            PanAfricanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sentence ${_checkpointIndex + 1} of ${_sentences.length}',
                    style: theme.textTheme.labelLarge,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _sentences[_checkpointIndex].englishGloss,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (_checkpointFailId == _sentences[_checkpointIndex].id) ...[
                    SizedBox(height: 12.h),
                    Text(
                      QuestChapter3Copy.checkpointFail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PanAfricanColors.error,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    PanAfricanSecondaryButton(
                      label: QuestChapter3Copy.checkpointReplay,
                      onPressed: _replayFailedSentence,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _sentences[_checkpointIndex].comprehensionPromptEn,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 12.h),
            ..._sentences[_checkpointIndex].options.map(
              (opt) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: PanAfricanButton(
                  label: opt.labelEn,
                  isOutlined: true,
                  onPressed: () => _submitCheckpointAnswer(opt.id),
                ),
              ),
            ),
          ],
          if (_phase == QuestChapter3Phase.councilDebate) ...[
            Text(
              QuestChapter3Copy.councilTitle,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              widget.councilChapter.objectiveEn,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 16.h),
            Text(
              _scaffold.positionEn,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 12.h),
            PanAfricanCard(
              child: Text(
                previewBuiltSentence(
                  scaffold: _scaffold,
                  filledTokenIds: _filledSlots,
                  preferTwi: !_subtitlesOn,
                  twiUnlocked: !widget.twiSurfaceLocked,
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              QuestSentenceBuilderCopy.hint,
              style: theme.textTheme.bodySmall,
            ),
            if (_builderStatus == QuestBuilderValidation.wrongPosition)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'Try a position that defends the Stool, not negotiation.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PanAfricanColors.error,
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _scaffold.tokensForPool().map((token) {
                return PanAfricanChip(
                  label: token.displayLabel(
                    preferTwi: !_subtitlesOn,
                    twiUnlocked: !widget.twiSurfaceLocked,
                  ),
                  onSelected: () => _pickToken(token.id),
                );
              }).toList(),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: PanAfricanSecondaryButton(
                    label: 'Undo tile',
                    onPressed: _clearLastToken,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: PanAfricanButton(
                    label: QuestSentenceBuilderCopy.submit,
                    onPressed: _submitBuilder,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            const PersonaClaimChip(variant: PersonaClaimChipVariant.inferred),
            Text(
              QuestChapter3Copy.councilInferredNote,
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 8.h),
            _DialogueBubble(
              speaker: 'Yaa Asantewaa',
              englishLine: QuestChapter3Copy.councilPersonaReply,
              showSubtitle: true,
              emphasized: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Golden/widget fixture for subtitle-on demand dialogue (no network fonts).
@visibleForTesting
class YaaQuestDialogueSubtitlesFixture extends StatelessWidget {
  const YaaQuestDialogueSubtitlesFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _DialogueBubble(
          speaker: 'Governor’s messenger',
          englishLine: QuestChapter3Copy.governorDemand,
          showSubtitle: true,
        ),
        SizedBox(height: 12),
        _DialogueBubble(
          speaker: 'Yaa Asantewaa',
          englishLine: QuestChapter3Copy.yaaReplyLocked,
          showSubtitle: true,
          emphasized: true,
        ),
      ],
    );
  }
}

class _DialogueBubble extends StatelessWidget {
  const _DialogueBubble({
    required this.speaker,
    required this.englishLine,
    required this.showSubtitle,
    this.emphasized = false,
  });

  final String speaker;
  final String englishLine;
  final bool showSubtitle;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$speaker dialogue',
      child: PanAfricanCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              speaker,
              style: theme.textTheme.labelLarge?.copyWith(
                color: PanAfricanColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              englishLine,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (!showSubtitle)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'Subtitles hidden — toggle on if you need the English gloss.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PanAfricanColors.neutralMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
