import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/game/game_session_model.dart';
import '../../../providers/game_content_provider.dart';
import '../../../models/game/game_content_models.dart';
import '../../../utils/modern_griot_design_system.dart';
import '../../../widgets/griot/griot_widgets.dart';
import '../../../widgets/game/game_widgets.dart';
import '../base_game_screen.dart';

/// Proverb Unlocker — fill-in-the-blank ancestral tablet UI.
class ProverbUnlockerGame extends BaseGameScreen {
  const ProverbUnlockerGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.proverbUnlocker;

  @override
  ConsumerState<ProverbUnlockerGame> createState() =>
      _ProverbUnlockerGameState();
}

class _ProverbUnlockerGameState
    extends BaseGameScreenState<ProverbUnlockerGame> {
  List<GameProverb> _proverbs = [];
  int _currentIndex = 0;
  List<String> _proverbWords = [];
  List<int> _blankIndices = [];
  Map<int, String> _filledBlanks = {};
  List<String> _tokenOptions = [];
  Set<String> _usedTokens = {};
  String _culturalNote = '';
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  int getCardCount() => 6;

  @override
  Future<void> onGameInitialized() async {
    final loaded = ref.read(
      gameProverbsProvider(GameContentFilter(language: widget.language)),
    );
    if (loaded.isNotEmpty) {
      _proverbs = List.of(loaded)..shuffle(Random());
      if (_proverbs.length > 6) _proverbs = _proverbs.sublist(0, 6);
    } else {
      _proverbs = _fallbackProverbs();
    }
    _prepareRound();
  }

  List<GameProverb> _fallbackProverbs() => [
        const GameProverb(
            id: 1,
            language: 'Yoruba',
            original: 'Agbara eniyan ju ti eranko lo',
            translation: 'Human strength surpasses that of animals',
            meaning: 'Unity and intelligence overcome brute force',
            cefr: 'A1'),
        const GameProverb(
            id: 2,
            language: 'Swahili',
            original: 'Haraka haraka haina baraka',
            translation: 'Hurry hurry has no blessing',
            meaning: 'Patience leads to better outcomes',
            cefr: 'A1'),
        const GameProverb(
            id: 3,
            language: 'Zulu',
            original: 'Umuntu ngumuntu ngabantu',
            translation: 'A person is a person through people',
            meaning: 'Humanity is defined by community',
            cefr: 'A1'),
        const GameProverb(
            id: 4,
            language: 'Igbo',
            original: 'Onye aghana nwanne ya',
            translation: "Be your brother's keeper",
            meaning: 'Look after each other always',
            cefr: 'A1'),
        const GameProverb(
            id: 5,
            language: 'Xhosa',
            original: 'Umntu ngumntu ngabantu',
            translation: 'I am because we are',
            meaning: 'Individual identity is rooted in collective belonging',
            cefr: 'A1'),
        const GameProverb(
            id: 6,
            language: 'Amharic',
            original: 'Sew besew yinoralal',
            translation: 'People live through people',
            meaning: 'Community support sustains life',
            cefr: 'A1'),
      ];

  void _prepareRound() {
    if (_currentIndex >= _proverbs.length) {
      finishGame();
      return;
    }
    final proverb = _proverbs[_currentIndex];
    final words = proverb.original.split(' ');
    final rng = Random();

    final blankCount = (words.length > 5) ? 2 : 1;
    final blanks = <int>{};
    while (blanks.length < blankCount && blanks.length < words.length) {
      blanks.add(rng.nextInt(words.length));
    }

    final correctTokens = blanks.map((i) => words[i]).toList();
    final distractors = <String>[];
    for (final p in _proverbs) {
      for (final w in p.original.split(' ')) {
        if (!correctTokens.contains(w) && !distractors.contains(w)) {
          distractors.add(w);
        }
        if (distractors.length >= 5 - correctTokens.length) break;
      }
      if (distractors.length >= 5 - correctTokens.length) break;
    }
    while (distractors.length + correctTokens.length < 5) {
      distractors.add('word${distractors.length}');
    }

    final allTokens = [
      ...correctTokens,
      ...distractors.take(5 - correctTokens.length)
    ]..shuffle(rng);

    setState(() {
      _proverbWords = words;
      _blankIndices = blanks.toList()..sort();
      _filledBlanks = {};
      _tokenOptions = allTokens;
      _usedTokens = {};
      _showResult = false;
      _isCorrect = false;
      _culturalNote = proverb.meaning ?? proverb.translation;
    });
  }

  void _tapToken(String token) {
    if (_showResult || _usedTokens.contains(token)) return;
    HapticFeedback.selectionClick();
    final nextBlank = _blankIndices.firstWhere(
      (i) => !_filledBlanks.containsKey(i),
      orElse: () => -1,
    );
    if (nextBlank < 0) return;
    setState(() {
      _filledBlanks[nextBlank] = token;
      _usedTokens.add(token);
    });
  }

  void _tapFilledBlank(int index) {
    if (_showResult) return;
    final token = _filledBlanks[index];
    if (token == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _filledBlanks.remove(index);
      _usedTokens.remove(token);
    });
  }

  void _unlockWisdom() {
    if (_filledBlanks.length < _blankIndices.length) return;
    HapticFeedback.mediumImpact();
    final correct = _blankIndices.every(
      (i) => _filledBlanks[i] == _proverbWords[i],
    );

    setState(() {
      _showResult = true;
      _isCorrect = correct;
    });

    completeTurn(
      cardId: 'proverb_$_currentIndex',
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {
        'filled': _filledBlanks.map((k, v) => MapEntry(k.toString(), v)),
        'expected': {
          for (final i in _blankIndices) i.toString(): _proverbWords[i]
        },
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _currentIndex++;
      _prepareRound();
    });
  }

  @override
  String? get appBarTitle => 'Proverb Unlocker';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_proverbs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 24.h),
          children: [
            _ancestralTablet(cs),
            SizedBox(height: 20.h),
            _wisdomTokens(cs),
            SizedBox(height: 24.h),
            GriotGradientButton(
              label: 'Unlock Wisdom',
              icon: Icons.lock_open_rounded,
              onPressed:
                  _filledBlanks.length == _blankIndices.length && !_showResult
                      ? _unlockWisdom
                      : null,
            ),
            SizedBox(height: 20.h),
            GameCulturalNoteCard(
              title: "Griot's Insight",
              body: _culturalNote,
            ),
            if (_showResult) ...[
              SizedBox(height: 16.h),
              _resultBanner(cs),
            ],
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: _currentIndex + 1,
            totalSteps: _proverbs.length,
          ),
        ),
      ],
    );
  }

  Widget _ancestralTablet(ColorScheme cs) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD4A574), Color(0xFFB8956A)],
          ),
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.lg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 36.sp, color: const Color(0xFFFFD700).withOpacity(0.6)),
            SizedBox(height: 16.h),
            Text(
              'Ancestral Proverb',
              style: ModernGriotTypography.titleMedium(
                  context: context, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6.w,
                  runSpacing: 12.h,
                  children: List.generate(_proverbWords.length, (i) {
                    if (_blankIndices.contains(i)) {
                      final filled = _filledBlanks[i];
                      final showCorrectSlot = _showResult &&
                          filled != null &&
                          filled == _proverbWords[i];
                      final showWrongSlot = _showResult &&
                          filled != null &&
                          filled != _proverbWords[i];
                      return GestureDetector(
                        onTap: () => _tapFilledBlank(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          constraints: BoxConstraints(minWidth: 60.w),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: showCorrectSlot
                                ? ModernGriotColors.secondary.withOpacity(0.3)
                                : showWrongSlot
                                    ? ModernGriotColors.error.withOpacity(0.3)
                                    : filled != null
                                        ? Colors.white.withOpacity(0.25)
                                        : Colors.white.withOpacity(0.1),
                            borderRadius: ModernGriotRadius.borderSm,
                            border: Border(
                              bottom: BorderSide(
                                color: showCorrectSlot
                                    ? ModernGriotColors.secondary
                                    : showWrongSlot
                                        ? ModernGriotColors.error
                                        : const Color(0xFFFFD700),
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            filled ?? '___',
                            textAlign: TextAlign.center,
                            style: ModernGriotTypography.bodyLarge(
                              context: context,
                              color: filled != null
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        _proverbWords[i],
                        style: ModernGriotTypography.bodyLarge(
                            context: context, color: Colors.white),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            if (_proverbs.isNotEmpty && _currentIndex < _proverbs.length)
              Text(
                _proverbs[_currentIndex].translation,
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(
                  context: context,
                  color: Colors.white.withOpacity(0.65),
                ).copyWith(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wisdomTokens(ColorScheme cs) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10.w,
      runSpacing: 10.h,
      children: _tokenOptions.map((token) {
        final used = _usedTokens.contains(token);
        return GestureDetector(
          onTap: () => _tapToken(token),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: used ? 0.35 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: used
                    ? cs.surfaceContainerHigh
                    : ModernGriotColors.primaryContainer.withOpacity(0.2),
                borderRadius: ModernGriotRadius.borderPill,
                border: Border.all(
                  color: used
                      ? cs.outlineVariant.withOpacity(0.2)
                      : ModernGriotColors.primaryContainer,
                  width: 1.5,
                ),
                boxShadow: used ? null : ModernGriotShadows.sm,
              ),
              child: Text(
                token,
                style: ModernGriotTypography.labelLarge(
                  context: context,
                  color: used
                      ? ModernGriotColors.onSurfaceVariant
                      : ModernGriotColors.primary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _resultBanner(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isCorrect
                ? ModernGriotColors.secondary
                : ModernGriotColors.error,
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _isCorrect
                  ? 'Wisdom unlocked! The ancestors speak through you.'
                  : 'Not quite — the correct words were: ${_blankIndices.map((i) => _proverbWords[i]).join(", ")}',
              style: ModernGriotTypography.bodyMedium(context: context),
            ),
          ),
        ],
      ),
    );
  }
}
