import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:typed_data';
import 'dart:io';
import '../../models/lesson_item_model.dart';
import '../../services/voice/pronunciation_analysis_service.dart';
import '../../providers/dio_provider.dart';
import '../../widgets/global/error_recovery_widget.dart';
import '../../widgets/global/offline_banner.dart';
import '../../utils/screen_integration_helper.dart';
import '../../utils/screen_helpers.dart';
import '../../core/errors/global_error_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PronunciationPracticeScreen extends ConsumerStatefulWidget {
  final LessonItem lessonItem;

  const PronunciationPracticeScreen({
    Key? key,
    required this.lessonItem,
  }) : super(key: key);

  @override
  ConsumerState<PronunciationPracticeScreen> createState() => _PronunciationPracticeScreenState();
}

class _PronunciationPracticeScreenState extends ConsumerState<PronunciationPracticeScreen>
    with PerformanceScreenMixin {
  late PronunciationAnalysisService _pronunciationService;
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isAnalyzing = false;
  Uint8List? _recordedAudio;
  PronunciationAnalysisResult? _lastResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    final dio = ref.read(client);
    _pronunciationService = PronunciationAnalysisService(dio);
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/pronunciation_${DateTime.now().millisecondsSinceEpoch}.pcm';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _recordedAudio = null;
          _lastResult = null;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Microphone permission denied';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path != null) {
        final audioFile = await _readAudioFile(path);
        setState(() {
          _isRecording = false;
          _recordedAudio = audioFile;
        });
        await _analyzePronunciation(audioFile);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _error = 'Failed to stop recording: $e';
      });
    }
  }

  Future<Uint8List> _readAudioFile(String path) async {
    final file = await File(path).readAsBytes();
    return Uint8List.fromList(file);
  }

  Future<void> _analyzePronunciation(Uint8List audioData) async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final result = await _pronunciationService.analyzePronunciation(
        audioData: audioData,
        sampleRate: 16000,
        lessonItem: widget.lessonItem,
        enableToneAnalysis: widget.lessonItem.tonePattern != null,
        enablePhonemeAnalysis: true,
      );

      setState(() {
        _lastResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to analyze pronunciation: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pronunciation Practice'),
        ),
        body: ErrorBoundary(
          errorMessage: _error,
          onRetry: () {
            if (_recordedAudio != null) {
              _analyzePronunciation(_recordedAudio!);
            }
          },
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLessonItemCard(),
          const SizedBox(height: 24),
          _buildRecordingSection(),
          if (_isAnalyzing) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_lastResult != null) ...[
            const SizedBox(height: 24),
            _buildResultsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonItemCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(widget.lessonItem.language)),
                const SizedBox(width: 8),
                Chip(label: Text(widget.lessonItem.level)),
                const SizedBox(width: 8),
                Chip(label: Text(widget.lessonItem.category)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.lessonItem.text,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            if (widget.lessonItem.ipa != null) ...[
              const SizedBox(height: 8),
              Text(
                '/${widget.lessonItem.ipa}/',
                style: TextStyle(fontSize: 20, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              widget.lessonItem.translation,
              style: const TextStyle(fontSize: 18),
            ),
            if (widget.lessonItem.tonePattern != null && widget.lessonItem.tonePattern!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.lessonItem.tonePattern!.map((tone) => Chip(
                  label: Text(tone),
                  color: WidgetStateProperty.all(Colors.blue[100]),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            IconButton(
              iconSize: 80,
              icon: Icon(
                _isRecording ? Icons.stop_circle : Icons.mic,
                color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
              ),
              onPressed: _isRecording ? _stopRecording : _startRecording,
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording ? 'Recording... Tap to stop' : 'Tap to start recording',
              style: const TextStyle(fontSize: 16),
            ),
            if (_isRecording) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_lastResult == null) return const SizedBox.shrink();

    final result = _lastResult!;
    final scoreColor = result.overallScore > 0.8
        ? Colors.green
        : result.overallScore > 0.6
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pronunciation Score',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreCircle('Overall', result.overallScore, scoreColor),
                _buildScoreCircle('Phoneme', result.phonemeAccuracy, Colors.blue),
                _buildScoreCircle('Tone', result.toneAccuracy, Colors.purple),
                _buildScoreCircle('Fluency', result.fluencyScore, Colors.teal),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Feedback',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(result.feedback),
            if (result.suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Suggestions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...result.suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(suggestion)),
                  ],
                ),
              )),
            ],
            if (result.phonemeErrors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Phoneme Errors',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...result.phonemeErrors.map((error) => ListTile(
                dense: true,
                title: Text('${error.phoneme}: Expected "${error.expected}", got "${error.actual}"'),
                subtitle: Text('Time: ${error.startTime.toStringAsFixed(2)}s - ${error.endTime.toStringAsFixed(2)}s'),
              )),
            ],
            if (result.toneErrors != null && result.toneErrors!.hasError) ...[
              const SizedBox(height: 16),
              Text(
                'Tone Errors',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...result.toneErrors!.errors.map((error) => ListTile(
                dense: true,
                title: Text('Syllable ${error.syllableIndex + 1}: Expected ${error.expectedTone}, got ${error.actualTone}'),
                subtitle: Text('${error.syllableText}'),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCircle(String label, double score, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: score,
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

