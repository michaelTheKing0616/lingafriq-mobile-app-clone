import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../games/gamekit/game_feedback.dart';
import '../../games/gamekit/game_scoring.dart';
import '../../lessons/tone_perception_drill.dart';
import '../../models/verified_lexeme.dart';
import '../../services/lexicon_lookup_service.dart';
import '../../utils/api_service.dart';
import '../../utils/pan_african_design_system.dart';
import 'league_scoring.dart';
import 'minimal_pair_duel_game.dart';

enum MinimalPairDuelPhase {
  loading,
  ready,
  playing,
  correct,
  wrong,
  whyWrong,
  results,
  error,
  offline,
  practiceMode,
  waitingForOpponent,
}

/// Flagship Minimal Pair Duel (P8-921): hear a word, tap the matching picture.
class MinimalPairDuelScreen extends ConsumerStatefulWidget {
  const MinimalPairDuelScreen({
    super.key,
    required this.language,
    this.itemSetSeed,
    this.onBack,
  });

  final String language;
  final String? itemSetSeed;
  final VoidCallback? onBack;

  @override
  ConsumerState<MinimalPairDuelScreen> createState() =>
      _MinimalPairDuelScreenState();
}

class _MinimalPairDuelScreenState extends ConsumerState<MinimalPairDuelScreen> {
  static const _title = 'Minimal Pair Duel';
  static const _instructions =
      'Listen once, then tap the picture that matches the word you heard.';
  static const _whyWrongCopy =
      'Hear the pair side by side — tone or length is what changed the meaning.';
  static const _practiceLabel = 'Practice — scores do not count toward leagues.';
  static const _errorCopy =
      'We could not load this duel. Check your connection and try again.';
  static const _maxRounds = 5;

  final AudioPlayer _player = AudioPlayer();
  MinimalPairDuelPhase _phase = MinimalPairDuelPhase.loading;
  String? _loadError;
  List<MinimalPairDuelSet> _sessionSets = const [];
  MinimalPairDuelTurn? _turn;
  MinimalPairDuelTapResult? _lastTap;
  int _round = 0;
  final List<MinimalPairDuelLeagueScore> _roundScores = [];
  bool _practiceNotScored = true;
  bool _showVerdict = false;
  DateTime? _turnStartedAt;

  @override
  void initState() {
    super.initState();
    _practiceNotScored = gameKitPracticeNotScoredMode(
      isSpeakingGame: false,
      realScorerLive: false,
    );
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final catalog = await loadTonePerceptionCatalogFromAsset();
      final drills = drillsForLanguage(catalog, widget.language.toLowerCase());
      final lexemes = await _fetchVerifiedLexemes(widget.language);
      final mediaById = minimalPairMediaFromLexemes(lexemes);
      final eligible = buildEligibleDuelSets(
        drills: drills,
        mediaByOptionId: mediaById,
      );
      if (eligible.isEmpty) {
        setState(() {
          _phase = MinimalPairDuelPhase.error;
          _loadError =
              'No minimal-pair sets with pictures and audio are ready for this language yet.';
        });
        return;
      }
      final seed = widget.itemSetSeed ??
          'mpd_${widget.language}_${DateTime.now().millisecondsSinceEpoch}';
      final ids = deriveAsyncItemSetIds(
        itemSetSeed: seed,
        eligibleSets: eligible,
        maxSets: _maxRounds,
      );
      final byId = {for (final s in eligible) s.setId: s};
      _sessionSets = ids.map((id) => byId[id]!).toList(growable: false);
      setState(() {
        _phase = _practiceNotScored
            ? MinimalPairDuelPhase.practiceMode
            : MinimalPairDuelPhase.ready;
      });
      await _loadNextTurn();
    } catch (_) {
      setState(() {
        _phase = MinimalPairDuelPhase.error;
        _loadError = _errorCopy;
      });
    }
  }

  Future<List<VerifiedLexeme>> _fetchVerifiedLexemes(String languageCode) async {
    await ApiService.initialize();
    try {
      final response = await ApiService.get(
        verifiedLexiconSearchPath,
        queryParameters: {
          'language': languageCode.trim().toLowerCase(),
          'q': '',
          'limit': '80',
        },
      );
      if (response.statusCode != 200) return const [];
      final body = response.data;
      final rows = body is Map ? body['items'] ?? body['results'] : null;
      if (rows is! List) return const [];
      final out = <VerifiedLexeme>[];
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          out.add(VerifiedLexeme.fromApiJson(row));
        } else if (row is Map) {
          out.add(VerifiedLexeme.fromApiJson(row.cast<String, dynamic>()));
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _loadNextTurn() async {
    if (_round >= _sessionSets.length) {
      setState(() => _phase = MinimalPairDuelPhase.results);
      return;
    }
    final set = _sessionSets[_round];
    final turn = buildMinimalPairDuelTurn(set: set, rng: Random());
    _turnStartedAt = DateTime.now();
    setState(() {
      _turn = turn;
      _lastTap = null;
      _showVerdict = false;
      _phase = MinimalPairDuelPhase.playing;
    });
    await _playHeardWord();
  }

  Future<void> _playHeardWord() async {
    final turn = _turn;
    if (turn == null) return;
    final uri = audioUriForOption(turn, turn.heardOptionId);
    if (uri == null) return;
    try {
      await _player.setUrl(uri);
      await _player.play();
    } catch (_) {
      setState(() => _phase = MinimalPairDuelPhase.offline);
    }
  }

  Future<void> _playConfusedPair() async {
    final ids = _lastTap?.confusedPairOptionIds ?? const [];
    final turn = _turn;
    if (turn == null || ids.length < 2) return;
    for (final id in ids) {
      final uri = audioUriForOption(turn, id);
      if (uri == null) continue;
      try {
        await _player.setUrl(uri);
        await _player.play();
        await _player.processingStateStream
            .firstWhere((s) => s == ProcessingState.completed);
      } catch (_) {
        break;
      }
    }
  }

  void _onPictureTap(String optionId) {
    if (_showVerdict || _turn == null) return;
    final elapsed = _turnStartedAt == null
        ? 0
        : DateTime.now().difference(_turnStartedAt!).inMilliseconds;
    final result = gradeMinimalPairDuelTap(
      turn: _turn!,
      selectedOptionId: optionId,
    );
    _roundScores.add(scoreTurn(result: result, responseTimeMs: elapsed));
    setState(() {
      _lastTap = result;
      _showVerdict = true;
      _phase = result.correct
          ? MinimalPairDuelPhase.correct
          : MinimalPairDuelPhase.wrong;
    });
    if (!result.correct) {
      unawaited(_playConfusedPair());
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _phase = MinimalPairDuelPhase.whyWrong);
      });
    } else {
      Future<void>.delayed(const Duration(milliseconds: 700), _advanceRound);
    }
  }

  void _advanceRound() {
    if (!mounted) return;
    _round++;
    unawaited(_loadNextTurn());
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('$_title · ${_round.clamp(0, _maxRounds)} / $_maxRounds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: switch (_phase) {
        MinimalPairDuelPhase.loading => const Center(
            child: CircularProgressIndicator(),
          ),
        MinimalPairDuelPhase.error => _StateMessage(
            message: _loadError ?? _errorCopy,
            actionLabel: 'Try again',
            onAction: () {
              setState(() => _phase = MinimalPairDuelPhase.loading);
              unawaited(_bootstrap());
            },
          ),
        MinimalPairDuelPhase.offline => _StateMessage(
            message: _loadError ?? 'You are offline. Duel needs lexicon audio.',
            actionLabel: 'Back',
            onAction: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
        MinimalPairDuelPhase.results => _buildResults(context),
        MinimalPairDuelPhase.waitingForOpponent => _StateMessage(
            message: 'Waiting for your friend to finish the same set…',
            actionLabel: 'Keep practising',
            onAction: () => setState(
              () => _phase = MinimalPairDuelPhase.practiceMode,
            ),
          ),
        _ => Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_practiceNotScored) const _PracticeBanner(label: _practiceLabel),
                Text(
                  _instructions,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                if (_turn != null) ...[
                  Semantics(
                    liveRegion: true,
                    label: 'Playing word audio',
                    child: FilledButton.icon(
                      onPressed: reduceMotion ? null : _playHeardWord,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Play again'),
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Expanded(child: _pictureGrid(context)),
                ],
                if (_showVerdict && _lastTap != null)
                  GameKitVerdictSlot(
                    phase: GameKitFeedbackPhase.localVerdict,
                    isCorrect: _lastTap!.correct,
                    correctLabel: 'Correct',
                    wrongLabel: 'Not quite',
                    pendingLabel: 'Checking…',
                  ),
                if (_phase == MinimalPairDuelPhase.whyWrong) ...[
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    _whyWrongCopy,
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                  FilledButton(
                    onPressed: _advanceRound,
                    child: const Text('Next pair'),
                  ),
                ],
              ],
            ),
          ),
      },
    );
  }

  Widget _pictureGrid(BuildContext context) {
    final turn = _turn!;
    final crossCount = turn.options.length <= 2 ? 2 : 2;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: PanAfricanSpacing.sm,
        crossAxisSpacing: PanAfricanSpacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: turn.options.length,
      itemBuilder: (context, index) {
        final opt = turn.options[index];
        final selected = _lastTap?.selectedOptionId == opt.id;
        final isCorrectOption = opt.id == turn.heardOptionId;
        Color? border;
        if (_showVerdict) {
          if (isCorrectOption) {
            border = Theme.of(context).colorScheme.primary;
          } else if (selected) {
            border = Theme.of(context).colorScheme.error;
          }
        }
        return Semantics(
          button: true,
          label: '${opt.form}, ${opt.glossEn}',
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            child: InkWell(
              onTap: () => _onPictureTap(opt.id),
              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  border: border != null ? Border.all(color: border, width: 3) : null,
                ),
                padding: EdgeInsets.all(PanAfricanSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        opt.imageUri,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_outlined,
                          size: 48.sp,
                          semanticLabel: opt.imageAlt.isNotEmpty
                              ? opt.imageAlt
                              : opt.glossEn,
                        ),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      opt.glossEn,
                      style: PanAfricanTypography.labelMedium(context),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResults(BuildContext context) {
    final total = mergeDuelSessionScores(_roundScores);
    final pct = (total.accuracy * 100).round();
    return _StateMessage(
      message:
          'You matched $pct% of the pairs. Accuracy ranks leagues; speed only breaks ties.',
      actionLabel: 'Done',
      onAction: widget.onBack ?? () => Navigator.of(context).pop(),
    );
  }
}

class _PracticeBanner extends StatelessWidget {
  const _PracticeBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Text(
            label,
            style: PanAfricanTypography.labelMedium(context),
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: PanAfricanTypography.bodyLarge(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

