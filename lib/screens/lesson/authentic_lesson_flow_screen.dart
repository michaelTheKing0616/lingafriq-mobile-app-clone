import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/curriculum_provider.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_screen.dart';
import 'package:lingafriq/screens/games/tone_trainer_game.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen_enhanced.dart';
import 'package:lingafriq/screens/lesson/lesson_flow_stages.dart';
import 'package:lingafriq/screens/lesson/widgets/lesson_complete_widget.dart';
import 'package:lingafriq/services/content/bundled_lesson_content_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/content/vocab_audio_controls.dart';
import 'package:lingafriq/widgets/lingafriq_scaffold.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Blueprint §39 — ten-stage authentic lesson flow from bundled curriculum.
class AuthenticLessonFlowScreen extends HookConsumerWidget {
  const AuthenticLessonFlowScreen({
    super.key,
    required this.lesson,
    required this.language,
    required this.level,
    this.unitQuiz = const [],
  });

  final CurriculumLesson lesson;
  final String language;
  final String level;
  final List<CurriculumMcqItem> unitQuiz;

  static const _stages = [
    'Warm opening',
    'Context scene',
    'Vocabulary',
    'Pronunciation lab',
    'Grammar pattern',
    'Guided practice',
    'AI conversation',
    'Cultural intelligence',
    'Retention challenge',
    'Victory',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final stageIndex = useState(0);
    final practiceScore = useState(0.85);
    final bundled = BundledLessonContentService.fromCurriculumLesson(lesson);
    final vocab = lesson.vocabObjects;
    final dialogue = lesson.dialogue;
    final grammar = lesson.grammar ?? const <String>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVictory = stageIndex.value >= _stages.length - 1;

    void next() {
      if (isVictory) {
        ref.read(curriculumProvider.notifier).markLessonComplete(language, level, lesson.id);
        Navigator.pop(context, true);
        return;
      }
      stageIndex.value++;
      pageController.animateToPage(
        stageIndex.value,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }

    return LingAfriqScaffold(
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(36.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stage ${stageIndex.value + 1}/${_stages.length}: ${_stages[stageIndex.value]}',
                  style: TextStyle(fontSize: 12.sp, color: PanAfricanColors.primary),
                ),
                SizedBox(height: 6.h),
                LinearProgressIndicator(
                  value: (stageIndex.value + 1) / _stages.length,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(PanAfricanColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
      body: isVictory
          ? LessonCompleteWidget(
              totalXP: 100,
              accuracy: practiceScore.value,
              timeTaken: ((lesson.durationMin ?? 0) > 0 ? (lesson.durationMin ?? 12) : 12) * 60,
              onContinue: next,
            )
          : PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _stageCard(
                  isDark,
                  _stages[0],
                  LingAfriqUxVoice.lessonCompleteMessage(0.85),
                  'You are learning with real ${lesson.title} content — take your time.',
                ),
                _stageCard(
                  isDark,
                  _stages[1],
                  dialogue?.notes ?? dialogue?.culturalContext ?? lesson.title,
                  _dialogueText(dialogue),
                ),
                _vocabStage(vocab),
                _pronunciationStage(context, vocab),
                _stageCard(
                  isDark,
                  _stages[4],
                  lesson.objective ?? 'Grammar in context',
                  grammar.isEmpty
                      ? (bundled?['grammar_explanations'] as List?)?.join('\n') ?? 'Patterns from the dialogue.'
                      : grammar.join('\n'),
                ),
                LessonGuidedPracticeStage(
                  lesson: lesson,
                  language: language,
                  unitQuiz: unitQuiz,
                ),
                _aiStage(context, ref),
                _culturalStage(context, isDark, bundled, dialogue),
                LessonRetentionStage(lesson: lesson, language: language),
                const SizedBox.shrink(),
              ],
            ),
      bottomNavigationBar: isVictory
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: FilledButton(
                  onPressed: next,
                  style: FilledButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    minimumSize: Size(double.infinity, 48.h),
                  ),
                  child: Text(stageIndex.value >= _stages.length - 2 ? 'Finish lesson' : 'Continue'),
                ),
              ),
            ),
    );
  }

  Widget _stageCard(bool isDark, String title, String headline, String body) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: PanAfricanCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 12.h),
            Text(headline, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 12.h),
            Text(body, style: TextStyle(fontSize: 15.sp, height: 1.4)),
          ],
        ),
      ),
    );
  }

  String _dialogueText(CurriculumDialogue? d) {
    if (d == null) return '';
    return d.script
        .map((line) {
          final speaker = line['speaker'] ?? 'A';
          final text = line['text'] ?? '';
          final tr = line['translation'] ?? '';
          return '$speaker: $text${tr.isNotEmpty ? ' — $tr' : ''}';
        })
        .join('\n');
  }

  Widget _vocabStage(List<CurriculumVocab> vocab) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: vocab.length,
      itemBuilder: (_, i) {
        final v = vocab[i];
        return Card(
          margin: EdgeInsets.only(bottom: 10.h),
          child: ListTile(
            title: Text(v.word, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.sp)),
            subtitle: Text(v.meaning),
            trailing: VocabAudioControls(language: language, text: v.word, compact: true),
          ),
        );
      },
    );
  }

  Widget _pronunciationStage(BuildContext context, List<CurriculumVocab> vocab) {
    final word = vocab.isNotEmpty ? vocab.first.word : lesson.title;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Repeat after Polie', style: TextStyle(fontSize: 18.sp)),
            SizedBox(height: 16.h),
            Text(word, style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            VocabAudioControls(language: language, text: word),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ToneTrainerGame(
                      language: language,
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.graphic_eq),
              label: const Text('Open Tone Trainer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _culturalStage(
    BuildContext context,
    bool isDark,
    Map<String, dynamic>? bundled,
    CurriculumDialogue? dialogue,
  ) {
    final body = lesson.culturalNotes ??
        bundled?['cultural_notes']?.toString() ??
        dialogue?.culturalContext ??
        'Respect and context matter as much as words.';
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _stages[7],
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          PanAfricanCard(child: Text(body, style: TextStyle(fontSize: 15.sp, height: 1.4))),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CultureMagazineScreenEnhanced(
                    initialFilterLanguage: language,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Read in Culture Magazine'),
          ),
        ],
      ),
    );
  }

  Widget _aiStage(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Practice with Polie in character.'),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PolieWorkspaceScreen(
                      sourceLanguage: 'English',
                      targetLanguage: language,
                      initialMode: PolieMode.roleplay,
                      initialRoleplayScene: lesson.polieRoleplayPrompt ?? lesson.objective,
                      conversationOnly: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Open Polie roleplay'),
            ),
          ],
        ),
      ),
    );
  }
}
