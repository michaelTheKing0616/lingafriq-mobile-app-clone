import 'dart:io';
import 'package:flutter/material.dart';
import '../../providers/tts_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/dio_provider.dart';
import '../../providers/api_provider.dart';
import '../../services/voice/pronunciation_analysis_service.dart';
import '../../models/lesson_item_model.dart';
import '../../utils/supported_languages.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/media_url_resolver.dart';

/// Pronunciation Duel - Head-to-head pronunciation scoring
class PronunciationDuelGame extends BaseGameScreen {
  const PronunciationDuelGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.pronunciationDuel;

  @override
  ConsumerState<PronunciationDuelGame> createState() => _PronunciationDuelGameState();
}

class _PronunciationDuelGameState extends BaseGameScreenState<PronunciationDuelGame> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  PhraseCard? _currentCard;
  int _currentCardIndex = 0;
  bool _isRecording = false;
  bool _isPlaying = false;
  int? _pronunciationScore;
  List<String> _mistakes = [];
  final List<PhraseCard> _cards = [];
  Map<String, String>? _authHeaders;
  DateTime? _recordingStartedAt;

  @override
  int getCardCount() => 5;

  @override
  String? get appBarTitle => '${widget.getGameType().displayName} (${_currentCardIndex + 1}/${_cards.length})';

  @override
  Future<void> onGameInitialized() async {
    await _loadAuthHeaders();
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _currentCard = _cards[0];
    }
  }

  Future<void> _loadAuthHeaders() async {
    try {
      var token = ref.read(apiProvider.notifier).token;
      token ??= await ref.read(apiProvider.notifier).refreshAccessToken();
      if (token != null && token.isNotEmpty) {
        _authHeaders = {'Authorization': 'Bearer $token'};
      } else {
        _authHeaders = null;
      }
    } catch (_) {
      _authHeaders = null;
    }
  }

  Future<void> _playNativeAudio() async {
    final audioUrl = resolveMediaUrl(_currentCard?.audioNativeUrl);
    setState(() => _isPlaying = true);

    // Try URL-based playback first
    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(audioUrl, headers: _authHeaders);
        await _audioPlayer.play();
        await _audioPlayer.playerStateStream.firstWhere(
          (state) => state.processingState == ProcessingState.completed,
        );
        setState(() => _isPlaying = false);
        return;
      } catch (e) {
        debugPrint('Audio URL playback failed, trying TTS: $e');
      }
    }

    // TTS fallback
    final text = _currentCard?.text;
    if (text != null && text.isNotEmpty) {
      try {
        await ref.read(ttsProvider.notifier).speak(text, languageName: widget.language);
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('TTS fallback failed: $e');
      }
    }
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      setState(() => _isRecording = true);
      final path = await _getRecordingPath();
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _recordingStartedAt = DateTime.now();
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required to record pronunciation.')),
      );
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    final startedAt = _recordingStartedAt;
    _recordingStartedAt = null;
    if (startedAt != null && DateTime.now().difference(startedAt).inMilliseconds < 700) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording is too short. Please speak for at least 1 second.')),
        );
      }
      return;
    }
    if (path != null && _currentCard != null) {
      await _scorePronunciation(path);
    }
  }

  Future<String> _getRecordingPath() async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${tempDir.path}/recording_$timestamp.wav';
  }

  Future<void> _scorePronunciation(String audioPath) async {
    try {
      final dio = ref.read(client);
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found');
      }

      final audioData = await audioFile.readAsBytes();
      
      // Create a lesson item from the current card for pronunciation analysis
      final languageKey = SupportedLanguages.getKeyFromDisplayName(widget.language) ??
          widget.language.toLowerCase();
      final languageCode = SupportedLanguages.getLanguageCode(languageKey);
      final lessonItem = LessonItem(
        id: _currentCard!.cardId,
        language: widget.language,
        languageCode: languageCode,
        level: 'A1',
        category: 'vocabulary',
        type: 'word',
        text: _currentCard!.text,
        translation: _currentCard!.gloss,
        difficulty: 0.5,
        qualityScore: 0.0,
      );

      final pronunciationService = PronunciationAnalysisService(dio);
      final result = await pronunciationService.analyzePronunciation(
        audioData: audioData,
        sampleRate: 16000, // Standard sample rate
        lessonItem: lessonItem,
        enableToneAnalysis: true,
        enablePhonemeAnalysis: true,
      );

      final score = (result.overallScore * 100).round();
      final mistakes = result.phonemeErrors
          .map((e) => '${e.phoneme}: ${e.expected} → ${e.actual}')
          .toList();

      final looksLikeAnalysisFailure = score <= 0 &&
          mistakes.isEmpty &&
          (result.fluencyScore <= 0) &&
          (result.phonemeAccuracy <= 0);
      if (looksLikeAnalysisFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analysis failed for this recording. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _pronunciationScore = null;
          _mistakes = ['Could not score this recording. Please record again.'];
        });
        return;
      }

      setState(() {
        _pronunciationScore = score;
        _mistakes = mistakes;
      });

      // Complete turn
      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;
      
      await completeTurn(
        cardId: _currentCard!.cardId,
        result: score >= 85 ? GameResult.correct : GameResult.partial,
        durationMs: duration,
        confidence: result.overallScore,
        feedback: {
          'score': score,
          'mistakes': mistakes,
          'phoneme_accuracy': result.phonemeAccuracy,
          'tone_accuracy': result.toneAccuracy,
          'fluency': result.fluencyScore,
        },
        userAction: 'pronounced',
      );
    } catch (e) {
      debugPrint('Pronunciation scoring error: $e');
      setState(() {
        _pronunciationScore = null;
        _mistakes = ['Unable to analyze pronunciation. Please record and try again.'];
      });

      // Don't penalize user for API/server failures
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not analyze pronunciation. Try recording again.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _nextCard() {
    if (_currentCardIndex < _cards.length - 1) {
      setState(() {
        _currentCardIndex++;
        _currentCard = _cards[_currentCardIndex];
        _pronunciationScore = null;
        _mistakes = [];
      });
    } else {
      finishGame();
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_currentCard == null) {
      return const Center(child: Text('No cards available'));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 7.h, 4.w, 4.w),
      child: Column(
        children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentCardIndex + 1) / _cards.length,
            ),
            SizedBox(height: 4.h),
            // Card display
            Card(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Text(
                      _currentCard!.text,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentCard!.ascii != _currentCard!.text)
                      Text(
                        _currentCard!.ascii,
                        style: TextStyle(
                          fontSize: 20.sp,
                          color: Colors.grey,
                        ),
                      ),
                    SizedBox(height: 2.h),
                    Text(
                      _currentCard!.gloss,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            // Audio controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _isPlaying ? null : _playNativeAudio,
                  icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Playing...' : 'Play Native'),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            // Recording controls
            if (_pronunciationScore == null)
              Column(
                children: [
                  FilledButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Stop Recording' : 'Record'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.blue,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                    ),
                  ),
                ],
              )
            else
              // Score display
              Column(
                children: [
                  Text(
                    'Score: $_pronunciationScore/100',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: _pronunciationScore! >= 85
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  if (_mistakes.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Mistakes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._mistakes.map((m) => Text('- $m')),
                  ],
                  SizedBox(height: 2.h),
                  FilledButton(
                    onPressed: _nextCard,
                    child: Text(_currentCardIndex < _cards.length - 1
                        ? 'Next Card'
                        : 'Finish'),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}

