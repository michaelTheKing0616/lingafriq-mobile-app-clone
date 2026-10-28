import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_args.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_layout.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';

Widget buildPolieTutorPracticePanel(
  PolieModeSurfaceArgs a,
  PolieModeSurfaceLayout layout,
) {
  return layout.card(
    Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice',
            style: GoogleFonts.playfairDisplay(
              color: a.theme.title,
              fontSize: layout.isTinyPhone ? 20 : 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            a.tutorLesson?.practiceQuestion ??
                'How would you apply this concept?',
            style: layout.bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: layout.isTinyPhone ? 18 : 23,
            ),
          ),
          if ((a.tutorLesson?.practiceHint ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Hint: ${a.tutorLesson!.practiceHint}',
                style: layout.bodyStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: layout.isTinyPhone ? 16 : 20,
                ),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: a.tutorInput,
            minLines: 2,
            maxLines: 4,
            decoration: polieInputDecoration(
              a.theme,
              'Type your answer here...',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: a.isBusy || a.tutorLesson == null
                ? null
                : a.onCheckTutorAnswer,
            style: FilledButton.styleFrom(
              backgroundColor: a.theme.accent,
            ),
            child: Text(
              a.isBusy ? 'Checking...' : 'Check Answer',
            ),
          ),
          if (a.tutorFeedback != null) ...[
            const SizedBox(height: 10),
            Text(
              '${a.tutorFeedback!.verdict.toUpperCase()} • ${a.tutorFeedback!.score}',
              style: layout.bodyStyle.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.tutorFeedback!.encouragement,
              style: layout.bodyStyle,
            ),
            Text(
              a.tutorFeedback!.uxFeedbackLine(),
              style: layout.bodyStyle.copyWith(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (a.tutorFeedback!.correction.trim().isNotEmpty &&
                a.tutorFeedback!.correction != '-')
              Text(
                a.tutorFeedback!.correction,
                style: layout.bodyStyle,
              ),
            Text(
              'Why: ${a.tutorFeedback!.why}',
              style: layout.bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Next step: ${a.tutorFeedback!.nextStep}',
              style: layout.bodyStyle.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => a.tutorFlipped.value = false,
            child: const Text('Back to Lesson'),
          ),
        ],
      ),
    ),
  );
}
