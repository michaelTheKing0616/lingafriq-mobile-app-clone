import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;

/// Pronunciation Trainer with Waveform, Phoneme Timeline, Score Ring, Feedback
class TutorPronunciationModeScreen extends HookConsumerWidget {
  const TutorPronunciationModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final isRecording = useState(false);
    final isPlaying = useState(false);
    final pronunciationResult = useState<Map<String, dynamic>?>(null);
    final isLoading = useState(false);
    final audioPlayer = useMemoized(() => AudioPlayer());
    final localizationService = useMemoized(() => DynamicLocalizationService());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Load available languages dynamically
    final availableLanguages = AppLanguage.values;

    Future<void> recordAndScore() async {
      if (textController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter text to practice')),
        );
        return;
      }

      isRecording.value = true;
      isLoading.value = true;
      
      // Simulate recording - in production, use actual audio recording
      await Future.delayed(const Duration(seconds: 2));
      isRecording.value = false;

      try {
        final response = await ApiService.post(
          AppConfig.tutorPronounce,
          data: {
            'text': textController.text,
            'language': selectedLanguage.value.name,
            'audioUrl': 'recorded_audio_url', // In production, upload audio first
          },
        );

        if (response.statusCode == 200) {
          pronunciationResult.value = response.data['data'] ?? response.data;
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
          ),
        );
      } finally {
        isRecording.value = false;
        isLoading.value = false;
      }
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Analyzing pronunciation...',
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text Input
            TextField(
              controller: textController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Text to Practice',
                hintText: 'Enter text to practice pronunciation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                filled: true,
                fillColor: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
              ),
              style: PanAfricanTypography.bodyLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),

            // Language Selector - Dynamic
            FutureBuilder<List<AppLanguage>>(
              future: Future.value(availableLanguages),
              builder: (context, snapshot) {
                return DropdownButtonFormField<AppLanguage>(
                  value: selectedLanguage.value,
                  decoration: InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  items: availableLanguages.map((lang) => DropdownMenuItem<AppLanguage>(
                    value: lang,
                    child: Text(
                      lang.name.substring(0, 1).toUpperCase() + lang.name.substring(1),
                    ),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) selectedLanguage.value = value;
                  },
                );
              },
            ),
            SizedBox(height: PanAfricanSpacing.lg),

            // Record Button
            ElevatedButton.icon(
              onPressed: isRecording.value ? null : recordAndScore,
              icon: isRecording.value
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.mic),
              label: Text(
                isRecording.value ? 'Recording...' : 'Record & Score',
                style: PanAfricanTypography.labelLarge(context)
                    .copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.tertiary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xl),

            // Pronunciation Result
            if (pronunciationResult.value != null)
              _buildPronunciationResult(
                context,
                pronunciationResult.value!,
                isDark,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
    );
  }

  Widget _buildPronunciationResult(
    BuildContext context,
    Map<String, dynamic> result,
    bool isDark,
  ) {
    final overallScore = (result['overallScore'] ?? 0.0) as double;
    final accuracyScore = (result['accuracyScore'] ?? 0.0) as double;
    final rhythmScore = (result['rhythmScore'] ?? 0.0) as double;
    final toneScore = (result['toneScore'] ?? 0.0) as double;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        children: [
          // Score Ring
          _ScoreRing(
            score: overallScore,
            size: 150.w,
          ),
          SizedBox(height: PanAfricanSpacing.lg),

          // Detailed Scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreCard(
                label: 'Accuracy',
                score: accuracyScore,
                color: PanAfricanColors.primary,
                isDark: isDark,
              ),
              _ScoreCard(
                label: 'Rhythm',
                score: rhythmScore,
                color: PanAfricanColors.secondary,
                isDark: isDark,
              ),
              _ScoreCard(
                label: 'Tone',
                score: toneScore,
                color: PanAfricanColors.tertiary,
                isDark: isDark,
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.lg),

          // Feedback
          if (result['feedback'] != null) ...[
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Feedback',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              result['feedback'],
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ],

          // Phoneme Feedback
          if (result['phonemeFeedback'] != null &&
              (result['phonemeFeedback'] as List).isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Phoneme Analysis',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            _PhonemeTimeline(
              phonemes: result['phonemeFeedback'] as List,
              isDark: isDark,
            ),
          ],

          // Next Exercises
          if (result['nextExercises'] != null &&
              (result['nextExercises'] as List).isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Recommended Practice',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['nextExercises'] as List).map((exercise) {
              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                child: ListTile(
                  leading: Icon(Icons.school, color: PanAfricanColors.primary),
                  title: Text(
                    exercise,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final double score;
  final double size;

  const _ScoreRing({
    required this.score,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 12,
              backgroundColor: PanAfricanColors.neutralLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getScoreColor(score),
              ),
            ),
          ),
          // Score text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${score.toInt()}',
                style: PanAfricanTypography.displayMedium(context)
                    .copyWith(color: _getScoreColor(score)),
              ),
              Text(
                'Score',
                style: PanAfricanTypography.bodySmall(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return PanAfricanColors.success;
    if (score >= 60) return PanAfricanColors.secondary;
    if (score >= 40) return PanAfricanColors.warning;
    return PanAfricanColors.error;
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final bool isDark;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      ),
      child: Column(
        children: [
          Text(
            '${score.toInt()}',
            style: PanAfricanTypography.headlineSmall(context)
                .copyWith(color: color),
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Text(
            label,
            style: PanAfricanTypography.bodySmall(context),
          ),
        ],
      ),
    );
  }
}

class _PhonemeTimeline extends StatelessWidget {
  final List phonemes;
  final bool isDark;

  const _PhonemeTimeline({
    required this.phonemes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: phonemes.length,
        itemBuilder: (context, index) {
          final phoneme = phonemes[index] as Map<String, dynamic>;
          final isCorrect = phoneme['correct'] ?? true;
          
          return Container(
            width: 50.w,
            margin: EdgeInsets.only(right: PanAfricanSpacing.xs),
            decoration: BoxDecoration(
              color: isCorrect
                  ? PanAfricanColors.success.withOpacity(0.2)
                  : PanAfricanColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
              border: Border.all(
                color: isCorrect ? PanAfricanColors.success : PanAfricanColors.error,
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    phoneme['phoneme'] ?? '',
                    style: PanAfricanTypography.labelMedium(context),
                  ),
                  Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 16.sp,
                    color: isCorrect ? PanAfricanColors.success : PanAfricanColors.error,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

