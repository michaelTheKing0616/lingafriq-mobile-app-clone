
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_args.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_tutor_practice.dart';

Widget buildPolieTutorModeSurface(PolieModeSurfaceArgs a) {
  final layout = a.layout();
      const lessonTopics = ['Greetings', 'Pronouns', 'Tones', 'Family Terms'];
      final showSidebar = !layout.isPhone;
      return Container(
        key: a.key,
        child: Row(
          children: [
            if (showSidebar)
              Container(
                width: 230,
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                color: const Color(0xFF2A170B),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Lessons',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.tutorStreakBannerText,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFFE8DAC5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Difficulty',
                      style: GoogleFonts.nunito(color: const Color(0xFFE8DAC5)),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: a.tutorDifficulty.value,
                      dropdownColor: const Color(0xFF2A1F14),
                      style: const TextStyle(color: Color(0xFFFAF3E0)),
                      decoration: polieInputDecoration(
                        a.theme,
                        'Difficulty',
                      ).copyWith(fillColor: const Color(0xFF3A2A1C)),
                      items: const ['beginner', 'intermediate', 'advanced']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => a.tutorDifficulty.value = v ?? 'beginner',
                    ),
                    const SizedBox(height: 12),
                    ...lessonTopics.map(
                      (topic) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: topic == 'Greetings'
                                ? const Color(0xFFD4822A)
                                : const Color(0xFF3A2A1C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            topic,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A2A1C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '💡 Quick Fact\nYoruba has 3 tones: high (á), mid (a), and low (à).',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFFE8DAC5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    layout.introBanner(introDismissed: a.introDismissed, onDismissIntro: a.onDismissIntro),
                    layout.errorBanner(a.modeError),
                    if (!showSidebar)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A170B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.tutorStreakBannerText,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFFE8DAC5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: a.tutorDifficulty.value,
                              dropdownColor: const Color(0xFF2A1F14),
                              style: const TextStyle(color: Color(0xFFFAF3E0)),
                              decoration: polieInputDecoration(
                                a.theme,
                                'Difficulty',
                              ).copyWith(fillColor: const Color(0xFF3A2A1C)),
                              items:
                                  const ['beginner', 'intermediate', 'advanced']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) =>
                                  a.tutorDifficulty.value = v ?? 'beginner',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: lessonTopics
                                  .map(
                                    (topic) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: topic == 'Greetings'
                                            ? const Color(0xFFD4822A)
                                            : const Color(0xFF3A2A1C),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        topic,
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    layout.isTinyPhone
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Lesson 1: ${a.tutorLesson?.concept ?? 'Greetings by Time of Day'}',
                                style: GoogleFonts.playfairDisplay(
                                  color: a.theme.title,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: a.isBusy ? null : a.onLoadTutorLesson,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: a.theme.accent,
                                      ),
                                      child: Text(a.isBusy ? 'Loading...' : 'New Card'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: AppLocalizations.of(a.context)!.polieTutorSavedCards,
                                    onPressed: a.isBusy
                                        ? null
                                        : () => a.onOpenTutorSavedCards(),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.bookmark_rounded),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: AppLocalizations.of(a.context)!.polieTutorSaveCard,
                                    onPressed: (a.isBusy || a.tutorLesson == null)
                                        ? null
                                        : () => a.onSaveTutorCard(),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                    ),
                                    icon: Icon(
                                      a.tutorIsCurrentSaved.value
                                          ? Icons.bookmark_added_rounded
                                          : Icons.bookmark_add_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Lesson 1: ${a.tutorLesson?.concept ?? 'Greetings by Time of Day'}',
                                  style: GoogleFonts.playfairDisplay(
                                    color: a.theme.title,
                                    fontSize: layout.isPhone ? 22 : 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: a.isBusy ? null : a.onLoadTutorLesson,
                                style: FilledButton.styleFrom(
                                  backgroundColor: a.theme.accent,
                                ),
                                child: Text(a.isBusy ? 'Loading...' : 'New Card'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: AppLocalizations.of(a.context)!.polieTutorSavedCards,
                                onPressed: a.isBusy
                                    ? null
                                    : () => a.onOpenTutorSavedCards(),
                                style: IconButton.styleFrom(backgroundColor: Colors.white),
                                icon: const Icon(Icons.bookmark_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: AppLocalizations.of(a.context)!.polieTutorSaveCard,
                                onPressed: (a.isBusy || a.tutorLesson == null)
                                    ? null
                                    : () => a.onSaveTutorCard(),
                                style: IconButton.styleFrom(backgroundColor: Colors.white),
                                icon: Icon(
                                  a.tutorIsCurrentSaved.value
                                      ? Icons.bookmark_added_rounded
                                      : Icons.bookmark_add_rounded,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.33,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(a.theme.accent),
                    ),
                    const SizedBox(height: 16),
                    AnimatedCrossFade(
                      firstChild: layout.card(
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.tutorLesson?.concept ??
                                    'Greetings by Time of Day',
                                style: GoogleFonts.playfairDisplay(
                                  color: a.theme.title,
                                  fontSize: layout.isTinyPhone ? 20 : 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                a.tutorLesson?.explanation ?? '',
                                style: layout.bodyStyle.copyWith(
                                  fontSize: layout.isTinyPhone ? 15 : 18,
                                ),
                              ),
                              const SizedBox(height: 14),
                              layout.card(
                                color: const Color(0xFFF6EED8),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.tutorLesson!
                                                      .example.targetLang ??
                                                  '-',
                                              style: GoogleFonts.nunito(
                                                fontSize:
                                                    layout.isTinyPhone ? 26 : 34,
                                                fontWeight: FontWeight.w700,
                                                color: a.theme.title,
                                              ),
                                            ),
                                            Text(
                                              a.tutorLesson?.example
                                                      .transliteration ??
                                                  '-',
                                              style: layout.monoStyle,
                                            ),
                                            Text(
                                              a.tutorLesson!
                                                      .example.english ??
                                                  '-',
                                              style: layout.bodyStyle.copyWith(
                                                fontSize:
                                                    layout.isTinyPhone ? 18 : 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Listen',
                                        onPressed: a.tutorLesson == null
                                            ? null
                                            : () => a.onSpeakText(
                                                  a.tutorLesson!
                                                      .example.targetLang,
                                                ),
                                        icon: Icon(
                                          Icons.volume_up_outlined,
                                          color: a.theme.title,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              layout.card(
                                color: const Color(0xFFF8F3E6),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    '💡 Memory Tip\n${a.tutorLesson?.memoryTip ?? '-'}',
                                    style: layout.bodyStyle.copyWith(
                                      fontSize: layout.isTinyPhone ? 17 : 22,
                                    ),
                                  ),
                                ),
                              ),
                              if ((a.tutorLesson?.watchOut ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                layout.card(
                                  color: const Color(0xFFFBEAEC),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      '⚠️ Watch Out\n${a.tutorLesson!.watchOut}',
                                      style: layout.bodyStyle.copyWith(
                                        fontSize: layout.isTinyPhone ? 17 : 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: a.tutorLesson == null
                                    ? null
                                    : () => a.tutorFlipped.value = true,
                                style: FilledButton.styleFrom(
                                  backgroundColor: a.theme.accent,
                                  minimumSize: const Size(double.infinity, 52),
                                ),
                                child: const Text('Practice This Lesson'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      secondChild: buildPolieTutorPracticePanel(a, layout),
                      crossFadeState: a.tutorFlipped.value
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    
}
