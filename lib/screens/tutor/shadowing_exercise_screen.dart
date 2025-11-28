import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
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
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error evaluating: $e')),
        );
      }
      setState(() {
        _isEvaluating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shadowing Exercise'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: isDark ? Colors.grey[800] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference Text',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: context.adaptive,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.referenceText,
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [Colors.red, Colors.redAccent]
                          : [AppColors.primaryGreen, AppColors.accentGold],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : AppColors.primaryGreen)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _isRecording
                    ? 'Recording... Tap to stop'
                    : 'Tap to start recording',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: context.adaptive54,
                ),
              ),
            ),
            if (_isEvaluating) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Evaluating your pronunciation...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.adaptive54,
                  ),
                ),
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 24),
              Card(
                color: isDark ? Colors.grey[800] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.adaptive,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildScoreCard(
                            'Score',
                            '${((_feedback!['score'] as num) * 100).toStringAsFixed(1)}%',
                            AppColors.primaryGreen,
                          ),
                          _buildScoreCard(
                            'WER',
                            '${((_feedback!['wer'] as num) * 100).toStringAsFixed(1)}%',
                            Colors.orange,
                          ),
                        ],
                      ),
                      if (_feedback!['userText'] != null &&
                          (_feedback!['userText'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'You said:',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: context.adaptive54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _feedback!['userText'] as String,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: context.adaptive,
                          ),
                        ),
                      ],
                      if (_feedback!['corrections'] != null &&
                          (_feedback!['corrections'] as List).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Corrections:',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: context.adaptive54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...((_feedback!['corrections'] as List).map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppColors.accentGold,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${e['original']} → ${e['correction']}\n${e['explanation']}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: context.adaptive,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.adaptive54,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

