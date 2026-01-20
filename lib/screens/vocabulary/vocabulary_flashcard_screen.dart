import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Visual Flashcard Screen for Vocabulary
/// Interactive flashcards with swipe gestures, animations, and progress tracking
class VocabularyFlashcardScreen extends HookConsumerWidget {
  final String language;
  final String languageName;
  final String? category;

  const VocabularyFlashcardScreen({
    Key? key,
    required this.language,
    required this.languageName,
    this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabService = ref.read(vocabularyProgressServiceProvider);
    final words = useState<List<WordMastery>>([]);
    final currentIndex = useState(0);
    final isFlipped = useState(false);
    final showAnswer = useState(false);
    final isLoading = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final swipeController = useAnimationController();

    // Load words
    useEffect(() {
      _loadWords(vocabService, words, isLoading);
      return null;
    }, []);

    if (isLoading.value) {
      return Scaffold(
        appBar: AppBar(title: Text('Flashcards')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (words.value.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Flashcards')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64.sp, color: PanAfricanColors.neutralMedium),
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                'No words available',
                style: PanAfricanTypography.bodyLarge(context),
              ),
            ],
          ),
        ),
      );
    }

    final currentWord = words.value[currentIndex.value];
    final progress = (currentIndex.value + 1) / words.value.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show category filter
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${currentIndex.value + 1} / ${words.value.length}',
                          style: PanAfricanTypography.bodyMedium(context),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: PanAfricanTypography.bodyMedium(context),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: PanAfricanColors.neutralLight,
                      valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                      minHeight: 4.h,
                    ),
                  ],
                ),
              ),

              // Flashcard
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    isFlipped.value = !isFlipped.value;
                    showAnswer.value = !showAnswer.value;
                    HapticFeedback.lightImpact();
                  },
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: _Flashcard(
                        key: ValueKey('${currentWord.word}_${currentWord.language}'),
                        word: currentWord,
                        isFlipped: isFlipped.value,
                        showAnswer: showAnswer.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Incorrect
                    _ActionButton(
                      icon: Icons.close,
                      label: 'Incorrect',
                      color: PanAfricanColors.error,
                      onPressed: () {
                        _handleAnswer(vocabService, currentWord, false);
                        _nextCard(currentIndex, words.value.length, isFlipped, showAnswer);
                      },
                    ),
                    // Flip
                    _ActionButton(
                      icon: Icons.flip,
                      label: 'Flip',
                      color: PanAfricanColors.primary,
                      onPressed: () {
                        isFlipped.value = !isFlipped.value;
                        showAnswer.value = !showAnswer.value;
                        HapticFeedback.mediumImpact();
                      },
                    ),
                    // Correct
                    _ActionButton(
                      icon: Icons.check,
                      label: 'Correct',
                      color: PanAfricanColors.success,
                      onPressed: () {
                        _handleAnswer(vocabService, currentWord, true);
                        _nextCard(currentIndex, words.value.length, isFlipped, showAnswer);
                      },
                    ),
                  ],
                ),
              ),

              // Navigation
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous),
                      onPressed: currentIndex.value > 0
                          ? () {
                              currentIndex.value--;
                              isFlipped.value = false;
                              showAnswer.value = false;
                            }
                          : null,
                    ),
                    SizedBox(width: PanAfricanSpacing.lg),
                    Text(
                      'Swipe or tap to flip',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                    SizedBox(width: PanAfricanSpacing.lg),
                    IconButton(
                      icon: Icon(Icons.skip_next),
                      onPressed: currentIndex.value < words.value.length - 1
                          ? () {
                              currentIndex.value++;
                              isFlipped.value = false;
                              showAnswer.value = false;
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadWords(
    VocabularyProgressService service,
    ValueNotifier<List<WordMastery>> words,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      final progress = await service.loadProgress(languageName);
      final allWords = progress.words.values.toList();
      words.value = category != null
          ? allWords.where((w) => w.category == category).toList()
          : allWords;
    } catch (e) {
      StructuredLogger().error('Error loading vocabulary words', error: e, context: {'language': language, 'category': category});
    } finally {
      isLoading.value = false;
    }
  }

  void _handleAnswer(
    VocabularyProgressService service,
    WordMastery word,
    bool isCorrect,
  ) async {
    try {
      await service.recordReview(word.word, word.language, isCorrect);
      HapticFeedback.mediumImpact();
    } catch (e) {
      StructuredLogger().error('Error recording vocabulary review', error: e, context: {'word': word.word, 'language': word.language, 'isCorrect': isCorrect});
    }
  }

  void _nextCard(
    ValueNotifier<int> currentIndex,
    int totalWords,
    ValueNotifier<bool> isFlipped,
    ValueNotifier<bool> showAnswer,
  ) {
    if (currentIndex.value < totalWords - 1) {
      currentIndex.value++;
      isFlipped.value = false;
      showAnswer.value = false;
    } else {
      // Completed all cards
      // Could show completion screen
    }
  }

  String _getWordMeaning(WordMastery word) {
    if (word.metadata != null && word.metadata!['meaning'] != null) {
      return word.metadata!['meaning'] as String;
    }
    if (word.metadata != null && word.metadata!['translation'] != null) {
      return word.metadata!['translation'] as String;
    }
    return 'Meaning not available';
  }

  String? _getWordExample(WordMastery word) {
    if (word.metadata != null) {
      if (word.metadata!['example'] != null) {
        return word.metadata!['example'] as String;
      }
      if (word.metadata!['exampleSentence'] != null) {
        return word.metadata!['exampleSentence'] as String;
      }
      if (word.metadata!['examples'] != null && 
          (word.metadata!['examples'] as List).isNotEmpty) {
        return (word.metadata!['examples'] as List).first as String;
      }
    }
    return null;
  }

  String? _getWordPronunciation(WordMastery word) {
    if (word.metadata != null && word.metadata!['pronunciation'] != null) {
      return word.metadata!['pronunciation'] as String;
    }
    return null;
  }
}

class _Flashcard extends StatelessWidget {
  final WordMastery word;
  final bool isFlipped;
  final bool showAnswer;
  final bool isDark;

  const _Flashcard({
    Key? key,
    required this.word,
    required this.isFlipped,
    required this.showAnswer,
    required this.isDark,
  }) : super(key: key);

  String _getWordMeaning(WordMastery word) {
    // Try to get meaning from metadata
    if (word.metadata != null && word.metadata!['meaning'] != null) {
      return word.metadata!['meaning'] as String;
    }
    if (word.metadata != null && word.metadata!['translation'] != null) {
      return word.metadata!['translation'] as String;
    }
    return 'Meaning not available';
  }

  String? _getWordExample(WordMastery word) {
    // Try to get example from metadata
    if (word.metadata != null && word.metadata!['example'] != null) {
      return word.metadata!['example'] as String;
    }
    return null;
  }

  String? _getWordPronunciation(WordMastery word) {
    // Try to get pronunciation from metadata
    if (word.metadata != null && word.metadata!['pronunciation'] != null) {
      return word.metadata!['pronunciation'] as String;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        ),
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Badge
              if (word.category.isNotEmpty)
                Chip(
                  label: Text(word.category),
                  backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                  labelStyle: PanAfricanTypography.labelSmall(context)?.copyWith(
                    color: PanAfricanColors.primary,
                  ),
                ),
              SizedBox(height: PanAfricanSpacing.lg),

              // Word or Translation
              if (!showAnswer) ...[
                // Show word
                Text(
                  word.word,
                  style: PanAfricanTypography.displayMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PanAfricanColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  'Tap to reveal translation',
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ] else ...[
                // Show meaning/translation from metadata or service
                Text(
                  _getWordMeaning(word),
                  style: PanAfricanTypography.displaySmall(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PanAfricanColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_getWordExample(word) != null) ...[
                  SizedBox(height: PanAfricanSpacing.lg),
                  Divider(),
                  SizedBox(height: PanAfricanSpacing.md),
                  Text(
                    _getWordExample(word)!,
                    textAlign: TextAlign.center,
                    style: PanAfricanTypography.bodyMedium(context)?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (_getWordPronunciation(word) != null) ...[
                  SizedBox(height: PanAfricanSpacing.md),
                  Text(
                    _getWordPronunciation(word)!,
                    style: PanAfricanTypography.bodySmall(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],

              SizedBox(height: PanAfricanSpacing.xl),

              // Mastery Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(5, (index) {
                    final filled = (word.masteryLevel * 5).round() > index;
                    return Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: PanAfricanColors.accent,
                      size: 20.sp,
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: Offset(0.9, 0.9));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          label,
          style: PanAfricanTypography.labelSmall(context),
        ),
      ],
    );
  }
}

