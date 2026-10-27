import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../games/gamekit/all_games_registry.dart';
import '../../games/gamekit/game_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../learning/learner_model/learner_skill_state.dart';
import '../../learning/skill_graph/skill_registry.dart';
import '../../providers/learner_model_provider.dart';
import '../../utils/pan_african_design_system.dart';

/// Per-game skill impact map from learner-model events only (P8-932).
class GameMasteryMapScreen extends ConsumerStatefulWidget {
  const GameMasteryMapScreen({
    super.key,
    required this.learnerId,
  });

  final String learnerId;

  @override
  ConsumerState<GameMasteryMapScreen> createState() => _GameMasteryMapScreenState();
}

class _GameMasteryMapScreenState extends ConsumerState<GameMasteryMapScreen> {
  String? _selectedSkillId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final rowsAsync = ref.watch(masteryMapSkillRowsProvider(widget.learnerId));
    final recordsAsync = ref.watch(masteryMapSessionRecordsProvider(widget.learnerId));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.gamesMasteryMapTitle),
      ),
      body: SafeArea(
        child: rowsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorBody(message: l10n.gamesMasteryMapError),
          data: (rows) {
            if (rows.isEmpty) {
              return _EmptyBody(message: l10n.gamesMasteryMapInstructions);
            }
            final selected = _selectedSkillId;
            final records = recordsAsync.maybeWhen(
              data: (v) => v,
              orElse: () => const <GameMasterySessionRecord>[],
            );
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.lg.w,
                vertical: PanAfricanSpacing.md.h,
              ),
              children: [
                Text(
                  l10n.gamesMasteryMapInstructions,
                  style: PanAfricanTypography.bodyLarge(context, color: cs.onSurfaceVariant),
                ),
                SizedBox(height: PanAfricanSpacing.lg.h),
                ...rows.map(
                  (row) => _SkillMapCard(
                    row: row,
                    l10n: l10n,
                    reduceMotion: reduceMotion,
                    expanded: selected == row.skillId,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedSkillId = selected == row.skillId ? null : row.skillId;
                      });
                    },
                    onGameTap: (gameId) {
                      HapticFeedback.lightImpact();
                      _showGameSessionsSheet(
                        context,
                        l10n: l10n,
                        gameId: gameId,
                        skillId: row.skillId,
                        records: records,
                        learnerId: widget.learnerId,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showGameSessionsSheet(
    BuildContext context, {
    required AppLocalizations l10n,
    required String gameId,
    required String skillId,
    required List<GameMasterySessionRecord> records,
    required String learnerId,
  }) {
    final sessions = sessionsForGameAndSkill(
      records: records,
      learnerId: learnerId,
      gameId: gameId,
      skillId: skillId,
    );
    final title = AllGamesRegistry.catalogEntryFor(gameId)?.name ?? gameId;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              PanAfricanSpacing.lg.w,
              PanAfricanSpacing.sm.h,
              PanAfricanSpacing.lg.w,
              PanAfricanSpacing.lg.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.titleMedium(ctx, color: cs.onSurface),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
                if (sessions.isEmpty)
                  Text(
                    l10n.gamesMasteryMapNotMeasured,
                    style: PanAfricanTypography.bodyMedium(ctx, color: cs.onSurfaceVariant),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm.h),
                      itemBuilder: (_, i) {
                        final s = sessions[i];
                        final delta = s.skillDeltas
                            .where((d) => d.skillId == skillId)
                            .toList();
                        final change = delta.isNotEmpty ? delta.first.changeKind : null;
                        final date = DateFormat.yMMMd().format(s.completedAt.toLocal());
                        final label = s.practiceNotScored
                            ? l10n.gamesMasteryMapPracticeLabel
                            : change == GameMasteryChangeKind.improved
                                ? l10n.gamesGameMasteryResultsImproved
                                : change == GameMasteryChangeKind.declined
                                    ? l10n.gamesGameMasteryResultsDeclined
                                    : l10n.gamesGameMasteryResultsNoChange;
                        return Semantics(
                          label: '$title, $date, $label',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            minVerticalPadding: PanAfricanSpacing.sm.h,
                            title: Text(date),
                            subtitle: Text(label),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkillMapCard extends StatelessWidget {
  const _SkillMapCard({
    required this.row,
    required this.l10n,
    required this.reduceMotion,
    required this.expanded,
    required this.onTap,
    required this.onGameTap,
  });

  final MasteryMapSkillRow row;
  final AppLocalizations l10n;
  final bool reduceMotion;
  final bool expanded;
  final VoidCallback onTap;
  final void Function(String gameId) onGameTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final skill = SkillRegistry.instance.findSkill(row.skillId);
    final title = skill?.name ?? row.skillId;
    final valueLabel = _valueLabel(l10n);

    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: PanAfricanRadius.lgBR,
        child: InkWell(
          borderRadius: PanAfricanRadius.lgBR,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: PanAfricanTypography.titleSmall(context, color: cs.onSurface),
                      ),
                    ),
                    Semantics(
                      label: valueLabel,
                      child: Text(
                        valueLabel,
                        style: PanAfricanTypography.labelLarge(
                          context,
                          color: row.valueKind == MasteryMapSkillValueKind.unsure
                              ? cs.outline
                              : cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (row.gameIds.isNotEmpty) ...[
                  SizedBox(height: PanAfricanSpacing.sm.h),
                  Text(
                    l10n.gamesMasteryMapGamesHeading,
                    style: PanAfricanTypography.bodySmall(context, color: cs.onSurfaceVariant),
                  ),
                ],
                AnimatedCrossFade(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                  crossFadeState:
                      expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: EdgeInsets.only(top: PanAfricanSpacing.sm.h),
                    child: Wrap(
                      spacing: PanAfricanSpacing.sm.w,
                      runSpacing: PanAfricanSpacing.sm.h,
                      children: row.gameIds.map((gameId) {
                        final gameTitle =
                            AllGamesRegistry.catalogEntryFor(gameId)?.name ?? gameId;
                        return Semantics(
                          button: true,
                          label: gameTitle,
                          child: ActionChip(
                            label: Text(gameTitle),
                            onPressed: () => onGameTap(gameId),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _valueLabel(AppLocalizations l10n) {
    switch (row.valueKind) {
      case MasteryMapSkillValueKind.notMeasured:
        return l10n.gamesMasteryMapNotMeasured;
      case MasteryMapSkillValueKind.unsure:
        return l10n.gamesMasteryMapUnsure;
      case MasteryMapSkillValueKind.masteryPercent:
      case MasteryMapSkillValueKind.scorerPercent:
        return '${row.masteryPercent ?? 0}%';
    }
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: PanAfricanTypography.bodyLarge(context),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: PanAfricanTypography.bodyLarge(context, color: cs.error),
        ),
      ),
    );
  }
}
