import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../utils/polie_design_tokens.dart';
import '../cast/cast_session.dart';
import 'sticker_generator.dart';

/// Copy key: avatar.share.phrase (ARB pending — do not mutate learner phrase text).
String speakingSharePhraseLabel(String phrase) => 'I can now say… $phrase';

/// Rig pose for the share card (speaking activity, bust-ready viseme).
CastPose buildSpeakingSharePose(SpeakingShareCardInput input) {
  final base = AvatarStickerRequest(
    preset: input.preset,
    reaction: AvatarReactionSticker.encouraging,
    viseme: 'aa',
    jawOpen: 0.65,
    reducedMotion: input.reducedMotion,
  ).toPose();
  return base.copyWith(activity: 'speaking');
}

@immutable
class SpeakingShareCardInput {
  const SpeakingShareCardInput({
    required this.preset,
    required this.phrase,
    this.isMinor = false,
    this.learnerDisplayName,
    this.learnerId,
    this.email,
    this.reducedMotion = false,
  });

  final String preset;
  final String phrase;
  final bool isMinor;
  final String? learnerDisplayName;
  final String? learnerId;
  final String? email;
  final bool reducedMotion;

  SpeakingShareCardInput sanitized() {
    if (!isMinor) return this;
    return SpeakingShareCardInput(
      preset: preset,
      phrase: phrase,
      isMinor: true,
      reducedMotion: reducedMotion,
    );
  }

  Map<String, String> visibleTextFields() {
    final safe = sanitized();
    final fields = <String, String>{
      'headline': speakingSharePhraseLabel(safe.phrase),
      'brand': 'LingAfriq',
    };
    if (!safe.isMinor && safe.learnerDisplayName != null) {
      fields['attribution'] = safe.learnerDisplayName!;
    }
    return fields;
  }
}

enum SpeakingShareCardState { rendering, ready, error }

/// Shareable “I can now say…” card with the learner rig speaking the phrase.
class SpeakingShareCard extends StatefulWidget {
  const SpeakingShareCard({
    super.key,
    required this.input,
    this.boundaryKey,
    this.onStateChanged,
  });

  final SpeakingShareCardInput input;
  final GlobalKey? boundaryKey;
  final ValueChanged<SpeakingShareCardState>? onStateChanged;

  static const cardWidth = 320.0;
  static const cardHeight = 400.0;

  @override
  State<SpeakingShareCard> createState() => _SpeakingShareCardState();
}

class _SpeakingShareCardState extends State<SpeakingShareCard> {
  static const _padLg = 24.0;
  static const _padMd = 16.0;
  static const _padSm = 8.0;
  static const _radiusLg = 20.0;
  static const _radiusMd = 12.0;

  late final CastSession _session;

  @override
  void initState() {
    super.initState();
    _session = CastSession(preset: widget.input.preset);
    _session.pose = buildSpeakingSharePose(widget.input);
    widget.onStateChanged?.call(SpeakingShareCardState.rendering);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onStateChanged?.call(SpeakingShareCardState.ready);
    });
  }

  @override
  void didUpdateWidget(SpeakingShareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      _session.pose = buildSpeakingSharePose(widget.input);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _session.activity('speaking');
      });
    }
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = widget.input.sanitized();
    final text = safe.visibleTextFields();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? PolieColors.surfaceContainer
        : PolieColors.surfaceContainerLight;
    final onSurface = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;

    return RepaintBoundary(
      key: widget.boundaryKey,
      child: Semantics(
        label: text['headline'],
        child: Material(
          color: surface,
          borderRadius: BorderRadius.circular(_radiusLg),
          child: SizedBox(
            width: SpeakingShareCard.cardWidth,
            height: SpeakingShareCard.cardHeight,
            child: Padding(
              padding: const EdgeInsets.all(_padLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_radiusMd),
                      child: AvatarRigFrame(
                        session: _session,
                        artboard: AvatarStickerGenerator.stickerArtboard,
                        placeholderColor: PolieColors.surfaceContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: _padMd),
                  Text(
                    text['headline']!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (text.containsKey('attribution')) ...[
                    const SizedBox(height: _padSm),
                    Text(
                      text['attribution']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: _padSm),
                  Text(
                    text['brand']!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PolieColors.goldEmber,
                          letterSpacing: 0.4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Raster helpers for share sheets.
abstract final class SpeakingShareCardCapture {
  static Future<Uint8List?> pngFromBoundary(GlobalKey boundaryKey) async {
    final context = boundaryKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }
}
