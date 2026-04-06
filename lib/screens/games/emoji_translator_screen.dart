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

class EmojiTranslatorGame extends BaseGameScreen {
  const EmojiTranslatorGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.emojiTranslator;

  @override
  ConsumerState<EmojiTranslatorGame> createState() =>
      _EmojiTranslatorGameState();
}

class _EmojiTranslatorGameState
    extends BaseGameScreenState<EmojiTranslatorGame> {
  List<_EmojiRiddle> _riddles = [];
  int _currentIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  bool _showResult = false;
  bool _isCorrect = false;
  int _streak = 0;
  int _correctCount = 0;
  final List<_PastRiddle> _pastRiddles = [];

  @override
  int getCardCount() => 10;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Future<void> onGameInitialized() async {
    final words = ref.read(
      gameWordsProvider(GameContentFilter(language: widget.language)),
    );
    if (words.length >= 10) {
      final shuffled = List.of(words)..shuffle(Random());
      _riddles = shuffled.take(10).map((w) => _EmojiRiddle(
        emojis: _generateEmojiCombo(w.word, w.topic),
        answer: w.word,
        hint: w.englishMeaning,
      )).toList();
    } else {
      _riddles = _fallbackRiddles();
    }
  }

  List<_EmojiRiddle> _fallbackRiddles() => [
        const _EmojiRiddle(emojis: '👋 😊 🌍', answer: 'hello', hint: 'A common greeting'),
        const _EmojiRiddle(emojis: '💧 🥤 🫗', answer: 'water', hint: 'Essential liquid'),
        const _EmojiRiddle(emojis: '🍚 🍲 🔥', answer: 'food', hint: 'We eat this'),
        const _EmojiRiddle(emojis: '🏠 🛏️ 🚪', answer: 'house', hint: 'Where you live'),
        const _EmojiRiddle(emojis: '📚 ✏️ 🎓', answer: 'school', hint: 'Place of learning'),
        const _EmojiRiddle(emojis: '👨‍👩‍👧 ❤️ 🏡', answer: 'family', hint: 'Your loved ones'),
        const _EmojiRiddle(emojis: '🌙 ⭐ 😴', answer: 'night', hint: 'After sunset'),
        const _EmojiRiddle(emojis: '☀️ 🌅 🐓', answer: 'morning', hint: 'Start of day'),
        const _EmojiRiddle(emojis: '🎵 🥁 💃', answer: 'dance', hint: 'Move to music'),
        const _EmojiRiddle(emojis: '🙏 🕌 ✨', answer: 'prayer', hint: 'Spiritual practice'),
      ];

  String _generateEmojiCombo(String word, String? topic) {
    final emojiSets = {
      'greetings': ['👋', '😊', '🤝'],
      'food': ['🍚', '🍲', '🔥'],
      'family': ['👨‍👩‍👧', '❤️', '🏡'],
      'travel': ['🚌', '✈️', '🗺️'],
      'nature': ['🌳', '🌍', '☀️'],
      'market': ['🛒', '💰', '🏪'],
    };
    final fallback = ['🔤', '💬', '🌍'];
    final set = emojiSets[topic?.toLowerCase()] ?? fallback;
    return set.join(' ');
  }

  void _submitAnswer() {
    if (_showResult || _answerController.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final riddle = _riddles[_currentIndex];
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correct = userAnswer == riddle.answer.toLowerCase() ||
        userAnswer == riddle.hint.toLowerCase();

    setState(() {
      _showResult = true;
      _isCorrect = correct;
      if (correct) {
        _streak++;
        _correctCount++;
      } else {
        _streak = 0;
      }
      _pastRiddles.add(_PastRiddle(
        emojis: riddle.emojis,
        answer: riddle.answer,
        wasCorrect: correct,
      ));
    });

    completeTurn(
      cardId: 'emoji_$_currentIndex',
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {'emojis': riddle.emojis, 'userAnswer': userAnswer},
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _currentIndex++;
      if (_currentIndex >= _riddles.length) {
        finishGame();
      } else {
        setState(() {
          _showResult = false;
          _answerController.clear();
        });
      }
    });
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_riddles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;
    final riddle = _currentIndex < _riddles.length
        ? _riddles[_currentIndex]
        : _riddles.last;
    final accuracy = _currentIndex > 0
        ? (_correctCount / _currentIndex * 100).toStringAsFixed(0)
        : '0';

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 24.h),
          children: [
            _buildEmojiDisplay(cs, riddle),
            SizedBox(height: 20.h),
            _buildInputField(cs),
            SizedBox(height: 16.h),
            _buildSabiTip(cs, riddle),
            SizedBox(height: 20.h),
            _buildStatsRow(cs, accuracy),
            SizedBox(height: 20.h),
            if (_pastRiddles.isNotEmpty) _buildPastRiddles(cs),
            if (_showResult) ...[
              SizedBox(height: 16.h),
              _buildResultBanner(cs, riddle),
            ],
          ],
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: _currentIndex + 1,
            totalSteps: _riddles.length,
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiDisplay(ColorScheme cs, _EmojiRiddle riddle) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        border: Border.all(color: ModernGriotColors.primaryContainer.withOpacity(0.4), width: 2),
        boxShadow: ModernGriotShadows.md,
      ),
      child: Column(
        children: [
          Text('Decode this:', style: ModernGriotTypography.labelLarge(
              context: context, color: ModernGriotColors.onSurfaceVariant)),
          SizedBox(height: 16.h),
          Text(riddle.emojis,
              style: TextStyle(fontSize: 56.sp),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInputField(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: ModernGriotRadius.borderXl,
              border: Border.all(color: cs.outlineVariant.withOpacity(0.15)),
            ),
            child: TextField(
              controller: _answerController,
              enabled: !_showResult,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitAnswer(),
              style: ModernGriotTypography.bodyLarge(context: context),
              decoration: InputDecoration(
                hintText: 'Type the meaning...',
                hintStyle: ModernGriotTypography.bodyLarge(
                    context: context, color: ModernGriotColors.onSurfaceVariant.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          onTap: _submitAnswer,
          child: Container(
            width: 52.r, height: 52.r,
            decoration: BoxDecoration(
              gradient: ModernGriotGradients.signatureGradient,
              shape: BoxShape.circle,
              boxShadow: ModernGriotShadows.fab,
            ),
            child: Icon(Icons.send_rounded, size: 22.sp,
                color: ModernGriotColors.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSabiTip(ColorScheme cs, _EmojiRiddle riddle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ModernGriotColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ModernGriotRadius.xl.r),
          topRight: Radius.circular(ModernGriotRadius.md.r),
          bottomLeft: Radius.circular(ModernGriotRadius.md.r),
          bottomRight: Radius.circular(ModernGriotRadius.xl.r),
        ),
        border: Border.all(color: ModernGriotColors.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, size: 20.sp, color: ModernGriotColors.secondary),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: 'Sabi Tip: ', style: ModernGriotTypography.labelLarge(
                      context: context, color: ModernGriotColors.secondary)),
                  TextSpan(text: riddle.hint, style: ModernGriotTypography.bodyMedium(
                      context: context, color: ModernGriotColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme cs, String accuracy) {
    return Row(
      children: [
        Expanded(
          child: GriotStatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: ModernGriotColors.primaryContainer,
            value: '$_streak',
            label: 'Streak',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GriotStatCard(
            icon: Icons.track_changes_rounded,
            iconColor: ModernGriotColors.secondary,
            value: '$accuracy%',
            label: 'Accuracy',
          ),
        ),
      ],
    );
  }

  Widget _buildPastRiddles(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Past Riddles', style: ModernGriotTypography.titleSmall(context: context)),
        SizedBox(height: 10.h),
        SizedBox(
          height: 100.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _pastRiddles.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, i) {
              final past = _pastRiddles[i];
              return Container(
                width: 110.w,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: past.wasCorrect
                      ? ModernGriotColors.secondary.withOpacity(0.08)
                      : ModernGriotColors.error.withOpacity(0.08),
                  borderRadius: ModernGriotRadius.borderXl,
                  border: Border.all(
                    color: past.wasCorrect
                        ? ModernGriotColors.secondary.withOpacity(0.2)
                        : ModernGriotColors.error.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(past.emojis, style: TextStyle(fontSize: 24.sp)),
                    SizedBox(height: 4.h),
                    Text(past.answer,
                        style: ModernGriotTypography.bodySmall(context: context),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                    Icon(
                      past.wasCorrect ? Icons.check_rounded : Icons.close_rounded,
                      size: 16.sp,
                      color: past.wasCorrect ? ModernGriotColors.secondary : ModernGriotColors.error,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultBanner(ColorScheme cs, _EmojiRiddle riddle) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isCorrect ? ModernGriotColors.secondary : ModernGriotColors.error,
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _isCorrect
                  ? 'Correct! You cracked the code.'
                  : 'The answer was: ${riddle.answer}',
              style: ModernGriotTypography.bodyMedium(context: context),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiRiddle {
  final String emojis;
  final String answer;
  final String hint;

  const _EmojiRiddle({
    required this.emojis,
    required this.answer,
    required this.hint,
  });
}

class _PastRiddle {
  final String emojis;
  final String answer;
  final bool wasCorrect;

  const _PastRiddle({
    required this.emojis,
    required this.answer,
    required this.wasCorrect,
  });
}
