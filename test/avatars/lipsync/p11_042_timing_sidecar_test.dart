import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/lipsync/timing_sidecar.dart';

void main() {
  test('sidecar round-trips phoneme start end per clip', () {
    const original = LipSyncTimingSidecar(
      clipId: 'clip-yo-001',
      languageId: 'yo',
      phonemes: [
        AlignedPhoneme(
          phoneme: 'gb',
          start: Duration.zero,
          end: const Duration(milliseconds: 80),
        ),
        AlignedPhoneme(
          phoneme: 'a',
          start: const Duration(milliseconds: 80),
          end: const Duration(milliseconds: 160),
        ),
      ],
    );
    final decoded = LipSyncTimingSidecar.decode(original.encode());
    expect(decoded.clipId, 'clip-yo-001');
    expect(decoded.phonemes, hasLength(2));
    expect(decoded.phonemes.first.phoneme, 'gb');
    expect(decoded.phonemes.first.end.inMilliseconds, 80);
  });

  test('gateway payload uses label fields as phonemes', () {
    final sidecar = LipSyncTimingSidecar.fromGatewayPayload({
      'language_id': 'yo',
      'phonemes': [
        {'label': 'gb', 'start_ms': 0, 'end_ms': 80},
      ],
    });
    expect(sidecar.phonemes.single.phoneme, 'gb');
  });
}
