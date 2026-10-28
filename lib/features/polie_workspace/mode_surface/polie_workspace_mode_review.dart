
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_args.dart';

Widget buildPolieReviewModeSurface(PolieModeSurfaceArgs a) {
  final layout = a.layout();
return SingleChildScrollView(
      key: a.key,
      padding: EdgeInsets.fromLTRB(layout.basePad, layout.basePad, layout.basePad, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          layout.introBanner(introDismissed: a.introDismissed, onDismissIntro: a.onDismissIntro),
          layout.errorBanner(a.modeError),
          Text(
            'Your Progress Report',
            style: GoogleFonts.playfairDisplay(
              fontSize: layout.isTinyPhone ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: a.theme.title,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Let's see how you're doing! 📊",
            style: layout.bodyStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              poliePeriodChip(
                context: a.context,
                label: 'This Week',
                selected: a.reviewPeriod.value == 'week',
                onTap: () => a.reviewPeriod.value = 'week',
              ),
              poliePeriodChip(
                context: a.context,
                label: 'This Month',
                selected: a.reviewPeriod.value == 'month',
                onTap: () => a.reviewPeriod.value = 'month',
              ),
              poliePeriodChip(
                context: a.context,
                label: 'All Time',
                selected: a.reviewPeriod.value == 'all',
                onTap: () => a.reviewPeriod.value = 'all',
              ),
              IconButton(
                onPressed: a.isBusy ? null : a.onLoadReview,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (a.reviewPayload == null)
            layout.card(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'No review data yet. Tap Refresh.',
                  style: layout.bodyStyle,
                ),
              ),
            )
          else ...[
            if (layout.isTinyPhone) ...[
              polieStatCard(
                a.context,
                'Words Learned',
                '${a.reviewPayload!.wordsSeen}',
                const Color(0xFFD4822A),
              ),
              const SizedBox(height: 8),
              polieStatCard(
                a.context,
                'Accuracy',
                '${a.reviewPayload!.accuracy.toStringAsFixed(1)}%',
                const Color(0xFF4A7C59),
              ),
              const SizedBox(height: 8),
              polieStatCard(
                a.context,
                'Day Streak',
                '${a.reviewPayload!.streak}',
                const Color(0xFFE2B93B),
              ),
              const SizedBox(height: 8),
              polieStatCard(
                a.context,
                'Lessons Done',
                '${a.reviewPayload!.lessonsDone}',
                const Color(0xFFC4663A),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: polieStatCard(
                      a.context,
                      'Words Learned',
                      '${a.reviewPayload!.wordsSeen}',
                      const Color(0xFFD4822A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: polieStatCard(
                      a.context,
                      'Accuracy',
                      '${a.reviewPayload!.accuracy.toStringAsFixed(1)}%',
                      const Color(0xFF4A7C59),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: polieStatCard(
                      a.context,
                      'Day Streak',
                      '${a.reviewPayload!.streak}',
                      const Color(0xFFE2B93B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: polieStatCard(
                      a.context,
                      'Lessons Done',
                      '${a.reviewPayload!.lessonsDone}',
                      const Color(0xFFC4663A),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            layout.card(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skills Breakdown',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...a.reviewPayload!.skillBars.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.key, style: layout.bodyStyle),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: e.value),
                              duration: const Duration(milliseconds: 520),
                              builder: (ctx, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      polieSkillColor(e.key),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            layout.card(
              color: const Color(0xFFD4822A),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Polie's Insights",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.reviewPayload!.headlineInsight,
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.reviewPayload!.coachingParagraph,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '💪 Your Strengths',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...a.reviewPayload!.strengths.map(
                      (s) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${s.area}\n${s.note}',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '🎯 Areas to Focus On',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...a.reviewPayload!.growthAreas.map(
                      (g) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${g.area}\n${g.note}\n💡 Quick win: ${g.quickWin}',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            layout.card(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Next Steps',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: a.reviewPayload!.nextSteps
                          .map(
                            (s) => SizedBox(
                              width: layout.isPhone
                                  ? (layout.screenWidth - (layout.basePad * 2) - 8)
                                        .clamp(220, 340)
                                        .toDouble()
                                  : 260,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: a.theme.border),
                                ),
                                child: Text(
                                  '${s.title}\n${s.why}\nStart now →',
                                  style: layout.bodyStyle.copyWith(fontSize: 13),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFC64F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        a.reviewPayload!.motivationalClose,
                        style: layout.bodyStyle.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
}
