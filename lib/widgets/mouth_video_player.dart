import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../utils/pan_african_design_system.dart';

/// Native mouth tutorial clip with captions and optional slow motion (P7-933).
class MouthVideoPlayer extends StatefulWidget {
  const MouthVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.caption,
    this.offersSlowMotion = false,
    this.playerBuilder,
  });

  final String videoUrl;
  final String caption;
  final bool offersSlowMotion;
  final Widget Function(String videoUrl)? playerBuilder;

  @override
  State<MouthVideoPlayer> createState() => _MouthVideoPlayerState();
}

class _MouthVideoPlayerState extends State<MouthVideoPlayer> {
  BetterPlayerController? _controller;
  bool _slowMotion = false;

  static const double _normalSpeed = 1.0;
  static const double _slowSpeed = 0.5;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl.trim();
    if (url.isNotEmpty && widget.playerBuilder == null) {
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
      );
      _controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: true,
          aspectRatio: 3 / 4,
          fit: BoxFit.contain,
          autoDispose: true,
        ),
        betterPlayerDataSource: dataSource,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _applySpeed() async {
    final speed = _slowMotion ? _slowSpeed : _normalSpeed;
    await _controller?.setSpeed(speed);
  }

  Future<void> _toggleSlowMotion() async {
    if (!widget.offersSlowMotion) return;
    setState(() => _slowMotion = !_slowMotion);
    await _applySpeed();
    SemanticsService.announce(
      _slowMotion ? 'Slow motion on' : 'Slow motion off',
      TextDirection.ltr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget videoChild;
    if (widget.playerBuilder != null) {
      videoChild = widget.playerBuilder!(url);
    } else if (_controller != null) {
      videoChild = AspectRatio(
        aspectRatio: 3 / 4,
        child: BetterPlayer(controller: _controller!),
      );
    } else {
      videoChild = const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Native mouth video with captions',
          child: videoChild,
        ),
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Text(
            widget.caption,
            style: PanAfricanTypography.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.offersSlowMotion && !reduceMotion)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _toggleSlowMotion,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              child: Text(
                _slowMotion ? 'Slow motion (on)' : 'Slow motion',
              ),
            ),
          ),
      ],
    );
  }
}
