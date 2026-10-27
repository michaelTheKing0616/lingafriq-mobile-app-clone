// P11-020 — Authored scenario beats for ADR-031 v1 personas (§8.4 branching).

import 'package:lingafriq/ai/personas/historical_persona_registry.dart';

/// One authored story beat with learner branch labels mapping to a next beat id.
class AuthoredBeat {
  const AuthoredBeat({
    required this.beatId,
    required this.summaryEn,
    required this.branches,
    this.isEntry = false,
  });

  final String beatId;
  final String summaryEn;
  /// Branch key → next beat id (must exist in the same template graph).
  final Map<String, String> branches;
  final bool isEntry;

  Map<String, String> branchLabelsForRegistry() {
    final out = <String, String>{};
    for (final entry in branches.entries) {
      out[entry.key] = '$summaryEn → ${entry.key}';
    }
    return out;
  }
}

/// Full beat graph for one roleplay scenario template.
class ScenarioBeatGraph {
  const ScenarioBeatGraph({
    required this.scenarioTemplateId,
    required this.personaId,
    required this.mode,
    required this.beats,
  });

  final String scenarioTemplateId;
  final String personaId;
  final String mode;
  final List<AuthoredBeat> beats;

  AuthoredBeat? beatById(String beatId) {
    for (final beat in beats) {
      if (beat.beatId == beatId) return beat;
    }
    return null;
  }

  AuthoredBeat get entryBeat {
    for (final beat in beats) {
      if (beat.isEntry) return beat;
    }
    return beats.first;
  }

  Set<String> allowedBeatIds() => beats.map((b) => b.beatId).toSet();

  /// Merged branch map for [RoleplayScenarioTemplate.branches] (AC1).
  Map<String, String> registryBranches() {
    final merged = <String, String>{};
    for (final beat in beats) {
      merged.addAll(beat.branchLabelsForRegistry());
    }
    return merged;
  }

  void validateStructure() {
    if (beats.isEmpty) {
      throw BeatsSchemaException('beats_empty', scenarioTemplateId);
    }
    final ids = allowedBeatIds();
    var entryCount = 0;
    for (final beat in beats) {
      if (beat.isEntry) entryCount++;
      if (beat.branches.isEmpty) {
        throw BeatsSchemaException('beat_missing_branch', '${scenarioTemplateId}:${beat.beatId}');
      }
      for (final target in beat.branches.values) {
        if (!ids.contains(target)) {
          throw BeatsSchemaException('branch_target_unknown', '$scenarioTemplateId:${beat.beatId}->$target');
        }
      }
    }
    if (entryCount != 1) {
      throw BeatsSchemaException('entry_beat_count', scenarioTemplateId);
    }
  }
}

class BeatsSchemaException implements Exception {
  BeatsSchemaException(this.code, this.detail);
  final String code;
  final String detail;
  @override
  String toString() => 'BeatsSchemaException($code, $detail)';
}

/// Canonical v1 scenario template ids (5 personas × 3 modes).
const List<String> kV1ScenarioTemplateIds = [
  'yaa_life',
  'yaa_opinion',
  'yaa_quiz',
  'nkrumah_life',
  'nkrumah_opinion',
  'nkrumah_quiz',
  'shaka_life',
  'shaka_opinion',
  'shaka_quiz',
  'baba_life',
  'baba_opinion',
  'baba_quiz',
  'mofolo_life',
  'mofolo_opinion',
  'mofolo_quiz',
];

/// Aliases from seed / engagement ids to registry template ids.
const Map<String, String> kScenarioTemplateAliases = {
  'yaa_asantewaa_life_story': 'yaa_life',
  'yaa_asantewaa_opinion_debate': 'yaa_opinion',
  'yaa_asantewaa_language_quiz': 'yaa_quiz',
  'nkrumah_kwame_life_story': 'nkrumah_life',
  'nkrumah_kwame_opinion_debate': 'nkrumah_opinion',
  'nkrumah_kwame_language_quiz': 'nkrumah_quiz',
  'shaka_zulu_life_story': 'shaka_life',
  'shaka_zulu_opinion_debate': 'shaka_opinion',
  'shaka_zulu_language_quiz': 'shaka_quiz',
  'ahmed_baba_life_story': 'baba_life',
  'ahmed_baba_opinion_debate': 'baba_opinion',
  'ahmed_baba_language_quiz': 'baba_quiz',
  'thomas_mofolo_life_story': 'mofolo_life',
  'thomas_mofolo_opinion_debate': 'mofolo_opinion',
  'thomas_mofolo_language_quiz': 'mofolo_quiz',
};

ScenarioBeatGraph _lifeGraph(String personaId, String templateId, String hookEn) {
  return ScenarioBeatGraph(
    scenarioTemplateId: templateId,
    personaId: personaId,
    mode: 'life_story',
    beats: [
      AuthoredBeat(
        beatId: 'opening',
        summaryEn: hookEn,
        isEntry: true,
        branches: {'continue': 'deeper', 'redirect': 'another_time'},
      ),
      AuthoredBeat(
        beatId: 'deeper',
        summaryEn: 'Expand on the chosen moment with sourced detail',
        branches: {'continue': 'reflect', 'redirect': 'opening'},
      ),
      AuthoredBeat(
        beatId: 'another_time',
        summaryEn: 'Shift to a different documented episode',
        branches: {'continue': 'reflect', 'redirect': 'opening'},
      ),
      AuthoredBeat(
        beatId: 'reflect',
        summaryEn: 'Invite the learner to reflect on the lesson',
        branches: {'continue': 'opening'},
      ),
    ],
  );
}

ScenarioBeatGraph _opinionGraph(String personaId, String templateId) {
  return ScenarioBeatGraph(
    scenarioTemplateId: templateId,
    personaId: personaId,
    mode: 'opinion_debate',
    beats: [
      AuthoredBeat(
        beatId: 'stance',
        summaryEn: 'State a documented position calmly',
        isEntry: true,
        branches: {'agree': 'build', 'challenge': 'clarify'},
      ),
      AuthoredBeat(
        beatId: 'build',
        summaryEn: 'Acknowledge agreement and add historical context',
        branches: {'continue': 'stance'},
      ),
      AuthoredBeat(
        beatId: 'clarify',
        summaryEn: 'Respond to disagreement without anger',
        branches: {'continue': 'stance'},
      ),
    ],
  );
}

ScenarioBeatGraph _quizGraph(String personaId, String templateId, String langLabel) {
  return ScenarioBeatGraph(
    scenarioTemplateId: templateId,
    personaId: personaId,
    mode: 'language_quiz',
    beats: [
      AuthoredBeat(
        beatId: 'teach',
        summaryEn: 'Teach one $langLabel phrase with meaning',
        isEntry: true,
        branches: {'correct': 'praise', 'hint': 'coach'},
      ),
      AuthoredBeat(
        beatId: 'coach',
        summaryEn: 'Give a gentle hint and retry',
        branches: {'correct': 'praise', 'hint': 'teach'},
      ),
      AuthoredBeat(
        beatId: 'praise',
        summaryEn: 'Celebrate correct use and offer another phrase',
        branches: {'continue': 'teach'},
      ),
    ],
  );
}

final Map<String, ScenarioBeatGraph> _v1Catalog = () {
  final graphs = <String, ScenarioBeatGraph>{
    'yaa_life': _lifeGraph('yaa_asantewaa', 'yaa_life', 'Golden Stool resistance context'),
    'yaa_opinion': _opinionGraph('yaa_asantewaa', 'yaa_opinion'),
    'yaa_quiz': _quizGraph('yaa_asantewaa', 'yaa_quiz', 'Twi'),
    'nkrumah_life': _lifeGraph('nkrumah_kwame', 'nkrumah_life', 'Independence movement memory'),
    'nkrumah_opinion': _opinionGraph('nkrumah_kwame', 'nkrumah_opinion'),
    'nkrumah_quiz': _quizGraph('nkrumah_kwame', 'nkrumah_quiz', 'Nzema/English teaching'),
    'shaka_life': _lifeGraph('shaka_zulu', 'shaka_life', 'Zulu nation formation (narrated)'),
    'shaka_opinion': _opinionGraph('shaka_zulu', 'shaka_opinion'),
    'shaka_quiz': _quizGraph('shaka_zulu', 'shaka_quiz', 'isiZulu'),
    'baba_life': _lifeGraph('ahmed_baba', 'baba_life', 'Timbuktu scholarship and exile'),
    'baba_opinion': _opinionGraph('ahmed_baba', 'baba_opinion'),
    'baba_quiz': _quizGraph('ahmed_baba', 'baba_quiz', 'Arabic'),
    'mofolo_life': _lifeGraph('thomas_mofolo', 'mofolo_life', 'Sesotho literary life'),
    'mofolo_opinion': _opinionGraph('thomas_mofolo', 'mofolo_opinion'),
    'mofolo_quiz': _quizGraph('thomas_mofolo', 'mofolo_quiz', 'Sesotho'),
  };
  for (final graph in graphs.values) {
    graph.validateStructure();
  }
  return graphs;
}();

/// Resolve template id (aliases + canonical).
String resolveScenarioTemplateId(String rawId) {
  final trimmed = rawId.trim();
  return kScenarioTemplateAliases[trimmed] ?? trimmed;
}

/// Beat graph for a v1 scenario template, or null if unknown.
ScenarioBeatGraph? beatGraphForTemplate(String scenarioTemplateId) {
  final id = resolveScenarioTemplateId(scenarioTemplateId);
  return _v1Catalog[id];
}

/// All v1 graphs keyed by canonical template id.
Map<String, ScenarioBeatGraph> get v1ScenarioBeatCatalog => _v1Catalog;

/// Branches to hydrate empty registry templates for v1 personas (AC1).
Map<String, String> registryBranchesForTemplate(String scenarioTemplateId) {
  final graph = beatGraphForTemplate(scenarioTemplateId);
  if (graph == null) return const {};
  return graph.registryBranches();
}

/// Ensures every ADR-031 persona has three scenario graphs in the catalog.
void assertV1BeatCatalogCoversRoster() {
  if (_v1Catalog.length != kV1ScenarioTemplateIds.length) {
    throw BeatsSchemaException('catalog_size', '${_v1Catalog.length}');
  }
  for (final persona in DossierBackedPersonaRoster.v1) {
    final prefix = _templatePrefixForPersona(persona.personaId);
    for (final suffix in ['life', 'opinion', 'quiz']) {
      final id = '${prefix}_$suffix';
      if (!_v1Catalog.containsKey(id)) {
        throw BeatsSchemaException('missing_template', id);
      }
      if (_v1Catalog[id]!.personaId != persona.personaId) {
        throw BeatsSchemaException('persona_mismatch', id);
      }
    }
  }
}

String _templatePrefixForPersona(String personaId) {
  switch (personaId) {
    case 'yaa_asantewaa':
      return 'yaa';
    case 'nkrumah_kwame':
      return 'nkrumah';
    case 'shaka_zulu':
      return 'shaka';
    case 'ahmed_baba':
      return 'baba';
    case 'thomas_mofolo':
      return 'mofolo';
    default:
      throw BeatsSchemaException('unknown_v1_persona', personaId);
  }
}

/// Whether [nextBeatId] is allowed for improvisation within this scenario.
bool isAllowedNextBeat(String scenarioTemplateId, String nextBeatId) {
  final graph = beatGraphForTemplate(scenarioTemplateId);
  if (graph == null) return false;
  return graph.allowedBeatIds().contains(nextBeatId);
}

/// True when [nextBeatId] is not reachable from [currentBeatId] via authored branches.
bool isOffRailsTransition(
  String scenarioTemplateId,
  String currentBeatId,
  String nextBeatId,
) {
  final graph = beatGraphForTemplate(scenarioTemplateId);
  if (graph == null) return true;
  final allowed = graph.allowedBeatIds();
  if (!allowed.contains(nextBeatId)) return true;
  if (nextBeatId == currentBeatId) return false;
  final current = graph.beatById(currentBeatId) ?? graph.entryBeat;
  return !current.branches.values.contains(nextBeatId);
}

/// Default steer target when the model picks an invalid or unreachable beat.
String steerBeatId(String scenarioTemplateId, String currentBeatId) {
  final graph = beatGraphForTemplate(scenarioTemplateId);
  if (graph == null) return 'opening';
  final current = graph.beatById(currentBeatId) ?? graph.entryBeat;
  final targets = current.branches.values;
  if (targets.isEmpty) return current.beatId;
  return targets.first;
}
