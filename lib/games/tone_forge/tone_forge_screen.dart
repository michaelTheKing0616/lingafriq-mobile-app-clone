import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../screens/games/base_game_screen.dart';
import '../../screens/games/shell_labels.dart';
import '../../models/game/game_session_model.dart';
import '../../services/polie_game_client.dart';
import '../gamekit/game_session.dart' as gamekit_session;
import '../gamekit/game_animation_bridge.dart';
import '../gamekit/game_result.dart';
import '../animation/rive_game_guide.dart';
import 'tone_forge_game.dart';
import 'tone_forge_models.dart';
import 'tone_forge_audio.dart';
import 'package:path_provider/path_provider.dart';

/// ToneForge game screen - Flagship implementation
class ToneForgeScreen extends BaseGameScreen {
  const ToneForgeScreen({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.toneTrainer;

  @override
  ConsumerState<ToneForgeScreen> createState() => _ToneForgeScreenState();
}

class _ToneForgeScreenState extends BaseGameScreenState<ToneForgeScreen> {
  late ToneForgeGame _game;
  late PolieGameClient _polieClient;
  late GameAnimationBridge _animationBridge;
  late RiveGameGuideController _guideController;
  
  ToneForgeContent? _currentContent;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _showResult = false;
  GameTurnResult? _lastResult;
  
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final ToneForgeAudioAnalyzer _audioAnalyzer = ToneForgeAudioAnalyzer();

  @override
  void initState() {
    super.initState();
    _guideController = RiveGameGuideController();
    _animationBridge = GameAnimationBridge(guideController: _guideController);
    _polieClient = PolieGameClient();
    _game = ToneForgeGameFactory.create(
      polieClient: _polieClient,
      animationBridge: _animationBridge,
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  String? get shellProgressLabel {
    if (isLoading) return null;
    final s = session;
    if (s == null) return null;
    return sessionTurnProgressLabel(
      completedTurns: s.totalTurns,
      maxTurns: getCardCount(),
    );
  }

  @override
  String? get shellScoreLabel {
    if (isLoading) return null;
    final s = session;
    if (s == null) return null;
    return shellScorePointsLabel(s.correctCount);
  }

  @override
  Future<void> onGameInitialized() async {
    await _loadNewContent();
  }

  Future<void> _loadNewContent() async {
    if (session == null) return;

    setState(() {
      _showResult = false;
      _lastResult = null;
    });

    try {
      final gameSession = gamekit_session.GameSession(
        sessionId: session!.sessionId,
        userId: session!.userId,
        gameId: _game.config.gameId,
        language: widget.language,
        level: widget.level,
        startTime: session!.startTime,
        turns: [],
      );

      _currentContent = await _game.loadContent(gameSession);
      setState(() {});
    } catch (e) {
      debugPrint('Error loading content: $e');
    }
  }

  Future<void> _playAudio() async {
    if (_currentContent?.audioUrl == null) return;

    setState(() => _isPlaying = true);
    try {
      await _player.play(UrlSource(_currentContent!.audioUrl!));
      await _player.onPlayerComplete.first;
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tmp = await getTemporaryDirectory();
        final recordPath =
            '${tmp.path}${Platform.pathSeparator}tone_forge_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 44100,
          ),
          path: recordPath,
        );
        setState(() => _isRecording = true);
        _guideController.setListening(true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      _guideController.setListening(false);

      if (path != null && _currentContent != null) {
        await _processRecording(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _processRecording(String audioPath) async {
    if (session == null || _currentContent == null) return;

    try {
      // Read audio file and extract pitch contour
      // For now, we'll use a simplified approach
      // In production, you'd use a proper audio library to read the file
      final audioSamples = await _readAudioSamples(audioPath);
      final pitchContour = _audioAnalyzer.extractPitchContour(audioSamples);

      final input = ToneForgeInput(
        userPitchContour: pitchContour,
        audioSamples: audioSamples,
        durationMs: 0, // Calculate from audio length
      );

      final gameSession = gamekit_session.GameSession(
        sessionId: session!.sessionId,
        userId: session!.userId,
        gameId: _game.config.gameId,
        language: widget.language,
        level: widget.level,
        startTime: session!.startTime,
        turns: [],
      );

      final result = await _game.playTurn(_currentContent!, input, gameSession);

      setState(() {
        _lastResult = result;
        _showResult = true;
      });

      // Record turn
      await completeTurn(
        cardId: _currentContent!.contentId,
        result: result.score.isCorrect ? GameResult.correct : GameResult.incorrect,
        durationMs: 5000,
        confidence: result.score.accuracy,
        feedback: {
          'accuracy': result.score.accuracy,
          'feedback': result.feedback.message,
          'is_perfect': result.score.isPerfect,
        },
      );

      // Auto-advance after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _loadNewContent();
        }
      });
    } catch (e) {
      debugPrint('Error processing recording: $e');
    }
  }

  Future<List<double>> _readAudioSamples(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Recorded audio file not found');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Recorded audio is empty');
    }

    // Basic WAV/PCM16 parser (little-endian). If header not present, treat as raw PCM16.
    int dataOffset = 0;
    int dataLength = bytes.length;
    if (bytes.length >= 44 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x41 && // A
        bytes[10] == 0x56 && // V
        bytes[11] == 0x45 // E
        ) {
      // Find "data" chunk
      int i = 12;
      while (i + 8 <= bytes.length) {
        final chunkId = String.fromCharCodes(bytes.sublist(i, i + 4));
        final chunkSize = ByteData.sublistView(Uint8List.fromList(bytes), i + 4, i + 8)
            .getUint32(0, Endian.little);
        if (chunkId == 'data') {
          dataOffset = i + 8;
          dataLength = chunkSize;
          break;
        }
        i += 8 + chunkSize;
      }
    }

    final end = (dataOffset + dataLength).clamp(0, bytes.length);
    final pcm = Uint8List.fromList(bytes.sublist(dataOffset, end));
    final bd = ByteData.sublistView(pcm);

    final samples = <double>[];
    for (int i = 0; i + 1 < pcm.length; i += 2) {
      final v = bd.getInt16(i, Endian.little);
      samples.add(v / 32768.0);
    }
    return samples;
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading || _currentContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            SizedBox(height: 2.h),
            FilledButton(
              onPressed: () => _loadNewContent(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 4.h),
          // Rive Guide Character
          Center(
            child: RiveGameGuide(
              controller: _guideController,
              width: 150.w,
              height: 150.h,
            ),
          ),
          SizedBox(height: 4.h),
          // Content Display
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Text(
                    _currentContent!.text,
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (_currentContent!.ipa != null) ...[
                    SizedBox(height: 1.h),
                    Text(
                      _currentContent!.ipa!,
                      style: TextStyle(fontSize: 16.sp, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (_currentContent!.culturalContext != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      _currentContent!.culturalContext!,
                      style: TextStyle(fontSize: 14.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 4.h),
          // Audio Playback Button
          FilledButton.icon(
            onPressed: _isPlaying ? null : _playAudio,
            icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
            label: Text(_isPlaying ? 'Playing...' : 'Play Audio'),
          ),
          SizedBox(height: 2.h),
          // Recording Button
          FilledButton.icon(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            style: FilledButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red : Colors.blue,
            ),
          ),
          if (_showResult && _lastResult != null) ...[
            SizedBox(height: 4.h),
            Card(
              color: _lastResult!.score.isCorrect
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(
                      _lastResult!.score.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: _lastResult!.score.isCorrect ? Colors.green : Colors.red,
                      size: 48.sp,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _lastResult!.feedback.message,
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Accuracy: ${(_lastResult!.score.accuracy * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

