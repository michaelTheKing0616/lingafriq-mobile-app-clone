import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/pan_african_design_system.dart';
import 'proverb_weaver_game.dart';

enum ProverbWeaverPhase {
  loading,
  lockedBelowB1,
  ready,
  playing,
  hearProverb,
  situation,
  correct,
  wrong,
  whyWrong,
  results,
  error,
  offline,
  practiceMode,
}

/// Flagship Proverb Weaver (P8-924): weave fragments, hear proverb, pick situation.
class ProverbWeaverScreen extends StatefulWidget {
  const ProverbWeaverScreen({
    super.key,
    required this.language,
    this.learnerLevel,
    this.onBack,
    this.onOpenLegacyUnlocker,
    this.initialRound,
    this.initialPhase,
  });

  final String language;
  final String? learnerLevel;
  final VoidCallback? onBack;
  final VoidCallback? onOpenLegacyUnlocker;

  /// Test hook: inject a reviewed proverb round.
  final ProverbWeaverRound? initialRound;

  /// Test hook: skip bootstrap (e.g. [ProverbWeaverPhase.playing]).
  final ProverbWeaverPhase? initialPhase;

  @override
  State<ProverbWeaverScreen> createState() => _ProverbWeaverScreenState();
}

class _ProverbWeaverScreenState extends State<ProverbWeaverScreen> {
  static const title = 'Proverb Weaver';
  static const instructions =
      'Tap the word tiles in order to weave the proverb, then choose when people say it.';
  static const whyWrongCopy =
      'That situation does not fit the proverb’s meaning. Read the note and try the next round.';
  static const practiceLabel =
      'Practice — proverb rounds do not affect league rank until your level is B1 or higher.';
  static const errorCopy =
      'We could not load proverbs for this language yet. Try another language or come back soon.';
  static const lockedCopy =
      'Proverbs need context. Reach B1 in this language to unlock Proverb Weaver.';
  static const legacyLinkLabel = 'Classic tablet unlocker';

  ProverbWeaverPhase _phase = ProverbWeaverPhase.loading;
  String? _loadError;
  ProverbWeaverRound? _round;
  final List<String> _assembled = [];
  final List<String> _remaining = [];
  int _roundIndex = 0;
  int _correctCount = 0;
  static const _maxRounds = 3;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    if (widget.initialPhase != null) {
      _phase = widget.initialPhase!;
      _round = widget.initialRound;
      if (_round != null) {
        _remaining
          ..clear()
          ..addAll(_round!.shuffledFragments);
      }
    } else {
      unawaited(_bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    if (!proverbWeaverUnlockedForLevel(widget.learnerLevel)) {
      setState(() => _phase = ProverbWeaverPhase.lockedBelowB1);
      return;
    }
    try {
      final record = pickRecordForLanguage(widget.language, _rng);
      if (record == null) {
        setState(() {
          _phase = ProverbWeaverPhase.error;
          _loadError = errorCopy;
        });
        return;
      }
      await _startRound(record);
    } catch (_) {
      setState(() {
        _phase = ProverbWeaverPhase.error;
        _loadError = errorCopy;
      });
    }
  }

  Future<void> _startRound(ProverbWeaverRecord record) async {
    _round = buildRound(record: record, rng: _rng);
    _assembled.clear();
    _remaining
      ..clear()
      ..addAll(_round!.shuffledFragments);
    setState(() {
      _phase = ProverbWeaverPhase.playing;
    });
  }

  void _tapFragment(String fragment) {
    if (_phase != ProverbWeaverPhase.playing) return;
    if (!_remaining.contains(fragment)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _remaining.remove(fragment);
      _assembled.add(fragment);
    });
    if (_assembled.length == _round!.record.fragments.length) {
      _submitAssembly();
    }
  }

  void _submitAssembly() {
    final record = _round!.record;
    final ok = assemblyMatches(record, _assembled);
    if (!ok) {
      setState(() => _phase = ProverbWeaverPhase.wrong);
      return;
    }
    setState(() => _phase = ProverbWeaverPhase.hearProverb);
  }

  void _continueAfterHear() {
    setState(() => _phase = ProverbWeaverPhase.situation);
  }

  void _pickSituation(ProverbSituationChoice choice) {
    if (_phase != ProverbWeaverPhase.situation) return;
    if (choice.isCorrect) {
      _correctCount++;
      setState(() => _phase = ProverbWeaverPhase.correct);
    } else {
      setState(() => _phase = ProverbWeaverPhase.whyWrong);
    }
  }

  void _advance() {
    _roundIndex++;
    if (_roundIndex >= _maxRounds) {
      setState(() => _phase = ProverbWeaverPhase.results);
      return;
    }
    final record = pickRecordForLanguage(widget.language, _rng);
    if (record == null) {
      setState(() {
        _phase = ProverbWeaverPhase.error;
        _loadError = errorCopy;
      });
      return;
    }
    unawaited(_startRound(record));
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.onOpenLegacyUnlocker != null)
            TextButton(
              onPressed: widget.onOpenLegacyUnlocker,
              child: const Text(legacyLinkLabel),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          child: _bodyForPhase(context, reducedMotion),
        ),
      ),
    );
  }

  Widget _bodyForPhase(BuildContext context, bool reducedMotion) {
    switch (_phase) {
      case ProverbWeaverPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case ProverbWeaverPhase.lockedBelowB1:
        return _StateMessage(
          key: const ValueKey('locked'),
          message: lockedCopy,
          actionLabel: 'Back to Arcade',
          onAction: widget.onBack ?? () => Navigator.of(context).pop(),
        );
      case ProverbWeaverPhase.error:
        return _StateMessage(
          key: const ValueKey('error'),
          message: _loadError ?? errorCopy,
          actionLabel: 'Try again',
          onAction: () {
            setState(() => _phase = ProverbWeaverPhase.loading);
            unawaited(_bootstrap());
          },
        );
      case ProverbWeaverPhase.offline:
        return _StateMessage(
          key: const ValueKey('offline'),
          message:
              'You are offline. We saved your place — reconnect to hear licensed proverb audio.',
          actionLabel: 'Back',
          onAction: widget.onBack ?? () => Navigator.of(context).pop(),
        );
      case ProverbWeaverPhase.results:
        return _buildResults(context);
      default:
        return Padding(
          key: ValueKey(_phase.name),
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!proverbWeaverUnlockedForLevel(widget.learnerLevel))
                const _PracticeBanner(label: practiceLabel),
              Text(
                instructions,
                style: PanAfricanTypography.bodyMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              if (_round != null) _proverbHeader(context),
              SizedBox(height: PanAfricanSpacing.md),
              Expanded(child: _innerBody(context)),
            ],
          ),
        );
    }
  }

  Widget _proverbHeader(BuildContext context) {
    final record = _round!.record;
    return Semantics(
      container: true,
      label: 'Proverb in ${record.languageCode}',
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                record.translationEn,
                style: PanAfricanTypography.titleSmall(context),
              ),
              if (record.usageNoteEn.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: PanAfricanSpacing.xs),
                  child: Text(
                    record.usageNoteEn,
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _innerBody(BuildContext context) {
    switch (_phase) {
      case ProverbWeaverPhase.playing:
        return _assemblyBoard(context);
      case ProverbWeaverPhase.hearProverb:
        return _hearPanel(context);
      case ProverbWeaverPhase.situation:
        return _situationPicker(context);
      case ProverbWeaverPhase.whyWrong:
        return _StateMessage(
          message: whyWrongCopy,
          actionLabel: 'Next proverb',
          onAction: _advance,
        );
      case ProverbWeaverPhase.correct:
      case ProverbWeaverPhase.wrong:
        return _roundSummary(context);
      case ProverbWeaverPhase.ready:
      case ProverbWeaverPhase.practiceMode:
        return _assemblyBoard(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _assemblyBoard(BuildContext context) {
    return ListView(
      children: [
        Text(
          'Your weave',
          style: PanAfricanTypography.labelLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Wrap(
          spacing: PanAfricanSpacing.xs,
          runSpacing: PanAfricanSpacing.xs,
          children: [
            for (final word in _assembled)
              Chip(label: Text(word)),
            if (_assembled.isEmpty)
              Text(
                'Tap tiles below in order',
                style: PanAfricanTypography.bodySmall(context),
              ),
          ],
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Text(
          'Word tiles',
          style: PanAfricanTypography.labelLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Wrap(
          spacing: PanAfricanSpacing.sm,
          runSpacing: PanAfricanSpacing.sm,
          children: [
            for (final word in _remaining)
              Semantics(
                button: true,
                label: 'Add $word to proverb',
                child: FilledButton.tonal(
                  onPressed: () => _tapFragment(word),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(48.w, 48.h),
                  ),
                  child: Text(word),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _hearPanel(BuildContext context) {
    final record = _round!.record;
    final canPlay = proverbAudioPlayable(record);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.format_quote,
          size: 40,
          semanticLabel: 'Proverb complete',
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          record.text,
          style: PanAfricanTypography.headlineSmall(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          record.translationEn,
          style: PanAfricanTypography.bodyMedium(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Text(
          canPlay
              ? 'Licensed audio is available for this proverb.'
              : 'Read it aloud with your teacher — we do not play unverified synthesis here.',
          style: PanAfricanTypography.bodySmall(context),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton(
          onPressed: _continueAfterHear,
          child: const Text('Choose the situation'),
        ),
      ],
    );
  }

  Widget _situationPicker(BuildContext context) {
    final choices = _round?.situationOrder ?? const [];
    return ListView(
      children: [
        Text(
          'When would people say this proverb?',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        for (final choice in choices)
          Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
            child: Semantics(
              button: true,
              label: choice.labelEn,
              child: FilledButton.tonal(
                onPressed: () => _pickSituation(choice),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(52.h),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(choice.labelEn),
              ),
            ),
          ),
      ],
    );
  }

  Widget _roundSummary(BuildContext context) {
    final won = _phase == ProverbWeaverPhase.correct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          won ? Icons.check_circle : Icons.error_outline,
          size: 48,
          color: won
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          semanticLabel: won ? 'Correct' : 'Incorrect weave',
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          won ? 'Well woven!' : 'Order matters — try the next one.',
          style: PanAfricanTypography.titleMedium(context),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton(
          onPressed: _advance,
          child: Text(_roundIndex >= _maxRounds ? 'See results' : 'Next proverb'),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Session complete',
            style: PanAfricanTypography.headlineSmall(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            '$_correctCount of $_maxRounds situations matched',
            style: PanAfricanTypography.titleMedium(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PanAfricanSpacing.lg),
          FilledButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            child: const Text('Back to Arcade'),
          ),
        ],
      ),
    );
  }
}

class ProverbWeaverPreview extends StatelessWidget {
  const ProverbWeaverPreview({
    super.key,
    required this.phaseLabel,
    required this.hintEn,
    required this.body,
  });

  final String phaseLabel;
  final String hintEn;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(phaseLabel, style: theme.textTheme.titleMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(hintEn, style: theme.textTheme.bodyMedium),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Text(label, style: PanAfricanTypography.bodySmall(context)),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Text(
                message,
                style: PanAfricanTypography.bodyLarge(context),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
