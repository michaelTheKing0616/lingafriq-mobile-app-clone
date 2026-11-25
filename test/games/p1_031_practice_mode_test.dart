// P1-031 Spec-Tests (Mode A). Derived from the card ACs only; no Worker code.
//
// These are source-level contract tests. The three surfaces depend on
// recorder / TTS / provider plugins that cannot run in a deterministic
// unit environment, so behaviour is asserted through the source contract
// (copy keys, absence of score widgets, absence of RNG-fed scores, absence
// of score-driven XP/streak credit, announced practice label).
//
// Surface paths are the real repo locations (the card allowlist omits the
// `screens/` and `tutor/` segments).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _practiceModeKey = 'pron.practice_mode';
const _scoringSoonKey = 'pron.scoring_soon';

const _duelPath = 'lib/screens/games/pronunciation_duel_game.dart';
const _karaokePath = 'lib/screens/games/pronunciation_karaoke_screen.dart';
const _tutorPath = 'lib/screens/tutor/tutor_pronunciation_mode_screen.dart';

const Map<String, String> _surfaces = {
  'duel': _duelPath,
  'karaoke': _karaokePath,
  'tutor': _tutorPath,
};

/// Source with `//` line comments and `/* */` blocks removed, so comments
/// cannot satisfy or trip a contract.
String _code(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist (surface stays visible)');
  return file
      .readAsStringSync()
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

bool _referencesKey(String code, String key) =>
    code.contains("'$key'") || code.contains('"$key"');

void main() {
  group('P1-031 AC1 practice mode copy, no numeric score or grade', () {
    for (final entry in _surfaces.entries) {
      test('P1-031_AC1_${entry.key}_states_practice_mode_and_scoring_coming_soon', () {
        final code = _code(entry.value);
        expect(_referencesKey(code, _practiceModeKey), isTrue,
            reason: '${entry.value} must show copy key $_practiceModeKey');
        expect(_referencesKey(code, _scoringSoonKey), isTrue,
            reason: '${entry.value} must show copy key $_scoringSoonKey');
      });
    }

    test('P1-031_AC1_copy_keys_are_defined_in_en_localisation_resources', () {
      final arb = File('lib/l10n/app_en.arb');
      expect(arb.existsSync(), isTrue);
      final text = arb.readAsStringSync();
      for (final key in [_practiceModeKey, _scoringSoonKey]) {
        final underscored = key.replaceAll('.', '_');
        expect(text.contains('"$key"') || text.contains('"$underscored"'), isTrue,
            reason: 'app_en.arb lacks $key');
      }
    });

    test('P1-031_AC1_duel_attempt_does_not_render_accuracy_ring_or_score', () {
      final code = _code(_duelPath);
      expect(code.contains('GriotMasteryRing'), isFalse,
          reason: 'accuracy ring renders a numeric score after an attempt');
      expect(code.contains('_pronunciationScore'), isFalse,
          reason: 'a stored pronunciation score must not exist');
    });

    test('P1-031_AC1_karaoke_attempt_does_not_render_pitch_rhythm_or_percent_stats', () {
      final code = _code(_karaokePath);
      expect(code.contains('_pitchScore'), isFalse, reason: 'fake pitch score');
      expect(code.contains("label: 'Pitch'"), isFalse, reason: 'Pitch % stat card');
      expect(code.contains("label: 'Rhythm'"), isFalse, reason: 'Rhythm % stat card');
      expect(code.contains(r"'$_rhythmPercent%'"), isFalse, reason: 'rhythm percent shown');
    });

    test('P1-031_AC1_tutor_attempt_does_not_render_score_ring_cards_or_score_semantics', () {
      final code = _code(_tutorPath);
      expect(code.contains('_ScoreRing('), isFalse, reason: 'numeric score ring');
      expect(code.contains('_ScoreCard('), isFalse, reason: 'Accuracy/Rhythm/Tone numbers');
      expect(code.contains('Overall score'), isFalse, reason: 'score announced to screen readers');
    });
  });

  group('P1-031 AC2 no random-number generator feeds a displayed score', () {
    for (final entry in _surfaces.entries) {
      test('P1-031_AC2_${entry.key}_has_no_rng_statement_that_touches_a_score', () {
        final statements = _code(entry.value).split(';');
        final offenders = statements.where((s) {
          final usesRng = RegExp(r'\b_?rng\b|\bRandom\s*\(').hasMatch(s);
          return usesRng && RegExp('score', caseSensitive: false).hasMatch(s);
        }).map((s) => s.trim().split('\n').first).toList();
        expect(offenders, isEmpty, reason: 'RNG-fed score: $offenders');
      });

      test('P1-031_AC2_${entry.key}_has_no_integer_rng_used_to_fabricate_values', () {
        final code = _code(entry.value);
        expect(RegExp(r'\.nextInt\s*\(').hasMatch(code), isFalse,
            reason: '${entry.value} uses nextInt (fabricated integer score signature)');
      });
    }

    test('P1-031_AC2_tutor_does_not_default_failed_scoring_to_a_numeric_score', () {
      final code = _code(_tutorPath);
      expect(
          RegExp(r"\['(score|pronunciationScore|overallScore)'\][^;]*\?\?\s*0\.0")
              .hasMatch(code),
          isFalse,
          reason: 'zero-on-failure score default is a fake score');
    });
  });

  group('P1-031 AC3 no XP or streak credit from a fake score', () {
    test('P1-031_AC3_duel_turn_result_and_confidence_are_not_derived_from_a_score', () {
      final code = _code(_duelPath);
      expect(RegExp(r'score\s*>=').hasMatch(code), isFalse,
          reason: 'GameResult chosen from a score threshold');
      expect(RegExp(r'confidence:\s*score').hasMatch(code), isFalse,
          reason: 'confidence fed from a fake score');
      expect(code.contains("'score':"), isFalse, reason: 'score persisted in feedback');
    });

    test('P1-031_AC3_karaoke_does_not_show_or_credit_xp_for_simulated_recording', () {
      final code = _code(_karaokePath);
      expect(code.contains('+10 XP'), isFalse, reason: 'XP popup per simulated hit');
      expect(code.contains('xp: _rhythmHits'), isFalse, reason: 'XP derived from hits');
      expect(code.contains('_rhythmHits++'), isFalse, reason: 'hits counted without scoring');
    });

    test('P1-031_AC3_karaoke_turn_payload_has_no_pitch_or_rhythm_score', () {
      final code = _code(_karaokePath);
      expect(code.contains("'pitch_score'"), isFalse);
      expect(code.contains("'rhythm_score'"), isFalse);
      expect(RegExp(r'rhythmPct\s*>=').hasMatch(code), isFalse,
          reason: 'GameResult chosen from a fake rhythm percent');
    });

    test('P1-031_AC3_karaoke_streak_is_not_credited_from_phrase_completion', () {
      final code = _code(_karaokePath);
      expect(code.contains('streak: _phrasesCompleted'), isFalse,
          reason: 'streak credited from a scored simulated attempt');
    });

    test('P1-031_AC3_tutor_does_not_credit_attempts_from_a_score_response', () {
      final code = _code(_tutorPath);
      expect(code.contains('practiceCount.value + 1'), isFalse,
          reason: 'session count incremented from a scoring response');
    });
  });

  group('P1-031 AC4 surfaces stay playable as honest practice, label announced', () {
    const classes = {
      _duelPath: 'class PronunciationDuelGame',
      _karaokePath: 'class PronunciationKaraokeGame',
      _tutorPath: 'class TutorPronunciationModeScreen',
    };
    for (final entry in classes.entries) {
      test('P1-031_AC4_${entry.value.split(' ').last}_remains_defined_and_recordable', () {
        final code = _code(entry.key);
        expect(code.contains(entry.value), isTrue);
        expect(RegExp(r'Icons\.mic').hasMatch(code), isTrue,
            reason: 'practice controls must remain');
      });
    }

    for (final entry in _surfaces.entries) {
      test('P1-031_AC4_${entry.key}_practice_label_is_announced_to_screen_readers', () {
        final code = _code(entry.value);
        final announced = code.contains('liveRegion: true') ||
            code.contains('SemanticsService.announce');
        expect(announced && _referencesKey(code, _practiceModeKey), isTrue,
            reason: 'practice label must be a live region/announcement');
      });
    }

    test('P1-031_AC4_duel_simulated_recording_does_not_produce_a_result_state', () {
      final code = _code(_duelPath);
      expect(
          RegExp(r'_isRecording\s*=\s*false;[\s\S]{0,200}_pronunciationScore\s*=')
              .hasMatch(code),
          isFalse,
          reason: 'stopping a recording-less simulation must not set a score');
    });

    test('P1-031_AC4_tutor_does_not_upload_audio_to_a_scoring_endpoint', () {
      final code = _code(_tutorPath);
      expect(code.contains('/api/pronunciation/advanced/analyze'), isFalse,
          reason: 'scoring request must be removed until a real scorer ships');
      expect(code.contains('shadowingExercise'), isFalse,
          reason: 'local fallback scorer must be removed');
    });
  });
}
