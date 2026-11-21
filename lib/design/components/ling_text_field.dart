import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// A single-line field. The fill is the container role.
class LingTextField extends StatefulWidget {
  const LingTextField({
    required this.label,
    required this.unavailableLabel,
    this.controller,
    this.forcedState,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String unavailableLabel;
  final TextEditingController? controller;
  final LingForcedState? forcedState;
  final bool enabled;

  @override
  State<LingTextField> createState() => _LingTextFieldState();
}

class _LingTextFieldState extends State<LingTextField> {
  TextEditingController? _owned;
  late final FocusNode _focus = FocusNode();
  bool _pressed = false;

  TextEditingController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = TextEditingController();
    }
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _owned?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (widget.forcedState != null) return;
    setState(() {});
  }

  LingForcedState get _visual {
    final LingForcedState? forced = widget.forcedState;
    if (forced != null) return forced;
    if (!widget.enabled) return LingForcedState.disabled;
    if (_pressed) return LingForcedState.pressed;
    if (_focus.hasFocus) return LingForcedState.focused;
    return LingForcedState.atRest;
  }

  @override
  Widget build(BuildContext context) {
    final LingForcedState state = _visual;
    final Brightness brightness = Theme.of(context).brightness;
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final LingPalette palette = LingPalette.of(brightness);
    final Color base = palette.surfaceContainer;
    final Color fill = state == LingForcedState.pressed
        ? lingPressedFill(base, palette.onSurface, reduced)
        : base;
    final Color foreground = palette.onSurface;
    final BorderSide side = switch (state) {
      LingForcedState.focused => BorderSide(
        color: palette.accent,
        width: LingAfriqTokens.strokeregular,
      ),
      LingForcedState.disabled => BorderSide(
        color: palette.onSurface,
        width: LingAfriqTokens.strokehairline,
      ),
      _ => BorderSide(
        color: palette.onSurfaceVariant,
        width: LingAfriqTokens.strokehairline,
      ),
    };
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(LingAfriqTokens.radiussm),
      ),
      borderSide: side,
    );
    final bool disabled = state == LingForcedState.disabled;
    return Semantics(
      container: true,
      textField: true,
      enabled: !disabled,
      focused: state == LingForcedState.focused,
      label: lingSemanticsLabel(state, widget.label, widget.unavailableLabel),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: lingBody(foreground),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing8),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: LingAfriqTokens.spacing48,
                minHeight: LingAfriqTokens.spacing48,
              ),
              child: AnimatedContainer(
                key: state == LingForcedState.focused
                    ? LingMarks.ring
                    : LingMarks.fill,
                duration: lingSettle(reduced),
                curve: lingProductCurve,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(LingAfriqTokens.radiussm),
                  ),
                ),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: widget.forcedState == null
                      ? (_) => setState(() => _pressed = true)
                      : null,
                  onPointerUp: widget.forcedState == null
                      ? (_) => setState(() => _pressed = false)
                      : null,
                  onPointerCancel: widget.forcedState == null
                      ? (_) => setState(() => _pressed = false)
                      : null,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    enabled: !disabled,
                    readOnly: state == LingForcedState.loading,
                    showCursor: widget.forcedState == null && !reduced,
                    enableInteractiveSelection: widget.forcedState == null,
                    cursorColor: palette.accent,
                    style: lingBody(foreground),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: LingAfriqTokens.spacing16,
                        vertical: LingAfriqTokens.spacing12,
                      ),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      disabledBorder: border,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: LingAfriqTokens.spacing48,
                        minHeight: LingAfriqTokens.spacing48,
                      ),
                      suffixIcon: state == LingForcedState.loading
                          ? Center(
                              child: LingBusyMark(
                                color: foreground,
                                reducedMotion: reduced,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            if (disabled) ...[
              const SizedBox(height: LingAfriqTokens.spacing4),
              Text(
                widget.unavailableLabel,
                style: lingBody(foreground),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
