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
import '../../utils/pan_african_design_system.dart';
import '../../widgets/content/vocab_audio_controls.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';

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
  ConsumerState<PronunciationDuelGame> createState() =>
      _PronunciationDuelGameState();
}

class _PronunciationDuelGameState
    extends BaseGameScreenState<PronunciationDuelGame>
    with TickerProviderStateMixin {
  final List<PhraseCard> _cards = [];
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isPlayingNative = false;
  int? _pronunciationScore;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Simulated waveform amplitudes
  List<double> _nativeAmplitudes = [];
  List<double> _userAmplitudes = [];

  @override
  int getCardCount() => 5;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _generateNativeAmplitudes();
  }

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
  }

  void _generateNativeAmplitudes() {
    final rng = Random(42);
    _nativeAmplitudes = List.generate(16, (_) => 0.2 + rng.nextDouble() * 0.8);
  }

  PhraseCard? get _currentCard =>
      _currentIndex < _cards.length ? _cards[_currentIndex] : null;

  void _playNative() {
    if (_isPlayingNative) return;
    HapticFeedback.lightImpact();
    setState(() => _isPlayingNative = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isPlayingNative = false);
    });
  }

  void _toggleRecording() {
    HapticFeedback.mediumImpact();
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _pronunciationScore = null;
      _userAmplitudes = List.generate(16, (_) => 0.05);
    });
    _pulseController.repeat(reverse: true);

    // Simulate recording for 3 seconds, gradually building waveform
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isRecording) _stopRecording();
    });

    // Simulate growing amplitudes during recording
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: 500 * i), () {
        if (mounted && _isRecording) {
          final rng = Random();
          setState(() {
            _userAmplitudes = List.generate(
                16, (_) => 0.1 + rng.nextDouble() * 0.7);
          });
        }
      });
    }
  }

  void _stopRecording() {
    _pulseController.stop();
    _pulseController.value = 0;

    final rng = Random();
    final score = 75 + rng.nextInt(21); // 75-95% range

    setState(() {
      _isRecording = false;
      _pronunciationScore = score;
    });

    if (_currentCard != null) {
      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;
      completeTurn(
        cardId: _currentCard!.cardId,
        result: score >= 85 ? GameResult.correct : GameResult.partial,
        durationMs: duration,
        confidence: score / 100.0,
        feedback: {'score': score},
        userAction: 'pronounced',
      );
    }
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _pronunciationScore = null;
        _userAmplitudes = [];
        _generateNativeAmplitudes();
      });
    } else {
      finishGame();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  String? get appBarTitle =>
      'Pronunciation (${_currentIndex + 1}/${_cards.length})';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_cards.isEmpty) {
      return Center(
        child: Text('No cards available',
            style: ModernGriotTypography.bodyLarge(context: context)),
      );
    }

    final card = _currentCard;
    if (card == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final progress = _cards.isEmpty ? 0.0 : (_currentIndex + 1) / _cards.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
        child: Column(
          children: [
            SizedBox(height: PanAfricanSpacing.sm),
            GriotProgressBar(value: progress, height: 6, showGlowTip: true),
            SizedBox(height: PanAfricanSpacing.lg),
            // Word display
            Text(card.text,
                style: ModernGriotTypography.headlineLarge(context: context),
                textAlign: TextAlign.center),
            if (card.ipa != null) ...[
              SizedBox(height: PanAfricanSpacing.xxs),
              Text('/${card.ipa}/',
                  style: ModernGriotTypography.bodyMedium(
                      context: context, color: ModernGriotColors.onSurfaceVariant)),
            ],
            SizedBox(height: PanAfricanSpacing.xs),
            Text(card.gloss,
                style: ModernGriotTypography.bodyLarge(
                    context: context, color: ModernGriotColors.onSurfaceVariant),
                textAlign: TextAlign.center),
            SizedBox(height: PanAfricanSpacing.sm),
            VocabAudioControls(language: widget.language, text: card.text, compact: true),
            SizedBox(height: PanAfricanSpacing.lg),
            // Native speaker waveform
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: ModernGriotRadius.borderXl,
                border: Border.all(
                    color: ModernGriotColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.record_voice_over_rounded,
                          size: 18.sp, color: ModernGriotColors.secondary),
                      SizedBox(width: 6.w),
                      Text('Native Speaker',
                          style: ModernGriotTypography.labelLarge(
                              context: context, color: ModernGriotColors.secondary)),
                      const Spacer(),
                      IconButton(
                        onPressed: _playNative,
                        icon: Icon(
                          _isPlayingNative
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: ModernGriotColors.primary,
                          size: 32.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  GriotWaveformVisualizer(
                    amplitudes: _nativeAmplitudes,
                    height: 48,
                    animate: _isPlayingNative,
                    activeColor: ModernGriotColors.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            // User attempt area
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: ModernGriotRadius.borderXl,
                border: Border.all(
                  color: _isRecording
                      ? ModernGriotColors.primary
                      : ModernGriotColors.outlineVariant.withOpacity(0.3),
                  width: _isRecording ? 2 : 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.mic_rounded,
                          size: 18.sp, color: ModernGriotColors.tertiary),
                      SizedBox(width: 6.w),
                      Text('Your Attempt',
                          style: ModernGriotTypography.labelLarge(
                              context: context, color: ModernGriotColors.tertiary)),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  if (_userAmplitudes.isNotEmpty)
                    GriotWaveformVisualizer(
                      amplitudes: _userAmplitudes,
                      height: 48,
                      animate: _isRecording,
                      activeColor: ModernGriotColors.tertiary,
                    )
                  else
                    SizedBox(
                      height: 48.h,
                      child: Center(
                        child: Text('Tap the record button to begin',
                            style: ModernGriotTypography.bodySmall(
                                context: context,
                                color: ModernGriotColors.onSurfaceVariant)),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            // Pronunciation score gauge
            if (_pronunciationScore != null) ...[
              GriotMasteryRing(
                value: _pronunciationScore! / 100.0,
                size: 100,
                label: 'Accuracy',
              ),
              SizedBox(height: PanAfricanSpacing.md),
            ],
            // Record button
            if (_pronunciationScore == null)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) => Transform.scale(
                  scale: _isRecording ? _pulseAnim.value : 1.0,
                  child: child,
                ),
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isRecording
                          ? null
                          : ModernGriotGradients.signatureGradient,
                      color: _isRecording ? ModernGriotColors.error : null,
                      boxShadow: ModernGriotShadows.fab,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: ModernGriotColors.onPrimary,
                      size: 32.sp,
                    ),
                  ),
                ),
              )
            else
              GriotGradientButton(
                label: _currentIndex < _cards.length - 1
                    ? 'Next Word'
                    : 'Finish Game',
                icon: Icons.arrow_forward_rounded,
                onPressed: _nextCard,
              ),
            SizedBox(height: PanAfricanSpacing.lg),
            // Cultural note
            if (card.contextExamples.isNotEmpty)
              GameCulturalNoteCard(
                title: 'Pronunciation Tip',
                body: card.contextExamples.first,
                icon: Icons.tips_and_updates_rounded,
              ),
            SizedBox(height: PanAfricanSpacing.xl),
          ],
        ),
      ),
    );
  }
}
