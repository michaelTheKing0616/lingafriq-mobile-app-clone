import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/polie_design_tokens.dart';

/// Glass card for translation canvas, grammar lessons, story panels.
/// Frosted glass with soft gradient and optional glow.
class PolieGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hasGlow;
  final Color? glowColor;
  final double? borderRadius;

  const PolieGlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.hasGlow = false,
    this.glowColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? PolieRadius.lg;
    return Container(
      padding: padding ?? EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: hasGlow
            ? PolieElevation.level2(context, glowColor: glowColor ?? PolieColors.royalAmethyst)
            : PolieElevation.level1(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? PolieColors.surfaceGlassDark : PolieColors.surfaceGlass,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Language pill — always visible, shows selected language. States: idle, selected (glow), detecting (pulse).
class PolieLanguagePill extends StatelessWidget {
  final String label;
  final String? regionTag;
  final bool isSelected;
  final bool isDetecting;
  final Color? accentColor;
  final VoidCallback? onTap;

  const PolieLanguagePill({
    Key? key,
    required this.label,
    this.regionTag,
    this.isSelected = false,
    this.isDetecting = false,
    this.accentColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? PolieColors.royalAmethyst;
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: PolieSpacing.md,
          vertical: PolieSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(PolieRadius.pill),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDetecting)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            if (isDetecting) SizedBox(width: PolieSpacing.sm),
            Text(
              label,
              style: PolieTypography.label(context).copyWith(
                color: isSelected ? color : PolieColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (regionTag != null && regionTag!.isNotEmpty) ...[
              SizedBox(width: PolieSpacing.xs),
              Text(
                '— $regionTag',
                style: PolieTypography.bodySmall(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chat bubble: user, AI (teacher/character), or correction overlay.
enum PolieChatBubbleRole { user, assistant, correction }

class PolieChatBubble extends StatelessWidget {
  final String text;
  final PolieChatBubbleRole role;
  final bool isCorrectionOverlay;
  final String? correctionText;

  const PolieChatBubble({
    Key? key,
    required this.text,
    this.role = PolieChatBubbleRole.assistant,
    this.isCorrectionOverlay = false,
    this.correctionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = role == PolieChatBubbleRole.user;
    final isCorrection = role == PolieChatBubbleRole.correction || isCorrectionOverlay;

    Color bubbleColor;
    Color textColor;
    Alignment alignment;
    if (isCorrection) {
      bubbleColor = PolieColors.errorMuted.withOpacity(0.2);
      textColor = PolieColors.error;
      alignment = Alignment.centerLeft;
    } else if (isUser) {
      bubbleColor = PolieColors.royalAmethyst.withOpacity(0.25);
      textColor = PolieColors.textPrimary;
      alignment = Alignment.centerRight;
    } else {
      bubbleColor = isDark ? PolieColors.surfaceGlassDark : PolieColors.surfaceGlass;
      textColor = isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight;
      alignment = Alignment.centerLeft;
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: PolieSpacing.xs,
          horizontal: PolieSpacing.md,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: PolieSpacing.md,
          vertical: PolieSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(PolieRadius.md),
            topRight: Radius.circular(PolieRadius.md),
            bottomLeft: Radius.circular(isUser ? PolieRadius.md : 4),
            bottomRight: Radius.circular(isUser ? 4 : PolieRadius.md),
          ),
          border: Border.all(
            color: isUser
                ? PolieColors.royalAmethyst.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: PolieTypography.body(context).copyWith(color: textColor),
            ),
            if (isCorrectionOverlay && correctionText != null && correctionText!.isNotEmpty) ...[
              SizedBox(height: PolieSpacing.xs),
              Text(
                '→ $correctionText',
                style: PolieTypography.bodySmall(context).copyWith(
                  color: PolieColors.electricTeal,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Primary button with gradient glow. States: default, pressed, loading (orb morph), disabled.
class PoliePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final IconData? icon;

  const PoliePrimaryButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (enabled && !loading && onPressed != null) ? onPressed! : null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveOnPressed != null
              ? () {
                  HapticFeedback.mediumImpact();
                  effectiveOnPressed();
                }
              : null,
          borderRadius: BorderRadius.circular(PolieRadius.md),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: PolieSpacing.xl,
              vertical: PolieSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PolieColors.royalAmethyst,
                  PolieColors.royalAmethystLight.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(PolieRadius.md),
              boxShadow: [
                BoxShadow(
                  color: PolieColors.royalAmethyst.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: loading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon!, color: Colors.white, size: 20),
                        SizedBox(width: PolieSpacing.sm),
                      ],
                      Text(
                        label,
                        style: PolieTypography.label(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Glass morphism input field for Polie AI chat
class PolieInputField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool enabled;
  final int maxLines;
  final int? maxLength;

  const PolieInputField({
    Key? key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(PolieRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: PolieSpacing.md,
          sigmaY: PolieSpacing.md,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: PolieSpacing.md,
            vertical: PolieSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? PolieColors.surfaceGlassDark : PolieColors.surfaceGlass,
            borderRadius: BorderRadius.circular(PolieRadius.lg),
            border: Border.all(color: borderColor),
            boxShadow: PolieElevation.level1(context),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, color: PolieColors.textSecondary, size: PolieSpacing.md),
                SizedBox(width: PolieSpacing.sm),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: PolieTypography.body(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: PolieTypography.body(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (suffixIcon != null) ...[
                SizedBox(width: PolieSpacing.sm),
                GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon, color: PolieColors.textSecondary, size: PolieSpacing.md),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating language pill for Polie/AI Chat — always visible (e.g. top-right).
/// Use inside a Stack with Positioned, or as an AppBar action.
class PolieFloatingLanguagePill extends StatelessWidget {
  final String languageName;
  final String? regionTag;
  final Color? accentColor;
  final VoidCallback? onTap;

  const PolieFloatingLanguagePill({
    Key? key,
    required this.languageName,
    this.regionTag,
    this.accentColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PolieLanguagePill(
      label: languageName,
      regionTag: regionTag,
      isSelected: false,
      isDetecting: false,
      accentColor: accentColor,
      onTap: onTap,
    );
  }
}
