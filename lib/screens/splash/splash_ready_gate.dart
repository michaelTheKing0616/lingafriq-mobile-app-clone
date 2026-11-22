import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// How long startup may run before the splash shows a progress cue.
///
/// The splash leaves when [SplashReadyGate.ready] completes. It does not wait
/// for this duration.
const Duration splashProgressCueDelay = Duration(milliseconds: 1200);

/// Keeps the splash on screen until [ready] finishes.
///
/// A ready app leaves on the next frame. A start that is still running after
/// [progressAfter] stays on the splash and shows [SplashProgressCue].
class SplashReadyGate extends StatefulWidget {
  const SplashReadyGate({
    super.key,
    required this.ready,
    required this.builder,
    this.onReady,
    this.progressAfter = splashProgressCueDelay,
  });

  static const Key surfaceKey = Key('splash-ready-surface');
  static const Key progressKey = Key('splash-ready-progress');

  final Future<void> ready;
  final Widget Function(BuildContext context, bool showProgress) builder;
  final Future<void> Function()? onReady;
  final Duration progressAfter;

  @override
  State<SplashReadyGate> createState() => _SplashReadyGateState();
}

class _SplashReadyGateState extends State<SplashReadyGate> {
  Timer? _progressTimer;
  var _showProgress = false;
  var _dismissed = false;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer(widget.progressAfter, () {
      if (!mounted || _dismissed) return;
      setState(() => _showProgress = true);
    });
    unawaited(_waitForReady());
  }

  Future<void> _waitForReady() async {
    try {
      await widget.ready;
    } catch (_) {
      if (!mounted || _dismissed) return;
      setState(() => _showProgress = true);
      return;
    }
    if (!mounted || _dismissed) return;
    _progressTimer?.cancel();
    final next = widget.onReady;
    if (next != null) {
      await next();
    }
    if (!mounted) return;
    setState(() {
      _dismissed = true;
      _showProgress = false;
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return KeyedSubtree(
      key: SplashReadyGate.surfaceKey,
      child: widget.builder(context, _showProgress),
    );
  }
}

/// Steady progress cue shown only while a slow start is still on the splash.
class SplashProgressCue extends StatelessWidget {
  const SplashProgressCue({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CircularProgressIndicator(
        key: SplashReadyGate.progressKey,
        semanticsLabel: 'Loading',
        strokeWidth: 3,
        color: PanAfricanColors.secondary,
      ),
    );
  }
}
