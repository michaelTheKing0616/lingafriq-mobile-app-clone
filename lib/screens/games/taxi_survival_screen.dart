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

class TaxiSurvivalGame extends BaseGameScreen {
  const TaxiSurvivalGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.taxiBusStopSurvival;

  @override
  ConsumerState<TaxiSurvivalGame> createState() => _TaxiSurvivalGameState();
}

class _TaxiSurvivalGameState extends BaseGameScreenState<TaxiSurvivalGame> {
  List<_PhraseScramble> _puzzles = [];
  int _currentIndex = 0;
  List<String> _targetSlots = [];
  List<String?> _filledSlots = [];
  List<String> _wordBank = [];
  Set<int> _usedBankIndices = {};
  bool _showResult = false;
  bool _isCorrect = false;
  String _scenarioText = '';
  String _conductorSpeech = '';
  String _culturalNote = '';

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    final loaded = ref.read(
      gameScenariosProvider(GameContentFilter(
        language: widget.language,
        game: 'TaxiSurvival',
      )),
    );
    if (loaded.isNotEmpty) {
      final scenarios = List.of(loaded)..shuffle(Random());
      _puzzles = scenarios.take(5).map((s) => _PhraseScramble(
        scenario: s.title,
        conductorLine: s.prompt,
        targetPhrase: (s.expectedResponse ?? s.prompt).split(' '),
        culturalNote: s.culturalNote ?? 'Know key transport phrases before traveling.',
      )).toList();
    } else {
      _puzzles = _fallbackPuzzles();
    }
    _prepareRound();
  }

  List<_PhraseScramble> _fallbackPuzzles() => [
        _PhraseScramble(scenario: 'Boarding the Taxi', conductorLine: 'Wapi unaenda?', targetPhrase: ['Nataka', 'kwenda', 'sokoni'], culturalNote: 'State your destination clearly before boarding.'),
        _PhraseScramble(scenario: 'Paying the Fare', conductorLine: 'Nauli ni ngapi?', targetPhrase: ['Bei', 'gani', 'kwa', 'safari'], culturalNote: 'Negotiate fare before the journey starts.'),
        _PhraseScramble(scenario: 'Finding the Route', conductorLine: 'Gari ya wapi?', targetPhrase: ['Ninahitaji', 'basi', 'la', 'Dar'], culturalNote: 'Matatu routes are called by destination.'),
        _PhraseScramble(scenario: 'Requesting a Stop', conductorLine: 'Simama hapa!', targetPhrase: ['Tafadhali', 'simama', 'hapa'], culturalNote: 'Say "Shusha" to get off at your stop.'),
        _PhraseScramble(scenario: 'Asking for Change', conductorLine: 'Chenji yako', targetPhrase: ['Tafadhali', 'nipe', 'chenji'], culturalNote: 'Always carry small bills for exact fare.'),
      ];

  void _prepareRound() {
    if (_currentIndex >= _puzzles.length) {
      finishGame();
      return;
    }
    final puzzle = _puzzles[_currentIndex];
    final rng = Random();

    final distractors = ['na', 'sana', 'leo', 'ndio', 'hapana', 'kama'];
    distractors.shuffle(rng);
    final extraCount = min(2, distractors.length);
    final bank = [...puzzle.targetPhrase, ...distractors.take(extraCount)]
      ..shuffle(rng);

    setState(() {
      _scenarioText = puzzle.scenario;
      _conductorSpeech = puzzle.conductorLine;
      _culturalNote = puzzle.culturalNote;
      _targetSlots = puzzle.targetPhrase;
      _filledSlots = List.filled(puzzle.targetPhrase.length, null);
      _wordBank = bank;
      _usedBankIndices = {};
      _showResult = false;
      _isCorrect = false;
    });
  }

  void _tapBankWord(int bankIndex) {
    if (_showResult || _usedBankIndices.contains(bankIndex)) return;
    HapticFeedback.selectionClick();
    final nextEmpty = _filledSlots.indexWhere((s) => s == null);
    if (nextEmpty < 0) return;
    setState(() {
      _filledSlots[nextEmpty] = _wordBank[bankIndex];
      _usedBankIndices.add(bankIndex);
    });
    if (!_filledSlots.contains(null)) _checkAnswer();
  }

  void _tapSlot(int slotIndex) {
    if (_showResult || _filledSlots[slotIndex] == null) return;
    HapticFeedback.selectionClick();
    final word = _filledSlots[slotIndex]!;
    final bankIdx = _wordBank.indexOf(word);
    setState(() {
      _filledSlots[slotIndex] = null;
      if (bankIdx >= 0) _usedBankIndices.remove(bankIdx);
    });
  }

  void _checkAnswer() {
    final correct = List.generate(_targetSlots.length,
        (i) => _filledSlots[i] == _targetSlots[i]).every((v) => v);
    HapticFeedback.mediumImpact();
    setState(() {
      _showResult = true;
      _isCorrect = correct;
    });

    completeTurn(
      cardId: 'taxi_$_currentIndex',
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {
        'filled': _filledSlots,
        'expected': _targetSlots,
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _currentIndex++;
      _prepareRound();
    });
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_puzzles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 24.h),
          children: [
            _buildSituationCard(cs),
            SizedBox(height: 16.h),
            _buildTerminalScene(cs),
            SizedBox(height: 16.h),
            _buildStepTracker(cs),
            SizedBox(height: 20.h),
            _buildConstructionSlots(cs),
            SizedBox(height: 20.h),
            _buildWordBank(cs),
            SizedBox(height: 20.h),
            GameCulturalNoteCard(
              title: 'Transport Etiquette',
              body: _culturalNote,
            ),
            if (_showResult) ...[
              SizedBox(height: 16.h),
              _buildResultBanner(cs),
            ],
          ],
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: _currentIndex + 1,
            totalSteps: _puzzles.length,
          ),
        ),
      ],
    );
  }

  Widget _buildSituationCard(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Container(
            width: 44.r, height: 44.r,
            decoration: BoxDecoration(
              color: ModernGriotColors.primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.map_rounded, size: 22.sp, color: ModernGriotColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(_scenarioText, style: ModernGriotTypography.titleMedium(context: context)),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalScene(ColorScheme cs) {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A5C5C), Color(0xFF2E8B8B)],
        ),
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.md,
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20.w, bottom: 16.h,
            child: Icon(Icons.directions_bus_rounded, size: 72.sp,
                color: Colors.white.withOpacity(0.2)),
          ),
          Positioned(
            left: 20.w, top: 20.h,
            child: CircleAvatar(
              radius: 28.r,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Icon(Icons.person_rounded, size: 28.sp, color: Colors.white),
            ),
          ),
          Positioned(
            left: 86.w, top: 16.h, right: 20.w,
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(ModernGriotRadius.xl.r),
                  bottomLeft: Radius.circular(ModernGriotRadius.xl.r),
                  bottomRight: Radius.circular(ModernGriotRadius.xl.r),
                ),
              ),
              child: Text(_conductorSpeech,
                  style: ModernGriotTypography.bodyLarge(
                      context: context, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTracker(ColorScheme cs) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: ModernGriotColors.primaryContainer.withOpacity(0.15),
          borderRadius: ModernGriotRadius.borderPill,
        ),
        child: Text(
          'Step ${_currentIndex + 1} of ${_puzzles.length}',
          style: ModernGriotTypography.labelLarge(
              context: context, color: ModernGriotColors.primary),
        ),
      ),
    );
  }

  Widget _buildConstructionSlots(ColorScheme cs) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.w,
      runSpacing: 10.h,
      children: List.generate(_filledSlots.length, (i) {
        final word = _filledSlots[i];
        final showCorrectSlot = _showResult && word != null && word == _targetSlots[i];
        final showWrongSlot = _showResult && word != null && word != _targetSlots[i];

        Color bg;
        Color borderColor;
        if (showCorrectSlot) {
          bg = ModernGriotColors.secondary.withOpacity(0.2);
          borderColor = ModernGriotColors.secondary;
        } else if (showWrongSlot) {
          bg = ModernGriotColors.error.withOpacity(0.2);
          borderColor = ModernGriotColors.error;
        } else if (word != null) {
          bg = ModernGriotColors.primaryContainer.withOpacity(0.15);
          borderColor = ModernGriotColors.primaryContainer;
        } else {
          bg = cs.surfaceContainerHighest.withOpacity(0.5);
          borderColor = cs.outlineVariant;
        }

        return GestureDetector(
          onTap: () => _tapSlot(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: BoxConstraints(minWidth: 60.w),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: ModernGriotRadius.borderMd,
              border: word == null
                  ? Border.all(color: borderColor, width: 1.5,
                      style: BorderStyle.solid)
                  : Border.all(color: borderColor, width: 1.5),
            ),
            child: Text(
              word ?? '___',
              textAlign: TextAlign.center,
              style: ModernGriotTypography.bodyLarge(
                context: context,
                color: word != null
                    ? ModernGriotColors.onSurface
                    : ModernGriotColors.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWordBank(ColorScheme cs) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10.w,
      runSpacing: 10.h,
      children: List.generate(_wordBank.length, (i) {
        final used = _usedBankIndices.contains(i);
        return GestureDetector(
          onTap: () => _tapBankWord(i),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: used ? 0.35 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: used
                    ? cs.surfaceContainerHigh
                    : ModernGriotColors.primaryContainer.withOpacity(0.15),
                borderRadius: ModernGriotRadius.borderPill,
                border: Border.all(
                  color: used
                      ? cs.outlineVariant.withOpacity(0.2)
                      : ModernGriotColors.primaryContainer,
                  width: 1.5,
                ),
                boxShadow: used ? null : ModernGriotShadows.sm,
              ),
              child: Text(_wordBank[i],
                  style: ModernGriotTypography.labelLarge(
                    context: context,
                    color: used
                        ? ModernGriotColors.onSurfaceVariant
                        : ModernGriotColors.primary,
                  )),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResultBanner(ColorScheme cs) {
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
                  ? 'Correct! You navigated like a local.'
                  : 'Not quite — the correct phrase: ${_targetSlots.join(" ")}',
              style: ModernGriotTypography.bodyMedium(context: context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhraseScramble {
  final String scenario;
  final String conductorLine;
  final List<String> targetPhrase;
  final String culturalNote;

  const _PhraseScramble({
    required this.scenario,
    required this.conductorLine,
    required this.targetPhrase,
    required this.culturalNote,
  });
}
