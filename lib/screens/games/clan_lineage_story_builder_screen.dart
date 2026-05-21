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
import 'game_scenario_loader.dart';
import 'base_game_screen.dart';

class ClanStoryGame extends BaseGameScreen {
  const ClanStoryGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.clanLineageStoryBuilder;

  @override
  ConsumerState<ClanStoryGame> createState() => _ClanStoryGameState();
}

class _ClanStoryGameState extends BaseGameScreenState<ClanStoryGame> {
  final List<_Ancestor> _ancestors = [];
  int _currentStep = 0;
  final List<String> _journalEntries = [];
  bool _showingChoice = false;
  List<String> _narrativeChoices = [];
  String? _selectedChoice;
  List<GameScenario> _bundledScenarios = [];

  static const _maxSteps = 5;

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    final cards = gameProv.availableCards;
    _ancestors.clear();
    _bundledScenarios = loadBundledGameScenarios(
      ref,
      language: widget.language,
      game: 'VillageQuest',
      max: _maxSteps,
    );

    if (_bundledScenarios.isNotEmpty) {
      for (var i = 0; i < _maxSteps; i++) {
        final s = _bundledScenarios[i % _bundledScenarios.length];
        _ancestors.add(_Ancestor(
          name: s.title,
          role: s.culturalNote ?? 'Elder',
          description: s.prompt,
          cardId: cards.isNotEmpty ? cards[i % cards.length].cardId : 'ancestor_$i',
          scenario: s,
        ));
      }
      final opener = _bundledScenarios.first;
      _journalEntries.add('${opener.title}: ${opener.prompt}');
    } else {
      final names = [
        ('Elder Ifeoma', 'The Matriarch', 'Keeper of ancestral wisdom and oral history'),
        ('Obi the Seer', 'Village Oracle', 'Interpreter of dreams and signs from the spirit world'),
        ('Commander K', 'War Chief', 'Defender of the clan during the Great Migration'),
        ('Amara of the River', 'Healer', 'Master of herbal remedies passed down generations'),
        ('Kofi the Builder', 'Architect', 'Designer of the sacred meeting grounds'),
      ];

      for (var i = 0; i < _maxSteps; i++) {
        final n = names[i % names.length];
        _ancestors.add(_Ancestor(
          name: n.$1,
          role: n.$2,
          description: n.$3,
          cardId: cards.isNotEmpty ? cards[i % cards.length].cardId : 'ancestor_$i',
        ));
      }

      _journalEntries.add(
        'The story of the ${widget.language} clan begins in a village '
        'nestled between ancient baobab trees...',
      );
    }

    _prepareChoices();
    setState(() {});
  }

  void _prepareChoices() {
    if (_currentStep >= _maxSteps) return;
    final ancestor = _ancestors[_currentStep];
    if (ancestor.scenario != null) {
      final s = ancestor.scenario!;
      final pool = _bundledScenarios.isNotEmpty
          ? _bundledScenarios
          : [s];
      _narrativeChoices = pool
          .map((e) => (e.expectedResponse ?? e.prompt).trim())
          .where((t) => t.isNotEmpty)
          .take(3)
          .toList();
      while (_narrativeChoices.length < 3) {
        _narrativeChoices.add(s.prompt);
      }
    } else {
      _narrativeChoices = [
        '${ancestor.name} shared the secret of ${_culturalTopic()}.',
        '${ancestor.name} led the clan through ${_culturalChallenge()}.',
        '${ancestor.name} discovered a hidden ${_culturalArtifact()}.',
      ];
    }
    _narrativeChoices.shuffle(Random());
    _showingChoice = true;
    _selectedChoice = null;
  }

  String _culturalTopic() {
    const topics = ['the talking drum', 'iron smelting', 'indigo dyeing', 'kola nut ceremonies', 'moonlight tales'];
    return topics[Random().nextInt(topics.length)];
  }

  String _culturalChallenge() {
    const challenges = ['the dry season famine', 'a territorial dispute', 'the river crossing', 'the locust plague', 'the traders\' betrayal'];
    return challenges[Random().nextInt(challenges.length)];
  }

  String _culturalArtifact() {
    const artifacts = ['bronze casting technique', 'weaving pattern', 'sacred grove', 'ancestral mask', 'ceremonial staff'];
    return artifacts[Random().nextInt(artifacts.length)];
  }

  Future<void> _appendNarrative(String choice) async {
    if (_selectedChoice != null) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _selectedChoice = choice;
      _showingChoice = false;
      _journalEntries.add(choice);
      _ancestors[_currentStep].completed = true;
    });

    final ancestor = _ancestors[_currentStep];
    final canContinue = await completeTurn(
      cardId: ancestor.cardId,
      result: GameResult.correct,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 3000,
      confidence: 1.0,
      feedback: {
        'ancestor': ancestor.name,
        'choice': choice,
        'step': _currentStep + 1,
      },
    );

    if (!canContinue || !mounted) return;

    setState(() {
      _currentStep++;
      if (_currentStep >= _maxSteps) {
        _journalEntries.add(
          'And so the lineage lives on, carried forward by every word spoken in ${widget.language}.',
        );
        finishGame();
      } else {
        _prepareChoices();
      }
    });
  }

  @override
  String? get appBarTitle =>
      isLoading ? null : 'Clan Lineage (${_currentStep + 1}/$_maxSteps)';

  @override
  Widget buildGameContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        GameTopBar(
          onClose: () {
            HapticFeedback.lightImpact();
            (widget.onBack ?? () => Navigator.pop(context))();
          },
          currentStep: _currentStep + 1,
          totalSteps: _maxSteps,
          streak: 0,
          xp: 0,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            child: Column(
              children: [
                _buildAncestralTree(cs, isDark),
                SizedBox(height: 16.h),
                _buildAncestorScroll(cs, isDark),
                SizedBox(height: 16.h),
                if (_showingChoice) _buildNarrativeChoices(cs, isDark),
                SizedBox(height: 16.h),
                _buildJournalPanel(cs, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAncestralTree(ColorScheme cs, bool isDark) {
    return SizedBox(
      height: 200.h,
      child: CustomPaint(
        painter: _AncestralTreePainter(
          ancestors: _ancestors,
          currentStep: _currentStep,
          primaryColor: ModernGriotColors.primary,
          successColor: ModernGriotColors.secondary,
          surfaceColor: isDark
              ? ModernGriotColorsDark.surfaceContainer
              : ModernGriotColors.surfaceContainer,
          onSurfaceColor: isDark
              ? ModernGriotColorsDark.onSurface
              : ModernGriotColors.onSurface,
        ),
        size: Size(double.infinity, 200.h),
      ),
    );
  }

  Widget _buildAncestorScroll(ColorScheme cs, bool isDark) {
    return SizedBox(
      height: 130.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _ancestors.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final ancestor = _ancestors[index];
          final isCurrent = index == _currentStep;
          final isCompleted = ancestor.completed;

          return Container(
            width: 140.w,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: isCurrent
                  ? ModernGriotColors.primary.withAlpha(25)
                  : (isDark
                      ? ModernGriotColorsDark.surfaceContainerHigh
                      : ModernGriotColors.surfaceContainerLow),
              borderRadius: ModernGriotRadius.borderXl,
              border: isCurrent
                  ? Border.all(color: ModernGriotColors.primary, width: 2)
                  : null,
              boxShadow: ModernGriotShadows.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? ModernGriotColors.secondary.withAlpha(50)
                        : ModernGriotColors.primaryContainer.withAlpha(50),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : Icons.person_rounded,
                    size: 22.sp,
                    color: isCompleted
                        ? ModernGriotColors.secondary
                        : ModernGriotColors.primaryContainer,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  ancestor.name,
                  style: ModernGriotTypography.labelLarge(context: context).copyWith(
                    color: isCurrent ? ModernGriotColors.primary : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  ancestor.role,
                  style: ModernGriotTypography.labelSmall(context: context).copyWith(
                    color: ModernGriotColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  ancestor.description,
                  style: ModernGriotTypography.bodySmall(context: context),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNarrativeChoices(ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose the next chapter:',
          style: ModernGriotTypography.titleMedium(context: context),
        ),
        SizedBox(height: 10.h),
        ..._narrativeChoices.map((choice) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: GameOptionButton(
              label: choice,
              state: GameOptionState.idle,
              onTap: () => _appendNarrative(choice),
              icon: Icons.auto_stories_rounded,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJournalPanel(ColorScheme cs, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark
            ? ModernGriotColorsDark.surfaceContainerHigh
            : ModernGriotColors.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 20.sp, color: ModernGriotColors.primary),
              SizedBox(width: 8.w),
              Text(
                'Living Journal',
                style: ModernGriotTypography.titleMedium(context: context).copyWith(
                  color: ModernGriotColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ..._journalEntries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  entry,
                  style: ModernGriotTypography.bodyMedium(context: context).copyWith(
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )),
          if (_currentStep < _maxSteps && !_showingChoice) ...[
            SizedBox(height: 8.h),
            Center(
              child: GriotGradientButton(
                label: 'Append Narrative',
                icon: Icons.edit_note_rounded,
                onPressed: () {
                  setState(() => _prepareChoices());
                },
              ),
            ),
          ],
          if (_currentStep < _maxSteps)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: GameCulturalNoteCard(
                title: 'Cultural Note',
                body: 'In many African traditions, lineage stories are '
                    'passed down through griots — oral historians who '
                    'preserve the memory of entire clans through song and narrative.',
              ),
            ),
        ],
      ),
    );
  }
}

class _Ancestor {
  final String name;
  final String role;
  final String description;
  final String cardId;
  final GameScenario? scenario;
  bool completed;

  _Ancestor({
    required this.name,
    required this.role,
    required this.description,
    required this.cardId,
    this.scenario,
    this.completed = false,
  });
}

class _AncestralTreePainter extends CustomPainter {
  final List<_Ancestor> ancestors;
  final int currentStep;
  final Color primaryColor;
  final Color successColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  _AncestralTreePainter({
    required this.ancestors,
    required this.currentStep,
    required this.primaryColor,
    required this.successColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final dashPaint = Paint()
      ..color = onSurfaceColor.withAlpha(60)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Vertical dashed center line
    const dashHeight = 6.0;
    const dashGap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(centerX, y),
        Offset(centerX, (y + dashHeight).clamp(0, size.height)),
        dashPaint,
      );
      y += dashHeight + dashGap;
    }

    if (ancestors.isEmpty) return;

    final nodeSpacing = size.height / (ancestors.length + 1);

    for (var i = 0; i < ancestors.length; i++) {
      final ancestor = ancestors[i];
      final nodeY = nodeSpacing * (i + 1);
      final isLeft = i.isEven;
      final nodeX = isLeft ? centerX - 50 : centerX + 50;

      // Connector line to center
      final connectorPaint = Paint()
        ..color = ancestor.completed
            ? successColor.withAlpha(180)
            : onSurfaceColor.withAlpha(40)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(centerX, nodeY), Offset(nodeX, nodeY), connectorPaint);

      // Node circle
      final nodePaint = Paint()..style = PaintingStyle.fill;
      final radius = 12.0;

      if (ancestor.completed) {
        nodePaint.color = successColor;
        canvas.drawCircle(Offset(nodeX, nodeY), radius, nodePaint);
        // Check mark
        final checkPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(nodeX - 4, nodeY)
          ..lineTo(nodeX - 1, nodeY + 4)
          ..lineTo(nodeX + 5, nodeY - 3);
        canvas.drawPath(path, checkPaint);
      } else if (i == currentStep) {
        nodePaint.color = primaryColor;
        canvas.drawCircle(Offset(nodeX, nodeY), radius, nodePaint);
        // Name label
        final tp = TextPainter(
          text: TextSpan(
            text: ancestor.name.split(' ').first,
            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: radius * 2);
        tp.paint(canvas, Offset(nodeX - tp.width / 2, nodeY - tp.height / 2));
      } else {
        // Placeholder — dashed circle
        final dashedPaint = Paint()
          ..color = onSurfaceColor.withAlpha(50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        const segments = 12;
        for (var s = 0; s < segments; s += 2) {
          final startAngle = (s / segments) * 2 * 3.14159;
          final sweepAngle = (1 / segments) * 2 * 3.14159;
          canvas.drawArc(
            Rect.fromCircle(center: Offset(nodeX, nodeY), radius: radius),
            startAngle,
            sweepAngle,
            false,
            dashedPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AncestralTreePainter old) =>
      old.currentStep != currentStep ||
      old.ancestors.length != ancestors.length;
}
