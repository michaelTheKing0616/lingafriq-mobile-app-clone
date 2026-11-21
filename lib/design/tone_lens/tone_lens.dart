import 'package:flutter/material.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/tone_lens/tone_contour.dart';

/// A checked tone comes from spelling or from audio that has been checked.
///
/// There is no third value. A word with neither uses [ToneLens.unverified].
enum ToneSource { orthography, validatedAudio }

/// Reads the contour sequence. The first word is capitalised.
///
/// `Mid, then high, then rising, then low.`
String toneContourSequence(List<ToneContourKind> contours) {
  if (contours.isEmpty) return '';
  final List<String> words = contours
      .map(toneContourWord)
      .toList(growable: false);
  final String first = words.first;
  final String titled =
      '${first.substring(0, 1).toUpperCase()}${first.substring(1)}';
  if (words.length == 1) return '$titled.';
  return '$titled, then ${words.skip(1).join(', then ')}.';
}

/// Screen-reader line for a tone mark.
///
/// A checked word reads `Tone on Ẹ kú àárọ̀. Mid, then high, then rising, then low.`
/// An unverified word says the tone is not checked.
String toneLensLabel({
  required String word,
  required List<ToneContourKind> contours,
  required bool unverified,
}) {
  if (unverified) return 'Tone on $word. The tone is not checked.';
  final String sequence = toneContourSequence(contours);
  if (sequence.isEmpty) return 'Tone on $word.';
  return 'Tone on $word. $sequence';
}

class _Ramp {
  const _Ramp({
    required this.surface,
    required this.container,
    required this.ink,
  });

  final Color surface;
  final Color container;
  final Color ink;

  static const _Ramp light = _Ramp(
    surface: LingAfriqTokens.roleLightSurface,
    container: LingAfriqTokens.roleLightSurfaceContainer,
    ink: LingAfriqTokens.roleLightOnSurface,
  );

  static const _Ramp dark = _Ramp(
    surface: LingAfriqTokens.roleDarkSurface,
    container: LingAfriqTokens.roleDarkSurfaceContainer,
    ink: LingAfriqTokens.roleDarkOnSurface,
  );

  static _Ramp of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Pitch contour above a target-language word.
///
/// Shape is the cue. Every kind uses one onSurface stroke. The contour is
/// already drawn: reduced motion does not animate it on.
///
/// [source] is [ToneSource.orthography] or [ToneSource.validatedAudio].
/// [unverified] draws the broken line instead of [contours].
class ToneLens extends StatelessWidget {
  const ToneLens({
    required this.word,
    required this.contours,
    required this.source,
    this.unverified = false,
    super.key,
  });

  final String word;
  final List<ToneContourKind> contours;
  final ToneSource source;
  final bool unverified;

  @override
  Widget build(BuildContext context) {
    final _Ramp ramp = _Ramp.of(Theme.of(context).brightness);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: toneLensLabel(
        word: word,
        contours: contours,
        unverified: unverified,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ramp.container,
          borderRadius: const BorderRadius.all(
            Radius.circular(LingAfriqTokens.radiusmd),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ToneContour(
                color: ramp.ink,
                background: ramp.container,
                kinds: contours,
                unverified: unverified,
              ),
              const SizedBox(height: LingAfriqTokens.spacing4),
              DefaultTextStyle(
                style: TextStyle(color: ramp.ink),
                child: TargetText(text: word),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
