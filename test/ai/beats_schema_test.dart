import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quests/beats_schema.dart';

void main() {
  test('AC1_v1_catalog_covers_adr031_roster_with_branches', () {
    assertV1BeatCatalogCoversRoster();
    for (final id in kV1ScenarioTemplateIds) {
      final graph = v1ScenarioBeatCatalog[id]!;
      expect(graph.registryBranches().isNotEmpty, true);
    }
  });

  test('AC2_allowed_next_beat_in_authored_set', () {
    expect(isAllowedNextBeat('yaa_life', 'deeper'), true);
    expect(isAllowedNextBeat('yaa_life', 'not_a_beat'), false);
  });

  test('AC3_off_rails_unreachable_transition', () {
    expect(
      isOffRailsTransition('yaa_life', 'opening', 'reflect'),
      true,
    );
    expect(
      isOffRailsTransition('yaa_life', 'opening', 'deeper'),
      false,
    );
    expect(steerBeatId('yaa_life', 'opening'), 'deeper');
  });

  test('aliases_resolve_to_canonical_template', () {
    expect(
      resolveScenarioTemplateId('nkrumah_kwame_language_quiz'),
      'nkrumah_quiz',
    );
  });
}
