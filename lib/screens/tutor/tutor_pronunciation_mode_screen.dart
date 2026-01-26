import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';

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
    final recorder = useMemoized(() => AudioRecordingService());
    final recordingPath = useState<String?>(null);

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

      try {
        // Tap-to-record behavior:
        // - First tap: start recording
        // - Second tap: stop recording and analyze
        if (!isRecording.value) {
          final path = await recorder.startRecording(sampleRate: 16000, numChannels: 1);
          if (path == null) {
            throw Exception('Microphone permission denied or recorder unavailable.');
          }
          recordingPath.value = path;
          isRecording.value = true;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recording... tap again to stop & analyze')),
            );
          }
          return;
        }

        // Stop recording
        final path = await recorder.stopRecording();
        isRecording.value = false;
        if (path == null) {
          throw Exception('Failed to stop recording.');
        }
        recordingPath.value = path;

        isLoading.value = true;

        // Primary: backend pronunciation analysis (world-class when backend is available).
        try {
          final resp = await ApiService.uploadFile(
            '/api/pronunciation/advanced/analyze',
            path,
            fileFieldName: 'audio',
            additionalData: {
              'expected_text': textController.text.trim(),
              'language': selectedLanguage.value.name,
              'include_phoneme_details': 'true',
              'include_tone_analysis': 'true',
              'include_fluency_metrics': 'true',
            },
          );

          if (resp.statusCode == 200) {
            pronunciationResult.value = (resp.data is Map) ? (resp.data['data'] ?? resp.data) : resp.data;
            return;
          }
        } catch (_) {
          // Fall through to local AI fallback.
        }

        // Fallback: local AI-based scoring via Groq Whisper + WER.
        final bytes = await recorder.getRecordingBytes(path);
        if (bytes == null || bytes.isEmpty) {
          throw Exception('Failed to read recorded audio.');
        }

        final groq = ref.read(groqChatProvider.notifier);
        final eval = await groq.shadowingExercise(bytes, textController.text.trim());
        final score = (eval['score'] as num?)?.toDouble() ?? 0.0;
        final pron = (eval['pronunciationScore'] as num?)?.toDouble() ?? 0.0;
        final wer = (eval['wer'] as num?)?.toDouble() ?? 1.0;

        pronunciationResult.value = {
          'overallScore': score,
          'accuracyScore': (1.0 - wer).clamp(0.0, 1.0),
          'rhythmScore': (score * 0.9).clamp(0.0, 1.0),
          'toneScore': (pron).clamp(0.0, 1.0),
          'feedback': groq.pronunciationFeedback(score),
          'transcription': eval['userText'],
          'corrections': eval['corrections'] ?? [],
        };
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
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
              onPressed: isLoading.value ? null : recordAndScore,
              icon: isRecording.value ? const Icon(Icons.stop) : const Icon(Icons.mic),
              label: Text(
                isRecording.value ? 'Stop & Analyze' : 'Record',
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
      ),
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

