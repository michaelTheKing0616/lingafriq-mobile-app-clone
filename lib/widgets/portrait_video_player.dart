import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final betterPlayerController = Provider.family.autoDispose((ref, String url) {
  BetterPlayerDataSource betterPlayerDataSource =
      BetterPlayerDataSource(BetterPlayerDataSourceType.network, url);
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
  return controller;
});

class PortraitPlayerPage extends ConsumerWidget {
  final String videoUrl;

  const PortraitPlayerPage({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(betterPlayerController(videoUrl));
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(controller: controller),
    );
  }
}
