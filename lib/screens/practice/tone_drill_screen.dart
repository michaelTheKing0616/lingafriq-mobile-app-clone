import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../models/lesson_item_model.dart';
import '../../services/voice/tone_error_detection_service.dart';
import '../../services/voice/tone_drill_service.dart';
import '../../services/voice/pitch_visualization_service.dart';
import '../../widgets/pronunciation/visual_pitch_feedback_widget.dart';
import '../../utils/screen_helpers.dart';

class ToneDrillScreen extends StatefulWidget {
  final LessonItem lessonItem;
  final List<ToneError>? initialErrors;

  const ToneDrillScreen({
    Key? key,
    required this.lessonItem,
    this.initialErrors,
  }) : super(key: key);

  @override
  State<ToneDrillScreen> createState() => _ToneDrillScreenState();
}

class _ToneDrillScreenState extends State<ToneDrillScreen> {
  final ToneErrorDetectionService _toneErrorService = ToneErrorDetectionService();
  final ToneDrillService _drillService = ToneDrillService();
  final PitchVisualizationService _pitchService = PitchVisualizationService();
  final AudioRecorder _recorder = AudioRecorder();

  ToneDrill? _currentDrill;
  ToneErrorResult? _lastResult;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  Uint8List? _recordedAudio;
  List<PitchPoint> _userPitchContour = [];
  int _currentDrillIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDrill();
  }

  Future<void> _loadDrill() async {
    try {
      ToneDrill drill;
      if (widget.initialErrors != null && widget.initialErrors!.isNotEmpty) {
        drill = await _drillService.generateDrillFromErrors(
          widget.lessonItem,
          widget.initialErrors!,
        );
      } else {
        drill = await _drillService.generateDrillFromItem(widget.lessonItem);
      }

      setState(() {
        _currentDrill = drill;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading drill: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/tone_drill_${DateTime.now().millisecondsSinceEpoch}.pcm';
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
          _userPitchContour = [];
        });
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
        final audioFile = await _readAudioFile(path);
        setState(() {
          _isRecording = false;
          _recordedAudio = audioFile;
        });
        await _analyzeRecording(audioFile);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  Future<Uint8List> _readAudioFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Recorded audio file not found');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Recorded audio is empty');
    }
    return Uint8List.fromList(bytes);
  }

  List<double> _convertToAudioSamples(Uint8List audioData) {
    final samples = <double>[];
    for (int i = 0; i < audioData.length - 1; i += 2) {
      final sample = (audioData[i] | (audioData[i + 1] << 8));
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      samples.add(signedSample / 32768.0);
    }
    return samples;
  }

  Future<void> _analyzeRecording(Uint8List audioData) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Convert audio to samples
      final audioSamples = _convertToAudioSamples(audioData);

      // Extract pitch contour
      final pitchContour = await _pitchService.extractPitchContour(
        audioSamples: audioSamples,
        sampleRate: 16000.0,
      );

      // Detect tone errors
      final result = await _toneErrorService.detectToneErrors(
        audioData: audioData,
        sampleRate: 16000,
        lessonItem: widget.lessonItem,
        userPitchContour: pitchContour,
      );

      setState(() {
        _lastResult = result;
        _userPitchContour = pitchContour;
        _isAnalyzing = false;
      });

      if (mounted && result.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tone accuracy: ${(result.overallAccuracy * 100).toStringAsFixed(1)}%'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excellent! Tones are correct'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing: $e')),
        );
      }
    }
  }

  void _nextDrillItem() {
    if (_currentDrill != null && _currentDrillIndex < _currentDrill!.items.length - 1) {
      setState(() {
        _currentDrillIndex++;
        _lastResult = null;
        _recordedAudio = null;
        _userPitchContour = [];
      });
    }
  }

  void _previousDrillItem() {
    if (_currentDrillIndex > 0) {
      setState(() {
        _currentDrillIndex--;
        _lastResult = null;
        _recordedAudio = null;
        _userPitchContour = [];
      });
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tone Practice'),
      ),
      body: withErrorBoundary(
        _buildBody(),
        onRetry: _loadDrill,
      ),
    );
  }

  Widget _buildBody() {
    if (_currentDrill == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentItem = _currentDrill!.items[_currentDrillIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDrillItemCard(currentItem),
          const SizedBox(height: 24),
          _buildRecordingSection(),
          if (_lastResult != null) ...[
            const SizedBox(height: 24),
            _buildResultsSection(),
          ],
          const SizedBox(height: 24),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildDrillItemCard(DrillItem item) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              item.text,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            if (item.ipa.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '/${item.ipa}/',
                style: TextStyle(fontSize: 20, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: item.tonePattern.map((tone) => Chip(
                label: Text(tone),
                color: WidgetStateProperty.all(Colors.blue[100]),
              )).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              item.translation,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isAnalyzing)
              const CircularProgressIndicator()
            else
              IconButton(
                iconSize: 64,
                icon: Icon(
                  _isRecording ? Icons.stop_circle : Icons.mic,
                  color: _isRecording ? Colors.red : Colors.blue,
                ),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
            const SizedBox(height: 8),
            Text(
              _isRecording ? 'Recording...' : 'Tap to record',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_lastResult == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tone Accuracy: ${(_lastResult!.overallAccuracy * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _lastResult!.overallAccuracy > 0.8 ? Colors.green : Colors.orange,
              ),
            ),
            if (_lastResult!.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._lastResult!.errors.map((error) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Syllable ${error.syllableIndex + 1}: Expected ${error.expectedTone}, got ${error.actualTone}',
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (_lastResult!.userPitchContour.isNotEmpty && _lastResult!.expectedPitchContour.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Pitch Comparison:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: VisualPitchFeedbackWidget(
                  userPitch: _lastResult!.userPitchContour,
                  nativePitch: _lastResult!.expectedPitchContour,
                  timePoints: _lastResult!.userPitchContour.map((p) => p.time).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: _currentDrillIndex > 0 ? _previousDrillItem : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Previous'),
        ),
        Text(
          '${_currentDrillIndex + 1}/${_currentDrill?.items.length ?? 0}',
          style: const TextStyle(fontSize: 16),
        ),
        ElevatedButton.icon(
          onPressed: _currentDrill != null && _currentDrillIndex < _currentDrill!.items.length - 1
              ? _nextDrillItem
              : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

