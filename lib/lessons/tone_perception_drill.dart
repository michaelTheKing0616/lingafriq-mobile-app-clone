/// Tone perception drills from sourced minimal pairs (P5-026, ELEVATION §6.2).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// copy_keys: tone.listen, tone.pick
abstract final class TonePerceptionCopyKeys {
  static const listen = 'tone.listen';
  static const pick = 'tone.pick';

  static const defaultListen = 'Listen to the word, then choose the matching meaning.';
  static const defaultPick = 'Tap the meaning you heard';
}

abstract final class TonePerceptionCodes {
  static const pairUnsourced = 'TonePairUnsourced';
}

class TonePairUnsourced implements Exception {
  TonePairUnsourced(this.pairId, this.detail)
      : code = TonePerceptionCodes.pairUnsourced;

  final String pairId;
  final String detail;
  final String code;

  @override
  String toString() => '$code: $pairId — $detail';
}

class FsiToneReference {
  const FsiToneReference({
    required this.name,
    required this.licence,
    required this.uriOrCitation,
    required this.use,
  });

  final String name;
  final String licence;
  final String uriOrCitation;
  final String use;

  factory FsiToneReference.fromJson(Map<String, dynamic> json) {
    return FsiToneReference(
      name: json['name'] as String,
      licence: json['licence'] as String,
      uriOrCitation: json['uri_or_citation'] as String,
      use: json['use'] as String,
    );
  }
}

class TonePerceptionOption {
  const TonePerceptionOption({
    required this.id,
    required this.form,
    required this.glossEn,
    required this.sourceId,
  });

  final String id;
  final String form;
  final String glossEn;
  final String sourceId;

  factory TonePerceptionOption.fromJson(Map<String, dynamic> json) {
    return TonePerceptionOption(
      id: json['id'] as String,
      form: json['form'] as String,
      glossEn: json['gloss_en'] as String,
      sourceId: json['source_id'] as String,
    );
  }
}

class TonePerceptionDrillSpec {
  const TonePerceptionDrillSpec({
    required this.id,
    required this.promptGlossEn,
    required this.correctOptionId,
    required this.options,
    required this.pairSourceId,
    this.audioUri,
  });

  final String id;
  final String promptGlossEn;
  final String correctOptionId;
  final List<TonePerceptionOption> options;
  final String pairSourceId;
  final String? audioUri;

  factory TonePerceptionDrillSpec.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>;
    return TonePerceptionDrillSpec(
      id: json['id'] as String,
      promptGlossEn: json['prompt_gloss_en'] as String,
      correctOptionId: json['correct_option_id'] as String,
      options: rawOptions
          .map((e) => TonePerceptionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      pairSourceId: json['pair_source_id'] as String,
      audioUri: json['audio_uri'] as String?,
    );
  }
}

class TonePerceptionLanguagePack {
  const TonePerceptionLanguagePack({
    required this.languageCode,
    required this.drills,
    this.fsiReference,
  });

  final String languageCode;
  final List<TonePerceptionDrillSpec> drills;
  final FsiToneReference? fsiReference;
}

class TonePerceptionCatalog {
  const TonePerceptionCatalog({
    required this.cardId,
    required this.packs,
  });

  final String cardId;
  final Map<String, TonePerceptionLanguagePack> packs;
}

/// Perception answer: correct/incorrect only (AC4 — no pronunciation score).
class TonePerceptionAnswer {
  const TonePerceptionAnswer({
    required this.drillId,
    required this.selectedOptionId,
    required this.correct,
  });

  final String drillId;
  final String selectedOptionId;
  final bool correct;
}

bool optionHasSource(TonePerceptionOption option) {
  return option.sourceId.trim().isNotEmpty;
}

void assertDrillOptionsSourced(TonePerceptionDrillSpec drill) {
  if (drill.pairSourceId.trim().isEmpty) {
    throw TonePairUnsourced(drill.id, 'pair_source_id is required');
  }
  for (final option in drill.options) {
    if (!optionHasSource(option)) {
      throw TonePairUnsourced(
        drill.id,
        'option ${option.id} requires source_id',
      );
    }
  }
}

void assertCatalogSourced(TonePerceptionCatalog catalog) {
  for (final pack in catalog.packs.values) {
    for (final drill in pack.drills) {
      assertDrillOptionsSourced(drill);
    }
  }
}

TonePerceptionCatalog parseTonePerceptionCatalog(Map<String, dynamic> root) {
  final langs = root['languages'];
  if (langs is! Map<String, dynamic>) {
    throw FormatException('languages must be a map');
  }
  final packs = <String, TonePerceptionLanguagePack>{};
  for (final entry in langs.entries) {
    final code = entry.key;
    final block = entry.value as Map<String, dynamic>;
    final rawDrills = block['drills'] as List<dynamic>? ?? const [];
    final drills = rawDrills
        .map((e) => TonePerceptionDrillSpec.fromJson(e as Map<String, dynamic>))
        .toList();
    final fsiRaw = block['fsi_tone_reference'];
    packs[code] = TonePerceptionLanguagePack(
      languageCode: code,
      drills: drills,
      fsiReference: fsiRaw is Map<String, dynamic>
          ? FsiToneReference.fromJson(fsiRaw)
          : null,
    );
  }
  final catalog = TonePerceptionCatalog(
    cardId: root['card'] as String? ?? 'P5-026',
    packs: packs,
  );
  assertCatalogSourced(catalog);
  return catalog;
}

TonePerceptionCatalog loadTonePerceptionCatalogFromJson(String jsonText) {
  final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
  return parseTonePerceptionCatalog(decoded);
}

Future<TonePerceptionCatalog> loadTonePerceptionCatalogFromAsset([
  String assetPath = 'assets/data/tone/minimal_pairs.json',
]) async {
  final jsonText = await rootBundle.loadString(assetPath);
  return loadTonePerceptionCatalogFromJson(jsonText);
}

List<TonePerceptionDrillSpec> drillsForLanguage(
  TonePerceptionCatalog catalog,
  String languageCode,
) {
  final pack = catalog.packs[languageCode];
  if (pack == null) {
    return const [];
  }
  return pack.drills;
}

TonePerceptionAnswer gradePerceptionChoice({
  required TonePerceptionDrillSpec drill,
  required String selectedOptionId,
}) {
  final correct = selectedOptionId == drill.correctOptionId;
  return TonePerceptionAnswer(
    drillId: drill.id,
    selectedOptionId: selectedOptionId,
    correct: correct,
  );
}

enum TonePerceptionPhase { intro, listen, choose, result }

/// Learner-facing perception drill (listen → choose → correct/incorrect).
class TonePerceptionDrillScreen extends StatefulWidget {
  const TonePerceptionDrillScreen({
    super.key,
    required this.drill,
    this.listenPrompt = TonePerceptionCopyKeys.defaultListen,
    this.pickPrompt = TonePerceptionCopyKeys.defaultPick,
    this.onComplete,
  });

  final TonePerceptionDrillSpec drill;
  final String listenPrompt;
  final String pickPrompt;
  final void Function(TonePerceptionAnswer answer)? onComplete;

  @override
  State<TonePerceptionDrillScreen> createState() =>
      _TonePerceptionDrillScreenState();
}

class _TonePerceptionDrillScreenState extends State<TonePerceptionDrillScreen> {
  TonePerceptionPhase _phase = TonePerceptionPhase.intro;
  TonePerceptionAnswer? _answer;

  void _advanceToListen() {
    setState(() => _phase = TonePerceptionPhase.listen);
  }

  void _advanceToChoose() {
    setState(() => _phase = TonePerceptionPhase.choose);
  }

  void _select(String optionId) {
    final answer = gradePerceptionChoice(
      drill: widget.drill,
      selectedOptionId: optionId,
    );
    setState(() {
      _answer = answer;
      _phase = TonePerceptionPhase.result;
    });
    widget.onComplete?.call(answer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge;

    return Semantics(
      label: widget.drill.promptGlossEn,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.drill.promptGlossEn, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              if (_phase == TonePerceptionPhase.intro) ...[
                Text(widget.listenPrompt, style: body),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _advanceToListen,
                    child: Text(TonePerceptionCopyKeys.listen),
                  ),
                ),
              ],
              if (_phase == TonePerceptionPhase.listen) ...[
                Text(widget.listenPrompt, style: body),
                if (widget.drill.audioUri != null)
                  Semantics(
                    label: 'Audio clip for tone perception',
                    child: Text(
                      widget.drill.audioUri!,
                      style: body?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _advanceToChoose,
                    child: Text(TonePerceptionCopyKeys.pick),
                  ),
                ),
              ],
              if (_phase == TonePerceptionPhase.choose) ...[
                Text(widget.pickPrompt, style: body),
                const SizedBox(height: 8),
                ...widget.drill.options.map(
                  (opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Semantics(
                      label: '${opt.form}, ${opt.glossEn}',
                      button: true,
                      child: SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _select(opt.id),
                          child: Text('${opt.form} — ${opt.glossEn}'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (_phase == TonePerceptionPhase.result && _answer != null) ...[
                Text(
                  _answer!.correct ? 'Correct' : 'Incorrect',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _answer!.correct
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
