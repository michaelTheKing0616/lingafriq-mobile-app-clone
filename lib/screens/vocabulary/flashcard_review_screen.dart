import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/offline/local_vocabulary.dart';
import '../../services/offline/vocabulary_store.dart';
import '../../utils/pan_african_design_system.dart';
import 'package:lingafriq/screens/media/media_clip_player_screen.dart';

class FlashcardReviewScreen extends ConsumerStatefulWidget {
  final List<LocalVocabulary> words;
  final String language;

  const FlashcardReviewScreen({
    super.key,
    required this.words,
    required this.language,
  });

  @override
  ConsumerState<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen> {
  final VocabularyStore _vocabStore = VocabularyStore();
  int _currentIndex = 0;
  bool _isFlipped = false;
  int _correctCount = 0;
  int _incorrectCount = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.words.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        appBar: AppBar(
          title: Text('Review Due Words', style: PanAfricanTypography.titleLarge(context)),
          backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64.sp,
                color: PanAfricanColors.success,
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              Text(
                'No words due for review!',
                style: PanAfricanTypography.headlineSmall(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                'Great job keeping up with your reviews.',
                style: PanAfricanTypography.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currentWord = widget.words[_currentIndex];
    final progress = (_currentIndex + 1) / widget.words.length;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Review Due Words', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        leading: IconButton(
          icon: Icon(PanAfricanIcons.back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${widget.words.length}',
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                    Text(
                      'Correct: $_correctCount | Incorrect: $_incorrectCount',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                    valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                  ),
                ),
              ],
            ),
          ),
          
          // Flashcard
          Expanded(
            child: Center(
              child: Semantics(
                label: _isFlipped ? '${currentWord.word}: ${currentWord.translation}. Tap to flip back.' : '${currentWord.word}. Tap to reveal translation.',
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isFlipped = !_isFlipped);
                  },
                  child: Container(
                  margin: EdgeInsets.all(PanAfricanSpacing.lg),
                  width: double.infinity,
                  height: 300.h,
                  decoration: BoxDecoration(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
                    boxShadow: PanAfricanShadows.lg,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.xl),
                      child: _isFlipped
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentWord.translation,
                                  style: PanAfricanTypography.headlineMedium(context),
                                  textAlign: TextAlign.center,
                                ),
                                if (currentWord.pronunciation != null) ...[
                                  SizedBox(height: PanAfricanSpacing.md),
                                  Text(
                                    currentWord.pronunciation!,
                                    style: PanAfricanTypography.bodyLarge(context).copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: PanAfricanColors.textSecondaryLight,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (currentWord.exampleSentence != null) ...[
                                  SizedBox(height: PanAfricanSpacing.lg),
                                  Text(
                                    currentWord.exampleSentence!,
                                    style: PanAfricanTypography.bodyMedium(context),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (currentWord.sourceMediaId != null &&
                                    currentWord.sourceMediaId!.isNotEmpty) ...[
                                  SizedBox(height: PanAfricanSpacing.md),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => MediaClipPlayerScreen(
                                            mediaId: currentWord.sourceMediaId!,
                                            title: currentWord.word,
                                            startMs: currentWord.sourceStartMs,
                                            endMs: currentWord.sourceEndMs,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.play_circle_rounded),
                                    label: const Text('Play source clip'),
                                  ),
                                ],
                                SizedBox(height: PanAfricanSpacing.md),
                                Text(
                                  'Tap to see word',
                                  style: PanAfricanTypography.bodySmall(context).copyWith(
                                    color: PanAfricanColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentWord.word,
                                  style: PanAfricanTypography.headlineLarge(context),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: PanAfricanSpacing.md),
                                Text(
                                  'Tap to reveal translation',
                                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                                    color: PanAfricanColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              ),
            ),
          ),
          
          // Rating buttons
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: _isFlipped
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRatingButton(
                        context,
                        'Again',
                        0,
                        Colors.red,
                        isDark,
                      ),
                      _buildRatingButton(
                        context,
                        'Hard',
                        1,
                        Colors.orange,
                        isDark,
                      ),
                      _buildRatingButton(
                        context,
                        'Good',
                        3,
                        Colors.blue,
                        isDark,
                      ),
                      _buildRatingButton(
                        context,
                        'Easy',
                        5,
                        Colors.green,
                        isDark,
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'Tap the card to reveal the answer',
                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                        color: PanAfricanColors.textSecondaryLight,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton(
    BuildContext context,
    String label,
    int quality,
    Color color,
    bool isDark,
  ) {
    return Semantics(
      label: 'Rate as $label and go to next card',
      button: true,
      child: ElevatedButton(
        onPressed: () async {
        HapticFeedback.mediumImpact();
        final currentWord = widget.words[_currentIndex];
        
        try {
          await _vocabStore.reviewWord(currentWord.id, quality);
          
          if (quality >= 3) {
            setState(() => _correctCount++);
          } else {
            setState(() => _incorrectCount++);
          }
          
          if (_currentIndex < widget.words.length - 1) {
            setState(() {
              _currentIndex++;
              _isFlipped = false;
            });
          } else {
            // Review complete
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Review complete! Correct: $_correctCount, Incorrect: $_incorrectCount'),
                  backgroundColor: PanAfricanColors.success,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error reviewing word: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        ),
      ),
      child: Text(
        label,
        style: PanAfricanTypography.labelMedium(context).copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    );
  }
}
