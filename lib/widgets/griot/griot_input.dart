import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Text input field following the Modern Griot design rules.
///
/// - surfaceContainerHighest background (no visible border)
/// - 2px primary underline on focus with soft inner glow
/// - Ghost border (outlineVariant at 15% opacity) for accessibility
///
/// ```dart
/// GriotInput(
///   controller: _emailController,
///   label: 'Email address',
///   prefixIcon: Icons.email_outlined,
/// )
/// ```
class GriotInput extends StatefulWidget {
  const GriotInput({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.validator,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final int maxLines;
  final int? minLines;
  final bool enabled;

  @override
  State<GriotInput> createState() => _GriotInputState();
}

class _GriotInputState extends State<GriotInput> {
  late final FocusNode _internalFocus;
  bool _hasFocus = false;

  FocusNode get _effectiveFocus => widget.focusNode ?? _internalFocus;

  @override
  void initState() {
    super.initState();
    _internalFocus = FocusNode();
    _effectiveFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _effectiveFocus.removeListener(_onFocusChange);
    if (widget.focusNode == null) _internalFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _hasFocus = _effectiveFocus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ghostBorder = cs.outlineVariant.withAlpha(38); // ~15%

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: ModernGriotRadius.borderXl,
            border: Border.all(color: ghostBorder, width: 1),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: cs.primary.withAlpha(25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: widget.controller,
                focusNode: _effectiveFocus,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                validator: widget.validator,
                onFieldSubmitted: widget.onFieldSubmitted,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                enabled: widget.enabled,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: widget.maxLines > 1 ? 16.h : 0,
                  ),
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontSize: 15.sp,
                    color: cs.onSurfaceVariant.withAlpha(153),
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Padding(
                          padding: EdgeInsets.only(left: 16.w, right: 8.w),
                          child: Icon(
                            widget.prefixIcon,
                            size: 20.sp,
                            color: _hasFocus
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        )
                      : null,
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  suffixIcon: widget.suffixIcon,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  errorStyle: TextStyle(
                    fontSize: 12.sp,
                    color: cs.error,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2.h,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: _hasFocus ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
