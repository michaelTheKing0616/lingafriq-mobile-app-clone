import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../screens/games/base_game_screen.dart';
import '../../models/game/game_session_model.dart';
import '../../services/polie_game_client.dart';
import '../gamekit/game_session.dart';
import '../gamekit/game_animation_bridge.dart';
import '../animation/rive_game_guide.dart';
import 'tone_forge_game.dart';
import 'tone_forge_models.dart';
import 'tone_forge_audio.dart';

/// ToneForge game screen - Flagship implementation
class ToneForgeScreen extends BaseGameScreen {
  const ToneForgeScreen({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

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
      final gameSession = GameSession(
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
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 44100,
          ),
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

      final gameSession = GameSession(
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
    // Simplified - in production, use proper audio file reading
    // This is a placeholder that returns mock data
    // Replace with actual audio file parsing
    return List.generate(1000, (i) => (math.sin(i * 0.1) * 0.5 + 0.5));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tone Forge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
      ),
    );
  }
}

