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

class FolktaleGame extends BaseGameScreen {
  const FolktaleGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.folktaleReconstruction;

  @override
  ConsumerState<FolktaleGame> createState() => _FolktaleGameState();
}

class _FolktaleGameState extends BaseGameScreenState<FolktaleGame> {
  late List<PhraseCard> _cards;
  List<_ScenePanel> _scenePanels = [];
  List<_ScenePanel?> _timelineSlots = [];
  List<double> _panelRotations = [];
  bool _showResult = false;
  bool _isCorrectOrder = false;

  static const _warmColors = [
    Color(0xFFD4A574),
    Color(0xFFC48B5C),
    Color(0xFFB87A4B),
    Color(0xFFAA6939),
  ];

  static const _captions = [
    'Hadithi ya kwanza',
    'Sehemu ya pili',
    'Sura ya tatu',
    'Mwisho wa hadithi',
  ];

  @override
  int getCardCount() => 6;

  @override
  bool get requiresPhraseCards => false;

  @override
  Future<void> onGameInitialized() async {
    _cards = ref.read(gameProvider.notifier).availableCards;
    _prepareRound();
  }

  void _prepareRound() {
    final rng = Random();
    final usableCards = _cards.take(4).toList();

    final correctOrder = List.generate(usableCards.length, (i) {
      return _ScenePanel(
        id: i,
        text: usableCards[i].text,
        caption: i < _captions.length ? _captions[i] : 'Scene ${i + 1}',
        color: _warmColors[i % _warmColors.length],
        gloss: usableCards[i].gloss,
      );
    });

    _panelRotations = List.generate(
      correctOrder.length,
      (_) => (rng.nextDouble() * 6 - 3) * (pi / 180),
    );

    setState(() {
      _scenePanels = List.of(correctOrder)..shuffle(rng);
      _timelineSlots = List.filled(correctOrder.length, null);
      _showResult = false;
      _isCorrectOrder = false;
    });
  }

  bool get _allSlotsFilled => _timelineSlots.every((s) => s != null);

  void _onPanelDropped(int slotIndex, _ScenePanel panel) {
    if (_showResult) return;
    HapticFeedback.selectionClick();
    setState(() {
      final existingSlot = _timelineSlots.indexOf(panel);
      if (existingSlot >= 0) _timelineSlots[existingSlot] = null;

      final displaced = _timelineSlots[slotIndex];
      _timelineSlots[slotIndex] = panel;

      if (displaced != null) {
        _scenePanels.add(displaced);
      }
      _scenePanels.remove(panel);
    });
  }

  void _returnToPool(_ScenePanel panel) {
    if (_showResult) return;
    HapticFeedback.selectionClick();
    setState(() {
      final slotIdx = _timelineSlots.indexOf(panel);
      if (slotIdx >= 0) _timelineSlots[slotIdx] = null;
      if (!_scenePanels.contains(panel)) _scenePanels.add(panel);
    });
  }

  void _checkOrder() {
    if (!_allSlotsFilled || _showResult) return;
    HapticFeedback.mediumImpact();
    final correct = List.generate(
      _timelineSlots.length,
      (i) => _timelineSlots[i]!.id == i,
    ).every((v) => v);

    setState(() {
      _showResult = true;
      _isCorrectOrder = correct;
    });

    completeTurn(
      cardId: 'folktale_order',
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 8000,
      feedback: {
        'order': _timelineSlots.map((s) => s?.id ?? -1).toList(),
        'correct': correct,
      },
    );

    if (correct) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) finishGame();
      });
    }
  }

  @override
  String? get appBarTitle => 'Folktale Reconstruction';

  @override
  Widget buildGameContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 24.h),
          children: [
            _scatteredPanelsGrid(cs),
            SizedBox(height: 24.h),
            _threadOfTimeline(cs),
            SizedBox(height: 24.h),
            if (_showResult) _resultCard(cs),
            if (_showResult) SizedBox(height: 16.h),
            GriotGradientButton(
              label: _showResult
                  ? (_isCorrectOrder ? 'Well Done!' : 'Try Again')
                  : 'Check Order',
              icon: _showResult
                  ? (_isCorrectOrder
                      ? Icons.celebration_rounded
                      : Icons.refresh_rounded)
                  : Icons.fact_check_rounded,
              onPressed: _showResult
                  ? (_isCorrectOrder
                      ? null
                      : () {
                          _prepareRound();
                        })
                  : (_allSlotsFilled ? _checkOrder : null),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: 1,
            totalSteps: 1,
          ),
        ),
      ],
    );
  }

  Widget _scatteredPanelsGrid(ColorScheme cs) {
    if (_scenePanels.isEmpty && !_allSlotsFilled) {
      return SizedBox(height: 40.h);
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12.w,
      runSpacing: 12.h,
      children: _scenePanels.map((panel) {
        final rotIdx = panel.id % _panelRotations.length;
        return Draggable<_ScenePanel>(
          data: panel,
          feedback: Material(
            color: Colors.transparent,
            child: _panelCard(panel, rotIdx, isDragging: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _panelCard(panel, rotIdx),
          ),
          child: _panelCard(panel, rotIdx),
        );
      }).toList(),
    );
  }

  Widget _panelCard(_ScenePanel panel, int rotIdx,
      {bool isDragging = false}) {
    final rotation = _panelRotations[rotIdx.clamp(0, _panelRotations.length - 1)];
    return Transform.rotate(
      angle: isDragging ? 0 : rotation,
      child: Container(
        width: 150.w,
        height: 120.h,
        decoration: BoxDecoration(
          color: panel.color,
          borderRadius: ModernGriotRadius.borderLg,
          boxShadow:
              isDragging ? ModernGriotShadows.xl : ModernGriotShadows.sm,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(Icons.image_rounded,
                  size: 40.sp, color: Colors.white.withOpacity(0.2)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(ModernGriotRadius.lg),
                    bottomRight: Radius.circular(ModernGriotRadius.lg),
                  ),
                ),
                child: Text(
                  panel.caption,
                  style: ModernGriotTypography.labelSmall(
                      context: context, color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _threadOfTimeline(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Row(
            children: [
              Icon(Icons.timeline_rounded,
                  size: 20.sp, color: ModernGriotColors.primary),
              SizedBox(width: 8.w),
              Text('Thread of Time',
                  style: ModernGriotTypography.titleSmall(context: context)),
            ],
          ),
        ),
        ...List.generate(_timelineSlots.length, (i) {
          final slot = _timelineSlots[i];
          final isLast = i == _timelineSlots.length - 1;
          final isTarget = slot == null;
          final isCompleted = slot != null;

          Color leftBorderColor;
          if (_showResult && isCompleted) {
            leftBorderColor = slot!.id == i
                ? ModernGriotColors.secondary
                : ModernGriotColors.error;
          } else if (isCompleted) {
            leftBorderColor = ModernGriotColors.secondary;
          } else {
            leftBorderColor = Colors.transparent;
          }

          return Column(
            children: [
              DragTarget<_ScenePanel>(
                onAcceptWithDetails: (details) =>
                    _onPanelDropped(i, details.data),
                builder: (context, candidateData, rejectedData) {
                  final isHovering = candidateData.isNotEmpty;
                  return GestureDetector(
                    onTap: isCompleted ? () => _returnToPool(slot!) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: isHovering
                            ? ModernGriotColors.primaryContainer
                                .withOpacity(0.15)
                            : isCompleted
                                ? cs.surfaceContainerLow
                                : cs.surfaceContainerHighest
                                    .withOpacity(0.4),
                        borderRadius: ModernGriotRadius.borderXl,
                        border: isTarget
                            ? Border.all(
                                color: isHovering
                                    ? ModernGriotColors.primary
                                    : cs.outlineVariant.withOpacity(0.3),
                                width: 1.5,
                                strokeAlign: BorderSide.strokeAlignInside,
                              )
                            : Border(
                                left: BorderSide(
                                    color: leftBorderColor, width: 3),
                              ),
                        boxShadow:
                            isCompleted ? ModernGriotShadows.sm : null,
                      ),
                      child: isCompleted
                          ? Row(
                              children: [
                                Container(
                                  width: 28.r,
                                  height: 28.r,
                                  decoration: BoxDecoration(
                                    color: leftBorderColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style:
                                          ModernGriotTypography.labelMedium(
                                        context: context,
                                        color: leftBorderColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot!.text,
                                        style:
                                            ModernGriotTypography.bodyMedium(
                                                context: context),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        slot.caption,
                                        style:
                                            ModernGriotTypography.labelSmall(
                                                context: context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Text(
                                'Drop scene ${i + 1} here',
                                style: ModernGriotTypography.bodySmall(
                                  context: context,
                                  color: ModernGriotColors.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
              if (!isLast)
                SizedBox(
                  height: 20.h,
                  child: CustomPaint(
                    painter: _DashedLinePainter(
                      color: cs.outlineVariant.withOpacity(0.3),
                    ),
                    size: Size(2.w, 20.h),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _resultCard(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(
            _isCorrectOrder
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color: _isCorrectOrder
                ? ModernGriotColors.secondary
                : ModernGriotColors.error,
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _isCorrectOrder
                  ? 'The folktale is restored! The ancestors smile upon you.'
                  : 'The timeline is not quite right. Try rearranging the scenes.',
              style: ModernGriotTypography.bodyMedium(context: context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenePanel {
  final int id;
  final String text;
  final String caption;
  final Color color;
  final String gloss;

  const _ScenePanel({
    required this.id,
    required this.text,
    required this.caption,
    required this.color,
    required this.gloss,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _ScenePanel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashHeight = 4.0;
    const gap = 3.0;
    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
