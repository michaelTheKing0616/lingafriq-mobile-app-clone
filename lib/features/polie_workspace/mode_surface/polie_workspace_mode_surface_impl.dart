import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_tx_helpers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_language_sheet.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

Widget polieWorkspaceModeSurface({
  required Key key,
  required BuildContext context,
  required PolieMode mode,
  required ModeTheme theme,
  required bool isBusy,
  required String? modeError,
  required TextEditingController translationInput,
  required TranslationPayload? translationOutput,
  required ValueNotifier<String> translationTone,
  required ValueNotifier<bool> autoTranslate,
  required ValueNotifier<bool> translationTrayOpen,
  required ValueNotifier<String> translationHistoryQuery,
  required List<dynamic> translationHistory,
  required Future<void> Function(String) onRunTranslation,
  required Future<void> Function() onSearchHistory,
  required Future<void> Function() onOpenTranslationHistory,
  required ValueNotifier<String> translationSourceLang,
  required ValueNotifier<String> translationTargetLang,
  required Future<void> Function() onTranslationLanguagesChanged,
  required TutorLessonPayload? tutorLesson,
  required TutorFeedbackPayload? tutorFeedback,
  required ValueNotifier<String> tutorDifficulty,
  required ValueNotifier<bool> tutorFlipped,
  required TextEditingController tutorInput,
  required Future<void> Function() onLoadTutorLesson,
  required Future<void> Function() onCheckTutorAnswer,
  required Future<void> Function() onSaveTutorCard,
  required Future<void> Function() onOpenTutorSavedCards,
  required ValueNotifier<bool> tutorIsCurrentSaved,
  required ValueNotifier<String> roleplayDifficulty,
  required ValueNotifier<String> roleplayScene,
  required List<RoleplayTurn> roleplayMessages,
  required TextEditingController roleplayInput,
  required Future<void> Function() onSendRoleplay,
  required List<ConversationTurn> conversationMessages,
  required TextEditingController conversationInput,
  required ValueNotifier<bool> conversationIncludeEnglishTranslations,
  required ValueNotifier<String> conversationResponseStyle,
  required double languageRatio,
  required Future<void> Function([String?]) onSendConversation,
  required Future<void> Function(String text, {String? languageName})
      onSpeakText,
  required bool conversationStreamingActive,
  required String conversationStreamingTarget,
  required bool conversationVoiceListening,
  required Future<void> Function() onToggleConversationVoiceInput,
  required VocabPayload? vocabCard,
  required ValueNotifier<bool> vocabReveal,
  required ValueNotifier<String> vocabSetName,
  required ValueNotifier<String> vocabDifficultyTarget,
  required int vocabDeckCount,
  required String? vocabSrsChoice,
  required Future<void> Function() onLoadVocabCard,
  required Future<void> Function(String) onScoreSrs,
  required ReviewPayload? reviewPayload,
  required ValueNotifier<String> reviewPeriod,
  required Future<void> Function() onLoadReview,
  required Set<String> introDismissed,
  required void Function(String modeName) onDismissIntro,
  required String tutorStreakBannerText,
}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 700;
    final isTinyPhone = screenWidth < 390;
    final basePad = isTinyPhone ? 8.0 : 12.0;
    final bodyStyle = GoogleFonts.nunito(color: theme.body, fontSize: 14);
    final monoStyle = GoogleFonts.jetBrainsMono(
      color: theme.title,
      fontSize: 13.5,
    );
    Widget card(Widget child, {Color? color}) {
      return Container(
        decoration: BoxDecoration(
          color: color ?? theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: child,
      );
    }

    final error = modeError == null
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red.shade300,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(modeError, style: bodyStyle)),
              ],
            ),
          );
    const modeDescriptions = <PolieMode, String>{
      PolieMode.translation:
          'Precision tool. Split-panel translation with dynamic output updates.',
      PolieMode.tutor:
          'Interactive classroom notebook with flip cards and inline feedback.',
      PolieMode.roleplay:
          'Dark cinematic stage with scene-first character cards and live coaching.',
      PolieMode.conversation:
          'WhatsApp-style chat with a patient friend. The only bubble-chat mode.',
      PolieMode.vocab:
          'Museum word theater: one dramatic word, dark focus, SRS actions.',
      PolieMode.review:
          'Personal coach dashboard with animated bars and clear next steps.',
    };
    const modeIcons = <PolieMode, String>{
      PolieMode.translation: '\u21C4',
      PolieMode.tutor: '\uD83D\uDCD6',
      PolieMode.roleplay: '\uD83C\uDFAD',
      PolieMode.conversation: '\uD83D\uDCAC',
      PolieMode.vocab: '\u2726',
      PolieMode.review: '\uD83D\uDCCA',
    };
    final intro =
        (mode == PolieMode.conversation || introDismissed.contains(mode.name))
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.accent.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modeIcons[mode] ?? '',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.name[0].toUpperCase() + mode.name.substring(1),
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: theme.title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        modeDescriptions[mode] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: theme.body,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onDismissIntro(mode.name),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: theme.body.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );

    if (mode == PolieMode.translation) {
      final alternatives = translationOutput?.alternatives ?? const <AltItem>[];
      final effectiveAlternatives = alternatives.isNotEmpty
          ? alternatives
          : buildFallbackAlternatives(
              translationOutput?.primary ?? '',
              translationTone.value,
            );
      final tones = const ['formal', 'casual', 'poetic', 'literal'];
      final wordCount = translationInput.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .length;
      return Container(
        key: key,
        padding: EdgeInsets.fromLTRB(basePad, basePad, basePad, basePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            intro,
            error,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isPhone ? 170 : 160,
                  child: CheckboxListTile(
                    value: autoTranslate.value,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-translate'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (_) =>
                        autoTranslate.value = !autoTranslate.value,
                  ),
                ),
                Text(
                  'Tone:',
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                ),
                ...tones.map(
                  (tone) => ChoiceChip(
                    label: Text(tone[0].toUpperCase() + tone.substring(1)),
                    selected: translationTone.value == tone,
                    selectedColor: theme.accent.withOpacity(0.2),
                    onSelected: (_) => translationTone.value = tone,
                  ),
                ),
                if (!isPhone)
                  Text(
                    '${translationInput.text.length} chars · $wordCount words',
                    style: bodyStyle,
                  ),
                IconButton(
                  tooltip: 'History',
                  onPressed: onOpenTranslationHistory,
                  icon: const Icon(Icons.history_rounded),
                ),
                IconButton(
                  tooltip: translationTrayOpen.value
                      ? 'Hide alternatives'
                      : 'Show alternatives',
                  onPressed: () =>
                      translationTrayOpen.value = !translationTrayOpen.value,
                  icon: Icon(
                    translationTrayOpen.value
                        ? Icons.expand_more_rounded
                        : Icons.expand_less_rounded,
                  ),
                ),
              ],
            ),
            if (isPhone) ...[
              const SizedBox(height: 4),
              Text(
                '${translationInput.text.length} chars · $wordCount words',
                style: bodyStyle,
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final l10n = AppLocalizations.of(context)!;
                  final panelGap = 8.0;
                  final idealPanelWidth = (constraints.maxWidth - panelGap) / 2;
                  final panelWidth = isPhone
                      ? idealPanelWidth
                      : idealPanelWidth.clamp(260.0, 460.0);
                  final leftPanel = Container(
                    width: panelWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isBusy
                                        ? null
                                        : () {
                                            showModalBottomSheet<void>(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (sheetContext) =>
                                                  PolieLanguageSearchSheet(
                                                title: 'Source language',
                                                selectedDisplayName:
                                                    translationSourceLang
                                                        .value,
                                                onSelected: (o) {
                                                  translationSourceLang
                                                      .value = o.displayName;
                                                  ensureDistinctTxLanguages(
                                                    translationSourceLang,
                                                    translationTargetLang,
                                                  );
                                                  onTranslationLanguagesChanged();
                                                },
                                              ),
                                            );
                                          },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  l10n.polieTranslationSourceLabel,
                                                  style: bodyStyle.copyWith(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                Text(
                                                  translationSourceLang.value,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: theme.body,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: isBusy
                                    ? null
                                    : () => onRunTranslation(
                                        translationInput.text,
                                      ),
                                icon: const Icon(Icons.sync_alt_rounded),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: TextField(
                            controller: translationInput,
                            maxLines: null,
                            expands: true,
                            style: GoogleFonts.nunito(
                              fontSize: isPhone ? 18 : 20,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              hintText: 'Type text here',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  final rightPanel = Container(
                    width: panelWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isBusy
                                        ? null
                                        : () {
                                            showModalBottomSheet<void>(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (sheetContext) =>
                                                  PolieLanguageSearchSheet(
                                                title: 'Target language',
                                                selectedDisplayName:
                                                    translationTargetLang
                                                        .value,
                                                onSelected: (o) {
                                                  translationTargetLang
                                                      .value = o.displayName;
                                                  ensureDistinctTxLanguages(
                                                    translationTargetLang,
                                                    translationSourceLang,
                                                  );
                                                  onTranslationLanguagesChanged();
                                                },
                                              ),
                                            );
                                          },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  l10n.polieTranslationTargetLabel,
                                                  style: bodyStyle.copyWith(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                Text(
                                                  translationTargetLang.value,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: theme.body,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => onSpeakText(
                                  translationOutput?.primary ?? '',
                                  languageName: translationTargetLang.value,
                                ),
                                icon: const Icon(
                                  Icons.volume_up_outlined,
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  final text =
                                      (translationOutput?.primary ?? '').trim();
                                  if (text.isEmpty) return;
                                  await Clipboard.setData(
                                    ClipboardData(text: text),
                                  );
                                },
                                icon: const Icon(Icons.copy_outlined, size: 20),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: onOpenTranslationHistory,
                                icon: const Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                polieBuildAnimatedWordFlow(
                                  translationOutput?.primary ?? '',
                                  GoogleFonts.nunito(
                                    fontSize: isPhone ? 20 : 24,
                                    color: theme.title,
                                  ),
                                ),
                                if ((translationOutput?.culturalNote ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    translationOutput!.culturalNote,
                                    style: bodyStyle.copyWith(
                                      color: theme.body.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (isPhone) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        leftPanel,
                        SizedBox(width: panelGap),
                        rightPanel,
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        leftPanel,
                        SizedBox(width: panelGap),
                        rightPanel,
                      ],
                    ),
                  );
                },
              ),
            ),
            if (translationTrayOpen.value &&
                MediaQuery.viewInsetsOf(context).bottom <= 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alternatives',
                      style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (effectiveAlternatives.isEmpty)
                      Text('No alternatives available yet.', style: bodyStyle)
                    else
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: effectiveAlternatives.length > 6
                              ? 6
                              : effectiveAlternatives.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final alt = effectiveAlternatives[i];
                            return ActionChip(
                              label: Text(
                                alt.text,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle.copyWith(fontSize: 13),
                              ),
                              onPressed: isBusy
                                  ? null
                                  : () {
                                      translationInput.text = alt.text;
                                      onRunTranslation(alt.text);
                                    },
                            );
                          },
                        ),
                      ),
                    if (effectiveAlternatives.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        effectiveAlternatives.first.note,
                        style: bodyStyle.copyWith(
                          color: theme.body.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (mode == PolieMode.tutor) {
      const lessonTopics = ['Greetings', 'Pronouns', 'Tones', 'Family Terms'];
      final showSidebar = !isPhone;
      return Container(
        key: key,
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
                      tutorStreakBannerText,
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
                      value: tutorDifficulty.value,
                      dropdownColor: const Color(0xFF2A1F14),
                      style: const TextStyle(color: Color(0xFFFAF3E0)),
                      decoration: polieInputDecoration(
                        theme,
                        'Difficulty',
                      ).copyWith(fillColor: const Color(0xFF3A2A1C)),
                      items: const ['beginner', 'intermediate', 'advanced']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => tutorDifficulty.value = v ?? 'beginner',
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
                    intro,
                    error,
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
                              tutorStreakBannerText,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFFE8DAC5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: tutorDifficulty.value,
                              dropdownColor: const Color(0xFF2A1F14),
                              style: const TextStyle(color: Color(0xFFFAF3E0)),
                              decoration: polieInputDecoration(
                                theme,
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
                                  tutorDifficulty.value = v ?? 'beginner',
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
                    isTinyPhone
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Lesson 1: ${tutorLesson?.concept ?? 'Greetings by Time of Day'}',
                                style: GoogleFonts.playfairDisplay(
                                  color: theme.title,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: isBusy ? null : onLoadTutorLesson,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.accent,
                                      ),
                                      child: Text(isBusy ? 'Loading...' : 'New Card'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: AppLocalizations.of(context)!.polieTutorSavedCards,
                                    onPressed: isBusy
                                        ? null
                                        : () => onOpenTutorSavedCards(),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.bookmark_rounded),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: AppLocalizations.of(context)!.polieTutorSaveCard,
                                    onPressed: (isBusy || tutorLesson == null)
                                        ? null
                                        : () => onSaveTutorCard(),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                    ),
                                    icon: Icon(
                                      tutorIsCurrentSaved.value
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
                                  'Lesson 1: ${tutorLesson?.concept ?? 'Greetings by Time of Day'}',
                                  style: GoogleFonts.playfairDisplay(
                                    color: theme.title,
                                    fontSize: isPhone ? 22 : 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: isBusy ? null : onLoadTutorLesson,
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.accent,
                                ),
                                child: Text(isBusy ? 'Loading...' : 'New Card'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: AppLocalizations.of(context)!.polieTutorSavedCards,
                                onPressed: isBusy
                                    ? null
                                    : () => onOpenTutorSavedCards(),
                                style: IconButton.styleFrom(backgroundColor: Colors.white),
                                icon: const Icon(Icons.bookmark_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: AppLocalizations.of(context)!.polieTutorSaveCard,
                                onPressed: (isBusy || tutorLesson == null)
                                    ? null
                                    : () => onSaveTutorCard(),
                                style: IconButton.styleFrom(backgroundColor: Colors.white),
                                icon: Icon(
                                  tutorIsCurrentSaved.value
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
                      valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                    ),
                    const SizedBox(height: 16),
                    AnimatedCrossFade(
                      firstChild: card(
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tutorLesson?.concept ??
                                    'Greetings by Time of Day',
                                style: GoogleFonts.playfairDisplay(
                                  color: theme.title,
                                  fontSize: isTinyPhone ? 20 : 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                tutorLesson?.explanation ?? '',
                                style: bodyStyle.copyWith(
                                  fontSize: isTinyPhone ? 15 : 18,
                                ),
                              ),
                              const SizedBox(height: 14),
                              card(
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
                                              tutorLesson
                                                      ?.example.targetLang ??
                                                  '-',
                                              style: GoogleFonts.nunito(
                                                fontSize:
                                                    isTinyPhone ? 26 : 34,
                                                fontWeight: FontWeight.w700,
                                                color: theme.title,
                                              ),
                                            ),
                                            Text(
                                              tutorLesson?.example
                                                      .transliteration ??
                                                  '-',
                                              style: monoStyle,
                                            ),
                                            Text(
                                              tutorLesson
                                                      ?.example.english ??
                                                  '-',
                                              style: bodyStyle.copyWith(
                                                fontSize:
                                                    isTinyPhone ? 18 : 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Listen',
                                        onPressed: tutorLesson == null
                                            ? null
                                            : () => onSpeakText(
                                                  tutorLesson
                                                      .example.targetLang,
                                                ),
                                        icon: Icon(
                                          Icons.volume_up_outlined,
                                          color: theme.title,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              card(
                                color: const Color(0xFFF8F3E6),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    '💡 Memory Tip\n${tutorLesson?.memoryTip ?? '-'}',
                                    style: bodyStyle.copyWith(
                                      fontSize: isTinyPhone ? 17 : 22,
                                    ),
                                  ),
                                ),
                              ),
                              if ((tutorLesson?.watchOut ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                card(
                                  color: const Color(0xFFFBEAEC),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      '⚠️ Watch Out\n${tutorLesson!.watchOut}',
                                      style: bodyStyle.copyWith(
                                        fontSize: isTinyPhone ? 17 : 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: tutorLesson == null
                                    ? null
                                    : () => tutorFlipped.value = true,
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.accent,
                                  minimumSize: const Size(double.infinity, 52),
                                ),
                                child: const Text('Practice This Lesson'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      secondChild: card(
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Practice',
                                style: GoogleFonts.playfairDisplay(
                                  color: theme.title,
                                  fontSize: isTinyPhone ? 20 : 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tutorLesson?.practiceQuestion ??
                                    'How would you apply this concept?',
                                style: bodyStyle.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isTinyPhone ? 18 : 23,
                                ),
                              ),
                              if ((tutorLesson?.practiceHint ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Hint: ${tutorLesson!.practiceHint}',
                                    style: bodyStyle.copyWith(
                                      fontStyle: FontStyle.italic,
                                      fontSize: isTinyPhone ? 16 : 20,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: tutorInput,
                                minLines: 2,
                                maxLines: 4,
                                decoration: polieInputDecoration(
                                  theme,
                                  'Type your answer here...',
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: isBusy || tutorLesson == null
                                    ? null
                                    : onCheckTutorAnswer,
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.accent,
                                ),
                                child: Text(
                                  isBusy ? 'Checking...' : 'Check Answer',
                                ),
                              ),
                              if (tutorFeedback != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '${tutorFeedback.verdict.toUpperCase()} • ${tutorFeedback.score}',
                                  style: bodyStyle.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tutorFeedback.encouragement,
                                  style: bodyStyle,
                                ),
                                Text(
                                  tutorFeedback.uxFeedbackLine(),
                                  style: bodyStyle.copyWith(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (tutorFeedback.correction.trim().isNotEmpty &&
                                    tutorFeedback.correction != '-')
                                  Text(
                                    tutorFeedback.correction,
                                    style: bodyStyle,
                                  ),
                                Text(
                                  'Why: ${tutorFeedback.why}',
                                  style: bodyStyle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Next step: ${tutorFeedback.nextStep}',
                                  style: bodyStyle.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () => tutorFlipped.value = false,
                                child: const Text('Back to Lesson'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      crossFadeState: tutorFlipped.value
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

    if (mode == PolieMode.roleplay) {
      final sceneSubtitle = <String, String>{
        'Market': 'Bargain for goods with a friendly vendor',
        'Restaurant': 'Order naturally and ask follow-up questions',
        'Meeting Elder': 'Use respectful phrases and proper tone',
        'Job Interview': 'Answer clearly and confidently',
        'Family Dinner': 'Keep the tone warm and social',
      };
      return Container(
        key: key,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A04), Color(0xFF1A130C)],
          ),
        ),
        child: Column(
          children: [
            intro,
            error,
            Container(
              width: double.infinity,
              height: isPhone ? 124 : 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8E2E09), Color(0xFFE09A18)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'At the ${roleplayScene.value}',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: isPhone ? 26 : 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Change Scene'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sceneSubtitle[roleplayScene.value] ??
                          'Practice natural conversation in context',
                      style: GoogleFonts.nunito(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 24, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(
                    opacity: (1 - (value / 24)).clamp(0, 1),
                    child: child,
                  ),
                );
              },
              child: card(
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFD4822A),
                        child: Text(
                          'MB',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mama Bisi',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Friendly, patient vendor',
                              style: GoogleFonts.nunito(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(
                              'Bilingual',
                              style: TextStyle(fontSize: isTinyPhone ? 11 : 12),
                            ),
                            backgroundColor: const Color(0xFF2BDB8C),
                            visualDensity: isTinyPhone
                                ? const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  )
                                : null,
                          ),
                          Chip(
                            label: Text(
                              'Hints',
                              style: TextStyle(fontSize: isTinyPhone ? 11 : 12),
                            ),
                            visualDensity: isTinyPhone
                                ? const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  )
                                : null,
                          ),
                          Chip(
                            label: Text(
                              'Immersion',
                              style: TextStyle(fontSize: isTinyPhone ? 11 : 12),
                            ),
                            visualDensity: isTinyPhone
                                ? const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                color: Colors.black.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: card(
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: roleplayMessages.length,
                  itemBuilder: (context, index) {
                    final item = roleplayMessages[index];
                    if (item.userText != null) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4663A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.userText!,
                            style: bodyStyle.copyWith(color: Colors.white),
                          ),
                        ),
                      );
                    }
                    final ai = item.ai!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15110D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4822A).withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  ai.characterResponse.targetLang,
                                  style: bodyStyle.copyWith(
                                    color: const Color(0xFFFAF3E0),
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: 'Listen',
                                onPressed: () => onSpeakText(
                                  ai.characterResponse.targetLang,
                                ),
                                icon: const Icon(
                                  Icons.volume_up_outlined,
                                  color: Color(0xFFF2C14E),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'English: ${ai.characterResponse.english}',
                            style: bodyStyle.copyWith(
                              color: const Color(0xFFD8C9B7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ai.coaching.feedbackType.toUpperCase()} • ${ai.coaching.userAccuracy}',
                            style: bodyStyle.copyWith(
                              color: const Color(0xFFF2C14E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ai.coaching.feedback,
                            style: bodyStyle.copyWith(
                              color: const Color(0xFFF2E6D7),
                            ),
                          ),
                          if ((ai.coaching.betterPhrasing ?? '').isNotEmpty)
                            Text(
                              'Try: ${ai.coaching.betterPhrasing}',
                              style: monoStyle.copyWith(
                                color: const Color(0xFFFAF3E0),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                color: Colors.black.withOpacity(0.28),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: roleplayInput,
                    style: const TextStyle(color: Color(0xFFFAF3E0)),
                    decoration: polieInputDecoration(theme, 'Speak your line...')
                        .copyWith(
                          hintStyle: const TextStyle(color: Color(0xFFD8C9B7)),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  icon: const Icon(Icons.mic_none_rounded, color: Colors.white),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isBusy ? null : onSendRoleplay,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.accent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: Text(isBusy ? '...' : '🌐'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (mode == PolieMode.conversation) {
      final l10n = AppLocalizations.of(context)!;
      return Container(
        key: key,
        color: const Color(0xFFF5F0E8),
        child: Column(
          children: [
            intro,
            error,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFD4822A),
                    child: Icon(Icons.smart_toy_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Polie',
                        style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Online',
                        style: bodyStyle.copyWith(
                          color: const Color(0xFF4A7C59),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: isTinyPhone ? 88 : 120,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: languageRatio.clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7C59),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                // +1 slot reserved for the live streaming bubble when active.
                itemCount: conversationMessages.length +
                    (conversationStreamingActive ? 1 : 0),
                itemBuilder: (context, index) {
                  // Render the live streaming bubble as the last slot.
                  if (conversationStreamingActive &&
                      index == conversationMessages.length) {
                    final preview = conversationStreamingTarget.trim();
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.border.withOpacity(0.45),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                preview.isEmpty
                                    ? 'Polie is typing…'
                                    : '$preview▎',
                                style: bodyStyle.copyWith(
                                  color: const Color(0xFF2D1B0E),
                                  fontStyle: preview.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final item = conversationMessages[index];
                  if (item.userText != null) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4822A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          item.userText!,
                          style: bodyStyle.copyWith(color: Colors.white),
                        ),
                      ),
                    );
                  }
                  final ai = item.ai!;
                  // Render dedicated error bubble with retry CTA when an AI
                  // turn represents a failed generation.
                  if (ai.isError) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4EC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD4822A).withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 18,
                                  color: Color(0xFFD4822A),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ai.errorMessage ??
                                        'Something went wrong. Try again.',
                                    style: bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: isBusy
                                      ? null
                                      : () {
                                          final retryText =
                                              item.userMessageForRetry;
                                          if (retryText != null &&
                                              retryText.trim().isNotEmpty) {
                                            onSendConversation(retryText);
                                          }
                                        },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.border.withOpacity(0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MarkdownBody(
                                  data: ai.messageTarget,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                    ),
                                    strong: bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    em: bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    listBullet: bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                    ),
                                    code: bodyStyle.copyWith(
                                      color: const Color(0xFF7A4A20),
                                      backgroundColor:
                                          const Color(0xFFF5E5D0),
                                      fontFamily: 'monospace',
                                    ),
                                    blockSpacing: 6,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: () => onSpeakText(ai.messageTarget),
                                icon: const Icon(
                                  Icons.volume_up_outlined,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          if (ai.englishTranslation != null &&
                              ai.englishTranslation!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F0E8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.border.withOpacity(0.55),
                                ),
                              ),
                              child: Text(
                                ai.englishTranslation!,
                                style: bodyStyle.copyWith(
                                  color: const Color(0xFF3F2A1A),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          if (ai.correction.hasCorrection)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ai.correction.uxFeedbackLine(),
                                    style: bodyStyle.copyWith(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if ((ai.correction.correction ?? '').isNotEmpty)
                                    Text(
                                      ai.correction.correction!,
                                      style: bodyStyle.copyWith(
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (ai.newVocab.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E5D0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New words',
                                    style: bodyStyle.copyWith(
                                      color: const Color(0xFF7A4A20),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: ai.newVocab.take(6).map((v) {
                                      return Tooltip(
                                        message: v.meaning.isEmpty
                                            ? v.word
                                            : '${v.word} — ${v.meaning}',
                                        child: InputChip(
                                          label: Text(
                                            v.word,
                                            style: TextStyle(
                                              fontSize:
                                                  isTinyPhone ? 11 : 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          backgroundColor: Colors.white,
                                          side: BorderSide(
                                            color: const Color(0xFFD4822A)
                                                .withOpacity(0.5),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: isBusy
                                              ? null
                                              : () => onSpeakText(v.word),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (ai.suggestedReplies.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: ai.suggestedReplies
                                  .take(3)
                                  .map(
                                    (reply) => ActionChip(
                                      label: SizedBox(
                                        width: isTinyPhone ? 140 : null,
                                        child: Text(
                                          reply,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: isTinyPhone ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                      visualDensity: isTinyPhone
                                          ? const VisualDensity(
                                              horizontal: -2,
                                              vertical: -2,
                                            )
                                          : null,
                                      onPressed: isBusy
                                          ? null
                                          : () => onSendConversation(reply),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: 'Copy',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: ai.messageTarget),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        duration: Duration(seconds: 1),
                                        content: Text('Copied'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: 'Share',
                                onPressed: () async {
                                  await Share.share(ai.messageTarget);
                                },
                                icon: const Icon(
                                  Icons.ios_share_rounded,
                                  size: 16,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: 'Regenerate',
                                onPressed: isBusy
                                    ? null
                                    : () {
                                        // Locate the immediately preceding
                                        // user message and resend it.
                                        for (var i = index - 1; i >= 0; i--) {
                                          final prev =
                                              conversationMessages[i];
                                          if (prev.userText != null) {
                                            onSendConversation(prev.userText);
                                            return;
                                          }
                                        }
                                      },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Style:',
                          style: bodyStyle.copyWith(
                            color: const Color(0xFF2D1B0E),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        ...const ['formal', 'humorous', 'witty', 'terse', 'lengthy']
                            .map(
                              (s) => ChoiceChip(
                                label: Text(
                                  s[0].toUpperCase() + s.substring(1),
                                ),
                                selected: conversationResponseStyle.value == s,
                                selectedColor: theme.accent.withOpacity(0.2),
                                onSelected: isBusy
                                    ? null
                                    : (_) => conversationResponseStyle.value = s,
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Switch(
                        value: conversationIncludeEnglishTranslations.value,
                        onChanged: isBusy
                            ? null
                            : (v) => conversationIncludeEnglishTranslations.value = v,
                        activeColor: theme.accent,
                      ),
                      Expanded(
                        child: Text(
                          l10n.polieConversationIncludeEnglishTranslations,
                          style: bodyStyle.copyWith(
                            color: const Color(0xFF2D1B0E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: conversationInput,
                          decoration: polieInputDecoration(theme, 'Type a message...')
                              .copyWith(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(color: theme.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(color: theme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(
                                    color: theme.accent,
                                    width: 1.3,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: isBusy
                            ? null
                            : () => onToggleConversationVoiceInput(),
                        style: IconButton.styleFrom(
                          backgroundColor: conversationVoiceListening
                              ? const Color(0xFFD4822A)
                              : Colors.white,
                          foregroundColor: conversationVoiceListening
                              ? Colors.white
                              : null,
                        ),
                        tooltip: conversationVoiceListening
                            ? 'Stop listening'
                            : 'Speak in ${translationTargetLang.value}',
                        icon: Icon(
                          conversationVoiceListening
                              ? Icons.stop_rounded
                              : Icons.mic_none_rounded,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: isBusy ? null : onSendConversation,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.accent,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: Text(isBusy ? '...' : '➤'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (mode == PolieMode.vocab) {
      return Container(
        key: key,
        color: const Color(0xFF0F0A04),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                intro,
                error,
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: card(
                    color: Colors.white.withOpacity(0.02),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 6,
                            spacing: 10,
                            children: [
                              Text(
                                vocabSetName.value,
                                style: bodyStyle.copyWith(
                                  color: const Color(0xFFFAF3E0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${(10 - vocabDeckCount).clamp(0, 10)}/10 • $vocabDeckCount remaining',
                                style: bodyStyle.copyWith(
                                  color: const Color(0xFFFAF3E0),
                                  fontSize: isTinyPhone ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: ((10 - vocabDeckCount).clamp(0, 10)) / 10,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD4822A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final category in const [
                                'Core Daily Words',
                                'Travel',
                                'Food',
                                'Greetings',
                                'Business',
                                'Culture',
                              ])
                                ChoiceChip(
                                  label: Text(
                                    category,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  selected: vocabSetName.value == category,
                                  selectedColor: const Color(
                                    0xFFD4822A,
                                  ).withOpacity(0.25),
                                  onSelected: (_) =>
                                      vocabSetName.value = category,
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: vocabDifficultyTarget.value,
                                    dropdownColor: const Color(0xFF1A130C),
                                    style: bodyStyle.copyWith(
                                      color: const Color(0xFFFAF3E0),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'mixed',
                                        child: Text('Difficulty: Mixed'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'beginner',
                                        child: Text('Difficulty: Beginner'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'intermediate',
                                        child: Text('Difficulty: Intermediate'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'advanced',
                                        child: Text('Difficulty: Advanced'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        vocabDifficultyTarget.value = v;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => vocabReveal.value = !vocabReveal.value,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: isTinyPhone
                            ? (screenWidth - 24).clamp(260, 330).toDouble()
                            : 330,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A130C),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4822A).withOpacity(0.35),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: vocabCard == null
                            ? Text(
                                'Tap "Next Word"',
                                style: bodyStyle.copyWith(
                                  color: const Color(0xFFFAF3E0),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (vocabReveal.value)
                                    Text(
                                      '${vocabCard.partOfSpeech.toUpperCase()} · ${vocabCard.difficulty.toUpperCase()}',
                                      style: bodyStyle.copyWith(
                                        color: const Color(0xFFF2C14E),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  else
                                    const Center(
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFFF2C14E),
                                        size: 26,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          vocabCard.word,
                                          style: GoogleFonts.jetBrainsMono(
                                            color: const Color(0xFFFAF3E0),
                                            fontSize: isTinyPhone ? 44 : 56,
                                            letterSpacing:
                                                isTinyPhone ? 1.0 : 1.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Listen to word',
                                        onPressed: () =>
                                            onSpeakText(vocabCard.word),
                                        icon: const Icon(
                                          Icons.volume_up_outlined,
                                          color: Color(0xFFF2C14E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vocabCard.pronunciation,
                                    style: bodyStyle.copyWith(
                                      color: const Color(0xFFF2C14E),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (!vocabReveal.value)
                                    Text(
                                      'Tap to reveal',
                                      style: bodyStyle.copyWith(
                                        color: const Color(0xFFD8C9B7),
                                      ),
                                    ),
                                  if (vocabReveal.value) ...[
                                    const SizedBox(height: 10),
                                    card(
                                      color: Colors.white.withOpacity(0.06),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
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
                                                    vocabCard.english,
                                                    style: bodyStyle.copyWith(
                                                      color: const Color(
                                                        0xFFFAF3E0,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    vocabCard.example.target,
                                                    style: bodyStyle.copyWith(
                                                      color: const Color(
                                                        0xFFFAF3E0,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    vocabCard.example.english,
                                                    style: bodyStyle.copyWith(
                                                      color: const Color(
                                                        0xFFD8C9B7,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Listen to example',
                                              onPressed: () => onSpeakText(
                                                vocabCard.example.target,
                                              ),
                                              icon: const Icon(
                                                Icons.volume_up_outlined,
                                                color: Color(0xFFF2C14E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    card(
                                      color: Colors.white.withOpacity(0.06),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          '💡 Memory Peg\n${vocabCard.memoryPeg}',
                                          style: bodyStyle.copyWith(
                                            color: const Color(0xFFF2C14E),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if ((vocabCard.culturalNote ?? '')
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      card(
                                        color: Colors.white.withOpacity(0.06),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            '🟢 Cultural Note\n${vocabCard.culturalNote}',
                                            style: bodyStyle.copyWith(
                                              color: const Color(0xFFFAF3E0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: polieSrsButton(
                              context,
                              'Again (1m)',
                              Colors.red.shade500,
                              isBusy ? null : () => onScoreSrs('again'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: polieSrsButton(
                              context,
                              'Hard (10m)',
                              Colors.orange.shade600,
                              isBusy ? null : () => onScoreSrs('hard'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: polieSrsButton(
                              context,
                              'Good (1d)',
                              Colors.green.shade600,
                              isBusy ? null : () => onScoreSrs('good'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: polieSrsButton(
                              context,
                              'Easy (4d)',
                              Colors.blue.shade600,
                              isBusy ? null : () => onScoreSrs('easy'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last SRS choice: ${vocabSrsChoice ?? '-'}',
                        style: bodyStyle.copyWith(
                          color: const Color(0xFFFAF3E0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: isBusy ? null : onLoadVocabCard,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.accent,
                        ),
                        child: Text(isBusy ? '...' : 'Next Word'),
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

    return SingleChildScrollView(
      key: key,
      padding: EdgeInsets.fromLTRB(basePad, basePad, basePad, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          intro,
          error,
          Text(
            'Your Progress Report',
            style: GoogleFonts.playfairDisplay(
              fontSize: isTinyPhone ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: theme.title,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Let's see how you're doing! 📊",
            style: bodyStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              poliePeriodChip(
                context: context,
                label: 'This Week',
                selected: reviewPeriod.value == 'week',
                onTap: () => reviewPeriod.value = 'week',
              ),
              poliePeriodChip(
                context: context,
                label: 'This Month',
                selected: reviewPeriod.value == 'month',
                onTap: () => reviewPeriod.value = 'month',
              ),
              poliePeriodChip(
                context: context,
                label: 'All Time',
                selected: reviewPeriod.value == 'all',
                onTap: () => reviewPeriod.value = 'all',
              ),
              IconButton(
                onPressed: isBusy ? null : onLoadReview,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reviewPayload == null)
            card(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'No review data yet. Tap Refresh.',
                  style: bodyStyle,
                ),
              ),
            )
          else ...[
            if (isTinyPhone) ...[
              polieStatCard(
                context,
                'Words Learned',
                '${reviewPayload.wordsSeen}',
                const Color(0xFFD4822A),
              ),
              const SizedBox(height: 8),
              polieStatCard(
                context,
                'Accuracy',
                '${reviewPayload.accuracy.toStringAsFixed(1)}%',
                const Color(0xFF4A7C59),
              ),
              const SizedBox(height: 8),
              polieStatCard(
                context,
                'Day Streak',
                '${reviewPayload.streak}',
                const Color(0xFFE2B93B),
              ),
              const SizedBox(height: 8),
              polieStatCard(
                context,
                'Lessons Done',
                '${reviewPayload.lessonsDone}',
                const Color(0xFFC4663A),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: polieStatCard(
                      context,
                      'Words Learned',
                      '${reviewPayload.wordsSeen}',
                      const Color(0xFFD4822A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: polieStatCard(
                      context,
                      'Accuracy',
                      '${reviewPayload.accuracy.toStringAsFixed(1)}%',
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
                      context,
                      'Day Streak',
                      '${reviewPayload.streak}',
                      const Color(0xFFE2B93B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: polieStatCard(
                      context,
                      'Lessons Done',
                      '${reviewPayload.lessonsDone}',
                      const Color(0xFFC4663A),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            card(
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
                    ...reviewPayload.skillBars.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.key, style: bodyStyle),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: e.value),
                              duration: const Duration(milliseconds: 520),
                              builder: (context, value, _) =>
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
            card(
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
                      reviewPayload.headlineInsight,
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewPayload.coachingParagraph,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.95),
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
                    ...reviewPayload.strengths.map(
                      (s) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                    ...reviewPayload.growthAreas.map(
                      (g) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
            card(
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
                      children: reviewPayload.nextSteps
                          .map(
                            (s) => SizedBox(
                              width: isPhone
                                  ? (screenWidth - (basePad * 2) - 8)
                                        .clamp(220, 340)
                                        .toDouble()
                                  : 260,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.border),
                                ),
                                child: Text(
                                  '${s.title}\n${s.why}\nStart now →',
                                  style: bodyStyle.copyWith(fontSize: 13),
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
                        reviewPayload.motivationalClose,
                        style: bodyStyle.copyWith(
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

