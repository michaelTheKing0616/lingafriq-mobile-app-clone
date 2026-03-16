import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/utils/media_url_resolver.dart';

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
  BetterPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant PortraitPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    final resolvedUrl = resolveMediaUrl(widget.videoUrl) ?? widget.videoUrl;
    if (resolvedUrl.trim().isEmpty) {
      setState(() => _error = 'Video source is unavailable.');
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getAccessToken();
    final authHeaders = (token != null && token.isNotEmpty)
        ? <String, String>{'Authorization': 'Bearer $token'}
        : <String, String>{};

    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        aspectRatio: 16 / 9,
        autoDispose: false,
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
    );

    try {
      await controller.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          resolvedUrl,
          headers: authHeaders,
        ),
      );
      if (mounted) {
        setState(() {
          _controller = controller;
          _error = null;
        });
      } else {
        controller.dispose();
      }
    } catch (_) {
      try {
        await controller.setupDataSource(
          BetterPlayerDataSource(
            BetterPlayerDataSourceType.network,
            resolvedUrl,
          ),
        );
        if (mounted) {
          setState(() {
            _controller = controller;
            _error = null;
          });
        } else {
          controller.dispose();
        }
      } catch (e) {
        controller.dispose();
        if (mounted) {
          setState(() {
            _error = 'Unable to load video.';
          });
        }
      }
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(controller: controller),
    );
  }
}
