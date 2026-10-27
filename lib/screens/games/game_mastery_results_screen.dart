import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../games/gamekit/game_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../utils/pan_african_design_system.dart';

/// Standard post-game results for GameKit sessions (P8-915).
class GameMasteryResultsScreen extends ConsumerWidget {
  const GameMasteryResultsScreen({
    super.key,
    required this.payload,
    this.onDone,
  });

  final GameMasteryResultsPayload payload;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final session = payload.session;
    final accuracyPct = (session.accuracy * 100).round();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.gamesGameMasteryResultsTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg.w, vertical: PanAfricanSpacing.md.h),
          children: [
            if (payload.practiceNotScored)
              Semantics(
                label: l10n.gamesGameMasteryResultsPracticeLabel,
                child: MaterialBanner(
                  backgroundColor: cs.surfaceContainerHighest,
                  leading: const Icon(Icons.hearing_outlined),
                  content: Text(l10n.gamesGameMasteryResultsPracticeLabel),
                  actions: const [SizedBox.shrink()],
                ),
              ),
            SizedBox(height: PanAfricanSpacing.md.h),
            Text(
              l10n.gamesGameMasteryResultsInstructions,
              style: PanAfricanTypography.bodyLarge(context, color: cs.onSurfaceVariant),
            ),
            SizedBox(height: PanAfricanSpacing.lg.h),
            _SummaryCard(
              accuracyLabel: '$accuracyPct%',
              turnsLabel: '${session.correctCount}/${session.totalTurns}',
              xpLabel: payload.serverXpAwarded != null
                  ? '+${payload.serverXpAwarded}'
                  : '—',
            ),
            SizedBox(height: PanAfricanSpacing.lg.h),
            Text(
              l10n.gamesGameMasteryResultsSkillsHeading,
              style: PanAfricanTypography.titleMedium(context, color: cs.onSurface),
            ),
            SizedBox(height: PanAfricanSpacing.sm.h),
            if (payload.skillDeltas.isEmpty)
              Text(
                l10n.gamesGameMasteryResultsError,
                style: PanAfricanTypography.bodyMedium(context, color: cs.error),
              )
            else
              ...payload.skillDeltas.map(
                (delta) => _SkillDeltaRow(delta: delta, l10n: l10n, reduceMotion: reduceMotion),
              ),
            SizedBox(height: PanAfricanSpacing.xl.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (onDone != null) {
                    onDone!();
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                child: Text(l10n.gamesGameMasteryResultsDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.accuracyLabel,
    required this.turnsLabel,
    required this.xpLabel,
  });

  final String accuracyLabel;
  final String turnsLabel;
  final String xpLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md.r),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(child: _StatTile(label: 'Accuracy', value: accuracyLabel)),
          Expanded(child: _StatTile(label: 'Correct', value: turnsLabel)),
          Expanded(child: _StatTile(label: 'XP', value: xpLabel)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: PanAfricanTypography.titleLarge(context)),
        Text(label, style: PanAfricanTypography.labelMedium(context)),
      ],
    );
  }
}

class _SkillDeltaRow extends StatelessWidget {
  const _SkillDeltaRow({
    required this.delta,
    required this.l10n,
    required this.reduceMotion,
  });

  final GameMasterySkillDelta delta;
  final AppLocalizations l10n;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final changeLabel = switch (delta.changeKind) {
      GameMasteryChangeKind.improved => l10n.gamesGameMasteryResultsImproved,
      GameMasteryChangeKind.declined => l10n.gamesGameMasteryResultsDeclined,
      GameMasteryChangeKind.noChange => l10n.gamesGameMasteryResultsNoChange,
    };
    final changeIcon = switch (delta.changeKind) {
      GameMasteryChangeKind.improved => Icons.trending_up,
      GameMasteryChangeKind.declined => Icons.trending_down,
      GameMasteryChangeKind.noChange => Icons.horizontal_rule,
    };
    final changeColor = switch (delta.changeKind) {
      GameMasteryChangeKind.improved => PanAfricanColors.primary,
      GameMasteryChangeKind.declined => PanAfricanColors.kenteRed,
      GameMasteryChangeKind.noChange => cs.onSurfaceVariant,
    };

    return Semantics(
      label:
          '${delta.skillId}: ${delta.masteryBeforePercent()}% to ${delta.masteryAfterPercent()}%, $changeLabel',
      child: Card(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm.h),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(changeIcon, color: changeColor, semanticLabel: changeLabel),
              SizedBox(width: PanAfricanSpacing.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _humanizeSkillId(delta.skillId),
                      style: PanAfricanTypography.titleSmall(context),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${delta.masteryBeforePercent()}% → ${delta.masteryAfterPercent()}%',
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      changeLabel,
                      style: PanAfricanTypography.labelLarge(context, color: changeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _humanizeSkillId(String id) {
    return id.replaceAll('_', ' ');
  }
}
