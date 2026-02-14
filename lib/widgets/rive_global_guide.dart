import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../games/animation/rive_game_guide.dart';
import '../games/animation/rive_asset_loader.dart';
import '../services/rive_gamification_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Global Rive Guide Widget
/// This widget can be placed anywhere in the app to show the animated guide character
/// It automatically connects to the gamification system
class RiveGlobalGuide extends ConsumerStatefulWidget {
  final double? width;
  final double? height;
  final Alignment alignment;
  final bool showInCorner;

  const RiveGlobalGuide({
    super.key,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.showInCorner = false,
  });

  @override
  ConsumerState<RiveGlobalGuide> createState() => _RiveGlobalGuideState();
}

class _RiveGlobalGuideState extends ConsumerState<RiveGlobalGuide> {
  late RiveGameGuideController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RiveGameGuideController();
    
    // Load Rive asset and connect to gamification service
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await RiveAssetLoader.loadRiveAsset(_controller);
      ref.read(riveGamificationServiceProvider).setController(_controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.width != null && widget.height != null
        ? Size(widget.width!, widget.height!)
        : Size(120.w, 120.h);

    final guide = RiveGameGuide(
      controller: _controller,
      width: size.width,
      height: size.height,
    );

    if (widget.showInCorner) {
      return Positioned(
        top: 16,
        right: 16,
        child: guide,
      );
    }

    return Align(
      alignment: widget.alignment,
      child: guide,
    );
  }
}

/// Floating Rive Guide (for overlay use)
class FloatingRiveGuide extends StatelessWidget {
  final double? size;
  final Offset? position;

  const FloatingRiveGuide({
    super.key,
    this.size,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    final guideSize = size ?? 100.0;
    final pos = position ?? const Offset(16, 16);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: RiveGlobalGuide(
        width: guideSize,
        height: guideSize,
      ),
    );
  }
}

