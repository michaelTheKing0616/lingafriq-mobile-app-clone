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

class GrammarJamGame extends BaseGameScreen {
  const GrammarJamGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.grammarJam;

  @override
  ConsumerState<GrammarJamGame> createState() => _GrammarJamGameState();
}

class _GrammarJamGameState extends BaseGameScreenState<GrammarJamGame> {
  final List<_GrammarRound> _rounds = [];
  int _currentIndex = 0;
  int _streak = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  Timer? _timer;
  int _timeRemaining = 15;
  double _pulseValue = 0.0;
  Timer? _pulseTimer;

  static const _maxRounds = 10;
  static const _roundDuration = 15;

  @override
  int getCardCount() => 10;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    final cards = gameProv.availableCards;

    _rounds.clear();
    final rng = Random();
    final lang = widget.language.toLowerCase();
    final drills = ref.read(
      grammarDrillsProvider(
        GameContentFilter(language: lang, game: 'GrammarJam'),
      ),
    );

    if (drills.isNotEmpty) {
      final pool = List.of(drills)..shuffle(rng);
      for (var i = 0; i < _maxRounds; i++) {
        final d = pool[i % pool.length];
        final options = List<String>.from(d.options)..shuffle(rng);
        _rounds.add(_GrammarRound(
          phrase: d.phrase,
          correctAnswer: d.correct,
          options: options,
          tip: d.tip,
          cardId: cards.isNotEmpty ? cards[i % cards.length].cardId : 'grammar_$i',
        ));
      }
    } else {
      final templates = _grammarTemplates(widget.language);
      for (var i = 0; i < _maxRounds; i++) {
        final template = templates[i % templates.length];
        final options = List<String>.from(template.options)..shuffle(rng);
        _rounds.add(_GrammarRound(
          phrase: template.phrase,
          correctAnswer: template.correctAnswer,
          options: options,
          tip: template.tip,
          cardId: cards.isNotEmpty ? cards[i % cards.length].cardId : 'grammar_$i',
        ));
      }
    }

    _startRound();
    _startPulse();
    setState(() {});
  }

  void _startRound() {
    _timeRemaining = _roundDuration;
    _selectedAnswer = null;
    _showResult = false;
    _isCorrect = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timeRemaining--);
      if (_timeRemaining <= 0) {
        t.cancel();
        _handleTimeout();
      }
    });
  }

  void _startPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted) return;
      setState(() {
        _pulseValue += 0.05;
        if (_pulseValue > 2 * pi) _pulseValue -= 2 * pi;
      });
    });
  }

  void _handleTimeout() {
    if (_showResult) return;
    _selectAnswer(null);
  }

  Future<void> _selectAnswer(String? answer) async {
    if (_showResult) return;
    _timer?.cancel();
    HapticFeedback.mediumImpact();

    final round = _rounds[_currentIndex];
    final correct = answer == round.correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _isCorrect = correct;
      _showResult = true;
      if (correct) {
        _streak++;
        _score++;
      } else {
        _streak = 0;
      }
    });

    await completeTurn(
      cardId: round.cardId,
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: (_roundDuration - _timeRemaining) * 1000,
      confidence: correct ? 1.0 : 0.0,
      feedback: {
        'phrase': round.phrase,
        'selected': answer,
        'correct': round.correctAnswer,
        'streak': _streak,
      },
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (_currentIndex < _maxRounds - 1) {
      setState(() {
        _currentIndex++;
        _startRound();
      });
    } else {
      finishGame();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  @override
  String? get appBarTitle =>
      isLoading ? null : 'Grammar Jam (${_currentIndex + 1}/$_maxRounds)';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_rounds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final round = _rounds[_currentIndex];

    return Column(
      children: [
        GameTopBar(
          onClose: () {
            HapticFeedback.lightImpact();
            (widget.onBack ?? () => Navigator.pop(context))();
          },
          currentStep: _currentIndex + 1,
          totalSteps: _maxRounds,
          streak: _streak,
          xp: _score * 10,
        ),
        _buildRhythmRiverPanel(cs, isDark, round),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              children: [
                _buildQuestionArea(cs, isDark, round),
                SizedBox(height: 12.h),
                _buildBeatTarget(cs),
                SizedBox(height: 16.h),
                _buildOptionGrid(cs, isDark, round),
                SizedBox(height: 16.h),
                GameCulturalNoteCard(
                  title: "Elder's Advice",
                  body: round.tip,
                  icon: Icons.music_note_rounded,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRhythmRiverPanel(ColorScheme cs, bool isDark, _GrammarRound round) {
    return Container(
      width: double.infinity,
      height: 80.h,
      decoration: BoxDecoration(
        color: ModernGriotColors.primary,
        boxShadow: ModernGriotShadows.md,
      ),
      child: Stack(
        children: [
          // Staff lines
          ...List.generate(4, (i) {
            final y = 16.0 + i * 16.0;
            return Positioned(
              left: 0,
              right: 0,
              top: y.h,
              child: Container(height: 1, color: Colors.white.withAlpha(30)),
            );
          }),
          // Floating phrase cards drifting across
          ..._buildFloatingPhrases(round),
          // Pulse bars on the sides
          Positioned(
            left: 8.w,
            top: 10.h,
            bottom: 10.h,
            child: _buildPulseBar(true),
          ),
          Positioned(
            right: 8.w,
            top: 10.h,
            bottom: 10.h,
            child: _buildPulseBar(false),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingPhrases(_GrammarRound round) {
    final words = round.phrase.split(' ');
    final rng = Random(round.phrase.hashCode);
    return List.generate(min(words.length, 4), (i) {
      final left = (rng.nextDouble() * 0.7 + 0.05);
      final top = (rng.nextDouble() * 0.5 + 0.15);
      return Positioned(
        left: left * 300.w,
        top: top * 60.h,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: ModernGriotColors.primaryContainer.withAlpha(60),
            borderRadius: ModernGriotRadius.borderSm,
          ),
          child: Text(
            words[i],
            style: ModernGriotTypography.labelSmall(context: context).copyWith(
              color: ModernGriotColors.onPrimary,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPulseBar(bool isLeft) {
    final intensity = (sin(_pulseValue * (isLeft ? 1.0 : 1.3)) + 1) / 2;
    return Container(
      width: 4.w,
      decoration: BoxDecoration(
        borderRadius: ModernGriotRadius.borderPill,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ModernGriotColors.primaryContainer.withAlpha((intensity * 200).toInt()),
            ModernGriotColors.onPrimary.withAlpha((intensity * 100).toInt()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionArea(ColorScheme cs, bool isDark, _GrammarRound round) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark
            ? ModernGriotColorsDark.surfaceContainerHigh
            : ModernGriotColors.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Column(
        children: [
          Text(
            round.phrase,
            style: ModernGriotTypography.titleLarge(context: context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          if (_streak > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ModernGriotColors.primaryContainer.withAlpha(40),
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Text(
                '$_streak Streak!',
                style: ModernGriotTypography.labelLarge(context: context).copyWith(
                  color: ModernGriotColors.primaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBeatTarget(ColorScheme cs) {
    final pulse = (sin(_pulseValue * 2) + 1) / 2;
    final size = 48.0 + pulse * 8.0;
    final timerFraction = _timeRemaining / _roundDuration;
    final timerColor = _timeRemaining <= 5
        ? ModernGriotColors.error
        : ModernGriotColors.primary;

    return SizedBox(
      height: 64.h,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 56.r,
              height: 56.r,
              child: CircularProgressIndicator(
                value: timerFraction,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(timerColor),
                backgroundColor: timerColor.withAlpha(30),
              ),
            ),
            Container(
              width: size.r,
              height: size.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ModernGriotColors.primary.withAlpha(40 + (pulse * 30).toInt()),
                border: Border.all(
                  color: ModernGriotColors.primary.withAlpha(120),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$_timeRemaining',
                  style: ModernGriotTypography.titleMedium(context: context).copyWith(
                    color: timerColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGrid(ColorScheme cs, bool isDark, _GrammarRound round) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 2.2,
      children: round.options.map((option) {
        GameOptionState state;
        if (!_showResult) {
          state = GameOptionState.idle;
        } else if (option == round.correctAnswer) {
          state = GameOptionState.correct;
        } else if (option == _selectedAnswer && !_isCorrect) {
          state = GameOptionState.wrong;
        } else {
          state = GameOptionState.idle;
        }

        return GameOptionButton(
          label: option,
          state: state,
          onTap: _showResult ? null : () => _selectAnswer(option),
        );
      }).toList(),
    );
  }

  static List<_GrammarTemplate> _grammarTemplates(String language) {
    final lang = language.toLowerCase();
    if (lang == 'yoruba') {
      return const [
        _GrammarTemplate('Mo ___ lo si ile-iwe.', 'n', ['n', 'ti', 'ma', 'ko'], 'Present continuous in Yoruba uses "n" before the verb.'),
        _GrammarTemplate('O ___ jeun?', 'ti', ['ti', 'n', 'yoo', 'ma'], '"Ti" marks the past tense — "Have you eaten?"'),
        _GrammarTemplate('A ___ lo ni ola.', 'yoo', ['yoo', 'ti', 'n', 'ko'], '"Yoo" indicates future tense in Yoruba.'),
        _GrammarTemplate('Emi ___ omo ile Yoruba.', 'ni', ['ni', 'si', 'ti', 'ko'], '"Ni" functions as "am/is" in identity statements.'),
        _GrammarTemplate('Won ___ wa nibi.', 'ko', ['ko', 'n', 'ti', 'yoo'], '"Ko" is the negation marker in Yoruba.'),
        _GrammarTemplate('Ojo ___ dara loni.', 'ko', ['ko', 'ti', 'n', 'ni'], 'Negative weather statements use "ko" before the adjective.'),
        _GrammarTemplate('Se o ___ mo?', 'mo', ['mo', 'ri', 'ti', 'le'], '"Mo" means "know" — asking "Do you know?"'),
        _GrammarTemplate('Mo fe ___ omi.', 'mu', ['mu', 'je', 'lo', 'wa'], '"Mu" means "drink" — paired with "fe" (want).'),
        _GrammarTemplate('E ___ mi lowo.', 'ran', ['ran', 'fun', 'ba', 'fi'], '"Ran...lowo" means "help me" in Yoruba.'),
        _GrammarTemplate('Ile ___ tobi.', 'naa', ['naa', 'yi', 'yen', 'kan'], '"Naa" is a definite article — "The house is big."'),
      ];
    } else if (lang == 'swahili') {
      return const [
        _GrammarTemplate('Nina ___ Kiswahili.', 'soma', ['soma', 'kula', 'lala', 'pika'], '"Soma" means "study/read" — "I am studying Swahili."'),
        _GrammarTemplate('Yeye ___ mwalimu.', 'ni', ['ni', 'si', 'ana', 'ali'], '"Ni" is the copula "is" in Swahili.'),
        _GrammarTemplate('Tuta ___ kesho.', 'enda', ['enda', 'kuja', 'soma', 'lala'], '"Tuta" + verb = future tense — "We will go tomorrow."'),
        _GrammarTemplate('Hawa ___ wanafunzi.', 'si', ['si', 'ni', 'wana', 'wali'], '"Si" is the negative copula — "They are not students."'),
        _GrammarTemplate('Nili ___ jana.', 'fika', ['fika', 'enda', 'kula', 'soma'], 'Past tense: "Nili" + verb — "I arrived yesterday."'),
        _GrammarTemplate('Ana ___ sasa.', 'pika', ['pika', 'soma', 'lala', 'enda'], '"Ana" marks present continuous — "She is cooking now."'),
        _GrammarTemplate('M ___ mkubwa.', 'ti', ['ti', 'zi', 'ki', 'vi'], 'M-/Wa- noun class for people — "The tree is big."'),
        _GrammarTemplate('Watoto wana ___ shuleni.', 'enda', ['enda', 'kuja', 'soma', 'lala'], '"Wana" + verb = present tense for Wa- class.'),
        _GrammarTemplate('Sina ___ ya kutosha.', 'pesa', ['pesa', 'maji', 'nyumba', 'gari'], '"Sina" = "I don\'t have" — vocabulary in context.'),
        _GrammarTemplate('Nyumba ___ nzuri.', 'hii', ['hii', 'ile', 'hiyo', 'hizo'], '"Hii" is proximal demonstrative for N- class.'),
      ];
    }
    return const [
      _GrammarTemplate('I ___ learning every day.', 'am', ['am', 'is', 'are', 'was'], '"Am" pairs with "I" for present continuous.'),
      _GrammarTemplate('She ___ to the market.', 'goes', ['goes', 'go', 'gone', 'going'], 'Third-person singular uses "-es" suffix.'),
      _GrammarTemplate('They ___ arrived yet.', "haven't", ["haven't", "hasn't", "didn't", "won't"], 'Present perfect negative with "they" uses "haven\'t".'),
      _GrammarTemplate('We ___ study tomorrow.', 'will', ['will', 'are', 'have', 'did'], '"Will" marks simple future tense.'),
      _GrammarTemplate('The book ___ on the table.', 'is', ['is', 'are', 'am', 'be'], 'Singular subject "book" takes "is".'),
      _GrammarTemplate('He ___ been waiting.', 'has', ['has', 'have', 'had', 'is'], 'Present perfect continuous with "he" uses "has".'),
      _GrammarTemplate('___ you like some tea?', 'Would', ['Would', 'Will', 'Do', 'Are'], '"Would" is used for polite offers.'),
      _GrammarTemplate('She speaks ___ than him.', 'better', ['better', 'good', 'best', 'well'], 'Comparative form of "well" is "better".'),
      _GrammarTemplate('Neither rain ___ snow stops us.', 'nor', ['nor', 'or', 'and', 'but'], '"Neither...nor" is the correct correlative pair.'),
      _GrammarTemplate('I wish I ___ there.', 'were', ['were', 'was', 'am', 'be'], 'Subjunctive mood uses "were" for all persons.'),
    ];
  }
}

class _GrammarRound {
  final String phrase;
  final String correctAnswer;
  final List<String> options;
  final String tip;
  final String cardId;

  const _GrammarRound({
    required this.phrase,
    required this.correctAnswer,
    required this.options,
    required this.tip,
    required this.cardId,
  });
}

class _GrammarTemplate {
  final String phrase;
  final String correctAnswer;
  final List<String> options;
  final String tip;

  const _GrammarTemplate(this.phrase, this.correctAnswer, this.options, this.tip);
}
