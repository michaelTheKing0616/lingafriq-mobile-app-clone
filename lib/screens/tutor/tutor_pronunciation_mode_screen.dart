import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show AppLanguage;
import 'package:just_audio/just_audio.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';

/// Pronunciation Mode — minimal layout, large record orb, waveform, phoneme heatmap, regional toggle, streak.
class TutorPronunciationModeScreen extends HookConsumerWidget {
  const TutorPronunciationModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final isRecording = useState(false);
    final recorder = useMemoized(() => AudioRecordingService());
    final recordingPath = useState<String?>(null);
    final useRegionalPronunciation = useState(false);
    final audioPlayer = useMemoized(() => AudioPlayer());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableLanguages = AppLanguage.values;

    Future<void> recordPractice() async {
      if (textController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter text to practice')),
        );
        return;
      }

      try {
        if (!isRecording.value) {
          final path = await recorder.startRecording(sampleRate: 16000, numChannels: 1);
          if (path == null) {
            throw Exception('Microphone permission denied or recorder unavailable.');
          }
          recordingPath.value = path;
          isRecording.value = true;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recording... tap again to stop')),
            );
          }
          return;
        }

        final path = await recorder.stopRecording();
        isRecording.value = false;
        if (path == null) {
          throw Exception('Failed to stop recording.');
        }
        recordingPath.value = path;
      } catch (e) {
        isRecording.value = false;
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }

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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PolieSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PronPracticeBanner(),
                  SizedBox(height: PolieSpacing.md),
                  PolieGlassCard(
                    padding: EdgeInsets.all(PolieSpacing.md),
                    child: Semantics(
                      label: 'Text to practice pronunciation',
                      textField: true,
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
                  SizedBox(height: PolieSpacing.xl),

                  Center(
                    child: Semantics(
                      label: isRecording.value ? 'Tap to stop recording' : 'Tap to start recording',
                      button: true,
                      child: GestureDetector(
                        onTap: recordPractice,
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
                          semanticLabel: isRecording.value ? 'Stop' : 'Record',
                        ),
                      ),
                    ),
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Center(
                    child: Text(
                      isRecording.value ? 'Tap to stop' : 'Tap to record',
                      style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textSecondary),
                    ),
                  ),
                  if (recordingPath.value != null && !isRecording.value) ...[
                    SizedBox(height: PolieSpacing.md),
                    _ReplayButtons(
                      recordingPath: recordingPath.value!,
                      player: audioPlayer,
                    ),
                  ],
                ],
              ),
            ),
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

  Future<void> _playAtSpeed(BuildContext context, double speed) async {
    try {
      await player.setFilePath(recordingPath);
      await player.setSpeed(speed);
      await player.play();
    } catch (e) {
      ErrorHandler.showError(context, e);
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
              _playAtSpeed(context, 1.0);
            },
            icon: Icon(Icons.play_arrow_rounded, color: PolieColors.electricTeal, size: 24),
            label: Text('Replay', style: PolieTypography.label(context).copyWith(color: PolieColors.electricTeal)),
          ),
          SizedBox(width: PolieSpacing.md),
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _playAtSpeed(context, 0.5);
            },
            icon: Icon(Icons.slow_motion_video_rounded, color: PolieColors.royalAmethyst, size: 24),
            label: Text('Slow motion', style: PolieTypography.label(context).copyWith(color: PolieColors.royalAmethyst)),
          ),
        ],
      ),
    );
  }
}

class _PronPracticeBanner extends StatelessWidget {
  const _PronPracticeBanner();

  static const _copy = <String, String>{
    'pron.practice_mode': 'Practice mode',
    'pron.scoring_soon': 'Scoring coming soon',
  };

  @override
  Widget build(BuildContext context) {
    final practiceMode = _copy['pron.practice_mode']!;
    final scoringSoon = _copy['pron.scoring_soon']!;
    return Semantics(
      liveRegion: true,
      excludeSemantics: true,
      label: '$practiceMode. $scoringSoon',
      child: PolieGlassCard(
        padding: EdgeInsets.all(PolieSpacing.md),
        child: Column(
          children: [
            Text(
              practiceMode,
              style: PolieTypography.label(context).copyWith(color: PolieColors.electricTeal),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PolieSpacing.xs),
            Text(
              scoringSoon,
              style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

