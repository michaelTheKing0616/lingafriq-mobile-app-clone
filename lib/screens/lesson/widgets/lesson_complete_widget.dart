import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Header-band colours for the three result tiles. All carry white labels at
/// >= 4.5:1 (checked in lesson_complete_widget_test.dart).
const kLessonResultXp = Color(0xFF8C5A00);
const kLessonResultAccuracy = PanAfricanColors.primary;
const kLessonResultTime = Color(0xFFA3322B);

/// Cast who celebrate the learner (bundled stills shared with the tutorial).
const kLessonCompleteCast = [
  'assets/images/cast_still_Amara.png',
  'assets/images/cast_still_Kofi.png',
];

/// Lesson complete (lesson-flow pack: cheering characters over a ground line,
/// big headline, labelled stat tiles, actions pinned to a bottom bar).
///
/// One readable screen for everyone: entrance motion is a short stagger that
/// is skipped when the OS asks for reduced motion. Share is gated (not cut):
/// hidden for child / teen profiles, paused while offline.
class LessonCompleteWidget extends StatelessWidget {
  final int totalXP;
  final int comboBonus;
  final double accuracy;
  final int timeTaken;
  final int bestCombo;

  /// Questions answered in this lesson; 0 means a teach-only lesson, so the
  /// accuracy tile says "Not quizzed" instead of a misleading 0%.
  final int totalQuestions;

  /// False when the device has no connection: progress is already stored
  /// locally, so we say so and pause sharing.
  final bool online;

  /// Child / teen profiles never see outward sharing.
  final bool childMode;
  final VoidCallback onContinue;
  final VoidCallback? onShare;

  const LessonCompleteWidget({
    super.key,
    required this.totalXP,
    this.comboBonus = 0,
    required this.accuracy,
    required this.timeTaken,
    this.bestCombo = 0,
    this.totalQuestions = 1,
    this.online = true,
    this.childMode = false,
    required this.onContinue,
    this.onShare,
  });

  bool get _quizzed => totalQuestions > 0;

  String _time(AppLocalizations l) {
    final m = timeTaken ~/ 60, s = timeTaken % 60;
    return m > 0 ? l.lcTimeMinSec(m, s) : l.lcTimeSec(s);
  }

  String _message(AppLocalizations l) {
    if (!_quizzed) return l.lcMsgNoQuiz;
    if (accuracy >= 90) return l.lcMsgGreat;
    if (accuracy >= 75) return l.lcMsgGood;
    if (accuracy >= 55) return l.lcMsgSteady;
    return l.lcMsgReview;
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final gap = PanAfricanSpacing.md;
    final accuracyText = _quizzed
        ? l.lcPercent(accuracy.round())
        : l.lcNoQuizValue;
    final showShare = onShare != null && !childMode;

    Widget enter(Widget w, int i) => motion
        ? w
              .animate(delay: (120 * i).ms)
              .fadeIn(duration: 280.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic)
        : w;

    // Large text: tiles become full-width rows so labels never break
    // mid-word; normal text keeps the pack's three side-by-side tiles.
    final bigText = MediaQuery.textScalerOf(context).scale(10) > 13;
    final stats = [
      (l.lcStatXp, '+$totalXP', Icons.bolt_rounded, kLessonResultXp),
      (
        l.lcStatAccuracy,
        accuracyText,
        Icons.track_changes_rounded,
        kLessonResultAccuracy,
      ),
      (l.lcStatTime, _time(l), Icons.timer_rounded, kLessonResultTime),
    ];
    Widget tile(int i) => enter(
      _ResultTile(
        key: Key('lc-tile-$i'),
        label: stats[i].$1,
        value: stats[i].$2,
        icon: stats[i].$3,
        color: stats[i].$4,
        row: bigText,
      ),
      i + 2,
    );
    final tiles = Semantics(
      container: true,
      label: l.lcSummaryA11y(totalXP, accuracyText, _time(l)),
      child: ExcludeSemantics(
        child: bigText
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) SizedBox(height: PanAfricanSpacing.xs),
                    tile(i),
                  ],
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) SizedBox(width: PanAfricanSpacing.xs),
                      Expanded(child: tile(i)),
                    ],
                  ],
                ),
              ),
      ),
    );

    final chips = [
      if (bestCombo > 1)
        _Chip(
          icon: Icons.local_fire_department_rounded,
          text: l.lcBestRun(bestCombo),
        ),
      if (comboBonus > 0)
        _Chip(
          icon: Icons.auto_awesome_rounded,
          text: l.lcComboBonus(comboBonus),
        ),
    ];

    final body = LayoutBuilder(
      builder: (context, box) {
        final heroH = (box.maxHeight * 0.30).clamp(96.0, 260.0);
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: gap, vertical: gap),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight - gap * 2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    enter(_Hero(height: heroH, label: l.lcHeroA11y), 0),
                    SizedBox(height: gap),
                    enter(
                      Text(
                        l.lessonComplete,
                        key: const Key('lc-title'),
                        textAlign: TextAlign.center,
                        style: PanAfricanTypography.headlineSmall(context)
                            .copyWith(
                              fontWeight: FontWeight.w800,
                              color: kLessonResultXp,
                            ),
                      ),
                      1,
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      _message(l),
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.bodyMedium(
                        context,
                      ).copyWith(color: scheme.onSurfaceVariant),
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                    tiles,
                    if (chips.isNotEmpty) ...[
                      SizedBox(height: gap),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: PanAfricanSpacing.xs,
                        runSpacing: PanAfricanSpacing.xs,
                        children: chips,
                      ),
                    ],
                    if (!online) ...[
                      SizedBox(height: gap),
                      _OfflineNote(text: l.lcOffline),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final rtl = Directionality.of(context) == TextDirection.rtl;
    final compactShare = bigText || MediaQuery.sizeOf(context).width < 360;
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(gap, PanAfricanSpacing.sm, gap, gap),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Row(
              children: [
                if (showShare) ...[
                  _ShareButton(
                    compact: compactShare,
                    label: l.lcShare,
                    a11y: l.lcShareA11y,
                    onPressed: online ? onShare : null,
                  ),
                  SizedBox(width: PanAfricanSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: Semantics(
                    label: l.lcContinueA11y,
                    button: true,
                    excludeSemantics: true,
                    child: PanAfricanButton(
                      key: const Key('lc-continue'),
                      onPressed: onContinue,
                      label: l.lcContinue,
                      icon: rtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      backgroundColor: PanAfricanColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      child: Column(
        children: [
          Expanded(child: body),
          bar,
        ],
      ),
    );
  }
}

/// Two cast members cheering on a sunburst in the brand's kente colours, with
/// a ground line (layout borrowed from the pack, art and colours our own).
class _Hero extends StatelessWidget {
  const _Hero({required this.height, required this.label});
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Overlap the pair toward each other in either reading direction.
    final dir = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return Semantics(
      image: true,
      label: label,
      child: SizedBox(
        key: const Key('lc-hero'),
        height: height,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: SunburstPainter()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, a) in kLessonCompleteCast.indexed)
                  Flexible(
                    child: Transform.translate(
                      offset: Offset(
                        (i == 0 ? 1 : -1) * dir * height * 0.08,
                        0,
                      ),
                      child: Image.asset(
                        a,
                        key: Key('lc-cast-$i'),
                        height: height * (i == 0 ? 0.98 : 0.86),
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Code-drawn celebration: alternating gold / green / red rays fading out
/// from behind the cast, plus a soft ground ellipse.
class SunburstPainter extends CustomPainter {
  const SunburstPainter();

  static const rays = [
    Color(0xFFF2B705),
    PanAfricanColors.primary,
    Color(0xFFC0392B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.55);
    final r = size.height * 0.62;
    const n = 18;
    for (var i = 0; i < n; i++) {
      final a0 = (i / n) * 2 * math.pi;
      final a1 = a0 + math.pi / n * 0.55;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * math.cos(a0), c.dy + r * math.sin(a0))
        ..lineTo(c.dx + r * math.cos(a1), c.dy + r * math.sin(a1))
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [
              rays[i % 3].withValues(alpha: 0.32),
              rays[i % 3].withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 4),
        width: size.height * 1.3,
        height: 10,
      ),
      Paint()..color = const Color(0x22000000),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pack-style result tile: coloured header band with a caps label, white
/// body with icon + value.
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.row = false,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  /// Full-width row form (used at large text scales).
  final bool row;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    if (row) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: BorderDirectional(
            start: BorderSide(color: color, width: 6),
            top: BorderSide(color: color, width: 2),
            bottom: BorderSide(color: color, width: 2),
            end: BorderSide(color: color, width: 2),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24.sp),
              SizedBox(width: PanAfricanSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: PanAfricanTypography.labelLarge(
                    context,
                  ).copyWith(color: color, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                value,
                style: PanAfricanTypography.titleMedium(
                  context,
                ).copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.xxs,
              vertical: PanAfricanSpacing.xxs,
            ),
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: PanAfricanTypography.labelSmall(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.xxs,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 20.sp),
                        SizedBox(width: PanAfricanSpacing.xxs),
                        Text(
                          value,
                          textAlign: TextAlign.center,
                          style: PanAfricanTypography.titleMedium(
                            context,
                          ).copyWith(color: color, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.compact,
    required this.label,
    required this.a11y,
    required this.onPressed,
  });
  final bool compact;
  final String label, a11y;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = OutlinedButton.styleFrom(
      minimumSize: Size(AdaptiveLayout.minTouchTarget, 48.h),
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
      foregroundColor: PanAfricanColors.primary,
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    final button = compact
        ? OutlinedButton(
            key: const Key('lc-share'),
            onPressed: onPressed,
            style: style,
            child: Icon(Icons.ios_share_rounded, size: 22.sp),
          )
        : OutlinedButton.icon(
            key: const Key('lc-share'),
            onPressed: onPressed,
            icon: Icon(Icons.ios_share_rounded, size: 20.sp),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: PanAfricanTypography.labelLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            style: style,
          );
    final child = Semantics(
      label: a11y,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: Tooltip(message: label, excludeFromSemantics: true, child: button),
    );
    return compact ? child : Expanded(child: child);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PanAfricanColors.onTertiaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm,
          vertical: PanAfricanSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: PanAfricanColors.onTertiaryContainer,
            ),
            SizedBox(width: PanAfricanSpacing.xxs),
            Flexible(
              child: Text(
                text,
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  color: PanAfricanColors.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PanAfricanCard(
      key: const Key('lc-offline'),
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.onSurfaceVariant),
          SizedBox(width: PanAfricanSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: PanAfricanTypography.bodySmall(
                context,
              ).copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
