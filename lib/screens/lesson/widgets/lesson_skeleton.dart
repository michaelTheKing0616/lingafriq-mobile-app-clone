import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Static lesson-shaped placeholder shown while sections load: the brand
/// header band, step pills, a prompt card and three answer rows, so the
/// screen does not jump when content arrives. Static on purpose, so it
/// never animates for reduced-motion users.
class LessonSkeleton extends StatelessWidget {
  const LessonSkeleton({super.key, required this.caption});
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final block = scheme.onSurface.withValues(alpha: 0.08);
    Widget bar(double h, {double? w, double r = 12, Color? c}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c ?? block,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Semantics(
      key: const Key('lesson-skeleton'),
      liveRegion: true,
      label: caption,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 20,
                16,
                16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PanAfricanColors.tertiary,
                    PanAfricanColors.secondary,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(22, w: 140, c: Colors.white.withValues(alpha: 0.35)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: bar(
                            8,
                            r: 4,
                            c: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        bar(110, r: 20),
                        const SizedBox(height: 20),
                        for (var i = 0; i < 3; i++) ...[
                          bar(56, r: 16),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          caption,
                          textAlign: TextAlign.center,
                          style: PanAfricanTypography.bodyMedium(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
