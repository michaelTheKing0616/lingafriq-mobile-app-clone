import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';

/// Modern animated button with Material 3 design
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final double? width;

  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.width,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isLoading) {
          widget.onPressed?.call();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          width: widget.width ?? double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AfricanTheme.primaryGreen,
            borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
            boxShadow: [
              BoxShadow(
                color: (widget.backgroundColor ?? AfricanTheme.primaryGreen)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.2, end: 0, duration: 300.ms),
      ),
    );
  }
}

