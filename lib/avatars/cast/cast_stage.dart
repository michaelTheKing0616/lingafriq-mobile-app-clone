import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../customisation/slot_binding.dart';
import 'cast_contract.dart';
import 'cast_file_cache.dart';
import 'cast_session.dart';
import 'viewport_gate.dart';

/// One [RiveWidgetController] for a visible character. Pauses when offscreen.
class CastStage extends StatefulWidget {
  const CastStage({
    super.key,
    required this.session,
    this.artboard = 'Character',
    this.onTap,
  });

  final CastSession session;
  final String artboard;
  final VoidCallback? onTap;

  @override
  State<CastStage> createState() => _CastStageState();
}

class _CastStageState extends State<CastStage> {
  RiveWidgetController? _controller;
  Object? _error;
  bool? _onScreen;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
    widget.session.onTapped = widget.onTap;
    _load();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CastStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.onTap != widget.onTap) {
      oldWidget.session.onTapped = null;
      oldWidget.session.removeListener(_onSession);
      widget.session.addListener(_onSession);
      widget.session.onTapped = widget.onTap;
    }
    if (oldWidget.artboard != widget.artboard ||
        oldWidget.session != widget.session) {
      _disposeController();
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final file = await CastFileCache.instance.load();
      final catalog = await CastContract.loadPartCatalog();
      if (!mounted) return;
      final controller = RiveWidgetController(
        file,
        artboardSelector: ArtboardSelector.byName(widget.artboard),
        stateMachineSelector: StateMachineSelector.byName('CharacterSM'),
      );
      final instance = controller.dataBind(
        DataBind.byName(widget.session.pose.preset),
      );
      widget.session.configurePartCatalog(catalog);
      widget.session.bind(file, instance);
      _applyReducedMotion();
      _controller = controller;
      _applyActive();
      setState(() => _error = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _applyReducedMotion() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    widget.session.reducedMotion(reduced);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) _applyReducedMotion();
  }

  void _applyActive() {
    final current = _controller;
    final visible = _onScreen;
    if (current == null || visible == null) return;
    if (current.active != visible) current.active = visible;
  }

  void _disposeController() {
    final instance = widget.session.bound;
    widget.session.unbind();
    instance?.dispose();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    widget.session.onTapped = null;
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final label = castSemanticsLabel(
      name: castSpokenName(widget.session.pose.preset),
      expression: widget.session.pose.expression,
      activity: widget.session.pose.activity,
    );
    return ViewportGate(
      onVisible: (visible) {
        _onScreen = visible;
        _applyActive();
      },
      child: Semantics(
        label: label,
        liveRegion: true,
        child: controller == null
            ? _Placeholder(
                preset: widget.session.pose.preset,
                failed: _error != null,
              )
            : RiveWidget(controller: controller, fit: Fit.contain),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.preset, required this.failed});

  final String preset;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          failed ? Icons.person_off_outlined : Icons.person_outline,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// CharacterChip drawn at 32, 48, or 64 px. Same ViewModel writes, no full body.
class CastChip extends StatelessWidget {
  const CastChip({super.key, required this.session, required this.size})
    : assert(size == 32 || size == 48 || size == 64);

  final CastSession session;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CastStage(session: session, artboard: 'CharacterChip'),
    );
  }
}
