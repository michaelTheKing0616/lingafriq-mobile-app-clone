import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lexicon_audio_client.dart';

void main() {
  group('LexiconAudioBundle', () {
    test('parses two recordings without needs_more_voices', () {
      final bundle = LexiconAudioBundle.fromApiJson({
        'lexeme_id': 'yo.lex.ọkọ.vehicle',
        'language': 'yo',
        'needs_more_voices': false,
        'playable_count': 2,
        'recordings': [
          {
            'voice_id': 'yo_f_lagos_01',
            'uri': 'audio/yo/9f2c1a4b5e6d7c8a.ogg',
            'speed': 'natural',
            'speaker_age_band': 'adult',
            'speaker_gender': 'female',
            'aligned_phones': ['ɔ̄', 'k', 'ɔ̀'],
            'kind': 'human',
            'consent_record_id': 'consent-1',
            'licence_register_id': 'lic-1',
          },
          {
            'voice_id': 'yo_m_ibadan_02',
            'uri': 'audio/yo/a1b2c3d4e5f67890.ogg',
            'speed': 'slow',
            'speaker_age_band': 'elder',
            'speaker_gender': 'male',
            'aligned_phones': ['ɔ̄', 'k', 'ɔ̀'],
            'kind': 'human',
            'consent_record_id': 'consent-2',
            'licence_register_id': 'lic-2',
          },
        ],
      });
      expect(bundle.needsMoreVoices, isFalse);
      expect(bundle.playableCount, 2);
      expect(bundle.playableUris, hasLength(2));
      expect(bundle.recordings.first.speakerGender, 'female');
    });

    test('flags needs_more_voices when only one clip exists', () {
      final bundle = LexiconAudioBundle.fromApiJson({
        'lexeme_id': 'yo.lex.ọkọ.vehicle',
        'language': 'yo',
        'needs_more_voices': true,
        'playable_count': 1,
        'recordings': [
          {
            'voice_id': 'yo_f_lagos_01',
            'uri': 'audio/yo/9f2c1a4b5e6d7c8a.ogg',
            'speed': 'natural',
            'speaker_age_band': 'adult',
            'speaker_gender': 'female',
            'aligned_phones': ['ɔ̄'],
          },
        ],
      });
      expect(bundle.needsMoreVoices, isTrue);
      expect(bundle.playableUris, hasLength(1));
    });
  });

  group('LexiconAudioException', () {
    test('surfaces typed attach rejection', () {
      final err = LexiconAudioException(
        code: 'LEXICON_AUDIO_TOO_MANY',
        message: 'at most 3 native recordings per lexeme',
        statusCode: 400,
      );
      expect(err.toString(), contains('LEXICON_AUDIO_TOO_MANY'));
    });
  });
}
