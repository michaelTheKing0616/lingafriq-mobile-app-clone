/// Word Forge morphology pools (P8-926): expert-reviewed pattern + lexicon anchors only.
library;

import 'dart:math';

import 'yoruba_serial_verbs.dart';

/// Publication labels allowed in slot pools (unverified / beta excluded).
const Set<String> kWordForgeAllowedLabels = {'expert_reviewed'};

class MorphemeOption {
  const MorphemeOption({
    required this.id,
    required this.surface,
    required this.glossEn,
    required this.sourceRef,
    required this.label,
  });

  final String id;
  final String surface;
  final String glossEn;
  final String sourceRef;
  final String label;

  bool get isPoolEligible => kWordForgeAllowedLabels.contains(label);
}

enum WordForgeSlotKind {
  subjectPrefix,
  tenseInfix,
  objectPrefix,
  verbStem,
  yoSubject,
  yoSerialV1,
  yoSerialV2,
}

class WordForgeSlotDefinition {
  const WordForgeSlotDefinition({
    required this.kind,
    required this.labelEn,
    required this.options,
  });

  final WordForgeSlotKind kind;
  final String labelEn;
  final List<MorphemeOption> options;

  List<MorphemeOption> poolOptions() =>
      options.where((o) => o.isPoolEligible).toList(growable: false);
}

class WordForgeTemplate {
  const WordForgeTemplate({
    required this.templateId,
    required this.languageCode,
    required this.promptEn,
    required this.contextEn,
    required this.slots,
    required this.solutionBySlotKind,
    required this.invalidRuleEn,
    required this.patternRef,
  });

  final String templateId;
  final String languageCode;
  final String promptEn;
  final String contextEn;
  final List<WordForgeSlotDefinition> slots;
  final Map<WordForgeSlotKind, String> solutionBySlotKind;
  final String invalidRuleEn;
  final String patternRef;
}

class WordForgeSelection {
  const WordForgeSelection(this.byKind);

  final Map<WordForgeSlotKind, MorphemeOption?> byKind;
}

class WordForgeComposeResult {
  const WordForgeComposeResult({
    required this.surface,
    required this.glossEn,
  });

  final String surface;
  final String glossEn;
}

class WordForgeValidation {
  const WordForgeValidation.correct({
    required this.surface,
    required this.glossEn,
  })  : isCorrect = true,
        invalidRule = null;

  const WordForgeValidation.invalidForm({
    required this.surface,
    required this.glossEn,
    required String invalidRule,
  })  : isCorrect = false,
        invalidRule = invalidRule;

  final bool isCorrect;
  final String surface;
  final String glossEn;
  final String? invalidRule;
}

/// Bundled morpheme fixtures (sources: assets/data/patterns/sw.json, zu.json).
const _kSwSlotDefinitions = [
      WordForgeSlotDefinition(
        kind: WordForgeSlotKind.subjectPrefix,
        labelEn: 'Subject',
        options: [
          MorphemeOption(
            id: 'sw.subj.ni',
            surface: 'ni-',
            glossEn: 'I',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.present-na',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'sw.subj.u',
            surface: 'u-',
            glossEn: 'you (sg.)',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.present-na',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'sw.subj.a',
            surface: 'a-',
            glossEn: 'he/she',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.present-na',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'sw.subj.tu',
            surface: 'tu-',
            glossEn: 'we',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.present-na',
            label: 'expert_reviewed',
          ),
        ],
      ),
      WordForgeSlotDefinition(
        kind: WordForgeSlotKind.tenseInfix,
        labelEn: 'Tense',
        options: [
          MorphemeOption(
            id: 'sw.tense.na',
            surface: '-na-',
            glossEn: 'present / ongoing',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.present-na',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'sw.tense.li',
            surface: '-li-',
            glossEn: 'past',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.past-li',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'sw.tense.ta',
            surface: '-ta-',
            glossEn: 'future',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.present-na',
            label: 'expert_reviewed',
          ),
        ],
      ),
      WordForgeSlotDefinition(
        kind: WordForgeSlotKind.objectPrefix,
        labelEn: 'Object',
        options: [
          MorphemeOption(
            id: 'sw.obj.ku',
            surface: '-ku-',
            glossEn: 'you',
            sourceRef: 'assets/data/lexicon/b1/sw.json#kupenda',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'sw.obj.ni',
            surface: '-ni-',
            glossEn: 'me',
            sourceRef: 'assets/data/lexicon/b1/sw.json#kupenda',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'sw.obj.none',
            surface: '',
            glossEn: '(no object prefix)',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.present-na',
            label: 'expert_reviewed',
          ),
        ],
      ),
      WordForgeSlotDefinition(
        kind: WordForgeSlotKind.verbStem,
        labelEn: 'Stem',
        options: [
          MorphemeOption(
            id: 'sw.stem.penda',
            surface: 'penda',
            glossEn: 'love / like',
            sourceRef: 'assets/data/lexicon/b1/sw.json#kupenda',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'sw.stem.enda',
            surface: 'enda',
            glossEn: 'go',
            sourceRef: 'assets/data/patterns/sw.json#sw.pat.present-na',
            label: 'expert_reviewed',
          ),
        ],
      ),
];

const List<WordForgeTemplate> kWordForgeTemplatesSw = [
  WordForgeTemplate(
    templateId: 'sw.present.3sg.like.you',
    languageCode: 'sw',
    promptEn: 'Build: he/she loves you',
    contextEn: 'Present tense with object prefix -ku- (you)',
    patternRef: 'sw.pat.present-na',
    invalidRuleEn:
        'Present progressive uses -na- after the subject prefix. The object "you" takes -ku- before the verb stem.',
    solutionBySlotKind: {
      WordForgeSlotKind.subjectPrefix: 'sw.subj.a',
      WordForgeSlotKind.tenseInfix: 'sw.tense.na',
      WordForgeSlotKind.objectPrefix: 'sw.obj.ku',
      WordForgeSlotKind.verbStem: 'sw.stem.penda',
    },
    slots: _kSwSlotDefinitions,
  ),
  WordForgeTemplate(
    templateId: 'sw.present.1sg.go',
    languageCode: 'sw',
    promptEn: 'Build: I am going (present)',
    contextEn: 'Ninaenda pattern — subject ni- + -na- + stem',
    patternRef: 'sw.pat.present-na',
    invalidRuleEn:
        'Ongoing movement uses -na- after ni-. Do not use past -li- or future -ta- for “I am going now”.',
    solutionBySlotKind: {
      WordForgeSlotKind.subjectPrefix: 'sw.subj.ni',
      WordForgeSlotKind.tenseInfix: 'sw.tense.na',
      WordForgeSlotKind.objectPrefix: 'sw.obj.none',
      WordForgeSlotKind.verbStem: 'sw.stem.enda',
    },
    slots: _kSwSlotDefinitions,
  ),
];

const _kZuSlotDefinitions = [
  WordForgeSlotDefinition(
        kind: WordForgeSlotKind.subjectPrefix,
        labelEn: 'Subject concord',
        options: [
          MorphemeOption(
            id: 'zu.subj.u',
            surface: 'u-',
            glossEn: 'class 1 (sg. person)',
            sourceRef: 'assets/data/patterns/zu.json#zu.pat.sc-c01',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'zu.subj.ba',
            surface: 'ba-',
            glossEn: 'class 2 (pl. people)',
            sourceRef: 'assets/data/patterns/zu.json#zu.pat.sc-c02',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'zu.subj.i',
            surface: 'i-',
            glossEn: 'class 9 (inanimate)',
            sourceRef: 'assets/data/patterns/zu.json#zu.pat.sc-c09',
            label: 'expert_reviewed',
          ),
        ],
      ),
      WordForgeSlotDefinition(
        kind: WordForgeSlotKind.tenseInfix,
        labelEn: 'Present',
        options: [
          MorphemeOption(
            id: 'zu.tense.ya',
            surface: '-ya-',
            glossEn: 'present',
            sourceRef: 'assets/data/patterns/zu.json#zu.pat.sc-c01',
            label: 'expert_reviewed',
          ),
        ],
      ),
      WordForgeSlotDefinition(
        kind: WordForgeSlotKind.objectPrefix,
        labelEn: 'Object',
        options: [
          MorphemeOption(
            id: 'zu.obj.none',
            surface: '',
            glossEn: '(none)',
            sourceRef: 'assets/data/patterns/zu.json#zu.pat.sc-c01',
            label: 'expert_reviewed',
          ),
        ],
      ),
      WordForgeSlotDefinition(
        kind: WordForgeSlotKind.verbStem,
        labelEn: 'Stem',
        options: [
          MorphemeOption(
            id: 'zu.stem.hamba',
            surface: 'hamba',
            glossEn: 'walk / go',
            sourceRef: 'assets/data/patterns/zu.json#zu.pat.sc-c01',
            label: 'expert_reviewed',
          ),
          MorphemeOption(
            id: 'zu.stem.dlala',
            surface: 'dlala',
            glossEn: 'play',
            sourceRef: 'assets/data/patterns/zu.json#zu.pat.sc-c02',
            label: 'expert_reviewed',
          ),
        ],
      ),
];

const List<WordForgeTemplate> kWordForgeTemplatesZu = [
  WordForgeTemplate(
    templateId: 'zu.present.c1.walk',
    languageCode: 'zu',
    promptEn: 'Build: the person is walking (class 1)',
    contextEn: 'Umuntu uyahamba — class 1 noun agrees with u- subject concord',
    patternRef: 'zu.pat.sc-c01',
    invalidRuleEn:
        'Class 1 (umu-/u-) nouns take subject concord u- on the verb, not ba- (class 2).',
    solutionBySlotKind: {
      WordForgeSlotKind.subjectPrefix: 'zu.subj.u',
      WordForgeSlotKind.tenseInfix: 'zu.tense.ya',
      WordForgeSlotKind.objectPrefix: 'zu.obj.none',
      WordForgeSlotKind.verbStem: 'zu.stem.hamba',
    },
    slots: _kZuSlotDefinitions,
  ),
  WordForgeTemplate(
    templateId: 'zu.present.c2.play',
    languageCode: 'zu',
    promptEn: 'Build: the people are playing (class 2)',
    contextEn: 'Abantu bayadlala — class 2 uses ba- concord',
    patternRef: 'zu.pat.sc-c02',
    invalidRuleEn:
        'Class 2 (aba-/a-) plural people take ba- on the verb. u- is for class 1 singular.',
    solutionBySlotKind: {
      WordForgeSlotKind.subjectPrefix: 'zu.subj.ba',
      WordForgeSlotKind.tenseInfix: 'zu.tense.ya',
      WordForgeSlotKind.objectPrefix: 'zu.obj.none',
      WordForgeSlotKind.verbStem: 'zu.stem.dlala',
    },
    slots: _kZuSlotDefinitions,
  ),
];

List<WordForgeTemplate> wordForgeTemplatesForLanguage(String languageCode) {
  final lang = languageCode.toLowerCase();
  if (lang == 'yo' || lang == 'yoruba') {
    return yorubaSerialTemplates();
  }
  if (lang == 'sw' || lang == 'swahili') {
    return List<WordForgeTemplate>.from(kWordForgeTemplatesSw);
  }
  if (lang == 'zu' || lang == 'zulu') {
    return List<WordForgeTemplate>.from(kWordForgeTemplatesZu);
  }
  return const [];
}

bool wordForgeLanguageSupported(String languageCode) {
  return wordForgeTemplatesForLanguage(languageCode).isNotEmpty;
}

WordForgeTemplate pickWordForgeTemplate({
  required String languageCode,
  required Random rng,
}) {
  final pool = wordForgeTemplatesForLanguage(languageCode);
  if (pool.isEmpty) {
    throw StateError('word_forge_unsupported_language');
  }
  return pool[rng.nextInt(pool.length)];
}

MorphemeOption? optionById(WordForgeTemplate template, String optionId) {
  for (final slot in template.slots) {
    for (final opt in slot.options) {
      if (opt.id == optionId) return opt;
    }
  }
  return null;
}

WordForgeSelection emptySelection(WordForgeTemplate template) {
  return WordForgeSelection({
    for (final slot in template.slots) slot.kind: null,
  });
}

String joinSurface(List<String> parts) {
  final cleaned = <String>[];
  for (final p in parts) {
    final s = p.trim();
    if (s.isEmpty) continue;
    cleaned.add(s.replaceAll(RegExp(r'^-+|-+$'), ''));
  }
  return cleaned.join('');
}

WordForgeComposeResult composeWordForge(WordForgeSelection selection) {
  if (selection.byKind.containsKey(WordForgeSlotKind.yoSubject)) {
    return composeYorubaSerial(selection);
  }
  final subj = selection.byKind[WordForgeSlotKind.subjectPrefix]?.surface ?? '';
  final tense = selection.byKind[WordForgeSlotKind.tenseInfix]?.surface ?? '';
  final obj = selection.byKind[WordForgeSlotKind.objectPrefix]?.surface ?? '';
  final stem = selection.byKind[WordForgeSlotKind.verbStem]?.surface ?? '';

  final surface = joinSurface([subj, tense, obj, stem]);

  final glossParts = <String>[
    selection.byKind[WordForgeSlotKind.subjectPrefix]?.glossEn ?? '?',
    selection.byKind[WordForgeSlotKind.tenseInfix]?.glossEn ?? '?',
    if ((selection.byKind[WordForgeSlotKind.objectPrefix]?.surface ?? '')
        .isNotEmpty)
      selection.byKind[WordForgeSlotKind.objectPrefix]!.glossEn,
    selection.byKind[WordForgeSlotKind.verbStem]?.glossEn ?? '?',
  ];
  final glossEn = glossParts.where((g) => g != '(none)' && g != '(no object prefix)').join(' · ');

  return WordForgeComposeResult(surface: surface, glossEn: glossEn);
}

bool _selectionMatchesSolution(
  WordForgeTemplate template,
  WordForgeSelection selection,
) {
  for (final entry in template.solutionBySlotKind.entries) {
    final chosen = selection.byKind[entry.key];
    if (chosen == null || chosen.id != entry.value) return false;
  }
  return true;
}

bool _selectionComplete(WordForgeTemplate template, WordForgeSelection selection) {
  for (final slot in template.slots) {
    if (selection.byKind[slot.kind] == null) return false;
  }
  return true;
}

WordForgeValidation validateWordForge({
  required WordForgeTemplate template,
  required WordForgeSelection selection,
}) {
  if (isYorubaSerialTemplate(template)) {
    return validateYorubaSerial(template: template, selection: selection);
  }
  final composed = composeWordForge(selection);
  if (!_selectionComplete(template, selection)) {
    return WordForgeValidation.invalidForm(
      surface: composed.surface,
      glossEn: composed.glossEn,
      invalidRule: 'Choose a value for every slot before you submit.',
    );
  }
  if (_selectionMatchesSolution(template, selection)) {
    return WordForgeValidation.correct(
      surface: composed.surface,
      glossEn: composed.glossEn,
    );
  }
  return WordForgeValidation.invalidForm(
    surface: composed.surface,
    glossEn: composed.glossEn,
    invalidRule: template.invalidRuleEn,
  );
}

String displaySlotsLine(WordForgeSelection selection) {
  if (selection.byKind.containsKey(WordForgeSlotKind.yoSubject)) {
    return displayYorubaSerialLine(selection);
  }
  final subj = selection.byKind[WordForgeSlotKind.subjectPrefix]?.surface ?? '…';
  final tense = selection.byKind[WordForgeSlotKind.tenseInfix]?.surface ?? '…';
  final obj = selection.byKind[WordForgeSlotKind.objectPrefix];
  final stem = selection.byKind[WordForgeSlotKind.verbStem]?.surface ?? '…';
  final objPart = (obj == null || obj.surface.isEmpty) ? '' : obj.surface;
  return '$subj$tense$objPart$stem';
}
