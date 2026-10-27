import 'package:flutter/material.dart';

import '../cast/cast_session.dart';
import '../cast/cast_stage.dart';

/// Reaction stickers reuse the cast rig — no bespoke sticker artwork (EP-§4.4-14).
enum AvatarReactionSticker {
  celebrate('celebrate', 'happy', 0.9),
  proud('celebrate', 'proud', 0.85),
  encouraging('encouraging', 'encouraging', 0.8),
  wave('idle', 'happy', 0.75),
  playful('idle', 'playful', 0.8);

  const AvatarReactionSticker(
    this.activity,
    this.expression,
    this.intensity,
  );

  final String activity;
  final String expression;
  final double intensity;
}

/// Rig snapshot used to raster a sticker frame.
@immutable
class AvatarStickerRequest {
  const AvatarStickerRequest({
    required this.preset,
    this.reaction = AvatarReactionSticker.celebrate,
    this.viseme = 'aa',
    this.jawOpen = 0.55,
    this.reducedMotion = true,
  });

  final String preset;
  final AvatarReactionSticker reaction;
  final String viseme;
  final double jawOpen;
  final bool reducedMotion;

  CastPose toPose() {
    return CastPose(
      preset: preset,
      activity: reaction.activity,
      expression: reaction.expression,
      intensity: reaction.intensity,
      viseme: viseme,
      jawOpen: jawOpen,
      reducedMotion: reducedMotion,
    );
  }
}

/// Applies [request] onto a live [CastSession] (existing VM bindings only).
abstract final class AvatarStickerGenerator {
  static const stickerArtboard = 'Bust';
  static const defaultStickerSize = 160.0;

  static void applyToSession(CastSession session, AvatarStickerRequest request) {
    final pose = request.toPose();
    session.activity(pose.activity);
    session.expression(pose.expression, pose.intensity);
    session.viseme(pose.viseme, pose.jawOpen);
    session.reducedMotion(pose.reducedMotion);
  }

  static CastSession sessionFor(AvatarStickerRequest request) {
    final session = CastSession(preset: request.preset);
    applyToSession(session, request);
    return session;
  }

  /// Sticker frame: bust artboard from the shared cast file.
  static Widget frame({
    required CastSession session,
    double size = defaultStickerSize,
    Key? boundaryKey,
  }) {
    return RepaintBoundary(
      key: boundaryKey,
      child: SizedBox(
        width: size,
        height: size,
        child: AvatarRigFrame(
          session: session,
          artboard: stickerArtboard,
        ),
      ),
    );
  }

  /// Stickers never embed learner identifiers (AC3 companion for reactions).
  static bool exportMetadataIsPiiFree(Map<String, String> metadata) {
    const forbidden = {
      'email',
      'phone',
      'learnerId',
      'userId',
      'displayName',
      'username',
      'fullName',
      'birthYear',
    };
    for (final key in metadata.keys) {
      if (forbidden.contains(key)) return false;
    }
    for (final value in metadata.values) {
      if (_looksLikeEmail(value)) return false;
    }
    return true;
  }

  static bool _looksLikeEmail(String value) =>
      value.contains('@') && value.contains('.');
}

/// Mounts [CastStage] after the first frame so session writes never run mid-build.
class AvatarRigFrame extends StatefulWidget {
  const AvatarRigFrame({
    super.key,
    required this.session,
    required this.artboard,
    this.placeholderColor = const Color(0xFF1A130C),
  });

  final CastSession session;
  final String artboard;
  final Color placeholderColor;

  @override
  State<AvatarRigFrame> createState() => _AvatarRigFrameState();
}

class _AvatarRigFrameState extends State<AvatarRigFrame> {
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_mounted) {
      return ColoredBox(color: widget.placeholderColor);
    }
    return CastStage(session: widget.session, artboard: widget.artboard);
  }
}
