import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/tts_provider.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/widgets/gamification/combo_tracker.dart';
import 'package:lingafriq/widgets/gamification/combo_display_widget.dart';
import 'package:lingafriq/services/sound_effects_service.dart';
import 'package:lingafriq/providers/gamification_provider.dart';

class ListeningQuizScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> passageData;

  const ListeningQuizScreen({Key? key, required this.passageData})
      : super(key: key);

  @override
  ConsumerState<ListeningQuizScreen> createState() =>
      _ListeningQuizScreenState();
}

class _ListeningQuizScreenState extends ConsumerState<ListeningQuizScreen> {
  bool _hasListened = false;
  final Map<int, String?> _selectedAnswers = {};
  final Map<int, TextEditingController> _textControllers = {};
  late final ComboTracker _comboTracker;

  @override
  void initState() {
    super.initState();
    _comboTracker = ComboTracker();
  }
  
  @override
  void dispose() {
    _comboTracker.dispose();
    ref.read(ttsProvider.notifier).stop();
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }


  Future<void> _playPassage() async {
    await safeAsync(
      context: context,
      operation: () async {
        final passage = widget.passageData['passage'] as String? ?? '';
        final languageName = (widget.passageData['language'] as String?) ?? 'english';
        await ref.read(ttsProvider.notifier).speak(
              passage,
              languageName: languageName,
            );
        if (mounted) {
          setState(() {
            _hasListened = true;
          });
        }
      },
      errorContext: 'playPassage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = (widget.passageData['questions'] as List?) ?? [];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(PanAfricanIcons.back, color: PolieColors.textPrimary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Listening Comprehension',
                        style: PolieTypography.h2(context).copyWith(color: PolieColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Play passage card
                      PolieGlassCard(
                        hasGlow: true,
                        glowColor: PolieColors.electricTeal,
                        padding: EdgeInsets.all(PolieSpacing.lg),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _playPassage();
                              },
                              child: Container(
                                width: 80.w,
                                height: 80.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [PolieColors.electricTeal, PolieColors.electricTealLight],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PolieColors.electricTeal.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  size: 48.sp,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            SizedBox(height: PolieSpacing.md),
                            Text(
                              _hasListened
                                  ? 'Tap to replay'
                                  : 'Tap to listen to the passage',
                              style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: PolieSpacing.lg),
                      ...questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final q = entry.value as Map<String, dynamic>;
                        return Padding(
                          padding: EdgeInsets.only(bottom: PolieSpacing.md),
                          child: _buildQuestionCard(q, index),
                        );
                      }),
                      SizedBox(height: PolieSpacing.md),
                      Semantics(
                        label: 'Submit quiz answers',
                        button: true,
                        child: PoliePrimaryButton(
                          label: 'Submit Answers',
                          icon: Icons.check_circle_rounded,
                          enabled: _hasListened,
                          onPressed: _hasListened ? _submitAnswers : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
            // Combo display widget
            ComboDisplayWidget(comboTracker: _comboTracker),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, int index) {
    final type = q['type'] as String? ?? 'open';
    final question = q['question'] as String? ?? '';

    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}: $question',
            style: PolieTypography.label(context).copyWith(color: PolieColors.textPrimary),
          ),
          SizedBox(height: PolieSpacing.md),
          if (type == 'mcq') ...[
            ...((q['options'] as List?) ?? []).asMap().entries.map((opt) {
              final optText = opt.value as String;
              final isSelected = _selectedAnswers[index] == optText;
              return Padding(
                padding: EdgeInsets.only(bottom: PolieSpacing.xs),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedAnswers[index] = optText;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? PolieColors.royalAmethyst.withOpacity(0.25) : PolieColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                      border: Border.all(
                        color: isSelected ? PolieColors.royalAmethyst : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? PolieColors.royalAmethyst : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? PolieColors.royalAmethyst : PolieColors.textSecondary,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 14.sp, color: Theme.of(context).colorScheme.onPrimary)
                              : null,
                        ),
                        SizedBox(width: PolieSpacing.sm),
                        Expanded(
                          child: Text(
                            optText,
                            style: PolieTypography.body(context).copyWith(
                              color: isSelected ? PolieColors.textPrimary : PolieColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            Builder(
              builder: (context) {
                if (!_textControllers.containsKey(index)) {
                  _textControllers[index] = TextEditingController();
                }
                return TextField(
                  controller: _textControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Your answer',
                    labelStyle: PolieTypography.label(context).copyWith(color: PolieColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                      borderSide: BorderSide(color: PolieColors.textSecondary.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                      borderSide: BorderSide(color: PolieColors.textSecondary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                      borderSide: BorderSide(color: PolieColors.royalAmethyst),
                    ),
                    filled: true,
                    fillColor: PolieColors.surfaceContainer,
                  ),
                  style: PolieTypography.body(context),
                  onChanged: (value) {
                    _selectedAnswers[index] = value;
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitAnswers() async {
    await safeAsync(
      context: context,
      operation: () async {
        // Evaluate answers and show results
        // This would call the provider's evaluateOpenAnswer method
        final questions = (widget.passageData['questions'] as List?) ?? [];
        int correctCount = 0;
        
        for (var i = 0; i < questions.length; i++) {
          final q = questions[i] as Map<String, dynamic>;
          final correctAnswer = q['answer'] as String?;
          final userAnswer = _selectedAnswers[i] ?? '';
          
          if (correctAnswer != null && 
              userAnswer.toLowerCase().trim() == correctAnswer.toLowerCase().trim()) {
            correctCount++;
            _comboTracker.recordCorrect();
          } else {
            _comboTracker.recordIncorrect();
          }
        }
        
        // Award XP with combo multiplier
        final multiplier = _comboTracker.currentMultiplier;
        await ref.read(gamificationProvider.notifier).awardXP(
          'listening_quiz_complete',
          multiplier: multiplier,
          sourceId: 'listening_quiz_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final soundEffects = ref.read(soundEffectsProvider);
        if (correctCount == questions.length) {
          soundEffects.playCelebration();
        } else {
          soundEffects.playCorrect();
        }
        _comboTracker.reset();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Answers submitted! Score: $correctCount/${questions.length}'),
            ),
          );
        }
      },
      errorContext: 'submitAnswers',
    );
  }
}

