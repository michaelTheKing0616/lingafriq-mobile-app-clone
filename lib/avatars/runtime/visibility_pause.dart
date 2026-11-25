import 'package:flutter/material.dart';

import 'character_controller.dart';

/// Injectable battery probe for tests and platform wiring (no client secrets).
abstract final class AvatarBatteryProbe {
  static Future<bool> Function() isLowBattery = () async => false;

  /// ≤ this percent triggers [applyLowPowerIdleMotion].
  static const int lowPowerThresholdPercent = 20;
}

/// Low-power idle: stop body idle loops; blinking continues (reducedMotion VM flag).
void applyLowPowerIdleMotion({
  required bool lowPower,
  void Function(bool reducedMotion)? onReducedMotion,
  CharacterController? character,
}) {
  if (lowPower) {
    onReducedMotion?.call(true);
    character?.active = false;
  } else {
    onReducedMotion?.call(false);
  }
}

/// Pauses a [CharacterController] when its subtree leaves the scroll viewport.
class CharacterVisibilityPause extends StatefulWidget {
  const CharacterVisibilityPause({
    super.key,
    required this.controller,
    required this.child,
    this.onLowPower,
    this.watchBattery = true,
  });

  final CharacterController controller;
  final Widget child;
  final ValueChanged<bool>? onLowPower;
  final bool watchBattery;

  @override
  State<CharacterVisibilityPause> createState() =>
      _CharacterVisibilityPauseState();
}

class _CharacterVisibilityPauseState extends State<CharacterVisibilityPause>
    with WidgetsBindingObserver {
  bool _onScreen = false;
  bool _lowPower = false;
  bool _visibilityKnown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.controller.isAttached) {
      widget.controller.active = false;
    }
    _refreshBattery();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBattery();
    }
  }

  Future<void> _refreshBattery() async {
    if (!widget.watchBattery) return;
    final low = await AvatarBatteryProbe.isLowBattery();
    if (!mounted || low == _lowPower) return;
    setState(() => _lowPower = low);
    widget.onLowPower?.call(low);
    applyLowPowerIdleMotion(
      lowPower: low,
      character: widget.controller,
      onReducedMotion: (_) {},
    );
    _applyActive();
  }

  void _onVisible(bool visible) {
    _visibilityKnown = true;
    _onScreen = visible;
    _applyActive();
  }

  void _applyActive() {
    if (_lowPower) {
      widget.controller.active = false;
      return;
    }
    if (!_visibilityKnown) {
      widget.controller.active = false;
      return;
    }
    widget.controller.active = _onScreen;
  }

  @override
  Widget build(BuildContext context) {
    return _AvatarViewportGate(
      onVisible: _onVisible,
      child: widget.child,
    );
  }
}

/// Conservative viewport gate: unknown layout ⇒ offscreen (paused).
class _AvatarViewportGate extends StatefulWidget {
  const _AvatarViewportGate({required this.onVisible, required this.child});

  final ValueChanged<bool> onVisible;
  final Widget child;

  @override
  State<_AvatarViewportGate> createState() => _AvatarViewportGateState();
}

class _AvatarViewportGateState extends State<_AvatarViewportGate> {
  bool _checkScheduled = false;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_schedule);
      _position = next;
      _position?.addListener(_schedule);
    }
    _schedule();
  }

  @override
  void dispose() {
    _position?.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
  }

  void _check() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      widget.onVisible(false);
      return;
    }
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      widget.onVisible(true);
      return;
    }
    final viewportObject = scrollable.context.findRenderObject();
    if (viewportObject is! RenderBox || !viewportObject.hasSize) {
      widget.onVisible(false);
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: viewportObject);
    final childRect = origin & box.size;
    final viewRect = Offset.zero & viewportObject.size;
    widget.onVisible(childRect.overlaps(viewRect));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
