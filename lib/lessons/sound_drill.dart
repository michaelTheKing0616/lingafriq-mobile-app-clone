/// Click, vowel-purity, and stress perception drills (P5-028, CURRICULUM §4).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// copy_keys: sound.listen
abstract final class SoundDrillCopyKeys {
  static const listen = 'sound.listen';

  static const defaultListen =
      'Listen to the clip, then choose the matching answer.';
}

abstract final class SoundDrillCodes {
  static const audioMissing = 'AudioMissing';
}

class AudioMissing implements Exception {
  AudioMissing(this.drillId, [this.detail = ''])
      : code = SoundDrillCodes.audioMissing;

  final String drillId;
  final String detail;
  final String code;

  @override
  String toString() =>
      '$code: $drillId${detail.isEmpty ? '' : ' — $detail'}';
}

enum SoundDrillKind {
  clickContrast('click_contrast'),
  vowelPurity('vowel_purity'),
  stress('stress');

  const SoundDrillKind(this.jsonValue);
  final String jsonValue;

  static SoundDrillKind parse(String raw) {
    return SoundDrillKind.values.firstWhere(
      (k) => k.jsonValue == raw,
      orElse: () => throw FormatException('unknown sound drill kind: $raw'),
    );
  }
}

class WaxalLicenceRef {
  const WaxalLicenceRef({
    required this.registerId,
    required this.licence,
    required this.uriOrCitation,
  });

  final String registerId;
  final String licence;
  final String uriOrCitation;

  factory WaxalLicenceRef.fromJson(Map<String, dynamic> json) {
    return WaxalLicenceRef(
      registerId: json['register_id'] as String,
      licence: json['licence'] as String,
      uriOrCitation: json['uri_or_citation'] as String,
    );
  }

  bool get isCommerciallyLicensed =>
      registerId.isNotEmpty && licence.isNotEmpty && uriOrCitation.isNotEmpty;
}

class FsiSoundReference {
  const FsiSoundReference({
    required this.name,
    required this.licence,
    required this.uriOrCitation,
    required this.use,
  });

  final String name;
  final String licence;
  final String uriOrCitation;
  final String use;

  factory FsiSoundReference.fromJson(Map<String, dynamic> json) {
    return FsiSoundReference(
      name: json['name'] as String,
      licence: json['licence'] as String,
      uriOrCitation: json['uri_or_citation'] as String,
      use: json['use'] as String,
    );
  }
}

class SoundDrillOption {
  const SoundDrillOption({
    required this.id,
    required this.form,
    required this.glossEn,
    required this.sourceId,
  });

  final String id;
  final String form;
  final String glossEn;
  final String sourceId;

  factory SoundDrillOption.fromJson(Map<String, dynamic> json) {
    return SoundDrillOption(
      id: json['id'] as String,
      form: json['form'] as String,
      glossEn: json['gloss_en'] as String,
      sourceId: json['source_id'] as String,
    );
  }
}

class SoundDrillSpec {
  const SoundDrillSpec({
    required this.id,
    required this.kind,
    required this.promptGlossEn,
    required this.correctOptionId,
    required this.options,
    required this.pairSourceId,
    required this.audioUri,
  });

  final String id;
  final SoundDrillKind kind;
  final String promptGlossEn;
  final String correctOptionId;
  final List<SoundDrillOption> options;
  final String pairSourceId;
  final String audioUri;

  factory SoundDrillSpec.fromJson(Map<String, dynamic> json) {
    return SoundDrillSpec(
      id: json['id'] as String,
      kind: SoundDrillKind.parse(json['kind'] as String),
      promptGlossEn: json['prompt_gloss_en'] as String,
      correctOptionId: json['correct_option_id'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => SoundDrillOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      pairSourceId: json['pair_source_id'] as String,
      audioUri: json['audio_uri'] as String? ?? '',
    );
  }
}

class SoundLanguagePack {
  const SoundLanguagePack({
    required this.languageCode,
    required this.drills,
    this.waxalLicence,
    this.fsiReference,
  });

  final String languageCode;
  final List<SoundDrillSpec> drills;
  final WaxalLicenceRef? waxalLicence;
  final FsiSoundReference? fsiReference;
}

class SoundDrillCatalog {
  const SoundDrillCatalog({
    required this.cardId,
    required this.packs,
  });

  final String cardId;
  final Map<String, SoundLanguagePack> packs;
}

class SoundDrillAnswer {
  const SoundDrillAnswer({
    required this.drillId,
    required this.selectedOptionId,
    required this.correct,
  });

  final String drillId;
  final String selectedOptionId;
  final bool correct;
}

void assertDrillHasAudio(SoundDrillSpec drill) {
  if (drill.audioUri.trim().isEmpty) {
    throw AudioMissing(drill.id, 'audio_uri is required');
  }
}

void assertClickPackLicence(SoundLanguagePack pack) {
  if (pack.languageCode != 'xh' && pack.languageCode != 'zu') {
    return;
  }
  final lic = pack.waxalLicence;
  if (lic == null || !lic.isCommerciallyLicensed) {
    throw FormatException(
      'WAXAL licence block required for ${pack.languageCode} click drills',
    );
  }
  if (!lic.uriOrCitation.contains('waxal')) {
    throw FormatException('WAXAL citation missing for ${pack.languageCode}');
  }
}

void assertDrillSourced(SoundDrillSpec drill) {
  assertDrillHasAudio(drill);
  if (drill.pairSourceId.trim().isEmpty) {
    throw FormatException('pair_source_id required for ${drill.id}');
  }
  for (final option in drill.options) {
    if (option.sourceId.trim().isEmpty) {
      throw FormatException('source_id required for option ${option.id}');
    }
  }
}

void assertCatalogBuilt(SoundDrillCatalog catalog) {
  for (final pack in catalog.packs.values) {
    assertClickPackLicence(pack);
    for (final drill in pack.drills) {
      assertDrillSourced(drill);
    }
  }
}

SoundDrillCatalog parseSoundDrillCatalog(Map<String, dynamic> root) {
  final langs = root['languages'];
  if (langs is! Map<String, dynamic>) {
    throw const FormatException('languages must be a map');
  }
  final packs = <String, SoundLanguagePack>{};
  for (final entry in langs.entries) {
    final code = entry.key;
    final block = entry.value as Map<String, dynamic>;
    final rawDrills = block['drills'] as List<dynamic>? ?? const [];
    final drills = rawDrills
        .map((e) => SoundDrillSpec.fromJson(e as Map<String, dynamic>))
        .toList();
    final waxalRaw = block['waxal_licence'];
    final fsiRaw = block['fsi_reference'];
    packs[code] = SoundLanguagePack(
      languageCode: code,
      drills: drills,
      waxalLicence: waxalRaw is Map<String, dynamic>
          ? WaxalLicenceRef.fromJson(waxalRaw)
          : null,
      fsiReference: fsiRaw is Map<String, dynamic>
          ? FsiSoundReference.fromJson(fsiRaw)
          : null,
    );
  }
  final catalog = SoundDrillCatalog(
    cardId: root['card'] as String? ?? 'P5-028',
    packs: packs,
  );
  assertCatalogBuilt(catalog);
  return catalog;
}

SoundDrillCatalog loadSoundDrillCatalogFromJson(String jsonText) {
  final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
  return parseSoundDrillCatalog(decoded);
}

Future<SoundDrillCatalog> loadSoundDrillCatalogFromAsset([
  String assetPath = 'assets/data/sound/clicks_vowels.json',
]) async {
  final jsonText = await rootBundle.loadString(assetPath);
  return loadSoundDrillCatalogFromJson(jsonText);
}

List<SoundDrillSpec> soundDrillsForLanguage(
  SoundDrillCatalog catalog,
  String languageCode,
) {
  return catalog.packs[languageCode]?.drills ?? const [];
}

SoundDrillAnswer gradeSoundChoice({
  required SoundDrillSpec drill,
  required String selectedOptionId,
}) {
  return SoundDrillAnswer(
    drillId: drill.id,
    selectedOptionId: selectedOptionId,
    correct: selectedOptionId == drill.correctOptionId,
  );
}

enum SoundDrillPhase { listen, choose, result }

/// Learner-facing sound drill (listen → choose → correct/incorrect).
class SoundDrillScreen extends StatefulWidget {
  const SoundDrillScreen({
    super.key,
    required this.drill,
    this.listenPrompt = SoundDrillCopyKeys.defaultListen,
    this.onComplete,
  });

  final SoundDrillSpec drill;
  final String listenPrompt;
  final void Function(SoundDrillAnswer answer)? onComplete;

  @override
  State<SoundDrillScreen> createState() => _SoundDrillScreenState();
}

class _SoundDrillScreenState extends State<SoundDrillScreen> {
  SoundDrillPhase _phase = SoundDrillPhase.listen;
  SoundDrillAnswer? _answer;

  void _advanceToChoose() {
    setState(() => _phase = SoundDrillPhase.choose);
  }

  void _select(String optionId) {
    final answer = gradeSoundChoice(
      drill: widget.drill,
      selectedOptionId: optionId,
    );
    setState(() {
      _answer = answer;
      _phase = SoundDrillPhase.result;
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
              if (_phase == SoundDrillPhase.listen) ...[
                Text(widget.listenPrompt, style: body),
                Semantics(
                  label: 'Audio clip for sound drill',
                  child: Text(
                    widget.drill.audioUri,
                    style: body?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _advanceToChoose,
                    child: const Text(SoundDrillCopyKeys.listen),
                  ),
                ),
              ],
              if (_phase == SoundDrillPhase.choose) ...[
                Text(widget.listenPrompt, style: body),
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
              if (_phase == SoundDrillPhase.result && _answer != null) ...[
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
