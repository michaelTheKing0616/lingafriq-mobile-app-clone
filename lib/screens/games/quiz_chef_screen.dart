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

class QuizChefGame extends BaseGameScreen {
  const QuizChefGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.quizChef;

  @override
  ConsumerState<QuizChefGame> createState() => _QuizChefGameState();
}

class _QuizChefGameState extends BaseGameScreenState<QuizChefGame> {
  final List<_RecipeRound> _rounds = [];
  int _currentIndex = 0;
  int _verbsCollected = 0;
  int _nounsCollected = 0;
  int _adjectivesCollected = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;

  static const _maxRounds = 10;
  static const _verbGoal = 4;
  static const _nounGoal = 4;
  static const _adjGoal = 2;

  @override
  int getCardCount() => 10;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    final cards = gameProv.availableCards;
    _rounds.clear();

    final templates = _recipeTemplates(widget.language);
    final rng = Random();
    for (var i = 0; i < _maxRounds; i++) {
      final t = templates[i % templates.length];
      final options = List<String>.from(t.options)..shuffle(rng);
      _rounds.add(_RecipeRound(
        question: t.question,
        correctAnswer: t.correctAnswer,
        options: options,
        category: t.category,
        proverbTip: t.proverbTip,
        cardId: cards.isNotEmpty ? cards[i % cards.length].cardId : 'recipe_$i',
      ));
    }
    setState(() {});
  }

  Future<void> _selectAnswer(String answer) async {
    if (_showResult) return;
    HapticFeedback.mediumImpact();

    final round = _rounds[_currentIndex];
    final correct = answer == round.correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _isCorrect = correct;
      _showResult = true;
      if (correct) {
        switch (round.category) {
          case _WordCategory.verb:
            _verbsCollected++;
            break;
          case _WordCategory.noun:
            _nounsCollected++;
            break;
          case _WordCategory.adjective:
            _adjectivesCollected++;
            break;
        }
      }
    });

    await completeTurn(
      cardId: round.cardId,
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      confidence: correct ? 1.0 : 0.0,
      feedback: {
        'question': round.question,
        'selected': answer,
        'correct': round.correctAnswer,
        'category': round.category.name,
      },
    );

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    if (_currentIndex < _maxRounds - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
      });
    } else {
      finishGame();
    }
  }

  @override
  String? get appBarTitle =>
      isLoading ? null : 'Quiz Chef (${_currentIndex + 1}/$_maxRounds)';

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
          streak: 0,
          xp: (_verbsCollected + _nounsCollected + _adjectivesCollected) * 10,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              children: [
                _buildRecipeProgressCard(cs, isDark),
                SizedBox(height: 16.h),
                _buildQuestionCard(cs, isDark, round),
                SizedBox(height: 16.h),
                _buildIngredientOptions(cs, isDark, round),
                SizedBox(height: 16.h),
                GameCulturalNoteCard(
                  title: "Chef's Proverb",
                  body: round.proverbTip,
                  icon: Icons.restaurant_rounded,
                ),
                SizedBox(height: 16.h),
                _buildBottomActionBar(cs, isDark, round),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeProgressCard(ColorScheme cs, bool isDark) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 22.sp, color: ModernGriotColors.primary),
              SizedBox(width: 8.w),
              Text(
                'Recipe Progress',
                style: ModernGriotTypography.titleMedium(context: context).copyWith(
                  color: ModernGriotColors.primary,
                ),
              ),
              const Spacer(),
              _buildRecipeBookDecoration(),
            ],
          ),
          SizedBox(height: 12.h),
          _buildIngredientCounter(
            'Verbs',
            _verbsCollected,
            _verbGoal,
            ModernGriotColors.primary,
          ),
          SizedBox(height: 8.h),
          _buildIngredientCounter(
            'Nouns',
            _nounsCollected,
            _nounGoal,
            ModernGriotColors.secondary,
          ),
          SizedBox(height: 8.h),
          _buildIngredientCounter(
            'Adjectives',
            _adjectivesCollected,
            _adjGoal,
            ModernGriotColors.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeBookDecoration() {
    return Container(
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        color: ModernGriotColors.primaryContainer.withAlpha(30),
        borderRadius: ModernGriotRadius.borderMd,
      ),
      child: Icon(
        Icons.menu_book_rounded,
        size: 18.sp,
        color: ModernGriotColors.primaryContainer,
      ),
    );
  }

  Widget _buildIngredientCounter(String label, int current, int goal, Color color) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: ModernGriotTypography.labelMedium(context: context),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: ModernGriotRadius.borderPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '$current/$goal',
          style: ModernGriotTypography.labelLarge(context: context).copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(ColorScheme cs, bool isDark, _RecipeRound round) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ModernGriotColors.primaryContainer.withAlpha(20),
            ModernGriotColors.surface,
          ],
        ),
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.md,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _categoryColor(round.category).withAlpha(30),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Text(
              'Ingredient: ${round.category.label}',
              style: ModernGriotTypography.labelMedium(context: context).copyWith(
                color: _categoryColor(round.category),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Icon(Icons.soup_kitchen_rounded, size: 36.sp, color: ModernGriotColors.primary),
          SizedBox(height: 12.h),
          Text(
            round.question,
            style: ModernGriotTypography.titleLarge(context: context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientOptions(ColorScheme cs, bool isDark, _RecipeRound round) {
    final icons = [Icons.restaurant, Icons.local_dining, Icons.bakery_dining];

    return Column(
      children: List.generate(round.options.length, (i) {
        final option = round.options[i];
        final icon = icons[i % icons.length];

        GameOptionState state;
        if (!_showResult) {
          state = _selectedAnswer == option
              ? GameOptionState.selected
              : GameOptionState.idle;
        } else if (option == round.correctAnswer) {
          state = GameOptionState.correct;
        } else if (option == _selectedAnswer && !_isCorrect) {
          state = GameOptionState.wrong;
        } else {
          state = GameOptionState.idle;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: _IngredientCard(
            text: option,
            icon: icon,
            state: state,
            categoryColor: _categoryColor(round.category),
            onTap: _showResult ? null : () => _selectAnswer(option),
          ),
        );
      }),
    );
  }

  Widget _buildBottomActionBar(ColorScheme cs, bool isDark, _RecipeRound round) {
    return GriotGlassPanel(
      borderRadius: ModernGriotRadius.borderXl,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: GriotGradientButton(
              label: 'Add to Recipe',
              icon: Icons.add_rounded,
              onPressed: _showResult && _isCorrect
                  ? () {
                      if (_currentIndex < _maxRounds - 1) {
                        setState(() {
                          _currentIndex++;
                          _selectedAnswer = null;
                          _showResult = false;
                        });
                      } else {
                        finishGame();
                      }
                    }
                  : null,
            ),
          ),
          SizedBox(width: 12.w),
          GriotSecondaryButton(
            label: 'Skip',
            onPressed: () {
              HapticFeedback.lightImpact();
              completeTurn(
                cardId: round.cardId,
                result: GameResult.skipped,
                durationMs: 0,
                feedback: {'skipped': true},
              );
              if (_currentIndex < _maxRounds - 1) {
                setState(() {
                  _currentIndex++;
                  _selectedAnswer = null;
                  _showResult = false;
                });
              } else {
                finishGame();
              }
            },
          ),
        ],
      ),
    );
  }

  Color _categoryColor(_WordCategory cat) {
    switch (cat) {
      case _WordCategory.verb:
        return ModernGriotColors.primary;
      case _WordCategory.noun:
        return ModernGriotColors.secondary;
      case _WordCategory.adjective:
        return ModernGriotColors.tertiary;
    }
  }

  static List<_RecipeTemplate> _recipeTemplates(String language) {
    final lang = language.toLowerCase();
    if (lang == 'yoruba') {
      return const [
        _RecipeTemplate('Which word means "to cook"?', 'Se ounjẹ', ['Se ounjẹ', 'Je ounjẹ', 'Mu omi'], _WordCategory.verb, 'As the Yoruba say: "A kì í fi ojú ẹni rí oúnjẹ, kó o má jẹ ẹ́" — you cannot see food and not eat it.'),
        _RecipeTemplate('Select the noun for "yam":', 'Isu', ['Isu', 'Pupa', 'Dùn'], _WordCategory.noun, '"Isu" is the staple root crop central to Yoruba cuisine and the New Yam Festival.'),
        _RecipeTemplate('Which describes "spicy"?', 'Ata', ['Ata', 'Ẹran', 'Omi'], _WordCategory.adjective, 'Pepper (ata) defines the heat level — Yoruba soups are famous for bold, spicy flavors.'),
        _RecipeTemplate('What is the verb for "eat"?', 'Jẹ', ['Jẹ', 'Isu', 'Ẹfọ́'], _WordCategory.verb, '"Jẹun" combines "jẹ" (eat) and "oun" (thing) — a daily greeting can be "Ṣe o ti jẹun?"'),
        _RecipeTemplate('Choose the noun for "soup":', 'Ọbẹ̀', ['Ọbẹ̀', 'Sè', 'Gbona'], _WordCategory.noun, 'Ọbẹ̀ is the heart of every Yoruba meal — poured over pounded yam or amala.'),
        _RecipeTemplate('Which means "sweet"?', 'Dùn', ['Dùn', 'Jẹ', 'Omi'], _WordCategory.adjective, '"Ó dùn" — it is sweet. Yoruba tonal marks change meaning: dún (sweet) vs dùn (painful).'),
        _RecipeTemplate('The verb "to stir" is:', 'Pọn', ['Pọn', 'Ẹfọ́', 'Gbona'], _WordCategory.verb, 'Stirring (pọn) the pot requires patience — just like learning a new language.'),
        _RecipeTemplate('Select "palm oil":', 'Epo pupa', ['Epo pupa', 'Dùn', 'Pọn'], _WordCategory.noun, 'Red palm oil (epo pupa) gives Yoruba dishes their signature warm color.'),
        _RecipeTemplate('Which means "fresh"?', 'Tuntun', ['Tuntun', 'Isu', 'Sè'], _WordCategory.adjective, '"Tuntun" (fresh/new) — fresh ingredients make the best recipes and the best vocabulary!'),
        _RecipeTemplate('The verb "to taste" is:', 'Tọ́wò', ['Tọ́wò', 'Ọbẹ̀', 'Ata'], _WordCategory.verb, '"Tọ́wò ọbẹ̀" — taste the soup. A good cook always tastes before serving.'),
      ];
    } else if (lang == 'swahili') {
      return const [
        _RecipeTemplate('Which word means "to cook"?', 'Pika', ['Pika', 'Kula', 'Nyama'], _WordCategory.verb, '"Akipika, anaimba" — When she cooks, she sings. Cooking and song go together.'),
        _RecipeTemplate('Select the noun for "rice":', 'Wali', ['Wali', 'Tamu', 'Pika'], _WordCategory.noun, 'Wali is a coastal Swahili staple, often paired with coconut beans (maharage ya nazi).'),
        _RecipeTemplate('Which describes "delicious"?', 'Tamu', ['Tamu', 'Wali', 'Kula'], _WordCategory.adjective, '"Chakula kitamu" — delicious food. "Tamu" also means "sweet."'),
        _RecipeTemplate('What is the verb for "eat"?', 'Kula', ['Kula', 'Nyama', 'Pilipili'], _WordCategory.verb, '"Kula vizuri" — eat well. Greetings in Swahili often ask about meals.'),
        _RecipeTemplate('Choose the noun for "fish":', 'Samaki', ['Samaki', 'Pika', 'Tamu'], _WordCategory.noun, 'Samaki is a protein cornerstone along the East African coast and Lake Victoria.'),
        _RecipeTemplate('Which means "hot" (spicy)?', 'Kali', ['Kali', 'Samaki', 'Wali'], _WordCategory.adjective, '"Pilipili kali" — hot pepper. Swahili cuisine balances kali with coconut creaminess.'),
        _RecipeTemplate('The verb "to mix" is:', 'Changanya', ['Changanya', 'Nyanya', 'Chumvi'], _WordCategory.verb, '"Changanya viungo" — mix the spices. A great recipe is about balance.'),
        _RecipeTemplate('Select "coconut milk":', 'Nazi', ['Nazi', 'Kali', 'Pika'], _WordCategory.noun, 'Tui ya nazi (coconut milk) is the creamy base of many coastal Swahili dishes.'),
        _RecipeTemplate('Which means "fresh"?', 'Mbichi', ['Mbichi', 'Samaki', 'Changanya'], _WordCategory.adjective, '"Mbichi" — fresh/raw. "Matunda mbichi" means fresh fruits in Swahili markets.'),
        _RecipeTemplate('The verb "to boil" is:', 'Chemsha', ['Chemsha', 'Nazi', 'Tamu'], _WordCategory.verb, '"Chemsha maji" — boil water. The foundation of chai (tea) and many dishes.'),
      ];
    }
    return const [
      _RecipeTemplate('Which word is a cooking verb?', 'Simmer', ['Simmer', 'Spoon', 'Savory'], _WordCategory.verb, 'Patience while simmering builds depth — in both food and language learning.'),
      _RecipeTemplate('Select a food noun:', 'Plantain', ['Plantain', 'Roast', 'Spicy'], _WordCategory.noun, 'Plantain is a versatile staple across West and Central Africa.'),
      _RecipeTemplate('Which is a taste adjective?', 'Tangy', ['Tangy', 'Grill', 'Maize'], _WordCategory.adjective, 'Tangy flavors come from fermentation — a technique common across African cuisines.'),
      _RecipeTemplate('The verb for preparing food:', 'Chop', ['Chop', 'Pepper', 'Sweet'], _WordCategory.verb, 'Chopping is the first step — breaking big tasks into small pieces.'),
      _RecipeTemplate('Choose the grain noun:', 'Millet', ['Millet', 'Blend', 'Bitter'], _WordCategory.noun, 'Millet is one of the oldest cultivated grains in Africa — a superfood staple.'),
      _RecipeTemplate('Which describes texture?', 'Creamy', ['Creamy', 'Okra', 'Fry'], _WordCategory.adjective, 'Creamy textures in African cooking often come from groundnuts or coconut.'),
      _RecipeTemplate('Select a cooking verb:', 'Braise', ['Braise', 'Cassava', 'Sour'], _WordCategory.verb, 'Braising combines dry and wet heat — slow cooking for deep flavors.'),
      _RecipeTemplate('Which is a spice noun?', 'Turmeric', ['Turmeric', 'Steam', 'Mild'], _WordCategory.noun, 'Turmeric gives color and anti-inflammatory benefits to many African stews.'),
      _RecipeTemplate('Choose the flavor word:', 'Smoky', ['Smoky', 'Mortar', 'Stew'], _WordCategory.adjective, 'Smoky flavors come from cooking over open flames — a traditional method.'),
      _RecipeTemplate('The verb "to season" is:', 'Season', ['Season', 'Yam', 'Rich'], _WordCategory.verb, '"Season well" — the difference between bland and brilliant, in cooking and vocabulary.'),
    ];
  }
}

enum _WordCategory {
  verb('Verb'),
  noun('Noun'),
  adjective('Adjective');

  final String label;
  const _WordCategory(this.label);
}

class _RecipeRound {
  final String question;
  final String correctAnswer;
  final List<String> options;
  final _WordCategory category;
  final String proverbTip;
  final String cardId;

  const _RecipeRound({
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.category,
    required this.proverbTip,
    required this.cardId,
  });
}

class _RecipeTemplate {
  final String question;
  final String correctAnswer;
  final List<String> options;
  final _WordCategory category;
  final String proverbTip;

  const _RecipeTemplate(
    this.question,
    this.correctAnswer,
    this.options,
    this.category,
    this.proverbTip,
  );
}

class _IngredientCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final GameOptionState state;
  final Color categoryColor;
  final VoidCallback? onTap;

  const _IngredientCard({
    required this.text,
    required this.icon,
    required this.state,
    required this.categoryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bgColor;
    Color borderColor;
    Color fgColor;
    double borderWidth;

    switch (state) {
      case GameOptionState.idle:
        bgColor = cs.surfaceContainerLowest;
        borderColor = cs.outlineVariant;
        fgColor = cs.onSurface;
        borderWidth = 1;
        break;
      case GameOptionState.selected:
        bgColor = categoryColor.withAlpha(20);
        borderColor = categoryColor;
        fgColor = cs.onSurface;
        borderWidth = 2;
        break;
      case GameOptionState.correct:
        bgColor = ModernGriotColors.secondary.withAlpha(25);
        borderColor = ModernGriotColors.secondary;
        fgColor = ModernGriotColors.secondary;
        borderWidth = 2;
        break;
      case GameOptionState.wrong:
        bgColor = ModernGriotColors.error.withAlpha(25);
        borderColor = ModernGriotColors.error;
        fgColor = ModernGriotColors.error;
        borderWidth = 2;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: ModernGriotRadius.borderXl,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: state == GameOptionState.idle
              ? ModernGriotShadows.sm
              : const [],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(20),
                borderRadius: ModernGriotRadius.borderMd,
              ),
              child: Icon(icon, size: 22.sp, color: categoryColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: ModernGriotTypography.titleMedium(context: context).copyWith(
                  color: fgColor,
                ),
              ),
            ),
            if (state == GameOptionState.correct)
              Icon(Icons.check_circle_rounded, color: fgColor, size: 24.sp),
            if (state == GameOptionState.wrong)
              Icon(Icons.cancel_rounded, color: fgColor, size: 24.sp),
          ],
        ),
      ),
    );
  }
}
