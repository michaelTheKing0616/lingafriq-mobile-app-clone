// Chunks AI text output into natural speech segments for streaming TTS.

/// A single speakable phrase with metadata for TTS timing.
class PhraseChunk {
  final String text;
  final bool isSentenceEnd;
  final int estimatedDurationMs;

  const PhraseChunk({
    required this.text,
    this.isSentenceEnd = false,
    this.estimatedDurationMs = 0,
  });
}

/// Chunks partial text into speakable phrases for streaming TTS.
/// Splits on sentence boundaries, clause boundaries, and discourse markers,
/// with a minimum chunk size to avoid tiny fragments.
class PhraseChunker {
  PhraseChunker();

  static const int minChunkTokens = 6;

  /// Approximate ms per word for duration estimate (language-neutral baseline).
  static const int _msPerWord = 250;

  static final RegExp _sentenceEnd = RegExp(r'[.!?]\s+');
  static final RegExp _clauseBoundary = RegExp(r'[,;:\s—]\s+');
  static final RegExp _discourseMarkers = RegExp(
    r'\b(However|Now|Therefore|Thus|Moreover|Furthermore|Meanwhile|Indeed|Nevertheless|Still)\s+',
    caseSensitive: false,
  );

  final StringBuffer _buffer = StringBuffer();

  /// Number of "tokens" (here: words) in [text].
  static int _wordCount(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  /// Chunk [partialText] into speakable phrases.
  /// Splits on sentence boundaries (.!?), then clause boundaries (, ; : —),
  /// then discourse markers. Enforces minimum chunk size of [minChunkTokens] words.
  static List<PhraseChunk> chunk(String partialText) {
    final trimmed = partialText.trim();
    if (trimmed.isEmpty) return [];

    final chunks = <PhraseChunk>[];
    String remaining = trimmed;

    while (remaining.isNotEmpty) {
      remaining = remaining.trimLeft();
      if (remaining.isEmpty) break;

      // Prefer sentence end
      final sentenceMatch = _sentenceEnd.firstMatch(remaining);
      int splitIndex = -1;
      bool isSentenceEnd = false;

      if (sentenceMatch != null) {
        final end = sentenceMatch.end;
        final candidate = remaining.substring(0, end).trim();
        if (_wordCount(candidate) >= minChunkTokens) {
          splitIndex = end;
          isSentenceEnd = true;
        }
      }

      // Else try clause boundary
      if (splitIndex < 0) {
        final clauseMatch = _clauseBoundary.firstMatch(remaining);
        if (clauseMatch != null) {
          final end = clauseMatch.end;
          final candidate = remaining.substring(0, end).trim();
          if (_wordCount(candidate) >= minChunkTokens) {
            splitIndex = end;
          }
        }
      }

      // Else try discourse marker
      if (splitIndex < 0) {
        final markerMatch = _discourseMarkers.firstMatch(remaining);
        if (markerMatch != null && markerMatch.start > 0) {
          final end = markerMatch.start;
          final candidate = remaining.substring(0, end).trim();
          if (_wordCount(candidate) >= minChunkTokens) {
            splitIndex = end;
          }
        }
      }

      // Emit one chunk: either up to split point or rest if too short
      if (splitIndex > 0) {
        final segment = remaining.substring(0, splitIndex).trim();
        remaining = remaining.substring(splitIndex);
        final words = _wordCount(segment);
        chunks.add(PhraseChunk(
          text: segment,
          isSentenceEnd: isSentenceEnd,
          estimatedDurationMs: words * _msPerWord,
        ));
      } else {
        // No good split and we have content: take rest when it meets minimum, or accumulate
        if (_wordCount(remaining) >= minChunkTokens) {
          chunks.add(PhraseChunk(
            text: remaining.trim(),
            isSentenceEnd: remaining.trim().endsWith(RegExp(r'[.!?]')),
            estimatedDurationMs: _wordCount(remaining) * _msPerWord,
          ));
          remaining = '';
        } else {
          break;
        }
      }
    }

    return chunks;
  }

  /// Incremental chunking for streaming: append [newText] and return any complete chunks.
  List<PhraseChunk> addText(String newText) {
    _buffer.write(newText);
    return _extractCompleteChunks();
  }

  List<PhraseChunk> _extractCompleteChunks() {
    final full = _buffer.toString();
    final chunks = chunk(full);
    if (chunks.isEmpty) return [];

    // Remove emitted text from buffer (keep last incomplete part)
    int consumed = 0;
    for (final c in chunks) {
      consumed += c.text.length;
      final idx = full.indexOf(c.text, consumed - c.text.length);
      if (idx >= 0) consumed = idx + c.text.length;
    }
    final rest = full.substring(consumed);
    _buffer.clear();
    _buffer.write(rest);
    return chunks;
  }

  /// Flush remaining buffer as a single chunk, or null if empty.
  PhraseChunk? flush() {
    final rest = _buffer.toString().trim();
    _buffer.clear();
    if (rest.isEmpty) return null;
    return PhraseChunk(
      text: rest,
      isSentenceEnd: rest.endsWith(RegExp(r'[.!?]')),
      estimatedDurationMs: _wordCount(rest) * _msPerWord,
    );
  }
}
