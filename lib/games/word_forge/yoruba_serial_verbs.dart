/// Yoruba serial-verb Word Forge variant (P8-930).
///
/// Valid verb pairs come only from bundled grammar records citing lexicon + FSI register.
library;

import 'dart:math';

import 'morphology_slots.dart';

/// UI copy (games.word_forge_yoruba.* contract).
abstract final class YorubaSerialVerbsCopy {
  static const title = 'Word Forge';
  static const instructions =
      'Pick the subject and two verbs in order. Yoruba serial verbs chain two verb roots with a shared meaning.';
  static const whyWrong =
      'That verb pair is not in our reviewed serial-verb list. Match the prompt or tap Why for the rule.';
  static const practiceLabel =
      'Practice — serial-verb rounds stay off league rank until scoring is verified.';
  static const error =
      'Word Forge is ready for Yoruba, Swahili, and Zulu. Pick one of those languages to play.';
  static const unsupportedWithinYo = 'No reviewed serial-verb templates are loaded for Yoruba yet.';
}

class YoSerialGrammarRecord {
  const YoSerialGrammarRecord({
    required this.recordId,
    required this.verb1OptionId,
    required this.verb2OptionId,
    required this.ruleEn,
    required this.meaningEn,
    required this.sourceRef,
    required this.label,
  });

  final String recordId;
  final String verb1OptionId;
  final String verb2OptionId;
  final String ruleEn;
  final String meaningEn;
  final String sourceRef;
  final String label;

  bool get isPoolEligible => kWordForgeAllowedLabels.contains(label);
}

/// Lexicon-anchored serial verb pairs (FSI register + Leipzig lexeme ids).
const List<YoSerialGrammarRecord> kYoSerialGrammarRecords = [
  YoSerialGrammarRecord(
    recordId: 'yo.sgr.mu-wa',
    verb1OptionId: 'yo.v1.mu',
    verb2OptionId: 'yo.v2.wa',
    ruleEn:
        'Serial verb mú … wá (take … come) expresses bringing something toward the speaker.',
    meaningEn: 'bring (toward speaker)',
    sourceRef: 'register:fsi-yoruba; assets/data/lexicon/a1/yo.json#yo.lex.mu',
    label: 'expert_reviewed',
  ),
  YoSerialGrammarRecord(
    recordId: 'yo.sgr.gbe-lo',
    verb1OptionId: 'yo.v1.gbe',
    verb2OptionId: 'yo.v2.lo',
    ruleEn:
        'Serial verb gbé … lọ (carry … go) expresses taking something away from here.',
    meaningEn: 'carry away',
    sourceRef:
        'register:fsi-yoruba; assets/data/lexicon/b1/yo.json#yo.lex.gbe-lọ',
    label: 'expert_reviewed',
  ),
  YoSerialGrammarRecord(
    recordId: 'yo.sgr.mu-lo',
    verb1OptionId: 'yo.v1.mu',
    verb2OptionId: 'yo.v2.lo',
    ruleEn:
        'Serial verb mú … lọ (take … go) expresses taking something away (similar to carry-and-go).',
    meaningEn: 'take away',
    sourceRef: 'register:fsi-yoruba; assets/data/lexicon/a1/yo.json#yo.lex.mu',
    label: 'expert_reviewed',
  ),
];

const _kYoSubjectSlot = WordForgeSlotDefinition(
  kind: WordForgeSlotKind.yoSubject,
  labelEn: 'Subject',
  options: [
    MorphemeOption(
      id: 'yo.subj.mo',
      surface: 'Mo',
      glossEn: 'I',
      sourceRef: 'assets/data/patterns/yo.json#yo.pat.progressive',
      label: 'expert_reviewed',
    ),
    MorphemeOption(
      id: 'yo.subj.o',
      surface: 'O',
      glossEn: 'you (sg.)',
      sourceRef: 'assets/data/patterns/yo.json#yo.pat.perfect',
      label: 'expert_reviewed',
    ),
    MorphemeOption(
      id: 'yo.subj.o3',
      surface: 'Ó',
      glossEn: 'he/she',
      sourceRef: 'assets/data/patterns/yo.json#yo.pat.progressive',
      label: 'expert_reviewed',
    ),
    MorphemeOption(
      id: 'yo.subj.a',
      surface: 'A',
      glossEn: 'we',
      sourceRef: 'register:fsi-yoruba',
      label: 'expert_reviewed',
    ),
  ],
);

const _kYoVerb1Slot = WordForgeSlotDefinition(
  kind: WordForgeSlotKind.yoSerialV1,
  labelEn: 'First verb',
  options: [
    MorphemeOption(
      id: 'yo.v1.mu',
      surface: 'mú',
      glossEn: 'take',
      sourceRef: 'assets/data/lexicon/a1/yo.json#mu',
      label: 'expert_reviewed',
    ),
    MorphemeOption(
      id: 'yo.v1.gbe',
      surface: 'gbé',
      glossEn: 'carry',
      sourceRef: 'assets/data/lexicon/b1/yo.json#gbé',
      label: 'expert_reviewed',
    ),
    MorphemeOption(
      id: 'yo.v1.lo',
      surface: 'lọ',
      glossEn: 'go',
      sourceRef: 'assets/data/lexicon/a1/yo.json#lọ',
      label: 'expert_reviewed',
    ),
    MorphemeOption(
      id: 'yo.v1.je-unverified',
      surface: 'jẹ',
      glossEn: 'eat (unverified pair)',
      sourceRef: 'curriculum/packs/yo/B2.synth.json#beta',
      label: 'beta',
    ),
  ],
);

const _kYoVerb2Slot = WordForgeSlotDefinition(
  kind: WordForgeSlotKind.yoSerialV2,
  labelEn: 'Second verb',
  options: [
    MorphemeOption(
      id: 'yo.v2.wa',
      surface: 'wá',
      glossEn: 'come',
      sourceRef: 'assets/data/lexicon/a1/yo.json#wa',
      label: 'expert_reviewed',
    ),
    MorphemeOption(
      id: 'yo.v2.lo',
      surface: 'lọ',
      glossEn: 'go',
      sourceRef: 'assets/data/lexicon/a1/yo.json#lọ',
      label: 'expert_reviewed',
    ),
    MorphemeOption(
      id: 'yo.v2.je',
      surface: 'jẹ',
      glossEn: 'eat',
      sourceRef: 'assets/data/lexicon/a1/yo.json#jẹ',
      label: 'expert_reviewed',
    ),
  ],
);

const List<WordForgeSlotDefinition> kYoSerialSlotDefinitions = [
  _kYoSubjectSlot,
  _kYoVerb1Slot,
  _kYoVerb2Slot,
];

const List<WordForgeTemplate> kWordForgeTemplatesYo = [
  WordForgeTemplate(
    templateId: 'yo.serial.mu-wa.1sg',
    languageCode: 'yo',
    promptEn: 'Build: I bring (serial mú … wá)',
    contextEn: 'Use subject Mo with the reviewed take-come pair.',
    patternRef: 'yo.sgr.mu-wa',
    invalidRuleEn:
        'Only listed serial verb pairs count. mú pairs with wá here, not lọ or jẹ alone.',
    solutionBySlotKind: {
      WordForgeSlotKind.yoSubject: 'yo.subj.mo',
      WordForgeSlotKind.yoSerialV1: 'yo.v1.mu',
      WordForgeSlotKind.yoSerialV2: 'yo.v2.wa',
    },
    slots: kYoSerialSlotDefinitions,
  ),
  WordForgeTemplate(
    templateId: 'yo.serial.mu-wa.3sg',
    languageCode: 'yo',
    promptEn: 'Build: he/she brings (serial mú … wá)',
    contextEn: 'Ó + mú + wá — same serial pattern as Mo mú wá.',
    patternRef: 'yo.sgr.mu-wa',
    invalidRuleEn:
        'Serial mú … wá needs Ó as subject and wá as the second verb, not lọ.',
    solutionBySlotKind: {
      WordForgeSlotKind.yoSubject: 'yo.subj.o3',
      WordForgeSlotKind.yoSerialV1: 'yo.v1.mu',
      WordForgeSlotKind.yoSerialV2: 'yo.v2.wa',
    },
    slots: kYoSerialSlotDefinitions,
  ),
  WordForgeTemplate(
    templateId: 'yo.serial.gbe-lo.1sg',
    languageCode: 'yo',
    promptEn: 'Build: I carry away (serial gbé … lọ)',
    contextEn: 'Mo + gbé + lọ — carry toward go, away from here.',
    patternRef: 'yo.sgr.gbe-lo',
    invalidRuleEn:
        'gbé … lọ is the carry-away pair. wá would mean come toward the speaker instead.',
    solutionBySlotKind: {
      WordForgeSlotKind.yoSubject: 'yo.subj.mo',
      WordForgeSlotKind.yoSerialV1: 'yo.v1.gbe',
      WordForgeSlotKind.yoSerialV2: 'yo.v2.lo',
    },
    slots: kYoSerialSlotDefinitions,
  ),
  WordForgeTemplate(
    templateId: 'yo.serial.mu-lo.2sg',
    languageCode: 'yo',
    promptEn: 'Build: you take away (serial mú … lọ)',
    contextEn: 'O + mú + lọ — take and go away.',
    patternRef: 'yo.sgr.mu-lo',
    invalidRuleEn:
        'mú … lọ pairs take with go. wá would change the direction to toward you.',
    solutionBySlotKind: {
      WordForgeSlotKind.yoSubject: 'yo.subj.o',
      WordForgeSlotKind.yoSerialV1: 'yo.v1.mu',
      WordForgeSlotKind.yoSerialV2: 'yo.v2.lo',
    },
    slots: kYoSerialSlotDefinitions,
  ),
];

bool isYorubaSerialTemplate(WordForgeTemplate template) =>
    template.languageCode == 'yo';

YoSerialGrammarRecord? grammarRecordForSelection({
  required MorphemeOption? verb1,
  required MorphemeOption? verb2,
}) {
  if (verb1 == null || verb2 == null) return null;
  for (final record in kYoSerialGrammarRecords) {
    if (!record.isPoolEligible) continue;
    if (record.verb1OptionId == verb1.id && record.verb2OptionId == verb2.id) {
      return record;
    }
  }
  return null;
}

WordForgeComposeResult composeYorubaSerial(WordForgeSelection selection) {
  final subj = selection.byKind[WordForgeSlotKind.yoSubject]?.surface ?? '';
  final v1 = selection.byKind[WordForgeSlotKind.yoSerialV1]?.surface ?? '';
  final v2 = selection.byKind[WordForgeSlotKind.yoSerialV2]?.surface ?? '';
  final surface = [subj, v1, v2].where((s) => s.isNotEmpty).join(' ');

  final record = grammarRecordForSelection(
    verb1: selection.byKind[WordForgeSlotKind.yoSerialV1],
    verb2: selection.byKind[WordForgeSlotKind.yoSerialV2],
  );
  final glossParts = <String>[
    selection.byKind[WordForgeSlotKind.yoSubject]?.glossEn ?? '?',
    selection.byKind[WordForgeSlotKind.yoSerialV1]?.glossEn ?? '?',
    selection.byKind[WordForgeSlotKind.yoSerialV2]?.glossEn ?? '?',
  ];
  final glossEn = record != null
      ? '${glossParts.join(' · ')} — ${record.meaningEn}'
      : glossParts.join(' · ');

  return WordForgeComposeResult(surface: surface, glossEn: glossEn);
}

WordForgeValidation validateYorubaSerial({
  required WordForgeTemplate template,
  required WordForgeSelection selection,
}) {
  final composed = composeYorubaSerial(selection);
  for (final slot in template.slots) {
    if (selection.byKind[slot.kind] == null) {
      return WordForgeValidation.invalidForm(
        surface: composed.surface,
        glossEn: composed.glossEn,
        invalidRule: 'Choose a value for every slot before you submit.',
      );
    }
  }

  final v1 = selection.byKind[WordForgeSlotKind.yoSerialV1];
  final v2 = selection.byKind[WordForgeSlotKind.yoSerialV2];
  if ((v1 != null && !v1.isPoolEligible) || (v2 != null && !v2.isPoolEligible)) {
    return WordForgeValidation.invalidForm(
      surface: composed.surface,
      glossEn: composed.glossEn,
      invalidRule:
          'That verb is not in the reviewed pool yet. Pick an expert-reviewed option.',
    );
  }

  final record = grammarRecordForSelection(verb1: v1, verb2: v2);
  if (record == null) {
    return WordForgeValidation.invalidForm(
      surface: composed.surface,
      glossEn: composed.glossEn,
      invalidRule:
          'This verb pair is not a listed serial construction. Use a reviewed mú…wá, gbé…lọ, or mú…lọ pair.',
    );
  }

  for (final entry in template.solutionBySlotKind.entries) {
    final chosen = selection.byKind[entry.key];
    if (chosen == null || chosen.id != entry.value) {
      return WordForgeValidation.invalidForm(
        surface: composed.surface,
        glossEn: composed.glossEn,
        invalidRule: record.ruleEn,
      );
    }
  }

  return WordForgeValidation.correct(
    surface: composed.surface,
    glossEn: composed.glossEn,
  );
}

String displayYorubaSerialLine(WordForgeSelection selection) {
  final subj = selection.byKind[WordForgeSlotKind.yoSubject]?.surface ?? '…';
  final v1 = selection.byKind[WordForgeSlotKind.yoSerialV1]?.surface ?? '…';
  final v2 = selection.byKind[WordForgeSlotKind.yoSerialV2]?.surface ?? '…';
  return '$subj $v1 $v2';
}

List<WordForgeTemplate> yorubaSerialTemplates() =>
    List<WordForgeTemplate>.from(kWordForgeTemplatesYo);

WordForgeTemplate pickYorubaSerialTemplate(Random rng) {
  final pool = kWordForgeTemplatesYo;
  return pool[rng.nextInt(pool.length)];
}
