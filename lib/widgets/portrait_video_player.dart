import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/media_url_resolver.dart';

/// Family key: always trim so pause/dispose in lesson flow matches the same provider
/// as the in-tree [PortraitPlayerPage].
String lessonVideoControllerKey(String url) => url.trim();

final betterPlayerController = Provider.family.autoDispose((ref, String url) {
  final key = lessonVideoControllerKey(url);
  if (key.isEmpty) {
    throw StateError('betterPlayerController: empty video URL');
  }
  final resolvedUrl = resolveMediaUrl(key) ?? key;
  BetterPlayerDataSource betterPlayerDataSource =
      BetterPlayerDataSource(BetterPlayerDataSourceType.network, resolvedUrl);
  final controller = BetterPlayerController(
    const BetterPlayerConfiguration(
      autoPlay: true,
      aspectRatio: 16 / 9,
      autoDispose: true,
      fullScreenAspectRatio: 16 / 9,
      expandToFill: false,
      fit: BoxFit.contain,
      autoDetectFullscreenAspectRatio: false,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      deviceOrientationsOnFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    ),
    betterPlayerDataSource: betterPlayerDataSource,
  );
  ref.onDispose(() {
    controller.pause();
    controller.dispose();
  });
  return controller;
});

class PortraitPlayerPage extends ConsumerStatefulWidget {
  final String videoUrl;

  const PortraitPlayerPage({
    super.key,
    required this.videoUrl,
  });

  @override
  ConsumerState<PortraitPlayerPage> createState() => _PortraitPlayerPageState();
}

class _PortraitPlayerPageState extends ConsumerState<PortraitPlayerPage> {
  @override
  void deactivate() {
    // Run before the route finishes popping so iOS / AVPlayer cannot keep
    // decoding audio in the background after the user leaves the screen.
    _pauseAttachedPlayer();
    super.deactivate();
  }

  void _pauseAttachedPlayer() {
    final raw = widget.videoUrl.trim();
    if (raw.isEmpty) return;
    try {
      final c = ref.read(betterPlayerController(raw));
      c.pause();
    } catch (_) {
      // Provider may not exist if the player never mounted.
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.videoUrl.trim();
    if (key.isEmpty) {
      return const SizedBox.shrink();
    }
    final controller = ref.watch(betterPlayerController(key));
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(controller: controller),
    );
  }
}
