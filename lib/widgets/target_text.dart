import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lingafriq/services/content/gloss_lookup.dart';
import 'package:lingafriq/widgets/tone_lens.dart';

/// Copy keys: text.hear, text.gloss, text.noAudio, text.noGloss (P4-140).
class TargetTextCopy {
  const TargetTextCopy({
    this.hear = 'Hear',
    this.gloss = 'Gloss',
    this.ipa = 'IPA',
    this.minimalPairs = 'Minimal pairs',
    this.noAudio = 'Audio not available',
    this.noGloss = 'Gloss not available',
    this.loadingGloss = 'Loading…',
  });

  final String hear;
  final String gloss;
  final String ipa;
  final String minimalPairs;
  final String noAudio;
  final String noGloss;
  final String loadingGloss;
}

enum TargetTextInteractionState {
  idle,
  playing,
  loadingGloss,
  glossOpen,
  noAudio,
  noGloss,
}

/// EP-§6.7-02 surfaces that must delegate target-language rendering to [TargetText].
///
/// Paths are relative to the mobile app package root. [enforced] flips on as each
/// elevate surface card lands; the integration test fails when an enforced path
/// exists on disk but does not reference [TargetText].
class TargetTextSurfaceContract {
  const TargetTextSurfaceContract._();

  static const entries = <TargetTextSurfaceEntry>[
    TargetTextSurfaceEntry('lessons', 'lib/lessons/grammar_aha_card.dart', enforced: false),
    TargetTextSurfaceEntry('lessons', 'lib/lessons/tone_perception_drill.dart', enforced: false),
    TargetTextSurfaceEntry('lessons', 'lib/lessons/sound_drill.dart', enforced: false),
    TargetTextSurfaceEntry('lessons', 'lib/lessons/tone_production_drill.dart', enforced: false),
    TargetTextSurfaceEntry('games', 'lib/screens/games/', enforced: false),
    TargetTextSurfaceEntry('chat', 'lib/screens/chat/', enforced: false),
    TargetTextSurfaceEntry('polie', 'lib/services/polie_content_generator.dart', enforced: false),
    TargetTextSurfaceEntry('personas', 'lib/ai/persona_grounding.dart', enforced: false),
    TargetTextSurfaceEntry('magazine', 'lib/screens/magazine/culture_magazine_screen.dart', enforced: false),
    TargetTextSurfaceEntry('dictionary', 'lib/screens/vocabulary/living_dictionary_screen.dart', enforced: false),
  ];
}

class TargetTextSurfaceEntry {
  const TargetTextSurfaceEntry(this.category, this.relativePath, {required this.enforced});

  final String category;
  final String relativePath;
  final bool enforced;
}

/// Single renderer for learner-facing target-language text (EP-§6.7).
class TargetText extends StatefulWidget {
  const TargetText({
    super.key,
    required this.text,
    this.tonePattern,
    this.syllables,
    this.lexemeId,
    this.glossLookup,
    this.inlineGloss,
    this.ipa,
    this.minimalPairs = const [],
    this.hasAudio = false,
    this.onHear,
    this.toneVerified = true,
    this.copy = const TargetTextCopy(),
    this.textScaleFactor,
    this.debugFontFamily,
  });

  final String text;
  final List<String>? tonePattern;
  final List<String>? syllables;
  final String? lexemeId;
  final GlossLookup? glossLookup;
  final String? inlineGloss;
  final String? ipa;
  final List<TargetMinimalPair> minimalPairs;
  final bool hasAudio;
  final Future<void> Function()? onHear;
  final bool toneVerified;
  final TargetTextCopy copy;
  final double? textScaleFactor;
  final String? debugFontFamily;

  @override
  State<TargetText> createState() => _TargetTextState();
}

class _TargetTextState extends State<TargetText> {
  TargetTextInteractionState _state = TargetTextInteractionState.idle;

  TextStyle _targetStyle(BuildContext context, double scale) {
    final base = widget.debugFontFamily != null
        ? TextStyle(fontFamily: widget.debugFontFamily, fontSize: 18 * scale, height: 1.5)
        : GoogleFonts.andika(fontSize: 18 * scale, height: 1.5);
    return base.copyWith(
      textBaseline: TextBaseline.alphabetic,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  Future<void> _handleTap() async {
    if (!widget.hasAudio || widget.onHear == null) {
      setState(() => _state = TargetTextInteractionState.noAudio);
      _showSnack(widget.copy.noAudio);
      return;
    }
    setState(() => _state = TargetTextInteractionState.playing);
    try {
      await widget.onHear!();
    } finally {
      if (mounted) setState(() => _state = TargetTextInteractionState.idle);
    }
  }

  Future<void> _handleLongPress() async {
    final lookup = widget.glossLookup;
    TargetLexemeGloss? resolved;
    if (lookup != null && widget.lexemeId != null) {
      setState(() => _state = TargetTextInteractionState.loadingGloss);
      resolved = await lookup.lookup(widget.lexemeId);
    }
    final gloss = resolved?.glossEn ?? widget.inlineGloss;
    final ipa = resolved?.ipa ?? widget.ipa;
    final pairs = resolved?.minimalPairs.isNotEmpty == true
        ? resolved!.minimalPairs
        : widget.minimalPairs;
    final empty = (gloss == null || gloss.trim().isEmpty) &&
        (ipa == null || ipa.trim().isEmpty) &&
        pairs.isEmpty;
    if (empty) {
      setState(() => _state = TargetTextInteractionState.noGloss);
      _showGlossSheet(
        gloss: null,
        ipa: null,
        pairs: const [],
        showNoGloss: true,
      );
      return;
    }
    setState(() => _state = TargetTextInteractionState.glossOpen);
    await _showGlossSheet(gloss: gloss, ipa: ipa, pairs: pairs, showNoGloss: false);
    if (mounted) setState(() => _state = TargetTextInteractionState.idle);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showGlossSheet({
    required String? gloss,
    required String? ipa,
    required List<TargetMinimalPair> pairs,
    required bool showNoGloss,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.text, style: _targetStyle(ctx, 1)),
                const SizedBox(height: 12),
                if (showNoGloss)
                  Text(widget.copy.noGloss, style: Theme.of(ctx).textTheme.bodyLarge)
                else ...[
                  if (gloss != null && gloss.trim().isNotEmpty)
                    ListTile(
                      title: Text(widget.copy.gloss),
                      subtitle: Text(gloss),
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (ipa != null && ipa.trim().isNotEmpty)
                    ListTile(
                      title: Text(widget.copy.ipa),
                      subtitle: Text(ipa),
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (pairs.isNotEmpty) ...[
                    Text(widget.copy.minimalPairs, style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    for (final p in pairs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(p.label ?? p.lexemeId),
                      ),
                  ],
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(widget.copy.hear),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.textScaleFactor ??
        (MediaQuery.textScalerOf(context).scale(18) / 18);
    final style = _targetStyle(context, scale);
    final tones = widget.tonePattern ?? const <String>[];

    return Semantics(
      label: '${widget.text}. ${widget.copy.hear} and ${widget.copy.gloss} available.',
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.text, style: style),
                if (tones.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ToneLensRow(tonePattern: tones, syllables: widget.syllables, verified: widget.toneVerified),
                ],
                if (_state == TargetTextInteractionState.loadingGloss)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(widget.copy.loadingGloss, style: Theme.of(context).textTheme.labelSmall),
                  ),
                if (_state == TargetTextInteractionState.noAudio)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_off_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.copy.noAudio,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
