/// Script learning tracks — Ge'ez/Fidel, N'Ko, Adlam, Tifinagh, Ajami (P5-083, ELEVATION §6.7).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/content/label_state.dart';
import 'package:lingafriq/widgets/content_label_badge.dart';

/// copy_keys: script.title.*
abstract final class ScriptTrackCopyKeys {
  static const titleGeez = 'script.title.geez';
  static const titleNko = 'script.title.nko';
  static const titleAdlam = 'script.title.adlam';
  static const titleTifinagh = 'script.title.tifinagh';
  static const titleAjami = 'script.title.ajami';
  static const comingLater = 'script.coming_later';

  static const defaultComingLater =
      'This script track is coming later — no unreviewed lessons are shown.';
}

abstract final class ScriptTrackCodes {
  static const trackMissing = 'ScriptTrackMissing';
  static const mislabeledVerified = 'ScriptContentMislabeled';
  static const lessonsMissing = 'ScriptLessonsMissing';
}

class ScriptTrackMissing implements Exception {
  ScriptTrackMissing(this.languageCode)
      : code = ScriptTrackCodes.trackMissing;

  final String languageCode;
  final String code;

  @override
  String toString() => '$code: no script track for $languageCode';
}

class ScriptContentMislabeled implements Exception {
  ScriptContentMislabeled(this.lessonId, this.labelRaw)
      : code = ScriptTrackCodes.mislabeledVerified;

  final String lessonId;
  final String labelRaw;
  final String code;

  @override
  String toString() =>
      '$code: lesson $lessonId has label "$labelRaw" — cannot present as verified';
}

enum ScriptTrackAvailability { available, comingLater }

enum ScriptTrackUiState { list, lesson, comingLater }

class ScriptGlyph {
  const ScriptGlyph({
    required this.character,
    required this.romanization,
    required this.sourceId,
    this.note = '',
  });

  final String character;
  final String romanization;
  final String sourceId;
  final String note;
}

class ScriptLesson {
  const ScriptLesson({
    required this.lessonId,
    required this.title,
    required this.label,
    required this.languageCodes,
    required this.glyphs,
  });

  final String lessonId;
  final String title;
  final ContentQualityLabel label;
  final List<String> languageCodes;
  final List<ScriptGlyph> glyphs;
}

class ScriptTrackDescriptor {
  const ScriptTrackDescriptor({
    required this.scriptId,
    required this.titleKey,
    required this.defaultTitle,
    required this.availability,
    this.lessonsAsset,
  });

  final String scriptId;
  final String titleKey;
  final String defaultTitle;
  final ScriptTrackAvailability availability;
  final String? lessonsAsset;
}

class ScriptTrackView {
  const ScriptTrackView({
    required this.descriptor,
    required this.uiState,
    required this.lessons,
    required this.languageCode,
  });

  final ScriptTrackDescriptor descriptor;
  final ScriptTrackUiState uiState;
  final List<ScriptLesson> lessons;
  final String languageCode;

  bool get isComingLater => uiState == ScriptTrackUiState.comingLater;
}

class ScriptTracksCatalog {
  const ScriptTracksCatalog({
    required this.cardId,
    required this.tracks,
    required this.languageToTrack,
  });

  final String cardId;
  final Map<String, ScriptTrackDescriptor> tracks;
  final Map<String, String> languageToTrack;
}

const _catalogAsset = 'assets/data/scripts/tracks_catalog.json';

ContentQualityLabel? parseScriptLessonLabel(String? raw) {
  return ContentQualityLabel.fromStorage(raw);
}

bool isScriptLessonDisplayable(ContentQualityLabel? label) {
  return label != null;
}

bool wouldPresentAsVerified(ContentQualityLabel? label) {
  return label == ContentQualityLabel.nativeVerified ||
      label == ContentQualityLabel.expertReviewed;
}

void assertLessonLabelDisplayable(String lessonId, String? labelRaw) {
  final label = parseScriptLessonLabel(labelRaw);
  if (!isScriptLessonDisplayable(label)) {
    throw ScriptContentMislabeled(lessonId, labelRaw ?? '');
  }
}

ScriptTracksCatalog parseScriptTracksCatalog(Map<String, dynamic> root) {
  final tracksRaw = root['tracks'];
  if (tracksRaw is! Map<String, dynamic>) {
    throw const FormatException('tracks must be a map');
  }
  final tracks = <String, ScriptTrackDescriptor>{};
  for (final entry in tracksRaw.entries) {
    final block = entry.value as Map<String, dynamic>;
    final availability = block['availability'] as String? ?? 'coming_later';
    tracks[entry.key] = ScriptTrackDescriptor(
      scriptId: block['script_id'] as String? ?? entry.key,
      titleKey: block['title_key'] as String? ?? ScriptTrackCopyKeys.titleGeez,
      defaultTitle: block['default_title'] as String? ?? entry.key,
      availability: availability == 'available'
          ? ScriptTrackAvailability.available
          : ScriptTrackAvailability.comingLater,
      lessonsAsset: block['lessons_asset'] as String?,
    );
  }
  final langMap = root['language_to_track'];
  if (langMap is! Map<String, dynamic>) {
    throw const FormatException('language_to_track must be a map');
  }
  return ScriptTracksCatalog(
    cardId: root['card'] as String? ?? 'P5-083',
    tracks: tracks,
    languageToTrack: langMap.map((k, v) => MapEntry(k, v as String)),
  );
}

ScriptTracksCatalog loadScriptTracksCatalogFromJson(String json) {
  return parseScriptTracksCatalog(jsonDecode(json) as Map<String, dynamic>);
}

Future<ScriptTracksCatalog> loadScriptTracksCatalogFromAsset([
  String assetPath = _catalogAsset,
]) async {
  final json = await rootBundle.loadString(assetPath);
  return loadScriptTracksCatalogFromJson(json);
}

List<ScriptLesson> parseScriptLessonsFile(Map<String, dynamic> root) {
  final lessonsRaw = root['lessons'];
  if (lessonsRaw is! List<dynamic>) {
    throw const FormatException('lessons must be a list');
  }
  final out = <ScriptLesson>[];
  for (final item in lessonsRaw) {
    final block = item as Map<String, dynamic>;
    final lessonId = block['lesson_id'] as String? ?? '';
    final labelRaw = block['label'] as String?;
    assertLessonLabelDisplayable(lessonId, labelRaw);
    final label = parseScriptLessonLabel(labelRaw)!;
    final langs = (block['language_codes'] as List<dynamic>? ?? const [])
        .map((v) => (v as String).toLowerCase())
        .toList();
    final glyphsRaw = block['glyphs'] as List<dynamic>? ?? const [];
    final glyphs = glyphsRaw.map((g) {
      final glyph = g as Map<String, dynamic>;
      return ScriptGlyph(
        character: glyph['character'] as String? ?? '',
        romanization: glyph['romanization'] as String? ?? '',
        sourceId: glyph['source_id'] as String? ?? '',
        note: glyph['note'] as String? ?? '',
      );
    }).toList();
    out.add(
      ScriptLesson(
        lessonId: lessonId,
        title: block['title'] as String? ?? lessonId,
        label: label,
        languageCodes: langs,
        glyphs: glyphs,
      ),
    );
  }
  return out;
}

List<ScriptLesson> loadScriptLessonsFromJson(String json) {
  return parseScriptLessonsFile(jsonDecode(json) as Map<String, dynamic>);
}

List<ScriptLesson> lessonsForLanguage(
  List<ScriptLesson> all,
  String languageCode,
) {
  final code = languageCode.trim().toLowerCase();
  return all
      .where((l) => l.languageCodes.contains(code))
      .toList(growable: false);
}

ScriptTrackView resolveScriptTrack({
  required ScriptTracksCatalog catalog,
  required String languageCode,
  required List<ScriptLesson> geezLessons,
}) {
  final code = languageCode.trim().toLowerCase();
  final trackId = catalog.languageToTrack[code];
  if (trackId == null) {
    throw ScriptTrackMissing(code);
  }
  final descriptor = catalog.tracks[trackId];
  if (descriptor == null) {
    throw ScriptTrackMissing(code);
  }
  if (descriptor.availability == ScriptTrackAvailability.comingLater) {
    return ScriptTrackView(
      descriptor: descriptor,
      uiState: ScriptTrackUiState.comingLater,
      lessons: const [],
      languageCode: code,
    );
  }
  if (descriptor.scriptId != 'geez_fidel') {
    return ScriptTrackView(
      descriptor: descriptor,
      uiState: ScriptTrackUiState.comingLater,
      lessons: const [],
      languageCode: code,
    );
  }
  final lessons = lessonsForLanguage(geezLessons, code);
  return ScriptTrackView(
    descriptor: descriptor,
    uiState:
        lessons.isEmpty ? ScriptTrackUiState.comingLater : ScriptTrackUiState.list,
    lessons: lessons,
    languageCode: code,
  );
}

/// Visible track shell — list, lesson, or honest coming-later (AC2–AC3).
class ScriptTrackPanel extends StatelessWidget {
  const ScriptTrackPanel({
    super.key,
    required this.view,
    this.selectedLessonId,
    this.onOpenLesson,
    this.onReportMistake,
  });

  final ScriptTrackView view;
  final String? selectedLessonId;
  final ValueChanged<ScriptLesson>? onOpenLesson;
  final VoidCallback? onReportMistake;

  @override
  Widget build(BuildContext context) {
    if (view.isComingLater) {
      return Semantics(
        label: ScriptTrackCopyKeys.defaultComingLater,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            ScriptTrackCopyKeys.defaultComingLater,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    final lesson = view.lessons.cast<ScriptLesson?>().firstWhere(
          (l) => l?.lessonId == selectedLessonId,
          orElse: () => null,
        );
    if (lesson != null) {
      return _LessonBody(lesson: lesson);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: view.lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = view.lessons[index];
        return Semantics(
          button: true,
          label: '${item.title}, ${item.label.displayName}',
          child: ListTile(
            minVerticalPadding: 12,
            title: Text(item.title),
            subtitle: Text(
              item.glyphs.map((g) => g.character).join(' '),
              style: const TextStyle(fontSize: 20),
            ),
            trailing: _ScriptLabelChip(label: item.label),
            onTap: onOpenLesson == null ? null : () => onOpenLesson!(item),
          ),
        );
      },
    );
  }
}

class _ScriptLabelChip extends StatelessWidget {
  const _ScriptLabelChip({required this.label});

  final ContentQualityLabel label;

  @override
  Widget build(BuildContext context) {
    final spec = contentLabelBadgeSpec(
      label: label,
      betaCopy: 'Beta',
      nativeLabel: 'Native-verified',
      expertLabel: 'Expert-reviewed',
    );
    if (spec == null) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: spec.semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: spec.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          spec.visibleText,
          style: TextStyle(color: spec.foreground, fontSize: 12),
        ),
      ),
    );
  }
}

class _LessonBody extends StatelessWidget {
  const _LessonBody({required this.lesson});

  final ScriptLesson lesson;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lesson.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _ScriptLabelChip(label: lesson.label),
          ],
        ),
        const SizedBox(height: 16),
        for (final glyph in lesson.glyphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              label: '${glyph.character}, ${glyph.romanization}',
              child: ListTile(
                minVerticalPadding: 12,
                title: Text(
                  glyph.character,
                  style: const TextStyle(fontSize: 32),
                ),
                subtitle: Text(glyph.romanization),
              ),
            ),
          ),
      ],
    );
  }
}
