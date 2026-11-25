/// Forced-alignment / TTS timing sidecar (P11-042).
library;

import 'dart:convert';

/// One aligner token. [phoneme] is IPA or MFA, never an orthographic letter.
class AlignedPhoneme {
  const AlignedPhoneme({
    required this.phoneme,
    required this.start,
    required this.end,
  });

  final String phoneme;
  final Duration start;
  final Duration end;

  Map<String, dynamic> toJson() => {
        'phoneme': phoneme,
        'start_ms': start.inMilliseconds,
        'end_ms': end.inMilliseconds,
      };

  factory AlignedPhoneme.fromJson(Map<String, dynamic> json) {
    return AlignedPhoneme(
      phoneme: (json['phoneme'] as String?) ?? (json['label'] as String?) ?? '',
      start: Duration(milliseconds: (json['start_ms'] as num?)?.round() ?? 0),
      end: Duration(milliseconds: (json['end_ms'] as num?)?.round() ?? 0),
    );
  }
}

/// Sidecar JSON written alongside a clip (forced aligner or TTS alignment).
class LipSyncTimingSidecar {
  const LipSyncTimingSidecar({
    required this.clipId,
    required this.languageId,
    required this.phonemes,
    this.source = 'forced_alignment',
    this.version = 1,
  });

  final String clipId;
  final String languageId;
  final List<AlignedPhoneme> phonemes;
  final String source;
  final int version;

  Map<String, dynamic> toJson() => {
        'version': version,
        'clip_id': clipId,
        'language_id': languageId,
        'source': source,
        'phonemes': phonemes.map((p) => p.toJson()).toList(),
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory LipSyncTimingSidecar.fromJson(Map<String, dynamic> json) {
    final list = json['phonemes'] as List<dynamic>? ?? const [];
    return LipSyncTimingSidecar(
      clipId: (json['clip_id'] as String?) ?? '',
      languageId: (json['language_id'] as String?) ?? 'default',
      source: (json['source'] as String?) ?? 'forced_alignment',
      version: (json['version'] as num?)?.round() ?? 1,
      phonemes: list
          .map((e) => AlignedPhoneme.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((p) => p.phoneme.isNotEmpty)
          .toList(growable: false),
    );
  }

  static LipSyncTimingSidecar decode(String raw) =>
      LipSyncTimingSidecar.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Gateway payload (`alignments.ts`) phoneme boundaries.
  static LipSyncTimingSidecar fromGatewayPayload(Map<String, dynamic> payload) {
    final list = payload['phonemes'] as List<dynamic>? ?? const [];
    return LipSyncTimingSidecar(
      clipId: (payload['clip_id'] as String?) ?? 'inline',
      languageId: (payload['language_id'] as String?) ?? 'default',
      source: 'gateway',
      phonemes: list
          .map((e) => AlignedPhoneme.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((p) => p.phoneme.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class RmsSample {
  const RmsSample({required this.at, required this.level});

  final Duration at;
  final double level;
}

class LipSyncSample {
  const LipSyncSample({required this.viseme, required this.jawOpen});

  final String viseme;
  final double jawOpen;
}
