import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
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
    // TODO: Use path_provider for proper path
    return '/tmp/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _scorePronunciation(String audioPath) async {
    // TODO: Call pronunciation scoring API
    // For now, mock scoring
    await Future.delayed(const Duration(seconds: 1));
    
    final mockScore = 70 + (DateTime.now().millisecond % 30); // 70-100
    final mockMistakes = mockScore < 85
        ? ['Vowel length', 'Tone accuracy']
        : [];

    setState(() {
      _pronunciationScore = mockScore;
      _mistakes = List<String>.from(mockMistakes);
    });

    // Complete turn
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;
    
    await completeTurn(
      cardId: _currentCard!.cardId,
      result: mockScore >= 85 ? GameResult.correct : GameResult.partial,
      durationMs: duration,
      confidence: mockScore / 100.0,
      feedback: {
        'score': mockScore,
        'mistakes': mockMistakes,
      },
      userAction: 'pronounced',
    );
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

