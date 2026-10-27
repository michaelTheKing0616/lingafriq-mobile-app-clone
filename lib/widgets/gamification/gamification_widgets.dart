// Gamification widgets export file
//
// Usage:
// ```dart
// import 'package:lingafriq/widgets/gamification/gamification_widgets.dart';
// ```

import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

export 'xp_progress_widget.dart';
export 'badge_gallery_widget.dart';
export 'streak_indicator_widget.dart';
export 'achievement_celebration_modal.dart';
export 'xp_gain_overlay.dart';
export 'daily_challenges_widget.dart';
export 'league_widget.dart';
export 'hearts_widget.dart';
export '../../screens/passport/cando_badge_screen.dart';

/// P10-910 — generic badge gallery is gated; meaningful status is can-do badges only.
class VerifiedCanDoStatusBanner extends StatelessWidget {
  const VerifiedCanDoStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Can-do badges replace generic badges',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: PanAfricanColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Your shareable badges come from can-do checkpoints — not magic items or the ancestral tree.',
          style: PanAfricanTypography.bodyMedium(context),
        ),
      ),
    );
  }
}
