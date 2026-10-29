import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/ai/ai_disclosure.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart'
    show AppLanguage;
import 'package:just_audio/just_audio.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';

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
    final analyzeStatus = useState<int?>(null);
    final analyzeBody = useState<Map<String, dynamic>?>(null);
    final isScoring = useState(false);
    final coachSyllables = useState<List<SyllableToneOverlayRow>>([]);
    final coachPhase = useState<ToneOverlayStatus?>(null);
    final coachRetry = useState(false);
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
          final path = await recorder.startRecording(
            sampleRate: 16000,
            numChannels: 1,
          );
          if (path == null) {
            throw Exception(
              'Microphone permission denied or recorder unavailable.',
            );
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
        isScoring.value = true;
        coachPhase.value = ToneOverlayStatus.loading;
        coachSyllables.value = [];
        coachRetry.value = false;

        final response = await ref
            .read(client)
            .post(
              '/api/ai/score/utterance',
              data: FormData.fromMap({
                'audio': await MultipartFile.fromFile(
                  path,
                  filename: 'pronunciation_audio.wav',
                ),
                'expected_text': textController.text,
                'language': selectedLanguage.value.code,
              }),
              options: Options(
                validateStatus: (status) => status != null && status < 600,
              ),
            );
        final raw = response.data;
        final body = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        analyzeStatus.value = response.statusCode;
        analyzeBody.value = body;
        isScoring.value = false;
        final unavailable =
            response.statusCode == 503 || body['retryable'] == true;
        if (!unavailable && response.statusCode == 200) {
          _applyShadowingCoachResult(
            body,
            coachSyllables,
            coachPhase,
            coachRetry,
          );
        }
        if (!unavailable && response.statusCode != 200) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
        }
      } catch (e) {
        isRecording.value = false;
        isScoring.value = false;
        if (e is DioException) {
          final status = e.response?.statusCode;
          final raw = e.response?.data;
          final body = raw is Map ? Map<String, dynamic>.from(raw) : null;
          if (status != null) analyzeStatus.value = status;
          if (body != null) analyzeBody.value = body;
          if (status == 503 || body?['retryable'] == true) {
            return;
          }
        }
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }

    return Scaffold(
      body: AiDisclosed(
        child: Container(
          decoration: const BoxDecoration(
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
                  _PronPracticeBanner(
                    analyzeStatus: analyzeStatus.value,
                    analyzeBody: analyzeBody.value,
                  ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: PolieSpacing.md,
                            vertical: PolieSpacing.sm,
                          ),
                          child: DropdownButtonFormField<AppLanguage>(
                            initialValue: selectedLanguage.value,
                            dropdownColor: isDark
                                ? PolieColors.surfaceContainer
                                : PolieColors.surfaceContainerLight,
                            decoration: const InputDecoration(
                              labelText: 'Language',
                              border: InputBorder.none,
                            ),
                            items: availableLanguages
                                .map(
                                  (lang) => DropdownMenuItem<AppLanguage>(
                                    value: lang,
                                    child: Text(
                                      lang.displayName,
                                      style: PolieTypography.body(context),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) selectedLanguage.value = value;
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: PolieSpacing.sm),
                      PolieGlassCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: PolieSpacing.sm,
                          vertical: PolieSpacing.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Regional',
                              style: PolieTypography.bodySmall(context),
                            ),
                            SizedBox(width: PolieSpacing.xs),
                            Switch(
                              value: useRegionalPronunciation.value,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                useRegionalPronunciation.value = v;
                              },
                              activeThumbColor: PolieColors.electricTeal,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PolieSpacing.xl),

                  Center(
                    child: Semantics(
                      label: isRecording.value
                          ? 'Tap to stop recording'
                          : 'Tap to start recording',
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
                                PolieColors.electricTealLight.withValues(
                                  alpha: 0.9,
                                ),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: PolieColors.electricTeal.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: isRecording.value ? 32 : 24,
                                spreadRadius: isRecording.value ? 4 : 0,
                              ),
                              BoxShadow(
                                color: PolieColors.electricTeal.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 48,
                                spreadRadius: -8,
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isRecording.value
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            size: 48.sp,
                            color: Theme.of(context).colorScheme.onPrimary,
                            semanticLabel: isRecording.value
                                ? 'Stop'
                                : 'Record',
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Center(
                    child: Text(
                      isRecording.value ? 'Tap to stop' : 'Tap to record',
                      style: PolieTypography.bodySmall(
                        context,
                      ).copyWith(color: PolieColors.textSecondary),
                    ),
                  ),
                  if (isScoring.value || coachPhase.value != null) ...[
                    SizedBox(height: PolieSpacing.md),
                    _ShadowingCoachPanel(
                      status: coachPhase.value ?? ToneOverlayStatus.loading,
                      syllables: coachSyllables.value,
                      retryPrompt: coachRetry.value,
                      onRetry: recordPractice,
                    ),
                  ],
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
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: PolieColors.electricTeal,
              size: 24,
            ),
            label: Text(
              'Replay',
              style: PolieTypography.label(
                context,
              ).copyWith(color: PolieColors.electricTeal),
            ),
          ),
          SizedBox(width: PolieSpacing.md),
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _playAtSpeed(context, 0.5);
            },
            icon: const Icon(
              Icons.slow_motion_video_rounded,
              color: PolieColors.royalAmethyst,
              size: 24,
            ),
            label: Text(
              'Slow motion',
              style: PolieTypography.label(
                context,
              ).copyWith(color: PolieColors.royalAmethyst),
            ),
          ),
        ],
      ),
    );
  }
}

void _applyShadowingCoachResult(
  Map<String, dynamic> body,
  ValueNotifier<List<SyllableToneOverlayRow>> syllables,
  ValueNotifier<ToneOverlayStatus?> phase,
  ValueNotifier<bool> retry,
) {
  final rawList = body['syllables'];
  final rows = <SyllableToneOverlayRow>[];
  if (rawList is List) {
    for (final item in rawList) {
      if (item is Map) {
        rows.add(
          SyllableToneOverlayRow.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
  }
  syllables.value = rows;
  final status = (body['status'] as String?)?.toLowerCase() ?? '';
  final retryRequested = body['retry_requested'] == true || status == 'unsure';
  final allUnsure = rows.isNotEmpty && rows.every((r) => r.isUnsure);
  if (retryRequested || allUnsure) {
    phase.value = ToneOverlayStatus.unsure;
    retry.value = true;
    return;
  }
  phase.value = rows.isEmpty
      ? ToneOverlayStatus.error
      : ToneOverlayStatus.scored;
  retry.value = false;
}

/// copy_keys: shadow.retry_noise, shadow.unsure (P6-028)
class _ShadowingCoachPanel extends StatelessWidget {
  const _ShadowingCoachPanel({
    required this.status,
    required this.syllables,
    required this.retryPrompt,
    required this.onRetry,
  });

  static const retryNoiseKey = 'shadow.retry_noise';
  static const unsureKey = 'shadow.unsure';
  static const retryNoiseCopy =
      'Background noise may have affected scoring. Try again in a quieter place.';
  static const unsureCopy =
      'We could not score this clearly. No score is shown — please try again.';

  final ToneOverlayStatus status;
  final List<SyllableToneOverlayRow> syllables;
  final bool retryPrompt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToneOverlayView(status: status, syllables: syllables),
          if (retryPrompt) ...[
            SizedBox(height: PolieSpacing.sm),
            Text(
              unsureCopy,
              key: const ValueKey(unsureKey),
              style: PolieTypography.bodySmall(
                context,
              ).copyWith(color: PolieColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PolieSpacing.sm),
            Semantics(
              button: true,
              label: retryNoiseCopy,
              child: TextButton(
                onPressed: onRetry,
                child: Text(
                  'Try again',
                  key: const ValueKey(retryNoiseKey),
                  style: PolieTypography.label(
                    context,
                  ).copyWith(color: PolieColors.electricTeal),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PronPracticeBanner extends StatelessWidget {
  const _PronPracticeBanner({this.analyzeStatus, this.analyzeBody});

  final int? analyzeStatus;
  final Map<String, dynamic>? analyzeBody;

  static const _copy = <String, String>{
    'pron.practice_mode': 'Practice mode',
    'pron.shadowing_hint':
        'Listen, record, and compare your pitch to the model line.',
    'pron.unavailable':
        'The scoring service is unavailable. No score is shown.',
  };

  bool get _isUnavailable {
    if (analyzeStatus == 503) return true;
    if (analyzeBody != null && analyzeBody!['retryable'] == true) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final practiceMode = _copy['pron.practice_mode']!;
    final subtitle = _isUnavailable
        ? _copy['pron.unavailable']!
        : _copy['pron.shadowing_hint']!;
    return Semantics(
      liveRegion: true,
      excludeSemantics: true,
      label: '$practiceMode. $subtitle',
      child: PolieGlassCard(
        padding: EdgeInsets.all(PolieSpacing.md),
        child: Column(
          children: [
            Text(
              practiceMode,
              style: PolieTypography.label(
                context,
              ).copyWith(color: PolieColors.electricTeal),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PolieSpacing.xs),
            Text(
              subtitle,
              style: PolieTypography.bodySmall(
                context,
              ).copyWith(color: PolieColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
