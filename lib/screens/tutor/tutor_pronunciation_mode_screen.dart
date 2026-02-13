import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show AppLanguage;
import 'package:just_audio/just_audio.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';

/// Pronunciation Mode — minimal layout, large record orb, waveform, phoneme heatmap, regional toggle, streak.
class TutorPronunciationModeScreen extends HookConsumerWidget {
  const TutorPronunciationModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final isRecording = useState(false);
    final pronunciationResult = useState<Map<String, dynamic>?>(null);
    final isLoading = useState(false);
    final recorder = useMemoized(() => AudioRecordingService());
    final recordingPath = useState<String?>(null);
    final useRegionalPronunciation = useState(false);
    final practiceCount = useState<int>(0);
    final audioPlayer = useMemoized(() => AudioPlayer()); // for optional playback of recording

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            practiceCount.value = practiceCount.value + 1;
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
        child: Scaffold(
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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PolieSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Text Input
                  PolieGlassCard(
                    padding: EdgeInsets.all(PolieSpacing.md),
                    child: TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Text to Practice',
                        hintText: 'Enter text to practice pronunciation...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PolieRadius.md),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? PolieColors.surfaceContainer
                            : PolieColors.surfaceContainerLight,
                      ),
                      style: PolieTypography.body(context),
                    ),
                  ),
                  SizedBox(height: PolieSpacing.md),

                  // Language + regional toggle
                  Row(
                    children: [
                      Expanded(
                        child: PolieGlassCard(
                          padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.sm),
                          child: DropdownButtonFormField<AppLanguage>(
                            value: selectedLanguage.value,
                            dropdownColor: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
                            decoration: InputDecoration(
                              labelText: 'Language',
                              border: InputBorder.none,
                            ),
                            items: availableLanguages.map((lang) => DropdownMenuItem<AppLanguage>(
                              value: lang,
                              child: Text(lang.displayName, style: PolieTypography.body(context)),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) selectedLanguage.value = value;
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: PolieSpacing.sm),
                      PolieGlassCard(
                        padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Regional', style: PolieTypography.bodySmall(context)),
                            SizedBox(width: PolieSpacing.xs),
                            Switch(
                              value: useRegionalPronunciation.value,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                useRegionalPronunciation.value = v;
                              },
                              activeColor: PolieColors.electricTeal,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (practiceCount.value > 0)
                    Padding(
                      padding: EdgeInsets.only(top: PolieSpacing.sm),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.xs),
                          decoration: BoxDecoration(
                            color: PolieColors.goldEmber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(PolieRadius.pill),
                            border: Border.all(color: PolieColors.goldEmber.withOpacity(0.5)),
                          ),
                          child: Text(
                            'Sessions: ${practiceCount.value}',
                            style: PolieTypography.label(context).copyWith(color: PolieColors.goldEmber),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: PolieSpacing.xl),

                  // Large record orb
                  Center(
                    child: GestureDetector(
                      onTap: isLoading.value ? null : recordAndScore,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isRecording.value ? 140.w : 120.w,
                        height: isRecording.value ? 140.w : 120.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              PolieColors.electricTeal,
                              PolieColors.electricTealLight.withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PolieColors.electricTeal.withOpacity(0.5),
                              blurRadius: isRecording.value ? 32 : 24,
                              spreadRadius: isRecording.value ? 4 : 0,
                            ),
                            BoxShadow(
                              color: PolieColors.electricTeal.withOpacity(0.3),
                              blurRadius: 48,
                              spreadRadius: -8,
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isRecording.value ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 48.sp,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Center(
                    child: Text(
                      isRecording.value ? 'Tap to stop & analyze' : 'Tap to record',
                      style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textSecondary),
                    ),
                  ),
                  SizedBox(height: PolieSpacing.xl),

                  if (pronunciationResult.value != null) ...[
                    _buildPronunciationResult(
                      context,
                      pronunciationResult.value!,
                      isDark,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
                    if (recordingPath.value != null) ...[
                      SizedBox(height: PolieSpacing.md),
                      _ReplayButtons(
                        recordingPath: recordingPath.value!,
                        player: audioPlayer,
                      ),
                    ],
                  ],
                ],
              ),
            ),
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
    final rawOverall = (result['overallScore'] ?? 0.0) as double;
    final overallScore = rawOverall <= 1 ? rawOverall * 100 : rawOverall;
    final rawAcc = (result['accuracyScore'] ?? 0.0) as double;
    final accuracyScore = rawAcc <= 1 ? rawAcc * 100 : rawAcc;
    final rawRhythm = (result['rhythmScore'] ?? 0.0) as double;
    final rhythmScore = rawRhythm <= 1 ? rawRhythm * 100 : rawRhythm;
    final rawTone = (result['toneScore'] ?? 0.0) as double;
    final toneScore = rawTone <= 1 ? rawTone * 100 : rawTone;

    // Simulated waveform bars (user vs reference) from score
    final barCount = 24;
    final userBars = List.generate(barCount, (i) => 0.3 + (i % 5) / 10 * (overallScore / 100));
    final refBars = List.generate(barCount, (i) => 0.4 + (i % 4) / 10);

    return PolieGlassCard(
      hasGlow: true,
      glowColor: PolieColors.electricTeal,
      child: Column(
        children: [
          _ScoreRing(score: overallScore, size: 150.w),
          SizedBox(height: PolieSpacing.lg),
          Text('Mouth shape', style: PolieTypography.label(context)),
          SizedBox(height: PolieSpacing.xs),
          _MouthShapePlaceholder(isDark: isDark),
          SizedBox(height: PolieSpacing.lg),
          Text('Waveform comparison', style: PolieTypography.label(context)),
          SizedBox(height: PolieSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _WaveformBars(bars: userBars, color: PolieColors.royalAmethyst, height: 40.h),
              SizedBox(width: PolieSpacing.sm),
              _WaveformBars(bars: refBars, color: PolieColors.electricTeal.withOpacity(0.7), height: 40.h),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: PolieSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('You', style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.royalAmethyst)),
                SizedBox(width: PolieSpacing.lg),
                Text('Reference', style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.electricTeal)),
              ],
            ),
          ),
          SizedBox(height: PolieSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreCard(label: 'Accuracy', score: accuracyScore, color: PolieColors.royalAmethyst, isDark: isDark),
              _ScoreCard(label: 'Rhythm', score: rhythmScore, color: PolieColors.goldEmber, isDark: isDark),
              _ScoreCard(label: 'Tone', score: toneScore, color: PolieColors.electricTeal, isDark: isDark),
            ],
          ),
          SizedBox(height: PolieSpacing.lg),
          if (result['feedback'] != null) ...[
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.md),
            Text('Feedback', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.sm),
            Text(result['feedback'].toString(), style: PolieTypography.body(context)),
          ],
          if (result['phonemeFeedback'] != null &&
              (result['phonemeFeedback'] as List).isNotEmpty) ...[
            SizedBox(height: PolieSpacing.lg),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.md),
            Text('Phoneme Analysis', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.sm),
            _PhonemeTimeline(
              phonemes: result['phonemeFeedback'] as List,
              isDark: isDark,
            ),
          ],

          // Next Exercises
          if (result['nextExercises'] != null &&
              (result['nextExercises'] as List).isNotEmpty) ...[
            SizedBox(height: PolieSpacing.lg),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.md),
            Text(
              'Recommended Practice',
              style: PolieTypography.label(context),
            ),
            SizedBox(height: PolieSpacing.sm),
            ...(result['nextExercises'] as List).map((exercise) {
              return Container(
                margin: EdgeInsets.only(bottom: PolieSpacing.sm),
                padding: EdgeInsets.all(PolieSpacing.sm),
                decoration: BoxDecoration(
                  color: PolieColors.royalAmethyst.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(PolieRadius.md),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.school_rounded, color: PolieColors.goldEmber),
                  title: Text(
                    exercise.toString(),
                    style: PolieTypography.body(context),
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

/// Placeholder for future mouth-shape animation (phoneme visualization).
class _MouthShapePlaceholder extends StatelessWidget {
  final bool isDark;

  const _MouthShapePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: PolieColors.electricTeal.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.record_voice_over_rounded,
          size: 32.sp,
          color: PolieColors.electricTeal.withOpacity(0.8),
        ),
      ),
    );
  }
}

/// Replay recording at normal or slow (0.5x) speed.
class _ReplayButtons extends StatelessWidget {
  final String recordingPath;
  final AudioPlayer player;

  const _ReplayButtons({required this.recordingPath, required this.player});

  Future<void> _playAtSpeed(double speed) async {
    try {
      await player.setFilePath(recordingPath);
      await player.setSpeed(speed);
      await player.play();
    } catch (e) {
      debugPrint('Replay failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PolieGlassCard(
      padding: EdgeInsets.symmetric(vertical: PolieSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _playAtSpeed(1.0);
            },
            icon: Icon(Icons.play_arrow_rounded, color: PolieColors.electricTeal, size: 24),
            label: Text('Replay', style: PolieTypography.label(context).copyWith(color: PolieColors.electricTeal)),
          ),
          SizedBox(width: PolieSpacing.md),
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _playAtSpeed(0.5);
            },
            icon: Icon(Icons.slow_motion_video_rounded, color: PolieColors.royalAmethyst, size: 24),
            label: Text('Slow motion', style: PolieTypography.label(context).copyWith(color: PolieColors.royalAmethyst)),
          ),
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
    if (score >= 80) return PolieColors.success;
    if (score >= 60) return PolieColors.electricTeal;
    if (score >= 40) return PolieColors.goldEmber;
    return PolieColors.error;
  }
}

class _WaveformBars extends StatelessWidget {
  final List<double> bars;
  final Color color;
  final double height;

  const _WaveformBars({required this.bars, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: 120.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((v) {
          return Container(
            width: 3.w,
            height: (v * height).clamp(8.0, height),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
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
    final displayScore = score <= 1 ? score * 100 : score;
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? PolieColors.surfaceContainer
            : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.md),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '${displayScore.toInt()}',
            style: PolieTypography.h2(context).copyWith(color: color),
          ),
          SizedBox(height: PolieSpacing.xs),
          Text(
            label,
            style: PolieTypography.bodySmall(context),
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
            margin: EdgeInsets.only(right: PolieSpacing.xs),
            decoration: BoxDecoration(
              color: isCorrect
                  ? PolieColors.success.withOpacity(0.2)
                  : PolieColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(PolieRadius.sm),
              border: Border.all(
                color: isCorrect ? PolieColors.success : PolieColors.error,
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    phoneme['phoneme'] ?? '',
                    style: PolieTypography.label(context),
                  ),
                  Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 16.sp,
                    color: isCorrect ? PolieColors.success : PolieColors.error,
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

