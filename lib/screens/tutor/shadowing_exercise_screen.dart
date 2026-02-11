import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ShadowingExerciseScreen extends ConsumerStatefulWidget {
  final String referenceText;
  final String language;

  const ShadowingExerciseScreen({
    Key? key,
    required this.referenceText,
    required this.language,
  }) : super(key: key);

  @override
  ConsumerState<ShadowingExerciseScreen> createState() =>
      _ShadowingExerciseScreenState();
}

class _ShadowingExerciseScreenState
    extends ConsumerState<ShadowingExerciseScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Uint8List? _recordedAudio;
  Map<String, dynamic>? _feedback;
  bool _isEvaluating = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final recordingPath =
            '${tempDir.path}${Platform.pathSeparator}shadowing_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: recordingPath,
        );
        setState(() {
          _isRecording = true;
          _feedback = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path != null) {
        final file = await File(path).readAsBytes();
        setState(() {
          _isRecording = false;
          _recordedAudio = Uint8List.fromList(file);
        });
        _evaluateRecording();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _evaluateRecording() async {
    if (_recordedAudio == null) return;

    setState(() {
      _isEvaluating = true;
    });

    try {
      final provider = ref.read(groqChatProvider.notifier);
      final result = await provider.shadowingExercise(
        _recordedAudio!,
        widget.referenceText,
      );

      setState(() {
        _feedback = result;
        _isEvaluating = false;
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
      setState(() {
        _isEvaluating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        'Shadowing Exercise',
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
                      // Reference text card
                      PolieGlassCard(
                        padding: EdgeInsets.all(PolieSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reference Text',
                              style: PolieTypography.label(context),
                            ),
                            SizedBox(height: PolieSpacing.sm),
                            Text(
                              widget.referenceText,
                              style: PolieTypography.body(context).copyWith(
                                color: PolieColors.electricTeal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: PolieSpacing.xl),
                      // Record button orb
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _isRecording ? _stopRecording() : _startRecording();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isRecording ? 140.w : 120.w,
                            height: _isRecording ? 140.w : 120.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isRecording
                                    ? [PolieColors.error, PolieColors.errorMuted]
                                    : [PolieColors.electricTeal, PolieColors.electricTealLight],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording ? PolieColors.error : PolieColors.electricTeal)
                                      .withOpacity(0.5),
                                  blurRadius: _isRecording ? 32 : 24,
                                  spreadRadius: _isRecording ? 4 : 0,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 48.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: PolieSpacing.md),
                      Center(
                        child: Text(
                          _isRecording
                              ? 'Recording... Tap to stop'
                              : 'Tap to start recording',
                          style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textSecondary),
                        ),
                      ),
                      if (_isEvaluating) ...[
                        SizedBox(height: PolieSpacing.xl),
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(PolieColors.electricTeal),
                          ),
                        ),
                        SizedBox(height: PolieSpacing.sm),
                        Center(
                          child: Text(
                            'Evaluating your pronunciation...',
                            style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textSecondary),
                          ),
                        ),
                      ],
                      if (_feedback != null) ...[
                        SizedBox(height: PolieSpacing.xl),
                        PolieGlassCard(
                          hasGlow: true,
                          glowColor: PolieColors.electricTeal,
                          padding: EdgeInsets.all(PolieSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Results',
                                style: PolieTypography.h2(context),
                              ),
                              SizedBox(height: PolieSpacing.lg),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildScoreCard(
                                    'Score',
                                    '${((_feedback!['score'] as num) * 100).toStringAsFixed(1)}%',
                                    PolieColors.success,
                                  ),
                                  _buildScoreCard(
                                    'WER',
                                    '${((_feedback!['wer'] as num) * 100).toStringAsFixed(1)}%',
                                    PolieColors.goldEmber,
                                  ),
                                ],
                              ),
                              if (_feedback!['userText'] != null &&
                                  (_feedback!['userText'] as String).isNotEmpty) ...[
                                SizedBox(height: PolieSpacing.lg),
                                Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
                                SizedBox(height: PolieSpacing.md),
                                Text(
                                  'You said:',
                                  style: PolieTypography.label(context),
                                ),
                                SizedBox(height: PolieSpacing.xs),
                                Text(
                                  _feedback!['userText'] as String,
                                  style: PolieTypography.body(context),
                                ),
                              ],
                              if (_feedback!['corrections'] != null &&
                                  (_feedback!['corrections'] as List).isNotEmpty) ...[
                                SizedBox(height: PolieSpacing.lg),
                                Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
                                SizedBox(height: PolieSpacing.md),
                                Text(
                                  'Corrections:',
                                  style: PolieTypography.label(context),
                                ),
                                SizedBox(height: PolieSpacing.sm),
                                ...((_feedback!['corrections'] as List).map((e) => Padding(
                                      padding: EdgeInsets.only(bottom: PolieSpacing.sm),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 18.sp,
                                            color: PolieColors.goldEmber,
                                          ),
                                          SizedBox(width: PolieSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              '${e['original']} → ${e['correction']}\n${e['explanation']}',
                                              style: PolieTypography.bodySmall(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      decoration: BoxDecoration(
        color: PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: PolieTypography.bodySmall(context),
          ),
          SizedBox(height: PolieSpacing.xs),
          Text(
            value,
            style: PolieTypography.h2(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

