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
import 'game_scenario_loader.dart';

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

    final scenarios = loadBundledGameScenarios(
      ref,
      language: widget.language,
      game: 'QuizChef',
      max: _maxRounds,
    );
    final rng = Random();

    if (scenarios.isNotEmpty) {
      for (var i = 0; i < _maxRounds; i++) {
        final scenario = scenarios[i % scenarios.length];
        final correct = (scenario.expectedResponse ?? scenario.prompt).trim();
        final distractors = scenarios
            .where((s) => s.id != scenario.id)
            .map((s) => (s.expectedResponse ?? s.prompt).trim())
            .where((text) => text.isNotEmpty && text != correct)
            .toSet()
            .take(3)
            .toList();
        final options = [correct, ...distractors];
        while (options.length < 4) {
          options.add('${scenario.title} (alt)');
        }
        options.shuffle(rng);
        _rounds.add(_RecipeRound(
          question: scenario.prompt,
          correctAnswer: correct,
          options: options.take(4).toList(),
          category: _categoryForIndex(i),
          proverbTip: scenario.culturalNote?.isNotEmpty == true
              ? scenario.culturalNote!
              : scenario.title,
          cardId: 'quiz_chef_${scenario.id}',
        ));
      }
    } else {
      final templates = _recipeTemplates(widget.language);
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
    }
    setState(() {});
  }

  static _WordCategory _categoryForIndex(int index) {
    switch (index % 3) {
      case 0:
        return _WordCategory.verb;
      case 1:
        return _WordCategory.noun;
      default:
        return _WordCategory.adjective;
    }
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
    } else if (lang == 'hausa') {
      return const [
        _RecipeTemplate('Which word means "to cook"?', 'Dafa', ['Dafa', 'Ruwa', 'Shinkafa'], _WordCategory.verb, '"Dafa abinci" — cook food. Hausa kitchens often center on one big pot and steady heat.'),
        _RecipeTemplate('Select the noun for "rice":', 'Shinkafa', ['Shinkafa', 'Miya', 'Yaji'], _WordCategory.noun, 'Shinkafa pairs with rich miya (soup) across the Sahel and savanna.'),
        _RecipeTemplate('Which describes "delicious"?', 'Mai dadi', ['Mai dadi', 'Ruwa', 'Barkono'], _WordCategory.adjective, '"Mai dadi" — tasty. A compliment cooks remember.'),
        _RecipeTemplate('What is the verb for "eat"?', 'Ci', ['Ci', 'Dafa', 'Miya'], _WordCategory.verb, '"Ci abinci" — eat food. Sharing a bowl is a sign of trust.'),
        _RecipeTemplate('Choose the noun for "soup":', 'Miya', ['Miya', 'Shinkafa', 'Ruwa'], _WordCategory.noun, 'Miya carries spices, oil, and meat — poured over grains or tuwo.'),
        _RecipeTemplate('Which means "pepper" (hot)?', 'Barkono', ['Barkono', 'Shinkafa', 'Ci'], _WordCategory.noun, 'Barkono brings heat; balance it with cooling sides.'),
        _RecipeTemplate('The verb "to wash (hands)" is:', 'Wanke', ['Wanke', 'Dafa', 'Miya'], _WordCategory.verb, '"Wanke hannaye" — wash hands before eating; hygiene is hospitality.'),
        _RecipeTemplate('Select "water":', 'Ruwa', ['Ruwa', 'Yaji', 'Shinkafa'], _WordCategory.noun, 'Ruwa is life — from the well to the pot.'),
        _RecipeTemplate('Which means "salt"?', 'Gishiri', ['Gishiri', 'Barkono', 'Miya'], _WordCategory.noun, 'Gishiri seasons gently; a little lifts every stew.'),
        _RecipeTemplate('The verb "to drink" is:', 'Sha', ['Sha', 'Ruwa', 'Ci'], _WordCategory.verb, '"Sha ruwa" — drink water. Hydration keeps the cook focused.'),
      ];
    } else if (lang == 'igbo') {
      return const [
        _RecipeTemplate('Which means "water"?', 'Mmiri', ['Mmiri', 'Nri', 'Ulo'], _WordCategory.noun, 'Mmiri starts every pot — from washing grains to finishing soup.'),
        _RecipeTemplate('Select the noun for "food":', 'Nri', ['Nri', 'Mmiri', 'Nna'], _WordCategory.noun, 'Nri is shared; bowls circle until everyone is full.'),
        _RecipeTemplate('Which means "thank you"?', 'Daalu', ['Daalu', 'Ndewo', 'Oma'], _WordCategory.verb, 'Say daalu after a good meal — gratitude seasons the next one.'),
        _RecipeTemplate('What means "hello"?', 'Ndewo', ['Ndewo', 'Nkita', 'Abali'], _WordCategory.verb, 'Ndewo opens the door; good food follows.'),
        _RecipeTemplate('Choose "mother":', 'Nne', ['Nne', 'Nna', 'Nwa'], _WordCategory.noun, 'Nne often guards the recipes that make a house a home.'),
        _RecipeTemplate('Which means "father"?', 'Nna', ['Nna', 'Nne', 'Ulo'], _WordCategory.noun, 'Nna brings kola; the table waits for everyone.'),
        _RecipeTemplate('The word for "house":', 'Ulo', ['Ulo', 'Mmiri', 'Nri'], _WordCategory.noun, 'Ulo is where steam, laughter, and aroma meet.'),
        _RecipeTemplate('Which means "good"?', 'Oma', ['Oma', 'Ojoo', 'Nta'], _WordCategory.adjective, 'When soup is oma, silence falls around the table.'),
        _RecipeTemplate('Select "friend":', 'Enyi', ['Enyi', 'Nri', 'Onwa'], _WordCategory.noun, 'Enyi shares seat and plate — chop no be solo work.'),
        _RecipeTemplate('Which means "yam"?', 'Ji', ['Ji', 'Ofe', 'Ose'], _WordCategory.noun, 'Ji anchors many feasts — roast, boil, or pound with pride.'),
      ];
    } else if (lang == 'pidgin') {
      return const [
        _RecipeTemplate('Which word means "food"?', 'Chop', ['Chop', 'Water', 'Padi'], _WordCategory.noun, '"Chop" — food you actually eat. If e sweet, you go know.'),
        _RecipeTemplate('Select the word for "to eat":', 'Chop', ['Chop', 'Fine', 'Waka'], _WordCategory.verb, '"I wan chop" — I want to eat. Straight to the point.'),
        _RecipeTemplate('Which describes "very good" (taste)?', 'Sweet', ['Sweet', 'Salty', 'Bitter'], _WordCategory.adjective, '"E sweet well well" — praise the cook!'),
        _RecipeTemplate('What is "water"?', 'Water', ['Water', 'Chop', 'Pepper'], _WordCategory.noun, 'Water no get enemy — especially for pepper soup.'),
        _RecipeTemplate('Choose "friend" (padi):', 'Padi', ['Padi', 'Chop', 'Wetin'], _WordCategory.noun, 'Good padi dey share chop, no be only gist.'),
        _RecipeTemplate('Which means "pepper" (hot)?', 'Pepper', ['Pepper', 'Salt', 'Oil'], _WordCategory.noun, 'Pepper fit humble you — respect am.'),
        _RecipeTemplate('The phrase "thank you" often:', 'Thank you', ['Thank you', 'Abeg', 'Wetin'], _WordCategory.verb, 'Politeness dey open doors — and second helpings.'),
        _RecipeTemplate('Select "palm oil":', 'Red oil', ['Red oil', 'Water', 'Salt'], _WordCategory.noun, 'Red oil dey give soup color wey you fit see from road.'),
        _RecipeTemplate('Which means "salt"?', 'Salt', ['Salt', 'Sugar', 'Pepper'], _WordCategory.noun, 'Salt small-small — no go overdo am.'),
        _RecipeTemplate('The verb "to go" (kitchen run):', 'Go', ['Go', 'Come', 'Stay'], _WordCategory.verb, '"Go market" — where ingredients become story.'),
      ];
    } else if (lang == 'zulu' || lang == 'isizulu') {
      return const [
        _RecipeTemplate('Which word means "to cook"?', 'Pheka', ['Pheka', 'Idla', 'Amanzi'], _WordCategory.verb, '"Pheka ukudla" — cook food. Zulu pots reward patience.'),
        _RecipeTemplate('Select the noun for "food":', 'Ukudla', ['Ukudla', 'Amanzi', 'Uthisha'], _WordCategory.noun, 'Ukudla is the meal — from pap to hearty stews.'),
        _RecipeTemplate('Which describes "delicious"?', 'Kumnandi', ['Kumnandi', 'Kubi', 'Mncane'], _WordCategory.adjective, '"Kumnandi" — tasty. The word people say with a full mouth.'),
        _RecipeTemplate('What is the verb for "eat"?', 'Idla', ['Idla', 'Pheka', 'Ukudla'], _WordCategory.verb, '"Idla kahle" — eat well. Hospitality is serious business.'),
        _RecipeTemplate('Choose the noun for "water":', 'Amanzi', ['Amanzi', 'Ukudla', 'Shisa'], _WordCategory.noun, 'Amanzi cools pepper heat and washes the day away.'),
        _RecipeTemplate('Which means "hot" (temperature)?', 'Shisa', ['Shisa', 'Banda', 'Ukudla'], _WordCategory.adjective, 'Shisa — when the pot is ready, you will know.'),
        _RecipeTemplate('The verb "to mix" is:', 'Hlanganisa', ['Hlanganisa', 'Pheka', 'Idla'], _WordCategory.verb, 'Mixing flavors is mixing cultures on one plate.'),
        _RecipeTemplate('Select "salt":', 'Usawoti', ['Usawoti', 'Amanzi', 'Shisa'], _WordCategory.noun, 'Usawoti balances — a pinch changes everything.'),
        _RecipeTemplate('Which means "cold"?', 'Banda', ['Banda', 'Shisa', 'Kumnandi'], _WordCategory.adjective, 'Banda drinks pair with spicy mains.'),
        _RecipeTemplate('The verb "to boil" is:', 'Bila', ['Bila', 'Idla', 'Amanzi'], _WordCategory.verb, 'Boiling clears and softens — the start of many stews.'),
      ];
    } else if (lang == 'xhosa' || lang == 'isixhosa') {
      return const [
        _RecipeTemplate('Which means "hello" (to one person)?', 'Molo', ['Molo', 'Enkosi', 'Amanzi'], _WordCategory.verb, 'Molo opens conversation — one respectful word at a time.'),
        _RecipeTemplate('Select "thank you":', 'Enkosi', ['Enkosi', 'Ukutya', 'Umhlobo'], _WordCategory.verb, 'Enkosi carries gratitude from the table to the teacher.'),
        _RecipeTemplate('Which means "water"?', 'Amanzi', ['Amanzi', 'Ukutya', 'Indlu'], _WordCategory.noun, 'Amanzi cools the throat after spice and work.'),
        _RecipeTemplate('Choose the noun for "food":', 'Ukutya', ['Ukutya', 'Incwadi', 'Isikolo'], _WordCategory.noun, 'Ukutya is shared; umndilili wentselo starts with what is on the plate.'),
        _RecipeTemplate('Which means "friend"?', 'Umhlobo', ['Umhlobo', 'Utitshala', 'Umfundi'], _WordCategory.noun, 'Friends pass dishes hand to hand.'),
        _RecipeTemplate('Select "house":', 'Indlu', ['Indlu', 'Umthi', 'Intaka'], _WordCategory.noun, 'Indlu is where steam, stories, and songs gather.'),
        _RecipeTemplate('Which means "teacher"?', 'Utitshala', ['Utitshala', 'Umntwana', 'Inja'], _WordCategory.noun, 'Utitshala shapes both language and manners.'),
        _RecipeTemplate('Choose "sun":', 'Ilanga', ['Ilanga', 'Inyanga', 'Ubusuku'], _WordCategory.noun, 'Ilanga dries maize and warms the courtyard.'),
        _RecipeTemplate('Which means "night"?', 'Ubusuku', ['Ubusuku', 'Imini', 'Ilanga'], _WordCategory.noun, 'Ubusuku is for rest — and for quiet study.'),
        _RecipeTemplate('Select "money":', 'Imali', ['Imali', 'Ikati', 'Inja'], _WordCategory.noun, 'Imali buys spice and books — invest both wisely.'),
      ];
    } else if (lang == 'amharic') {
      return const [
        _RecipeTemplate('Which means "hello" / peace?', 'ሰላም', ['ሰላም', 'ውሃ', 'ምግብ'], _WordCategory.verb, 'ሰላም is both greeting and wish — peace before the meal.'),
        _RecipeTemplate('Select "thank you":', 'አመሰግናለሁ', ['አመሰግናለሁ', 'ቤት', 'መጽሐፍ'], _WordCategory.verb, 'Gratitude in Amharic is full and formal — say it with eye contact.'),
        _RecipeTemplate('Which means "water"?', 'ውሃ', ['ውሃ', 'ምግብ', 'ጓደኛ'], _WordCategory.noun, 'ውሃ is life at altitude and in the kitchen.'),
        _RecipeTemplate('Choose "food":', 'ምግብ', ['ምግብ', 'ተማሪ', 'መምህር'], _WordCategory.noun, 'ምግብ carries spice routes and family recipes.'),
        _RecipeTemplate('Which means "house"?', 'ቤት', ['ቤት', 'ዛፍ', 'ወፍ'], _WordCategory.noun, 'ቤት is where injera lands hot from the mitad.'),
        _RecipeTemplate('Select "book":', 'መጽሐፍ', ['መጽሐፍ', 'ትምህርት ቤት', 'ልጅ'], _WordCategory.noun, 'መጽሐፍ holds grammar and gossip in careful balance.'),
        _RecipeTemplate('Which means "good"?', 'ጥሩ', ['ጥሩ', 'መጥፎ', 'ትንሽ'], _WordCategory.adjective, 'ጥሩ food needs no advertisement.'),
        _RecipeTemplate('Choose "sun":', 'ጸሐይ', ['ጸሐይ', 'ጨረቃ', 'ሌሊት'], _WordCategory.noun, 'ጸሐይ ripens berbere fields.'),
        _RecipeTemplate('Which means "night"?', 'ሌሊት', ['ሌሊት', 'ቀን', 'ኮከብ'], _WordCategory.noun, 'ሌሊት is for slow cooking and slow study.'),
        _RecipeTemplate('Select "money":', 'ገንዘብ', ['ገንዘብ', 'ውሻ', 'ድመት'], _WordCategory.noun, 'ገንዘብ feeds the market and the future.'),
      ];
    } else if (lang == 'twi' || lang == 'akan') {
      return const [
        _RecipeTemplate('Which means "thank you"?', 'Medaase', ['Medaase', 'Maakye', 'Nsuo'], _WordCategory.verb, 'Medaase closes the loop between host and guest.'),
        _RecipeTemplate('Select "water":', 'Nsuo', ['Nsuo', 'Aduane', 'Efie'], _WordCategory.noun, 'Nsuo washes hands and greens alike.'),
        _RecipeTemplate('Which means "food"?', 'Aduane', ['Aduane', 'Ɔdɔfo', 'Nwoma'], _WordCategory.noun, 'Aduane is fufu, stew, and the politics of the bowl.'),
        _RecipeTemplate('Choose "friend":', 'Ɔdɔfo', ['Ɔdɔfo', 'Maame', 'Agya'], _WordCategory.noun, 'Ɔdɔfo shares pepper and patience.'),
        _RecipeTemplate('Which means "house"?', 'Efie', ['Efie', 'Sukuu', 'Sika'], _WordCategory.noun, 'Efie is where the pestle meets the mortar.'),
        _RecipeTemplate('Select "good":', 'Pa', ['Pa', 'Bone', 'Kakra'], _WordCategory.adjective, 'Pa soup needs time and trust.'),
        _RecipeTemplate('Which means "sun"?', 'Awia', ['Awia', 'Bosome', 'Anadwo'], _WordCategory.noun, 'Awia sets the rhythm of market and farm.'),
        _RecipeTemplate('Choose "night":', 'Anadwo', ['Anadwo', 'Da', 'Nsoromma'], _WordCategory.noun, 'Anadwo holds stories and leftover stew.'),
        _RecipeTemplate('Which means "money"?', 'Sika', ['Sika', 'Kraman', 'Kɔtɔ'], _WordCategory.noun, 'Sika buys ingredients — wisdom seasons them.'),
        _RecipeTemplate('Select "mother":', 'Maame', ['Maame', 'Agya', 'Abɔfra'], _WordCategory.noun, 'Maame often guards the recipes that define home.'),
      ];
    } else if (lang == 'wolof') {
      return const [
        _RecipeTemplate('Which means "how are you"?', 'Nanga def', ['Nanga def', 'Jërëjëf', 'Ndox'], _WordCategory.verb, 'Nanga def starts every kitchen visit with respect.'),
        _RecipeTemplate('Select "thank you":', 'Jërëjëf', ['Jërëjëf', 'Ceeb', 'Xarit'], _WordCategory.verb, 'Jërëjëf is gratitude you can hear across the room.'),
        _RecipeTemplate('Which means "water"?', 'Ndox', ['Ndox', 'Kër', 'Téere'], _WordCategory.noun, 'Ndox cools thieb and tempers spice.'),
        _RecipeTemplate('Choose "rice / meal":', 'Ceeb', ['Ceeb', 'Xaj', 'Mus'], _WordCategory.noun, 'Ceeb bu jën is a coastal classic — rice and fish in harmony.'),
        _RecipeTemplate('Which means "friend"?', 'Xarit', ['Xarit', 'Jàngalekat', 'Jàngkat'], _WordCategory.noun, 'Xarit shares bowl and burden.'),
        _RecipeTemplate('Select "house":', 'Kër', ['Kër', 'Daara', 'Xaalis'], _WordCategory.noun, 'Kër is where attaya is poured three times.'),
        _RecipeTemplate('Which means "good"?', 'Baax', ['Baax', 'Bon', 'Tuuti'], _WordCategory.adjective, 'Baax food needs no filter.'),
        _RecipeTemplate('Choose "sun":', 'Naaj', ['Naaj', 'Weer', 'Ñaar'], _WordCategory.noun, 'Naaj dries fish and brightens the marché.'),
        _RecipeTemplate('Which means "night"?', 'Guddi', ['Guddi', 'Bes', 'Garab'], _WordCategory.noun, 'Guddi is for attaya after the heat.'),
        _RecipeTemplate('Select "money":', 'Xaalis', ['Xaalis', 'Páxi', 'Xaj'], _WordCategory.noun, 'Xaalis buys millet and mercy in careful measure.'),
      ];
    } else if (lang == 'afrikaans') {
      return const [
        _RecipeTemplate('Which means "hello"?', 'Hallo', ['Hallo', 'Dankie', 'Water'], _WordCategory.verb, 'Hallo in the kitchen means sleeves up.'),
        _RecipeTemplate('Select "thank you":', 'Dankie', ['Dankie', 'Kos', 'Vriend'], _WordCategory.verb, 'Dankie after a braai is non-negotiable.'),
        _RecipeTemplate('Which means "food"?', 'Kos', ['Kos', 'Huis', 'Skool'], _WordCategory.noun, 'Kos spans potjie pots and melktert alike.'),
        _RecipeTemplate('Choose "water":', 'Water', ['Water', 'Warm', 'Koud'], _WordCategory.noun, 'Water hydrates boerewors makers and beginners alike.'),
        _RecipeTemplate('Which means "friend"?', 'Vriend', ['Vriend', 'Ma', 'Pa'], _WordCategory.noun, 'Vriend shares braai tongs and playlists.'),
        _RecipeTemplate('Select "house":', 'Huis', ['Huis', 'Boom', 'Voël'], _WordCategory.noun, 'Huis is where beskuit crumbs are forgiven.'),
        _RecipeTemplate('Which means "good"?', 'Goed', ['Goed', 'Sleg', 'Klein'], _WordCategory.adjective, 'Goed kos needs patience and fire control.'),
        _RecipeTemplate('Choose "sun":', 'Son', ['Son', 'Maan', 'Ster'], _WordCategory.noun, 'Son sets the braai clock across the Karoo.'),
        _RecipeTemplate('Which means "night"?', 'Nag', ['Nag', 'Dag', 'Geld'], _WordCategory.noun, 'Nag is for potjie leftovers and slow stories.'),
        _RecipeTemplate('Select "money":', 'Geld', ['Geld', 'Hond', 'Kat'], _WordCategory.noun, 'Geld buys wood and wors — wisdom chooses the cut.'),
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
