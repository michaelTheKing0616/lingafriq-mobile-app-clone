import 'package:flutter/material.dart';
import 'package:lingafriq/services/lens/home_safari_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Today-tab Home Safari quest card (P7-910). Embed on the learner Today/home surface.
class HomeSafariCard extends StatelessWidget {
  const HomeSafariCard({
    super.key,
    required this.snapshot,
    this.onOpenLens,
    this.reduceMotion = false,
  });

  final HomeSafariQuestSnapshot snapshot;
  final VoidCallback? onOpenLens;
  final bool reduceMotion;

  static bool shouldShowOnTodayTab(HomeSafariQuestSnapshot snapshot) {
    return snapshot.phase == HomeSafariQuestPhase.active ||
        snapshot.phase == HomeSafariQuestPhase.complete ||
        snapshot.phase == HomeSafariQuestPhase.expired;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShowOnTodayTab(snapshot)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark
        ? PanAfricanColors.secondaryLight
        : PanAfricanColors.secondary;

    final title = _titleForPhase(snapshot.phase);
    final subtitle = _subtitle(snapshot);
    final progress = snapshot.targetCount == 0
        ? 0.0
        : snapshot.confirmedCount / snapshot.targetCount;

    return Semantics(
      label: 'Home Safari. $subtitle',
      child: Material(
        color: isDark
            ? PanAfricanColors.surfaceDark
            : PanAfricanColors.surfaceLight,
        elevation: 2,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: InkWell(
          onTap: snapshot.phase == HomeSafariQuestPhase.active
              ? onOpenLens
              : null,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.explore_rounded, color: accent),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: PanAfricanTypography.titleMedium(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  subtitle,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                if (snapshot.phase == HomeSafariQuestPhase.active ||
                    snapshot.phase == HomeSafariQuestPhase.complete) ...[
                  SizedBox(height: PanAfricanSpacing.md),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(PanAfricanRadius.sm),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: PanAfricanColors.neutralLight,
                      color: accent,
                    ),
                  ),
                ],
                if (snapshot.phase == HomeSafariQuestPhase.active &&
                    onOpenLens != null) ...[
                  SizedBox(height: PanAfricanSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onOpenLens,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Open Lens'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleForPhase(HomeSafariQuestPhase phase) {
    switch (phase) {
      case HomeSafariQuestPhase.complete:
        return 'Home Safari complete';
      case HomeSafariQuestPhase.expired:
        return 'Home Safari ended';
      case HomeSafariQuestPhase.active:
        return 'Home Safari';
      case HomeSafariQuestPhase.empty:
        return 'Home Safari';
    }
  }

  String _subtitle(HomeSafariQuestSnapshot snapshot) {
    switch (snapshot.phase) {
      case HomeSafariQuestPhase.complete:
        return 'safari.complete — you found ${snapshot.progressLabel()} kitchen items.';
      case HomeSafariQuestPhase.expired:
        return 'This week\'s quest expired at ${snapshot.progressLabel()}. A new quest starts next week.';
      case HomeSafariQuestPhase.active:
        return 'safari.progress — find ${snapshot.targetCount} kitchen items: ${snapshot.progressLabel()}.';
      case HomeSafariQuestPhase.empty:
        return '';
    }
  }
}
