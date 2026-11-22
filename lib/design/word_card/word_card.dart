import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/motion/motion_scope.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/tone_lens/tone_lens.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/services/word_card_service.dart';

/// Long-press word card. Copy comes from [l10nOf]. The sheet shows only what
/// [WordCardService] returns: a gloss, a human dialect clip, and the tone.
class WordCard extends StatefulWidget {
  const WordCard({required this.query, required this.service, super.key});

  static const Key sheetKey = ValueKey<String>('word-card');
  static const Key closeKey = ValueKey<String>('word-card-close');
  static const Key loadingKey = ValueKey<String>('word-card-loading');
  static const Key meaningKey = ValueKey<String>('word-card-meaning');
  static const Key audioKey = ValueKey<String>('word-card-audio');
  static const Key unavailableKey = ValueKey<String>(
    'word-card-audio-unavailable',
  );
  static const Key toneKey = ValueKey<String>('word-card-tone');
  static const Key saveKey = ValueKey<String>('word-card-save');
  static const Key retryKey = ValueKey<String>('word-card-retry');
  static const Key notAvailableKey = ValueKey<String>(
    'word-card-not-available',
  );
  static const Key savedKey = ValueKey<String>('word-card-saved');

  final WordCardQuery query;
  final WordCardService service;

  /// Opens the sheet. A missing navigator does nothing.
  static Future<void> show(
    BuildContext context, {
    required WordCardQuery query,
    WordCardService? service,
  }) {
    if (Navigator.maybeOf(context) == null) return Future<void>.value();
    final WordCardService gate = service ?? WordCardService();
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final LingMotionPlan plan = LingMotionPlan.resolve(reduced: reduced);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: palette.surface,
      sheetAnimationStyle: AnimationStyle(
        duration: plan.duration,
        reverseDuration: plan.duration,
      ),
      builder: (BuildContext context) {
        return WordCard(query: query, service: gate);
      },
    );
  }

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  WordCardRecord? _record;
  var _loading = true;
  var _saving = false;
  var _saved = false;
  var _saveFailed = false;
  var _audioBlocked = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final WordCardRecord record = await widget.service.open(widget.query);
    if (!mounted) return;
    setState(() {
      _record = record;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final WordCardRecord? record = _record;
    if (record == null || !record.hasMeaning || _saving || _saved) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    final WordCardSaveResult result = await widget.service.save(record);
    if (!mounted) return;
    final bool stored = result.saved && result.inMyWords && result.inReview;
    setState(() {
      _saving = false;
      _saved = stored;
      _saveFailed = !stored;
    });
  }

  Future<void> _play(WordCardRecord record) async {
    final bool played = await widget.service.play(record.audio);
    if (!mounted || played) return;
    setState(() => _audioBlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final WordCardRecord? record = _record;
    return TargetWordCardGate(
      child: Semantics(
        key: WordCard.sheetKey,
        container: true,
        label: l10n.shellLivingDictionary,
        child: Material(
          color: palette.surface,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: LingAfriqTokens.spacing48,
                  ),
                  child: TextButton(
                    key: WordCard.closeKey,
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    child: Text(
                      l10n.commonActionClose,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ),
              Text(
                l10n.shellLivingDictionary,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              if (_loading)
                Text(
                  l10n.loading,
                  key: WordCard.loadingKey,
                  style: lingBody(palette.onSurfaceVariant),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                )
              else if (record != null)
                ..._body(context, l10n, palette, record),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l10n,
    LingPalette palette,
    WordCardRecord record,
  ) {
    final bool audioMissing =
        _audioBlocked || !record.audio.playable || record.audio.synthetic;
    return <Widget>[
      ToneLens(
        key: WordCard.toneKey,
        word: record.word,
        contours: record.tone.contours,
        source: record.tone.validatedAudio
            ? ToneSource.validatedAudio
            : ToneSource.orthography,
        unverified: record.tone.unverified,
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      if (record.hasMeaning)
        Text(
          record.meaning!,
          key: WordCard.meaningKey,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        )
      else
        _notAvailable(l10n, palette),
      const SizedBox(height: LingAfriqTokens.spacing16),
      _audio(l10n, palette, record, audioMissing),
      if (record.hasMeaning) ...<Widget>[
        const SizedBox(height: LingAfriqTokens.spacing16),
        if (_saved)
          Text(
            l10n.hubLearnWordsAndReview,
            key: WordCard.savedKey,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          )
        else if (_saveFailed)
          _retry(l10n)
        else
          LingButton(
            key: WordCard.saveKey,
            label: l10n.commonActionSave,
            unavailableLabel: l10n.commonStateUnavailable,
            role: LingButtonRole.quiet,
            onPressed: () {
              unawaited(_save());
            },
          ),
      ],
    ];
  }

  Widget _notAvailable(AppLocalizations l10n, LingPalette palette) {
    final TextStyle style = lingBody(palette.onSurfaceVariant);
    return Column(
      key: WordCard.notAvailableKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.hubHSpeakNotAvailableTitle,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        Text(
          l10n.hubLearnNotAvailableWhy,
          style: style,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  Widget _audio(
    AppLocalizations l10n,
    LingPalette palette,
    WordCardRecord record,
    bool audioMissing,
  ) {
    return Column(
      key: WordCard.audioKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (audioMissing)
          Text(
            l10n.commonStateUnavailable,
            key: WordCard.unavailableKey,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          )
        else
          LingButton(
            label: l10n.lessonListen,
            unavailableLabel: l10n.commonStateUnavailable,
            role: LingButtonRole.quiet,
            onPressed: () {
              unawaited(_play(record));
            },
          ),
      ],
    );
  }

  Widget _retry(AppLocalizations l10n) {
    return Column(
      key: WordCard.retryKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.lessonLoadFailedTitle,
          style: lingBody(
            LingPalette.of(Theme.of(context).brightness).onSurface,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        LingButton(
          label: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: () {
            unawaited(_save());
          },
        ),
      ],
    );
  }
}
