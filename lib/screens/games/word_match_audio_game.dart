import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// WordMatch+Audio Game - Upgraded version with TTS, pronunciation, diacritics
class WordMatchAudioGame extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final String language;
  final String? level;

  const WordMatchAudioGame({
    Key? key,
    this.onBack,
    required this.language,
    this.level,
  }) : super(key: key);

  @override
  ConsumerState<WordMatchAudioGame> createState() => _WordMatchAudioGameState();
}

class _WordMatchAudioGameState extends ConsumerState<WordMatchAudioGame> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<_GameTile> _leftTiles = [];
  List<_GameTile> _rightTiles = [];
  String? _selectedLeft;
  String? _selectedRight;
  final List<_MatchResult> _results = [];
  GameSession? _session;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final gameProv = ref.read(gameProvider.notifier);
    _session = await gameProv.startGame(
      userId: user.id.toString(),
      gameType: GameType.wordMatchAudio,
      language: widget.language,
      level: widget.level,
      cardCount: 10,
    );

    final cards = gameProv.availableCards;
    if (cards.isEmpty) {
      // Load cards for session
      // Cards should be loaded by game provider
      return;
    }

    setStartTime(DateTime.now());
    setState(() {
      _leftTiles = cards.map((c) => _GameTile(
            id: c.cardId,
            label: c.text,
            audioUrl: c.audioNativeUrl,
            ascii: c.ascii,
          )).toList();
      _rightTiles = cards.map((c) => _GameTile(
            id: c.cardId,
            label: c.gloss,
          )).toList();

      // Shuffle both lists
      _leftTiles.shuffle(Random());
      _rightTiles.shuffle(Random());
    });
  }

  Future<void> _playAudio(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _selectTile(String side, String id) {
    setState(() {
      if (side == 'left') {
        _selectedLeft = _selectedLeft == id ? null : id;
        if (_selectedLeft != null) {
          final tile = _leftTiles.firstWhere((t) => t.id == _selectedLeft);
          _playAudio(tile.audioUrl);
        }
      } else {
        _selectedRight = _selectedRight == id ? null : id;
      }

      // Evaluate if both selected
      if (_selectedLeft != null && _selectedRight != null) {
        _evaluateMatch(_selectedLeft!, _selectedRight!);
        _selectedLeft = null;
        _selectedRight = null;
      }
    });
  }

  Future<void> _evaluateMatch(String leftId, String rightId) async {
    final correct = leftId == rightId;
    final duration = this.startTime != null
        ? DateTime.now().difference(this.startTime!).inMilliseconds
        : 0;

    setState(() {
      _results.add(_MatchResult(
        leftId: leftId,
        rightId: rightId,
        correct: correct,
        timestamp: DateTime.now(),
      ));
    });

    // Update game provider
    final gameProv = ref.read(gameProvider.notifier);
    await gameProv.completeTurn(
      cardId: leftId,
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: correct ? 1.0 : 0.0,
      userAction: 'matched_audio_played',
    );

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(correct ? 'Correct! 🎉' : 'Try again!'),
          backgroundColor: correct ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _finishGame() async {
    try {
      final gameProv = ref.read(gameProvider.notifier);
      final session = await gameProv.endGame();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game Complete! Accuracy: ${(session.accuracy * 100).toStringAsFixed(0)}%',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error finishing game: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Match + Audio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: _leftTiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Progress indicator
                  if (_results.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: LinearProgressIndicator(
                        value: _results.length / _leftTiles.length,
                        minHeight: 8,
                      ),
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        // Left column (native text with audio)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 1.h),
                                child: Text(
                                  'Tap a word (audio)',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _leftTiles.length,
                                  itemBuilder: (context, index) {
                                    final tile = _leftTiles[index];
                                    final isSelected = _selectedLeft == tile.id;
                                    final isMatched = _results.any(
                                      (r) => r.leftId == tile.id && r.correct,
                                    );

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 1.h),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: isMatched
                                              ? null
                                              : () => _selectTile('left', tile.id),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: EdgeInsets.all(3.w),
                                            decoration: BoxDecoration(
                                              color: isMatched
                                                  ? Colors.green.withOpacity(0.2)
                                                  : isSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer
                                                      : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                if (tile.audioUrl != null)
                                                  IconButton(
                                                    icon: const Icon(Icons.volume_up),
                                                    onPressed: () => _playAudio(tile.audioUrl),
                                                  ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        tile.label,
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                          fontWeight: FontWeight.bold,
                                                          decoration: isMatched
                                                              ? TextDecoration.lineThrough
                                                              : TextDecoration.none,
                                                        ),
                                                      ),
                                                      if (tile.ascii != null &&
                                                          tile.ascii != tile.label)
                                                        Text(
                                                          tile.ascii!,
                                                          style: TextStyle(
                                                            fontSize: 12.sp,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (isMatched)
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 2.w),
                        // Right column (meanings)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 1.h),
                                child: Text(
                                  'Tap the meaning',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _rightTiles.length,
                                  itemBuilder: (context, index) {
                                    final tile = _rightTiles[index];
                                    final isSelected = _selectedRight == tile.id;
                                    final isMatched = _results.any(
                                      (r) => r.rightId == tile.id && r.correct,
                                    );

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 1.h),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: isMatched
                                              ? null
                                              : () => _selectTile('right', tile.id),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: EdgeInsets.all(3.w),
                                            decoration: BoxDecoration(
                                              color: isMatched
                                                  ? Colors.green.withOpacity(0.2)
                                                  : isSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer
                                                      : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    tile.label,
                                                    style: TextStyle(
                                                      fontSize: 16.sp,
                                                      fontWeight: FontWeight.bold,
                                                      decoration: isMatched
                                                          ? TextDecoration.lineThrough
                                                          : TextDecoration.none,
                                                    ),
                                                  ),
                                                ),
                                                if (isMatched)
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Finish button
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _finishGame,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 3.h),
                        ),
                        child: Text(
                          'Finish Game',
                          style: TextStyle(fontSize: 18.sp),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _GameTile {
  final String id;
  final String label;
  final String? audioUrl;
  final String? ascii;

  _GameTile({
    required this.id,
    required this.label,
    this.audioUrl,
    this.ascii,
  });
}

class _MatchResult {
  final String leftId;
  final String rightId;
  final bool correct;
  final DateTime timestamp;

  _MatchResult({
    required this.leftId,
    required this.rightId,
    required this.correct,
    required this.timestamp,
  });
}

