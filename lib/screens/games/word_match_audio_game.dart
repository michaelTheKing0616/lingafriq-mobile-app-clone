import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/game_content_provider.dart';
import '../../widgets/content/vocab_audio_controls.dart';
import '../../models/game/game_content_models.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';

class WordMatchAudioGame extends BaseGameScreen {
  const WordMatchAudioGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.wordMatchAudio;

  @override
  ConsumerState<WordMatchAudioGame> createState() => _WordMatchAudioGameState();
}

class _WordMatchAudioGameState extends BaseGameScreenState<WordMatchAudioGame> {
  List<_MatchTile> _leftTiles = [];
  List<_MatchTile> _rightTiles = [];
  String? _selectedLeft;
  String? _selectedRight;
  final Set<String> _matchedIds = {};
  final Set<String> _errorIds = {};
  int _consecutiveCorrect = 0;
  bool _showStreakBadge = false;

  @override
  int getCardCount() => 10;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    final cards = gameProv.availableCards;
    if (cards.isEmpty) return;

    final displayCards = cards.take(5).toList();
    setState(() {
      _leftTiles = displayCards
          .map((c) => _MatchTile(id: c.cardId, label: c.text, audioUrl: c.audioNativeUrl))
          .toList()
        ..shuffle(Random());
      _rightTiles = displayCards
          .map((c) => _MatchTile(id: c.cardId, label: c.gloss))
          .toList()
        ..shuffle(Random());
    });
  }

  void _selectTile(String side, String id) {
    if (_matchedIds.contains(id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _errorIds.clear();
      if (side == 'left') {
        _selectedLeft = _selectedLeft == id ? null : id;
      } else {
        _selectedRight = _selectedRight == id ? null : id;
      }
    });
  }

  void _checkPairs() {
    if (_selectedLeft == null || _selectedRight == null) return;
    HapticFeedback.mediumImpact();

    final correct = _selectedLeft == _selectedRight;
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: _selectedLeft!,
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: correct ? 1.0 : 0.0,
      userAction: 'matched_pair',
    );

    setState(() {
      if (correct) {
        _matchedIds.add(_selectedLeft!);
        _consecutiveCorrect++;
        if (_consecutiveCorrect >= 3 && !_showStreakBadge) {
          _showStreakBadge = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showStreakBadge = false);
          });
        }
      } else {
        _consecutiveCorrect = 0;
        _errorIds.addAll({_selectedLeft!, _selectedRight!});
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _errorIds.clear());
        });
      }
      _selectedLeft = null;
      _selectedRight = null;
    });

    if (_matchedIds.length == _leftTiles.length) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) finishGame();
      });
    }
  }

  _TileState _tileState(String id, bool isLeft) {
    if (_matchedIds.contains(id)) return _TileState.matched;
    if (_errorIds.contains(id)) return _TileState.error;
    final selected = isLeft ? _selectedLeft : _selectedRight;
    if (selected == id) return _TileState.selected;
    return _TileState.idle;
  }

  @override
  Widget buildGameContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_leftTiles.isEmpty) {
      return Center(
        child: Text('No pairs available',
            style: ModernGriotTypography.bodyLarge(context: context)),
      );
    }

    final progress =
        _leftTiles.isEmpty ? 0.0 : _matchedIds.length / _leftTiles.length;
    final canCheck = _selectedLeft != null && _selectedRight != null;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
            child: Column(
              children: [
                SizedBox(height: PanAfricanSpacing.sm),
                // Progress (top bar style)
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ModernGriotColors.surfaceContainerHighest,
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ModernGriotGradients.signatureGradient,
                        borderRadius: ModernGriotRadius.borderPill,
                        boxShadow: [
                          BoxShadow(
                            color: ModernGriotColors.secondary.withOpacity(0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                Column(
                  children: [
                    Text(
                      l10n.gameWordMatchConnectMeaningTitle,
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.headlineSmall(
                        context: context,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      l10n.gameWordMatchConnectMeaningSubtitle,
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.bodyMedium(
                        context: context,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                // Two-column tile layout
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gap = isWide ? 32.0 : 12.0;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.language,
                                      style: ModernGriotTypography.labelSmall(
                                        context: context,
                                        color: ModernGriotColors.primary
                                            .withOpacity(0.7),
                                      ).copyWith(
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: ModernGriotColors.outlineVariant
                                            .withOpacity(0.35),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: PanAfricanSpacing.sm),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: _leftTiles.length,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(height: PanAfricanSpacing.sm),
                                    itemBuilder: (_, i) {
                                      final tile = _leftTiles[i];
                                      return _WordTile(
                                        label: tile.label,
                                        state: _tileState(tile.id, true),
                                        showSpeaker: true,
                                        audioLanguage: widget.language,
                                        useIndigoStyle: true,
                                        onTap: () => _selectTile('left', tile.id),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: ModernGriotColors.outlineVariant
                                            .withOpacity(0.35),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.gameWordMatchEnglishLabel,
                                      style: ModernGriotTypography.labelSmall(
                                        context: context,
                                        color: ModernGriotColors.secondary
                                            .withOpacity(0.7),
                                      ).copyWith(
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: PanAfricanSpacing.sm),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: _rightTiles.length,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(height: PanAfricanSpacing.sm),
                                    itemBuilder: (_, i) {
                                      final tile = _rightTiles[i];
                                      return _WordTile(
                                        label: tile.label,
                                        state: _tileState(tile.id, false),
                                        useBubbleStyle: true,
                                        onTap: () => _selectTile('right', tile.id),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 92),
              ],
            ),
          ),
          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  PanAfricanSpacing.md,
                  PanAfricanSpacing.sm,
                  PanAfricanSpacing.md,
                  PanAfricanSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: canCheck ? _checkPairs : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: ModernGriotColors.outlineVariant,
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: ModernGriotRadius.borderLg,
                    ),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.disabled)
                          ? ModernGriotColors.outlineVariant.withOpacity(0.6)
                          : ModernGriotColors.outlineVariant,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(states.contains(WidgetState.disabled) ? 0.6 : 1),
                    ),
                  ),
                  child: Text(
                    'CHECK PAIRS',
                    style: ModernGriotTypography.titleSmall(context: context).copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Streak badge
          if (_showStreakBadge)
            Positioned(
              top: 60.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.lg,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: ModernGriotGradients.signatureGradient,
                    borderRadius: ModernGriotRadius.borderPill,
                    boxShadow: ModernGriotShadows.lg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: ModernGriotColors.onPrimary, size: 20.sp),
                      SizedBox(width: 6.w),
                      Text('Perfect Streak!',
                          style: ModernGriotTypography.titleSmall(
                              context: context, color: ModernGriotColors.onPrimary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Tile states for word match
enum _TileState { idle, selected, matched, error }

class _WordTile extends StatelessWidget {
  final String label;
  final _TileState state;
  final bool showSpeaker;
  final String? audioLanguage;
  final bool useIndigoStyle;
  final bool useBubbleStyle;
  final VoidCallback onTap;

  const _WordTile({
    required this.label,
    required this.state,
    this.showSpeaker = false,
    this.audioLanguage,
    this.useIndigoStyle = false,
    this.useBubbleStyle = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMatched = state == _TileState.matched;
    final isSelected = state == _TileState.selected;
    final isError = state == _TileState.error;

    Color bg;
    Color borderColor;
    double borderWidth;
    if (isMatched) {
      bg = ModernGriotColors.secondary.withOpacity(0.12);
      borderColor = ModernGriotColors.secondary;
      borderWidth = 1.5;
    } else if (isSelected) {
      bg = useBubbleStyle
          ? ModernGriotColors.primary
          : ModernGriotColors.primaryContainer.withOpacity(0.25);
      borderColor = ModernGriotColors.primary;
      borderWidth = 2.0;
    } else if (isError) {
      bg = ModernGriotColors.error.withOpacity(0.1);
      borderColor = ModernGriotColors.error;
      borderWidth = 2.0;
    } else {
      bg = useIndigoStyle
          ? ModernGriotColors.primaryFixed.withOpacity(0.55)
          : (useBubbleStyle
              ? ModernGriotColors.surfaceContainerLow
              : ModernGriotColors.surfaceContainerLowest);
      borderColor = ModernGriotColors.outlineVariant.withOpacity(0.3);
      borderWidth = 1.0;
    }

    return GestureDetector(
      onTap: isMatched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm,
          vertical: PanAfricanSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: useBubbleStyle
              ? BorderRadius.circular(32)
              : ModernGriotRadius.borderLg,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelected ? ModernGriotShadows.sm : ModernGriotShadows.xs,
        ),
        child: Opacity(
          opacity: isMatched ? 0.6 : 1.0,
          child: Row(
            children: [
              if (showSpeaker && audioLanguage != null) ...[
                VocabAudioControls(
                  language: audioLanguage!,
                  text: label,
                  compact: true,
                ),
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: Text(
                  label,
                  textAlign: useBubbleStyle ? TextAlign.center : TextAlign.start,
                  style: ModernGriotTypography.bodyMedium(context: context).copyWith(
                    color: isSelected && useBubbleStyle
                        ? ModernGriotColors.onPrimary
                        : isError
                            ? ModernGriotColors.error
                            : (useIndigoStyle
                                ? ModernGriotColors.onPrimaryFixed
                                : ModernGriotColors.onSurface),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isMatched)
                Icon(Icons.check_circle_rounded,
                    size: 18.sp, color: ModernGriotColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTile {
  final String id;
  final String label;
  final String? audioUrl;
  const _MatchTile({required this.id, required this.label, this.audioUrl});
}
