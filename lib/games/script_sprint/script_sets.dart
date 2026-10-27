/// Script pools for Fidel Flight — catalog + verified strokes only (P8-927).
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lingafriq/content/label_state.dart';
import 'package:lingafriq/lessons/script_track.dart';
import 'package:lingafriq/lessons/stroke_order_view.dart';

abstract final class ScriptSprintCopyKeys {
  static const title = 'games.script_sprint.title';
  static const instructions = 'games.script_sprint.instructions';
  static const whyWrong = 'games.script_sprint.why_wrong';
  static const practiceLabel = 'games.script_sprint.practice_label';
  static const error = 'games.script_sprint.error';
}

class ScriptSprintGlyph {
  const ScriptSprintGlyph({
    required this.character,
    required this.romanization,
    required this.sourceId,
    this.soundLabel = '',
  });

  final String character;
  final String romanization;
  final String sourceId;
  final String soundLabel;
}

class ScriptSprintSet {
  const ScriptSprintSet({
    required this.scriptId,
    required this.title,
    required this.glyphs,
    required this.strokeCatalog,
    required this.recognizerReady,
    this.unavailableReason = '',
  });

  final String scriptId;
  final String title;
  final List<ScriptSprintGlyph> glyphs;
  final StrokeCatalog strokeCatalog;
  final bool recognizerReady;
  final String unavailableReason;

  bool get isPlayable => recognizerReady && glyphs.isNotEmpty;
}

/// Stroke guides for reviewed Fidel lesson glyphs (unicode block cites).
StrokeCatalog scriptSprintGeezStrokeCatalog() {
  return StrokeCatalog.fromJson({
    'card': 'P8-927',
    'glyphs': [
      {
        'character': '\u1200',
        'catalog_source_id': 'unicode:U+1200',
        'meaning': 'ha',
        'strokes': [
          {
            'source_id': 'unicode:U+1200:stroke1',
            'points': [
              [0.25, 0.75],
              [0.25, 0.25],
              [0.75, 0.25],
            ],
          },
          {
            'source_id': 'unicode:U+1200:stroke2',
            'points': [
              [0.75, 0.25],
              [0.75, 0.75],
            ],
          },
        ],
      },
      {
        'character': '\u1208',
        'catalog_source_id': 'unicode:U+1208',
        'meaning': 'la',
        'strokes': [
          {
            'source_id': 'unicode:U+1208:stroke1',
            'points': [
              [0.2, 0.5],
              [0.8, 0.5],
            ],
          },
          {
            'source_id': 'unicode:U+1208:stroke2',
            'points': [
              [0.5, 0.2],
              [0.5, 0.8],
            ],
          },
        ],
      },
      {
        'character': '\u1210',
        'catalog_source_id': 'unicode:U+1210',
        'meaning': 'ha (2nd order)',
        'strokes': [
          {
            'source_id': 'unicode:U+1210:stroke1',
            'points': [
              [0.3, 0.7],
              [0.7, 0.3],
            ],
          },
          {
            'source_id': 'unicode:U+1210:stroke2',
            'points': [
              [0.3, 0.3],
              [0.7, 0.7],
            ],
          },
        ],
      },
    ],
  });
}

Future<ScriptSprintSet> loadScriptSprintSetForLanguage(String languageCode) async {
  final catalogJson = await rootBundle.loadString(
    'assets/data/scripts/tracks_catalog.json',
  );
  final catalog = loadScriptTracksCatalogFromJson(catalogJson);
  final trackId = catalog.languageToTrack[languageCode.toLowerCase()];
  if (trackId == null) {
    return ScriptSprintSet(
      scriptId: '',
      title: '',
      glyphs: const [],
      strokeCatalog: kDefaultStrokeCatalog,
      recognizerReady: false,
      unavailableReason: 'No script track is linked to this language yet.',
    );
  }
  final descriptor = catalog.tracks[trackId];
  if (descriptor == null ||
      descriptor.availability != ScriptTrackAvailability.available) {
    return ScriptSprintSet(
      scriptId: trackId,
      title: descriptor?.defaultTitle ?? trackId,
      glyphs: const [],
      strokeCatalog: kDefaultStrokeCatalog,
      recognizerReady: false,
      unavailableReason:
          'This script is not yet available — stroke guides are still in review.',
    );
  }

  final lessonsAsset = descriptor.lessonsAsset;
  if (lessonsAsset == null) {
    return _unavailableSet(trackId, descriptor.defaultTitle, 'Lessons missing.');
  }

  final lessonsRaw = await rootBundle.loadString(lessonsAsset);
  final lessons = loadScriptLessonsFromJson(lessonsRaw);
  final reviewedGlyphs = <ScriptSprintGlyph>[];
  for (final lesson in lessons) {
    if (lesson.label != ContentQualityLabel.expertReviewed) continue;
    for (final g in lesson.glyphs) {
      reviewedGlyphs.add(
        ScriptSprintGlyph(
          character: g.character,
          romanization: g.romanization,
          sourceId: g.sourceId,
          soundLabel: g.note,
        ),
      );
    }
  }

  final strokes = scriptSprintGeezStrokeCatalog();
  final readyGlyphs = reviewedGlyphs
      .where((g) => strokes.dataFor(g.character) != null)
      .toList(growable: false);

  if (readyGlyphs.isEmpty) {
    return _unavailableSet(
      trackId,
      descriptor.defaultTitle,
      'Verified on-device recogniser is not ready for these characters yet.',
    );
  }

  return ScriptSprintSet(
    scriptId: trackId,
    title: descriptor.defaultTitle,
    glyphs: readyGlyphs,
    strokeCatalog: strokes,
    recognizerReady: true,
  );
}

ScriptSprintSet _unavailableSet(
  String scriptId,
  String title,
  String reason,
) {
  return ScriptSprintSet(
    scriptId: scriptId,
    title: title,
    glyphs: const [],
    strokeCatalog: kDefaultStrokeCatalog,
    recognizerReady: false,
    unavailableReason: reason,
  );
}
