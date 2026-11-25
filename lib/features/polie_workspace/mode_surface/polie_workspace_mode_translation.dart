import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_tx_helpers.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_language_sheet.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_args.dart';

Widget buildPolieTranslationModeSurface(PolieModeSurfaceArgs a) {
  final layout = a.layout();
  final alternatives = a.translationOutput?.alternatives ?? const <AltItem>[];
  final effectiveAlternatives = alternatives.isNotEmpty
      ? alternatives
      : buildFallbackAlternatives(
          a.translationOutput?.primary ?? '',
          a.translationTone.value,
        );
  final tones = const ['formal', 'casual', 'poetic', 'literal'];
  final wordCount = a.translationInput.text
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .length;
  return Container(
    key: a.key,
    padding: EdgeInsets.fromLTRB(
      layout.basePad,
      layout.basePad,
      layout.basePad,
      layout.basePad,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        layout.introBanner(
          introDismissed: a.introDismissed,
          onDismissIntro: a.onDismissIntro,
        ),
        layout.errorBanner(a.modeError),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: layout.isPhone ? 170 : 160,
              child: CheckboxListTile(
                value: a.autoTranslate.value,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-translate'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (_) =>
                    a.autoTranslate.value = !a.autoTranslate.value,
              ),
            ),
            Text(
              'Tone:',
              style: layout.bodyStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            ...tones.map(
              (tone) => ChoiceChip(
                label: Text(tone[0].toUpperCase() + tone.substring(1)),
                selected: a.translationTone.value == tone,
                selectedColor: a.theme.accent.withValues(alpha: 0.2),
                onSelected: (_) => a.translationTone.value = tone,
              ),
            ),
            if (!layout.isPhone)
              Text(
                '${a.translationInput.text.length} chars · $wordCount words',
                style: layout.bodyStyle,
              ),
            IconButton(
              tooltip: 'History',
              onPressed: a.onOpenTranslationHistory,
              icon: const Icon(Icons.history_rounded),
            ),
            IconButton(
              tooltip: a.translationTrayOpen.value
                  ? 'Hide alternatives'
                  : 'Show alternatives',
              onPressed: () =>
                  a.translationTrayOpen.value = !a.translationTrayOpen.value,
              icon: Icon(
                a.translationTrayOpen.value
                    ? Icons.expand_more_rounded
                    : Icons.expand_less_rounded,
              ),
            ),
          ],
        ),
        if (layout.isPhone) ...[
          const SizedBox(height: 4),
          Text(
            '${a.translationInput.text.length} chars · $wordCount words',
            style: layout.bodyStyle,
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final l10n = AppLocalizations.of(a.context)!;
              final panelGap = 8.0;
              final idealPanelWidth = (constraints.maxWidth - panelGap) / 2;
              final panelWidth = layout.isPhone
                  ? idealPanelWidth
                  : idealPanelWidth.clamp(260.0, 460.0);
              final leftPanel = Container(
                width: panelWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: a.theme.border),
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
                                onTap: a.isBusy
                                    ? null
                                    : () {
                                        showModalBottomSheet<void>(
                                          context: a.context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (sheetContext) =>
                                              PolieLanguageSearchSheet(
                                                title: 'Source language',
                                                selectedDisplayName: a
                                                    .translationSourceLang
                                                    .value,
                                                onSelected: (o) {
                                                  a
                                                          .translationSourceLang
                                                          .value =
                                                      o.displayName;
                                                  ensureDistinctTxLanguages(
                                                    a.translationSourceLang,
                                                    a.translationTargetLang,
                                                  );
                                                  a.onTranslationLanguagesChanged();
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
                                              style: layout.bodyStyle.copyWith(
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              a.translationSourceLang.value,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: LingAfriqFonts.roleStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: a.theme.body,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: a.isBusy
                                ? null
                                : () => a.onRunTranslation(
                                    a.translationInput.text,
                                  ),
                            icon: const Icon(Icons.sync_alt_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TextField(
                        controller: a.translationInput,
                        maxLines: null,
                        expands: true,
                        style: LingAfriqFonts.roleStyle(
                          fontSize: layout.isPhone ? 18 : 20,
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
                  border: Border.all(color: a.theme.border),
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
                                onTap: a.isBusy
                                    ? null
                                    : () {
                                        showModalBottomSheet<void>(
                                          context: a.context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (sheetContext) =>
                                              PolieLanguageSearchSheet(
                                                title: 'Target language',
                                                selectedDisplayName: a
                                                    .translationTargetLang
                                                    .value,
                                                onSelected: (o) {
                                                  a
                                                          .translationTargetLang
                                                          .value =
                                                      o.displayName;
                                                  ensureDistinctTxLanguages(
                                                    a.translationTargetLang,
                                                    a.translationSourceLang,
                                                  );
                                                  a.onTranslationLanguagesChanged();
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
                                              style: layout.bodyStyle.copyWith(
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              a.translationTargetLang.value,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: LingAfriqFonts.roleStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: a.theme.body,
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
                            onPressed: () => a.onSpeakText(
                              a.translationOutput?.primary ?? '',
                              languageName: a.translationTargetLang.value,
                            ),
                            icon: const Icon(
                              Icons.volume_up_outlined,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              final text = (a.translationOutput?.primary ?? '')
                                  .trim();
                              if (text.isEmpty) return;
                              await Clipboard.setData(
                                ClipboardData(text: text),
                              );
                            },
                            icon: const Icon(Icons.copy_outlined, size: 20),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: a.onOpenTranslationHistory,
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
                              a.translationOutput?.primary ?? '',
                              LingAfriqFonts.roleStyle(
                                fontSize: layout.isPhone ? 20 : 24,
                                color: a.theme.title,
                              ),
                            ),
                            if ((a.translationOutput?.culturalNote ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                a.translationOutput!.culturalNote,
                                style: layout.bodyStyle.copyWith(
                                  color: a.theme.body.withValues(alpha: 0.9),
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
              if (layout.isPhone) {
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
        if (a.translationTrayOpen.value &&
            MediaQuery.viewInsetsOf(a.context).bottom <= 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: a.theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alternatives',
                  style: layout.bodyStyle.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (effectiveAlternatives.isEmpty)
                  Text(
                    'No alternatives available yet.',
                    style: layout.bodyStyle,
                  )
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
                            style: layout.bodyStyle.copyWith(fontSize: 13),
                          ),
                          onPressed: a.isBusy
                              ? null
                              : () {
                                  a.translationInput.text = alt.text;
                                  a.onRunTranslation(alt.text);
                                },
                        );
                      },
                    ),
                  ),
                if (effectiveAlternatives.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    effectiveAlternatives.first.note,
                    style: layout.bodyStyle.copyWith(
                      color: a.theme.body.withValues(alpha: 0.8),
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
