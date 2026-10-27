import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/pan_african_design_system.dart';
import 'morphology_slots.dart';
import 'word_forge_game.dart';
import 'yoruba_serial_verbs.dart';

enum WordForgePhase {
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
  invalidForm,
}

/// Flagship Word Forge (P8-926): Swahili / Zulu morphology slots.
class WordForgeScreen extends StatefulWidget {
  const WordForgeScreen({
    super.key,
    required this.language,
    this.onBack,
    this.initialRound,
    this.initialPhase,
  });

  static const errorCopy = YorubaSerialVerbsCopy.error;

  final String language;
  final VoidCallback? onBack;

  final WordForgeRound? initialRound;
  final WordForgePhase? initialPhase;

  @override
  State<WordForgeScreen> createState() => _WordForgeScreenState();
}

class _WordForgeScreenState extends State<WordForgeScreen> {
  static const invalidFormTitle = 'Invalid form';

  bool get _isYoruba {
    final lang = widget.language.toLowerCase();
    return lang == 'yo' || lang == 'yoruba';
  }

  String get _title =>
      _isYoruba ? YorubaSerialVerbsCopy.title : 'Word Forge';

  String get _instructions => _isYoruba
      ? YorubaSerialVerbsCopy.instructions
      : 'Tap each slot to build the verb. Watch the gloss update as you go.';

  String get _whyWrongCopy => _isYoruba
      ? YorubaSerialVerbsCopy.whyWrong
      : 'That combination breaks the grammar rule for this prompt. Read the hint and try again.';

  String get _practiceLabel => _isYoruba
      ? YorubaSerialVerbsCopy.practiceLabel
      : 'Practice — morphology rounds do not affect league rank until scoring is verified.';

  WordForgePhase _phase = WordForgePhase.loading;
  WordForgeSessionPlan? _plan;
  int _roundCursor = 0;
  int _correctCount = 0;
  String? _lastInvalidRule;
  final Random _rng = Random();

  WordForgeRound? get _activeRound {
    final plan = _plan;
    if (plan == null || _roundCursor >= plan.rounds.length) return null;
    return plan.rounds[_roundCursor];
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPhase != null) {
      _phase = widget.initialPhase!;
      if (widget.initialRound != null) {
        _plan = WordForgeSessionPlan(
          languageCode: widget.language,
          rounds: [widget.initialRound!],
          practiceNotScored: true,
        );
      }
    } else {
      unawaited(_bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    if (!wordForgeLanguageSupported(widget.language)) {
      setState(() => _phase = WordForgePhase.error);
      return;
    }
    try {
      final plan = buildWordForgeSession(
        languageCode: widget.language,
        rng: _rng,
      );
      setState(() {
        _plan = plan;
        _phase = WordForgePhase.playing;
      });
    } catch (_) {
      setState(() => _phase = WordForgePhase.error);
    }
  }

  void _onSlotPick(WordForgeSlotDefinition slot, MorphemeOption option) {
    final round = _activeRound;
    if (round == null || _phase != WordForgePhase.playing) return;
    final updated = withSelection(
      round,
      setSlotOption(
        current: round.selection,
        kind: slot.kind,
        option: option,
      ),
    );
    final plan = _plan!;
    final rounds = List<WordForgeRound>.from(plan.rounds);
    rounds[_roundCursor] = updated;
    setState(() {
      _plan = WordForgeSessionPlan(
        languageCode: plan.languageCode,
        rounds: rounds,
        practiceNotScored: plan.practiceNotScored,
      );
    });
  }

  void _submit() {
    final round = _activeRound;
    if (round == null) return;
    final validation = validateWordForge(
      template: round.template,
      selection: round.selection,
    );
    if (validation.isCorrect) {
      _correctCount++;
      setState(() => _phase = WordForgePhase.correct);
      return;
    }
    if (validation.invalidRule != null &&
        validation.invalidRule!.contains('every slot')) {
      setState(() {
        _phase = WordForgePhase.invalidForm;
        _lastInvalidRule = validation.invalidRule;
      });
      return;
    }
    setState(() {
      _phase = WordForgePhase.wrong;
      _lastInvalidRule = validation.invalidRule ?? _whyWrongCopy;
    });
  }

  void _nextRound() {
    final plan = _plan;
    if (plan == null) return;
    if (_roundCursor + 1 >= plan.rounds.length) {
      setState(() => _phase = WordForgePhase.results);
      return;
    }
    setState(() {
      _roundCursor++;
      _phase = WordForgePhase.playing;
      _lastInvalidRule = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LingAfriqScaffoldLite(
      title: _title,
      onBack: widget.onBack,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_plan?.practiceNotScored == true)
                Padding(
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                  child: Text(
                    _practiceLabel,
                    style: PanAfricanTypography.bodySmall(context).copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(child: _body(context, reduceMotion)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool reduceMotion) {
    switch (_phase) {
      case WordForgePhase.loading:
        return const Center(child: CircularProgressIndicator());
      case WordForgePhase.error:
        return _StateMessage(
          message: WordForgeScreen.errorCopy,
          icon: Icons.translate_rounded,
        );
      case WordForgePhase.results:
        return _ResultsPane(
          correct: _correctCount,
          total: _plan?.rounds.length ?? 0,
          onDone: widget.onBack,
        );
      case WordForgePhase.correct:
        return _FeedbackPane(
          headline: 'Well built',
          detail: composeWordForge(_activeRound!.selection).glossEn,
          isCorrect: true,
          onContinue: _nextRound,
        );
      case WordForgePhase.wrong:
      case WordForgePhase.invalidForm:
      case WordForgePhase.whyWrong:
        return _FeedbackPane(
          headline: _phase == WordForgePhase.invalidForm
              ? invalidFormTitle
              : 'Not quite',
          detail: _lastInvalidRule ?? _whyWrongCopy,
          isCorrect: false,
          showWhy: _phase == WordForgePhase.wrong,
          onWhy: () => setState(() => _phase = WordForgePhase.whyWrong),
          onContinue: () => setState(() => _phase = WordForgePhase.playing),
        );
      case WordForgePhase.playing:
      case WordForgePhase.ready:
      case WordForgePhase.offline:
      case WordForgePhase.practiceMode:
        return _PlayingPane(
          round: _activeRound,
          onPick: _onSlotPick,
          onSubmit: _submit,
          reduceMotion: reduceMotion,
        );
    }
  }
}

class LingAfriqScaffoldLite extends StatelessWidget {
  const LingAfriqScaffoldLite({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PanAfricanColors.surface,
      appBar: AppBar(
        backgroundColor: PanAfricanColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(title, style: PanAfricanTypography.titleMedium(context)),
      ),
      body: child,
    );
  }
}

class _PlayingPane extends StatelessWidget {
  const _PlayingPane({
    required this.round,
    required this.onPick,
    required this.onSubmit,
    required this.reduceMotion,
  });

  final WordForgeRound? round;
  final void Function(WordForgeSlotDefinition, MorphemeOption) onPick;
  final VoidCallback onSubmit;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (round == null) {
      return const _StateMessage(message: WordForgeScreen.errorCopy);
    }
    final composed = composeWordForge(round!.selection);
    return ListView(
      children: [
        Text(
          round!.template.promptEn,
          style: PanAfricanTypography.titleSmall(context),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          round!.template.contextEn,
          style: PanAfricanTypography.bodySmall(context),
        ),
        if (isYorubaSerialTemplate(round!.template)) ...[
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            'Tone marks come from the lexicon — we never auto-generate them.',
            style: PanAfricanTypography.bodySmall(context).copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: PanAfricanSpacing.md),
        Semantics(
          label: 'Built form ${composed.surface}',
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: PanAfricanColors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: PanAfricanRadius.mdBR,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displaySlotsLine(round!.selection),
                  style: PanAfricanTypography.headlineSmall(context),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Text(
                  composed.glossEn,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.lg),
        for (final slot in round!.template.slots) ...[
          Text(slot.labelEn, style: PanAfricanTypography.labelLarge(context)),
          SizedBox(height: PanAfricanSpacing.xs),
          Wrap(
            spacing: PanAfricanSpacing.xs,
            runSpacing: PanAfricanSpacing.xs,
            children: [
              for (final opt in slot.poolOptions())
                _SlotChip(
                  label: opt.surface.isEmpty ? '∅' : opt.surface,
                  gloss: opt.glossEn,
                  selected: round!.selection.byKind[slot.kind]?.id == opt.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPick(slot, opt);
                  },
                ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md),
        ],
        SizedBox(
          height: 48.h,
          child: FilledButton(
            onPressed: onSubmit,
            child: const Text('Check form'),
          ),
        ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.gloss,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String gloss;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$label, $gloss',
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHigh,
        borderRadius: PanAfricanRadius.mdBR,
        child: InkWell(
          onTap: onTap,
          borderRadius: PanAfricanRadius.mdBR,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 48.h, minWidth: 48.w),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.sm,
                vertical: PanAfricanSpacing.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  Text(
                    gloss,
                    style: PanAfricanTypography.bodySmall(context).copyWith(
                      color: selected
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackPane extends StatelessWidget {
  const _FeedbackPane({
    required this.headline,
    required this.detail,
    required this.isCorrect,
    required this.onContinue,
    this.showWhy = false,
    this.onWhy,
  });

  final String headline;
  final String detail;
  final bool isCorrect;
  final VoidCallback onContinue;
  final bool showWhy;
  final VoidCallback? onWhy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 48.sp,
                  color: isCorrect
                      ? PanAfricanColors.primary
                      : PanAfricanColors.error,
                  semanticLabel: isCorrect ? 'Correct' : 'Incorrect',
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Text(headline, style: PanAfricanTypography.titleMedium(context)),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(detail, style: PanAfricanTypography.bodyMedium(context)),
              ],
            ),
          ),
        ),
        if (showWhy && onWhy != null)
          TextButton(onPressed: onWhy, child: const Text('Why?')),
        FilledButton(onPressed: onContinue, child: const Text('Continue')),
      ],
    );
  }
}

class _ResultsPane extends StatelessWidget {
  const _ResultsPane({
    required this.correct,
    required this.total,
    this.onDone,
  });

  final int correct;
  final int total;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'You forged $correct of $total',
          style: PanAfricanTypography.headlineSmall(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: PanAfricanSpacing.lg),
        FilledButton(
          onPressed: onDone ?? () => Navigator.of(context).maybePop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.message,
    this.icon,
  });

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 40.sp),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            message,
            style: PanAfricanTypography.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
