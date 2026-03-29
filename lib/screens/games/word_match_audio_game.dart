import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../providers/tts_provider.dart';
import '../../services/voice/voice_language_utils.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/api_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skeleton_loader.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/gamification/combo_tracker.dart';
import '../../widgets/gamification/combo_display_widget.dart';
import '../../services/sound_effects_service.dart';
import '../../providers/gamification_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/media_url_resolver.dart';
import 'templates/template_match_board.dart';

/// WordMatch+Audio Game - Upgraded version with TTS, pronunciation, diacritics
class WordMatchAudioGame extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final String language;
  final String? level;

  const WordMatchAudioGame({
    super.key,
    this.onBack,
    required this.language,
    this.level,
  });

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
  // ignore: unused_field
  GameSession? _session;
  DateTime? _startTime;
  bool _isLoading = true;
  String? _loadError;
  late final ComboTracker _comboTracker;
  Map<String, String>? _authHeaders;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _comboTracker = ComboTracker();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadAuthHeaders();
    await _initializeGame();
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

  @override
  void dispose() {
    _comboTracker.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeGame() async {
    try {
      // Use logged-in user if available; fall back to guest ID so games
      // always work even if userProvider hasn't been populated yet.
      final user = ref.read(userProvider);
      final userId =
          user?.id.toString() ??
          'guest_${DateTime.now().millisecondsSinceEpoch}';

      final gameProv = ref.read(gameProvider.notifier);
      _session = await gameProv.startGame(
        userId: userId,
        gameType: GameType.wordMatchAudio,
        language: widget.language,
        level: widget.level,
        cardCount: 10,
      );

      final cards = gameProv.availableCards;
      if (mounted) {
        setState(() {
          _hasFinished = false;
          _isLoading = false;
          _loadError = null;
        });
      }
      if (cards.isEmpty) {
        return;
      }

      if (cards.length < 4) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadError =
                'Not enough content for ${widget.language}. Try another language.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _startTime = DateTime.now();
          _leftTiles = cards
              .map(
                (c) => _GameTile(
                  id: c.cardId,
                  label: _resolveTargetLabel(c),
                  audioUrl: c.audioNativeUrl,
                  ascii: c.ascii,
                ),
              )
              .toList();
          _rightTiles = cards
              .map((c) => _GameTile(id: c.cardId, label: _resolveGlossLabel(c)))
              .toList();

          // Shuffle both lists
          _leftTiles.shuffle(Random());
          _rightTiles.shuffle(Random());
        });
      }
    } catch (e) {
      debugPrint('Error initializing WordMatchAudioGame: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e is DioException
              ? TransportErrorPolicy.toUserMessage(e)
              : 'Failed to start game. Please check your connection and try again.';
        });
      }
    }
  }

  Future<void> _playAudio(String? url, {String? fallbackText}) async {
    final resolved = resolveMediaUrl(url);
    if (resolved != null && resolved.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(resolved, headers: _authHeaders);
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play();
        return;
      } catch (e) {
        debugPrint(
          'Audio URL playback failed with auth headers, retrying public URL: $e',
        );
        try {
          await _audioPlayer.setUrl(resolved);
          await _audioPlayer.setVolume(1.0);
          await _audioPlayer.play();
          return;
        } catch (e2) {
          debugPrint('Audio URL playback failed, trying TTS: $e2');
        }
      }
    }

    // TTS fallback when no audio URL or URL playback failed
    if (fallbackText != null && fallbackText.isNotEmpty) {
      try {
        final lang = normalizeVoiceLanguage(widget.language);
        await ref.read(ttsProvider.notifier).speak(
              fallbackText,
              languageName: lang,
            );
      } catch (e) {
        debugPrint('TTS fallback failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio unavailable for this card right now.'),
            ),
          );
        }
      }
    }
  }

  String _resolveGlossLabel(dynamic card) {
    final text = card.text?.toString().trim() ?? '';
    final gloss = card.gloss?.toString().trim() ?? '';
    if (gloss.isNotEmpty && gloss.toLowerCase() != text.toLowerCase()) {
      return gloss;
    }
    final ascii = card.ascii?.toString().trim() ?? '';
    if (ascii.isNotEmpty &&
        _looksLikelyEnglish(ascii) &&
        ascii.toLowerCase() != text.toLowerCase()) {
      return ascii;
    }
    return 'No translation yet';
  }

  String _resolveTargetLabel(dynamic card) {
    final text = card.text?.toString().trim() ?? '';
    final ascii = card.ascii?.toString().trim() ?? '';
    final gloss = card.gloss?.toString().trim() ?? '';
    if (text.isNotEmpty && !_looksLikelyEnglish(text)) return text;
    if (ascii.isNotEmpty && !_looksLikelyEnglish(ascii)) return ascii;
    if (text.isNotEmpty) return text;
    if (ascii.isNotEmpty) return ascii;
    if (gloss.isNotEmpty) return gloss;
    return 'Word unavailable';
  }

  bool _looksLikelyEnglish(String value) {
    final s = value.toLowerCase();
    if (s.isEmpty) return false;
    const commonEnglishWords = {
      'the',
      'and',
      'is',
      'are',
      'you',
      'hello',
      'good',
      'morning',
      'thank',
      'please',
      'how',
      'where',
      'want',
      'learn',
      'welcome',
      'food',
      'love',
    };
    final tokens = s
        .split(RegExp(r'[^a-z]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return false;
    final englishHits = tokens.where(commonEnglishWords.contains).length;
    return englishHits >= (tokens.length / 2).ceil();
  }

  void _selectTile(String side, String id) {
    setState(() {
      if (side == 'left') {
        _selectedLeft = _selectedLeft == id ? null : id;
        if (_selectedLeft != null) {
          final tile = _leftTiles.firstWhere((t) => t.id == _selectedLeft);
          _playAudio(tile.audioUrl, fallbackText: tile.label);
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
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inMilliseconds
        : 0;
    final soundEffects = ref.read(soundEffectsProvider);

    // Sound effects and combo tracking
    if (correct) {
      soundEffects.playCorrect();
      _comboTracker.recordCorrect();
    } else {
      soundEffects.playIncorrect();
      _comboTracker.recordIncorrect();
    }

    setState(() {
      _results.add(
        _MatchResult(
          leftId: leftId,
          rightId: rightId,
          correct: correct,
          timestamp: DateTime.now(),
        ),
      );
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

    final correctUniqueMatches = _results
        .where((r) => r.correct)
        .map((r) => r.leftId)
        .toSet();
    if (!_hasFinished &&
        _leftTiles.isNotEmpty &&
        correctUniqueMatches.length >= _leftTiles.length) {
      _hasFinished = true;
      await _finishGame();
    }
  }

  Future<void> _finishGame() async {
    try {
      final gameProv = ref.read(gameProvider.notifier);
      final session = await gameProv.endGame();

      // Award XP with combo multiplier
      final multiplier = _comboTracker.currentMultiplier;
      await ref
          .read(gamificationProvider.notifier)
          .awardXP(
            'game_complete',
            multiplier: multiplier,
            sourceId:
                'word_match_audio_${widget.language}_${DateTime.now().millisecondsSinceEpoch}',
          );

      final soundEffects = ref.read(soundEffectsProvider);
      soundEffects.playCelebration();
      _comboTracker.reset();

      if (mounted) {
        _showCompletionDialog(session);
      }
    } catch (e) {
      debugPrint('Error finishing game: $e');
    }
  }

  void _showCompletionDialog(GameSession session) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (ctx, _, __) => AlertDialog(
        title: const Text('Game Complete'),
        content: Text(
          'Accuracy: ${(session.accuracy * 100).toStringAsFixed(0)}%\n'
          'Correct: ${session.correctCount}/${session.totalTurns}',
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _results.clear();
                _selectedLeft = null;
                _selectedRight = null;
                _leftTiles.clear();
                _rightTiles.clear();
                _isLoading = true;
                _loadError = null;
              });
              _initializeGame();
            },
            child: const Text('Try Again'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              (widget.onBack ?? () => Navigator.pop(context))();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return TemplateMatchBoard(
        title: 'Word Match + Audio',
        loading: true,
        board: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonLoader(
                child: Column(
                  children: [
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: PanAfricanColors.surfaceContainerLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 160,
                      height: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          color: PanAfricanColors.surfaceContainerLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading game...',
                style: PanAfricanTypography.bodyMedium(context),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return TemplateMatchBoard(
        title: 'Word Match + Audio',
        board: AppErrorState(
          message: _loadError!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _loadError = null;
              _hasFinished = false;
            });
            _initializeGame();
          },
        ),
      );
    }

    if (_leftTiles.isEmpty) {
      return TemplateMatchBoard(
        title: 'Word Match + Audio',
        board: AppEmptyState(
          icon: Icons.sports_esports_outlined,
          title: 'No content yet',
          subtitle:
              'No content available for this language. Try selecting another language or topic.',
          actionLabel: 'Go back',
          onAction: widget.onBack ?? () => Navigator.pop(context),
        ),
      );
    }

    return TemplateMatchBoard(
      title: 'Word Match + Audio',
      progressLabel: _results.isNotEmpty
          ? '${_results.length}/${_leftTiles.length}'
          : null,
      scoreLabel: '${_results.where((e) => e.correct).length}',
      board: Stack(
        children: [
          Padding(
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
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
                                            : () =>
                                                  _selectTile('left', tile.id),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: EdgeInsets.all(3.w),
                                          decoration: BoxDecoration(
                                            color: isMatched
                                                ? Colors.green.withOpacity(0.2)
                                                : isSelected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primaryContainer
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.volume_up,
                                                ),
                                                onPressed: () => _playAudio(
                                                  tile.audioUrl,
                                                  fallbackText: tile.label,
                                                ),
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration: isMatched
                                                            ? TextDecoration
                                                                  .lineThrough
                                                            : TextDecoration
                                                                  .none,
                                                      ),
                                                    ),
                                                    if (tile.ascii != null &&
                                                        tile.ascii !=
                                                            tile.label)
                                                      Text(
                                                        tile.ascii!,
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color:
                                                              Colors.grey[600],
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
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
                                            : () =>
                                                  _selectTile('right', tile.id),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: EdgeInsets.all(3.w),
                                          decoration: BoxDecoration(
                                            color: isMatched
                                                ? Colors.green.withOpacity(0.2)
                                                : isSelected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primaryContainer
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
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
                                                        ? TextDecoration
                                                              .lineThrough
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
                  child: Semantics(
                    label: 'Finish game',
                    button: true,
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
                ),
              ],
            ),
          ),
          // Combo display widget
          ComboDisplayWidget(comboTracker: _comboTracker),
        ],
      ),
    );
  }
}

class _GameTile {
  final String id;
  final String label;
  final String? audioUrl;
  final String? ascii;

  _GameTile({required this.id, required this.label, this.audioUrl, this.ascii});
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
