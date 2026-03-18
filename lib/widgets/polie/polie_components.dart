import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/polie_design_tokens.dart';

/// Core Polie card container.
/// Previously glassmorphism; now a clearer elevated surface for readability.
class PolieGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hasGlow;
  final Color? glowColor;
  final double? borderRadius;

  const PolieGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.hasGlow = false,
    this.glowColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? PolieRadius.lg;
    return Container(
      padding: padding ?? EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: hasGlow
            ? PolieElevation.level2(context, glowColor: glowColor ?? PolieColors.royalAmethyst)
            : PolieElevation.level1(context),
        border: Border.all(
          color: isDark ? colorScheme.outline.withOpacity(0.24) : colorScheme.outline.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: child,
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
    super.key,
    required this.label,
    this.regionTag,
    this.isSelected = false,
    this.isDetecting = false,
    this.accentColor,
    this.onTap,
  });

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
            color: isSelected ? color : Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
    super.key,
    required this.text,
    this.role = PolieChatBubbleRole.assistant,
    this.isCorrectionOverlay = false,
    this.correctionText,
  });

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
      bubbleColor = isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight;
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
                : Theme.of(context).colorScheme.outline.withOpacity(0.08),
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
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.icon,
  });

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
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon!, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                        SizedBox(width: PolieSpacing.sm),
                      ],
                      Text(
                        label,
                        style: PolieTypography.label(context).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isDark
        ? colorScheme.outline.withOpacity(0.32)
        : colorScheme.outline.withOpacity(0.22);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PolieSpacing.md,
        vertical: PolieSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: PolieElevation.level1(context),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, color: colorScheme.onSurfaceVariant, size: PolieSpacing.md),
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
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: PolieTypography.body(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
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
              child: Icon(suffixIcon, color: colorScheme.onSurfaceVariant, size: PolieSpacing.md),
            ),
          ],
        ],
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
    super.key,
    required this.languageName,
    this.regionTag,
    this.accentColor,
    this.onTap,
  });

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

class PolieModeSwitcherItem<T> {
  final T value;
  final String icon;
  final String label;
  const PolieModeSwitcherItem({
    required this.value,
    required this.icon,
    required this.label,
  });
}

class PolieModeSwitcherRail<T> extends StatelessWidget {
  final T selected;
  final List<PolieModeSwitcherItem<T>> items;
  final ValueChanged<T> onChanged;
  final Color accent;
  final Color activeTextColor;

  const PolieModeSwitcherRail({
    super.key,
    required this.selected,
    required this.items,
    required this.onChanged,
    this.accent = const Color(0xFFD4822A),
    this.activeTextColor = const Color(0xFFFAF3E0),
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;
    return SizedBox(
      height: compact ? 44 : 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: compact ? 8 : 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final active = item.value == selected;
          return Tooltip(
            message: item.label,
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(item.value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? (active ? 12 : 8) : (active ? 16 : 10),
                  vertical: compact ? 7 : 8,
                ),
                decoration: BoxDecoration(
                  color: active ? accent : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: active ? accent : const Color(0xFFD8D4CC),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(item.icon, style: TextStyle(fontSize: compact ? 14 : (active ? 16 : 15))),
                    if (active) ...[
                      SizedBox(width: compact ? 4 : 6),
                      Text(
                        item.label,
                        style: PolieTypography.label(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: activeTextColor.withOpacity(0.98),
                          fontSize: compact ? 12 : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
