import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/services/chat/chat_room_learning_service.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart' show PanAfricanSpacing;

/// Compact peer language badge for chat headers (P9-945 AC4).
class LanguageStatusChip extends StatelessWidget {
  const LanguageStatusChip({
    super.key,
    required this.entry,
  });

  final ChatLanguageStatusEntry entry;

  @override
  Widget build(BuildContext context) {
    if (!entry.visibleToViewer || entry.languageCode.isEmpty) {
      return const SizedBox.shrink();
    }

    final label = _labelFor(entry);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(ModernGriotRadius.full),
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(ModernGriotRadius.full),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.sm.w,
              vertical: PanAfricanSpacing.xxs.h,
            ),
            child: Text(
              label,
              style: ModernGriotTypography.labelMedium(context: context).copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _labelFor(ChatLanguageStatusEntry entry) {
    final name = entry.displayName?.trim();
    final lang = name != null && name.isNotEmpty
        ? name
        : entry.languageCode.toUpperCase();
    switch (entry.role) {
      case ChatLanguageRole.native:
        return 'Native · $lang';
      case ChatLanguageRole.learning:
        return 'Learning $lang';
    }
  }
}

/// Row of visible language badges; hides entirely when the list is empty.
class LanguageStatusChipRow extends StatelessWidget {
  const LanguageStatusChipRow({
    super.key,
    required this.entries,
  });

  final List<ChatLanguageStatusEntry> entries;

  @override
  Widget build(BuildContext context) {
    final visible =
        entries.where((e) => e.visibleToViewer && e.languageCode.isNotEmpty);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: PanAfricanSpacing.xs.w,
      runSpacing: PanAfricanSpacing.xxs.h,
      children: [
        for (final entry in visible) LanguageStatusChip(entry: entry),
      ],
    );
  }
}
