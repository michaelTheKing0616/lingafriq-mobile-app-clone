import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive/rive.dart';

import '../a11y/avatar_semantics.dart';
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
    this.useStill = true,
  });

  final CastSession session;
  final String artboard;
  final VoidCallback? onTap;

  /// Show the pre-rendered still for [CastSession.pose] preset while the Rive
  /// file loads or if it fails. Off only for the still generator itself.
  final bool useStill;

  /// Presets with a bundled still at `assets/images/cast_still_<preset>.png`.
  /// Regenerate with `test/tool/cast_stills_gen_test.dart`.
  static const stillPresets = [
    'PaLingAfriq',
    'Adisa',
    'Zuri',
    'Learner',
    'Kofi',
    'Amara',
  ];

  @override
  State<CastStage> createState() => _CastStageState();
}

class _CastStageState extends State<CastStage> {
  RiveWidgetController? _controller;
  bool? _onScreen;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
    widget.session.onTapped = widget.onTap;
    _load();
  }

  void _onSession() {
    if (!mounted) return;
    // AvatarCastSemantics can write to the session while it builds; defer the
    // rebuild to after the frame instead of marking dirty mid-build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
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
      _controller = controller;
      _applyActive();
      setState(() {});
    } catch (error, stack) {
      // The still stays on screen; nothing else to show the learner.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'cast_stage',
          silent: true,
        ),
      );
    }
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
    return ViewportGate(
      onVisible: (visible) {
        _onScreen = visible;
        _applyActive();
      },
      child: AvatarCastSemantics(
        session: widget.session,
        child: controller == null
            ? _Placeholder(
                preset: widget.session.pose.preset,
                useStill: widget.useStill,
              )
            : RiveWidget(controller: controller, fit: Fit.contain),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.preset, required this.useStill});

  final String preset;
  final bool useStill;

  @override
  Widget build(BuildContext context) {
    // A still of the same character, never a generic person icon. Unknown
    // presets get a quiet empty surface rather than a broken-looking glyph.
    if (useStill && CastStage.stillPresets.contains(preset)) {
      return Image.asset(
        'assets/images/cast_still_$preset.png',
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      );
    }
    return const SizedBox.expand();
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
