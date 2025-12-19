import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/api_provider.dart';
import '../../utils/progress_integration.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Pronunciation Duel - Head-to-head pronunciation scoring
class PronunciationDuelGame extends BaseGameScreen {
  const PronunciationDuelGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

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

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _currentCard = _cards[0];
    }
  }

  Future<void> _playNativeAudio() async {
    if (_currentCard?.audioNativeUrl == null) return;
    setState(() => _isPlaying = true);
    try {
      await _audioPlayer.setUrl(_currentCard!.audioNativeUrl!);
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      setState(() => _isRecording = true);
      final path = await _getRecordingPath();
      await _recorder.start(const RecordConfig(), path: path);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    
    if (path != null && _currentCard != null) {
      await _scorePronunciation(path);
    }
  }

  Future<String> _getRecordingPath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/pronunciation_duel_$ts.m4a';
  }

  Future<void> _scorePronunciation(String audioPath) async {
    try {
      final api = ref.read(apiProvider.notifier);
      final language = widget.language;
      final referenceText = _currentCard?.text ?? '';

      final result = await api.pronunciationQuick(
        audioPath: audioPath,
        expectedText: referenceText,
        language: language,
      );

      final score0to1 = (result['score'] ?? 0.7) as num;
      final score = (score0to1 * 100).round().clamp(0, 100);
      final mistakes = <String>[];
      if (result['phoneme_errors'] is List) {
        mistakes.addAll(List<String>.from(result['phoneme_errors']));
      } else if (result['feedback'] is String &&
          (result['feedback'] as String).isNotEmpty) {
        mistakes.add(result['feedback'] as String);
      }

      setState(() {
        _pronunciationScore = score;
        _mistakes = mistakes;
      });

      // Complete turn with real score
      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;

      await completeTurn(
        cardId: _currentCard!.cardId,
        result: score >= 85 ? GameResult.correct : GameResult.partial,
        durationMs: duration,
        confidence: score0to1.toDouble(),
        feedback: {
          'score': score,
          'feedback': result['feedback'],
          'phoneme_errors': result['phoneme_errors'],
          'word_errors': result['word_errors'],
        },
        userAction: 'pronounced',
      );

      // Feed into global progress (for pronunciation achievements, etc.)
      await ProgressIntegration.onChatActivity(
        ref,
        minutes: (duration / 1000.0 / 60.0),
        pronunciationScore: score0to1.toDouble(),
      );
    } catch (e) {
      debugPrint('Error scoring pronunciation: $e');
      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;
      await completeTurn(
        cardId: _currentCard!.cardId,
        result: GameResult.partial,
        durationMs: duration,
        confidence: 0.5,
        feedback: {'error': e.toString()},
        userAction: 'pronounced',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pronunciation scoring is temporarily unavailable.'),
          ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} (${_currentCardIndex + 1}/${_cards.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
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
                      foregroundColor: Colors.white,
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
      ),
    );
  }
}

