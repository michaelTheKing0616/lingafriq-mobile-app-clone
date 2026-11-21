import 'package:flutter/material.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

/// Catalogue states for a control. [atRest] is the catalogue id `default`.
///
/// A non-null forced state is painted as given, so a golden can show pressed
/// or focused without a gesture. When it is null, pressed and focused come
/// from the pointer and the focus node.
enum LingForcedState {
  atRest,
  pressed,
  focused,
  disabled,
  loading;

  static LingForcedState fromCatalogue(String state) {
    return switch (state) {
      'default' => LingForcedState.atRest,
      'pressed' => LingForcedState.pressed,
      'focused' => LingForcedState.focused,
      'disabled' => LingForcedState.disabled,
      'loading' => LingForcedState.loading,
      _ => throw ArgumentError.value(state, 'state', 'Not a control state'),
    };
  }
}

/// One filled accent means the primary action. A quiet control uses container.
enum LingFillRole { accent, container }

/// Keys a golden or a widget test can read without relying on a gesture.
abstract final class LingMarks {
  static const Key fill = ValueKey<String>('ling-fill');
  static const Key ring = ValueKey<String>('ling-ring');
  static const Key panel = ValueKey<String>('ling-panel');
}

/// Ramp roles for one brightness. The legacy cream token is not a page
/// background here.
class LingPalette {
  const LingPalette({
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceContainer,
    required this.accent,
    required this.onAccent,
  });

  factory LingPalette.of(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LingPalette(
        surface: LingAfriqTokens.roleDarkSurface,
        onSurface: LingAfriqTokens.roleDarkOnSurface,
        onSurfaceVariant: LingAfriqTokens.roleDarkOnSurfaceVariant,
        surfaceContainer: LingAfriqTokens.roleDarkSurfaceContainer,
        accent: LingAfriqTokens.roleDarkAccent,
        onAccent: LingAfriqTokens.roleDarkOnAccent,
      );
    }
    return const LingPalette(
      surface: LingAfriqTokens.roleLightSurface,
      onSurface: LingAfriqTokens.roleLightOnSurface,
      onSurfaceVariant: LingAfriqTokens.roleLightOnSurfaceVariant,
      surfaceContainer: LingAfriqTokens.roleLightSurfaceContainer,
      accent: LingAfriqTokens.roleLightAccent,
      onAccent: LingAfriqTokens.roleLightOnAccent,
    );
  }

  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surfaceContainer;
  final Color accent;
  final Color onAccent;
}

/// Product motion. The slow duration is the reduced-motion move: gentler, and
/// still at most 300 ms. It is not removed.
final Curve lingProductCurve = _productCurve();

Duration lingSettle(bool reducedMotion) {
  final int ms = reducedMotion
      ? LingAfriqTokens.motionProductSlow
      : LingAfriqTokens.motionProductFast;
  assert(ms > 0 && ms <= 300, 'product motion must stay within 300 ms');
  return Duration(milliseconds: ms);
}

double lingPressAmount(bool reducedMotion) => reducedMotion ? 0.08 : 0.16;

Color lingPressedFill(Color base, Color ink, bool reducedMotion) {
  return Color.alphaBlend(
    ink.withValues(alpha: lingPressAmount(reducedMotion)),
    base,
  );
}

TextStyle lingBody(Color color) {
  return TextStyle(
    fontFamily: LingAfriqType.bodyFamily,
    fontFamilyFallback: LingAfriqType.scriptFallback,
    fontSize: LingAfriqType.bodySize,
    height: LingAfriqType.targetHeight,
    color: color,
  );
}

double lingElevation(Brightness brightness, {required bool prominent}) {
  if (brightness == Brightness.dark) {
    return prominent
        ? LingAfriqTokens.elevationDarkmd
        : LingAfriqTokens.elevationDarksm;
  }
  return prominent
      ? LingAfriqTokens.elevationLightmd
      : LingAfriqTokens.elevationLightsm;
}

double _restingElevation(
  Brightness brightness,
  double requested,
  LingForcedState state,
) {
  if (state == LingForcedState.pressed || state == LingForcedState.disabled) {
    return brightness == Brightness.dark
        ? LingAfriqTokens.elevationDarknone
        : LingAfriqTokens.elevationLightnone;
  }
  return requested;
}

class _Paint {
  const _Paint({
    required this.fill,
    required this.foreground,
    required this.border,
    required this.gap,
    required this.elevation,
  });

  final Color fill;
  final Color foreground;
  final Border? border;
  final EdgeInsetsGeometry gap;
  final double elevation;
}

_Paint _paintFor({
  required LingPalette palette,
  required Brightness brightness,
  required LingForcedState state,
  required LingFillRole role,
  required bool reducedMotion,
  required double restingElevation,
}) {
  final Color base = role == LingFillRole.accent
      ? palette.accent
      : palette.surfaceContainer;
  final Color foreground = role == LingFillRole.accent
      ? palette.onAccent
      : palette.onSurface;
  final Color fill = switch (state) {
    LingForcedState.pressed => lingPressedFill(
      base,
      palette.onSurface,
      reducedMotion,
    ),
    LingForcedState.disabled => palette.surfaceContainer,
    _ => base,
  };
  final Border? border = switch (state) {
    LingForcedState.focused => Border.all(
      color: palette.accent,
      width: LingAfriqTokens.strokeregular,
    ),
    LingForcedState.disabled => Border.all(
      color: palette.onSurface,
      width: LingAfriqTokens.strokehairline,
    ),
    _ => null,
  };
  return _Paint(
    fill: fill,
    foreground: state == LingForcedState.disabled
        ? palette.onSurface
        : foreground,
    border: border,
    gap: state == LingForcedState.focused
        ? const EdgeInsets.all(LingAfriqTokens.spacing4)
        : EdgeInsets.zero,
    elevation: _restingElevation(brightness, restingElevation, state),
  );
}

/// Progress mark. When animations are disabled it holds a fixed value.
class LingBusyMark extends StatelessWidget {
  const LingBusyMark({
    required this.color,
    required this.reducedMotion,
    super.key,
  });

  final Color color;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.textScalerOf(
      context,
    ).scale(LingAfriqType.bodySize);
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: LingAfriqTokens.strokeregular,
        color: color,
        value: reducedMotion ? 0.75 : null,
      ),
    );
  }
}

/// Tracks press and focus unless [forcedState] is set.
class LingInteraction extends StatefulWidget {
  const LingInteraction({
    required this.labelFor,
    required this.builder,
    this.forcedState,
    this.onPressed,
    this.button = true,
    super.key,
  });

  final LingForcedState? forcedState;
  final VoidCallback? onPressed;
  final bool button;
  final String Function(LingForcedState state) labelFor;
  final Widget Function(BuildContext context, LingForcedState state) builder;

  @override
  State<LingInteraction> createState() => _LingInteractionState();
}

class _LingInteractionState extends State<LingInteraction> {
  bool _pressed = false;
  bool _focused = false;

  LingForcedState get _visual {
    final LingForcedState? forced = widget.forcedState;
    if (forced != null) return forced;
    if (widget.onPressed == null) return LingForcedState.disabled;
    if (_pressed) return LingForcedState.pressed;
    if (_focused) return LingForcedState.focused;
    return LingForcedState.atRest;
  }

  void _setPressed(bool value) {
    if (widget.forcedState != null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activate() {
    final LingForcedState state = _visual;
    if (state == LingForcedState.disabled || state == LingForcedState.loading) {
      return;
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final LingForcedState state = _visual;
    final bool interactive =
        state != LingForcedState.disabled && state != LingForcedState.loading;
    return Semantics(
      container: true,
      button: widget.button,
      enabled: state != LingForcedState.disabled,
      focused: state == LingForcedState.focused,
      label: widget.labelFor(state),
      onTap: interactive ? _activate : null,
      child: Focus(
        canRequestFocus: widget.forcedState == null && interactive,
        onFocusChange: (bool value) {
          if (widget.forcedState != null || _focused == value) return;
          setState(() => _focused = value);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: interactive ? _activate : null,
          child: ExcludeSemantics(child: widget.builder(context, state)),
        ),
      ),
    );
  }
}

/// Shared body for a button, chip, or list row.
class LingLabeledControl extends StatelessWidget {
  const LingLabeledControl({
    required this.state,
    required this.label,
    required this.unavailableLabel,
    required this.role,
    required this.radius,
    this.chevron = false,
    this.restingElevation = 0,
    super.key,
  });

  final LingForcedState state;
  final String label;
  final String unavailableLabel;
  final LingFillRole role;
  final BorderRadius radius;
  final bool chevron;

  /// Elevation while the control is at rest. Pressed and disabled use none.
  final double restingElevation;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final LingPalette palette = LingPalette.of(brightness);
    final _Paint paint = _paintFor(
      palette: palette,
      brightness: brightness,
      state: state,
      role: role,
      reducedMotion: reduced,
      restingElevation: restingElevation,
    );
    final TextStyle style = lingBody(paint.foreground);
    final Widget text = Text(
      label,
      style: style,
      softWrap: true,
      overflow: TextOverflow.visible,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double? width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;
        final Widget body = AnimatedContainer(
          key: state == LingForcedState.focused ? LingMarks.ring : null,
          duration: lingSettle(reduced),
          curve: lingProductCurve,
          width: width,
          padding: paint.gap,
          decoration: BoxDecoration(borderRadius: radius, border: paint.border),
          child: Material(
            key: LingMarks.fill,
            color: paint.fill,
            elevation: paint.elevation,
            shadowColor: palette.onSurface,
            surfaceTintColor: paint.fill,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LingAfriqTokens.spacing16,
                vertical: LingAfriqTokens.spacing12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (state == LingForcedState.loading) ...[
                        LingBusyMark(
                          color: paint.foreground,
                          reducedMotion: reduced,
                        ),
                        const SizedBox(width: LingAfriqTokens.spacing8),
                      ],
                      Expanded(child: text),
                      if (chevron && state != LingForcedState.loading)
                        Icon(
                          Icons.chevron_right,
                          color: paint.foreground,
                          size: LingAfriqTokens.spacing24,
                        ),
                    ],
                  ),
                  if (state == LingForcedState.disabled) ...[
                    const SizedBox(height: LingAfriqTokens.spacing4),
                    Text(
                      unavailableLabel,
                      style: style,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: LingAfriqTokens.spacing48,
            minHeight: LingAfriqTokens.spacing48,
          ),
          child: body,
        );
      },
    );
  }
}

/// Surface for a card, sheet, or dialog. The child keeps its own labels.
class LingPanel extends StatelessWidget {
  const LingPanel({
    required this.state,
    required this.child,
    required this.radius,
    required this.restingElevation,
    super.key,
  });

  final LingForcedState state;
  final Widget child;
  final BorderRadius radius;
  final double restingElevation;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final LingPalette palette = LingPalette.of(brightness);
    final _Paint paint = _paintFor(
      palette: palette,
      brightness: brightness,
      state: state,
      role: LingFillRole.container,
      reducedMotion: reduced,
      restingElevation: restingElevation,
    );
    return AnimatedContainer(
      key: state == LingForcedState.focused ? LingMarks.ring : null,
      duration: lingSettle(reduced),
      curve: lingProductCurve,
      padding: paint.gap,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: paint.border,
        boxShadow: paint.elevation <= 0
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: palette.onSurface.withValues(alpha: 0.12),
                  blurRadius: paint.elevation,
                  offset: Offset(0, paint.elevation),
                ),
              ],
      ),
      child: Material(
        key: LingMarks.panel,
        color: paint.fill,
        surfaceTintColor: paint.fill,
        elevation: LingAfriqTokens.elevationLightnone,
        borderRadius: radius,
        child: child,
      ),
    );
  }
}

String lingSemanticsLabel(
  LingForcedState state,
  String label,
  String unavailableLabel,
) {
  if (state == LingForcedState.disabled) return '$label $unavailableLabel';
  return label;
}

Curve _productCurve() {
  const String raw = LingAfriqTokens.motionProductEasing;
  final int open = raw.indexOf('(');
  final int close = raw.indexOf(')');
  final List<String> parts = raw.substring(open + 1, close).split(',');
  return Cubic(
    double.parse(parts[0]),
    double.parse(parts[1]),
    double.parse(parts[2]),
    double.parse(parts[3]),
  );
}
