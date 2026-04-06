import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/game_content_provider.dart';
import '../../models/game/game_content_models.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';

/// Pronunciation Karaoke — follow along with advancing words and hold
/// the mic button to "sing" each phrase.
///
/// Words auto-advance on a 1.5-second timer. The active word is enlarged
/// and highlighted; completed words dim and upcoming words fade. A
/// hold-to-record button shows a simulated waveform while held.
class PronunciationKaraokeGame extends BaseGameScreen {
  const PronunciationKaraokeGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.pronunciationKaraoke;

  @override
  ConsumerState<PronunciationKaraokeGame> createState() =>
      _PronunciationKaraokeGameState();
}

class _PronunciationKaraokeGameState
    extends BaseGameScreenState<PronunciationKaraokeGame> {
  final List<PhraseCard> _cards = [];
  int _currentPhraseIndex = 0;
  List<String> _words = [];
  int _currentWordIndex = -1;
  bool _isRecording = false;
  bool _karaokeStarted = false;
  int _rhythmHits = 0;
  int _totalWords = 0;
  int _phrasesCompleted = 0;
  Timer? _wordTimer;
  Timer? _waveformTimer;
  List<double> _waveformAmplitudes = List.filled(24, 0.08);
  final ScrollController _lyricScroll = ScrollController();
  final Random _rng = Random();

  bool _showScorePopup = false;
  String _scorePopupText = '';
  int _pitchScore = 0;

  @override
  int getCardCount() => 3;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isEmpty) {
      setError('No phrases available for Pronunciation Karaoke.');
      return;
    }
    _loadPhrase();
  }

  void _loadPhrase() {
    if (_currentPhraseIndex >= _cards.length) {
      finishGame();
      return;
    }

    final card = _cards[_currentPhraseIndex];
    final words = card.text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    setState(() {
      _words = words;
      _currentWordIndex = -1;
      _karaokeStarted = false;
      _showScorePopup = false;
    });
  }

  void _startKaraoke() {
    if (_karaokeStarted) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _karaokeStarted = true;
      _currentWordIndex = 0;
    });

    _wordTimer = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      final wasRecording = _isRecording;
      if (wasRecording && _currentWordIndex >= 0) {
        _rhythmHits++;
        _triggerScorePopup();
      }

      setState(() {
        _currentWordIndex++;
        _totalWords++;
      });

      _scrollToCurrentWord();

      if (_currentWordIndex >= _words.length) {
        t.cancel();
        _onPhraseComplete();
      }
    });
  }

  void _triggerScorePopup() {
    setState(() {
      _showScorePopup = true;
      _scorePopupText = '+10 XP';
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _showScorePopup = false);
    });
  }

  void _scrollToCurrentWord() {
    if (!_lyricScroll.hasClients) return;
    final target = _currentWordIndex * 90.0;
    _lyricScroll.animateTo(
      target.clamp(0.0, _lyricScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onPhraseComplete() async {
    _wordTimer?.cancel();
    _stopWaveform();

    final rhythmPct =
        _totalWords > 0 ? ((_rhythmHits / _totalWords) * 100).round() : 0;
    _pitchScore = 60 + _rng.nextInt(35);

    _phrasesCompleted++;

    final durationMs = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    await completeTurn(
      cardId: _cards[_currentPhraseIndex].cardId,
      result: rhythmPct >= 60 ? GameResult.correct : GameResult.partial,
      durationMs: durationMs,
      confidence: rhythmPct / 100.0,
      feedback: {
        'rhythm_score': rhythmPct,
        'pitch_score': _pitchScore,
        'phrase': _cards[_currentPhraseIndex].text,
        'phrase_index': _currentPhraseIndex + 1,
      },
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    _currentPhraseIndex++;
    _loadPhrase();
  }

  void _startRecording() {
    HapticFeedback.lightImpact();
    setState(() => _isRecording = true);
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted || !_isRecording) return;
      setState(() {
        _waveformAmplitudes = List.generate(
          24,
          (_) => _rng.nextDouble() * 0.7 + 0.2,
        );
      });
    });

    if (!_karaokeStarted) _startKaraoke();
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    _stopWaveform();
  }

  void _stopWaveform() {
    _waveformTimer?.cancel();
    _waveformTimer = null;
    if (mounted) {
      setState(() => _waveformAmplitudes = List.filled(24, 0.08));
    }
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    _waveformTimer?.cancel();
    _lyricScroll.dispose();
    super.dispose();
  }

  int get _rhythmPercent =>
      _totalWords > 0 ? ((_rhythmHits / _totalWords) * 100).round() : 0;

  @override
  String? get appBarTitle => _cards.isEmpty
      ? null
      : 'Karaoke (${_currentPhraseIndex + 1}/${_cards.length})';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_cards.isEmpty || _currentPhraseIndex >= _cards.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final cs = Theme.of(context).colorScheme;
    final phraseProgress = _cards.isEmpty
        ? 0.0
        : (_currentPhraseIndex + (_karaokeStarted ? 1 : 0)) / _cards.length;

    return Column(
      children: [
        GameTopBar(
          onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
          progress: phraseProgress.clamp(0.0, 1.0),
          streak: _phrasesCompleted,
          xp: _rhythmHits * 10,
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: GriotBentoGrid(
            gap: 10,
            items: [
              GriotBentoItem(
                span: 4,
                child: GriotStatCard(
                  icon: Icons.music_note_rounded,
                  iconColor: cs.primary,
                  value: '$_rhythmPercent%',
                  label: 'Rhythm',
                ),
              ),
              GriotBentoItem(
                span: 4,
                child: GriotStatCard(
                  icon: Icons.graphic_eq_rounded,
                  iconColor: ModernGriotColors.tertiary,
                  value: '${_pitchScore > 0 ? _pitchScore : '—'}%',
                  label: 'Pitch',
                ),
              ),
              GriotBentoItem(
                span: 4,
                child: GriotStatCard(
                  icon: Icons.flag_rounded,
                  iconColor: ModernGriotColors.secondary,
                  value: '$_phrasesCompleted/${_cards.length}',
                  label: 'Milestone',
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_karaokeStarted) ...[
                    Text(
                      'Hold the mic to start',
                      style: ModernGriotTypography.bodyLarge(
                        context: context,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  if (_karaokeStarted && _currentWordIndex < _words.length)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _words[_currentWordIndex],
                          key: ValueKey('word_$_currentWordIndex'),
                          style: ModernGriotTypography.displayMedium(
                            context: context,
                            color: cs.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  SizedBox(height: 16.h),

                  SizedBox(
                    height: 48.h,
                    child: ListView.builder(
                      controller: _lyricScroll,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: _words.length,
                      itemBuilder: (context, i) {
                        final isActive = i == _currentWordIndex;
                        final isDone = i < _currentWordIndex;
                        final isUpcoming = i > _currentWordIndex;

                        Color textColor = cs.onSurface;
                        double fontSize = 16.sp;
                        FontWeight weight = FontWeight.w500;

                        if (isActive) {
                          textColor = cs.primary;
                          fontSize = 20.sp;
                          weight = FontWeight.w800;
                        } else if (isDone) {
                          textColor = cs.onSurfaceVariant.withAlpha(100);
                        } else if (isUpcoming) {
                          textColor = cs.onSurfaceVariant.withAlpha(150);
                        }

                        return Padding(
                          padding: EdgeInsets.only(right: 16.w),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: weight,
                                color: textColor,
                              ),
                              child: Text(_words[i]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 12.h),

                  if (_currentPhraseIndex + 1 < _cards.length)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: GriotGlassPanel(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.queue_music_rounded,
                              size: 16.sp,
                              color: cs.onSurfaceVariant,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Next: ${_cards[_currentPhraseIndex + 1].text}',
                                style: ModernGriotTypography.bodySmall(
                                  context: context,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              if (_showScorePopup)
                Positioned(
                  top: 20.h,
                  child: GameScorePopup(
                    text: _scorePopupText,
                    color: ModernGriotColors.secondary,
                    onComplete: () {
                      if (mounted) setState(() => _showScorePopup = false);
                    },
                  ),
                ),
            ],
          ),
        ),

        Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            children: [
              GriotWaveformVisualizer(
                amplitudes: _waveformAmplitudes,
                animate: _isRecording,
                height: 40,
                barWidth: 3,
                gap: 2,
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecording(),
                onTapCancel: _stopRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _isRecording ? 88.r : 76.r,
                  height: _isRecording ? 88.r : 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isRecording
                        ? const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                          )
                        : ModernGriotGradients.signatureGradient,
                    boxShadow: _isRecording
                        ? ModernGriotShadows.glow(const Color(0xFFE53935))
                        : ModernGriotShadows.fab,
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 36.sp,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _isRecording ? 'Recording...' : 'Hold to record',
                style: ModernGriotTypography.labelMedium(
                  context: context,
                  color: _isRecording
                      ? ModernGriotColors.error
                      : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
