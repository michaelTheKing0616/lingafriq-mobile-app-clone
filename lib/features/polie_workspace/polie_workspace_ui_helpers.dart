import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';

Widget polieBuildAnimatedWordFlow(String text, TextStyle style) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (var i = 0; i < words.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey('${words[i]}-$i-$text'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 120 + (i * 20).clamp(0, 500)),
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: Text(words[i], style: style),
          ),
      ],
    );
}

InputDecoration polieInputDecoration(ModeTheme theme, String hint) {
    final isDark = theme.background.computeLuminance() < 0.2;
    return InputDecoration(
      hintText: hint,
      hintStyle: isDark ? const TextStyle(color: Color(0xFFD8C9B7)) : null,
      filled: true,
      fillColor: theme.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.accent, width: 1.3),
      ),
    );
}

Widget poliePeriodChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
}) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD4822A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9CBB6)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: selected ? Colors.white : const Color(0xFF2D1B0E),
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 14,
          ),
        ),
      ),
    );
}

ModeTheme polieThemeForMode(PolieMode mode) {
    switch (mode) {
      case PolieMode.translation:
        return const ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.tutor:
        return const ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.roleplay:
        return const ModeTheme(
          background: Color(0xFF0F0A04),
          card: Color(0xFF1A130C),
          title: Color(0xFFFAF3E0),
          body: Color(0xFFE8DAC5),
          border: Color(0xFF3A2A1C),
          accent: Color(0xFFC4663A),
        );
      case PolieMode.conversation:
        return const ModeTheme(
          background: Color(0xFFF5F0E8),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFE0D5C4),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.vocab:
        return const ModeTheme(
          background: Color(0xFF0F0A04),
          card: Color(0xFF1A130C),
          title: Color(0xFFFAF3E0),
          body: Color(0xFFE8DAC5),
          border: Color(0xFF3A2A1C),
          accent: Color(0xFFF2C14E),
        );
      case PolieMode.review:
      case PolieMode.pronunciation:
      case PolieMode.grammar:
        return const ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
    }
}

Widget polieSrsButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback? onTap,
) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 9 : 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ),
      ),
    );
}

Widget polieStatCard(
    BuildContext context,
    String label,
    String value,
    Color stripe,
) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9CBB6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: stripe,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: compact ? 11 : 12)),
          Row(
            children: [
              Icon(polieStatIcon(label), size: 16, color: stripe),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: compact ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
}

IconData polieStatIcon(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('word')) return Icons.menu_book_rounded;
    if (normalized.contains('accuracy')) return Icons.trending_up_rounded;
    if (normalized.contains('streak')) {
      return Icons.local_fire_department_rounded;
    }
    if (normalized.contains('lesson')) return Icons.chat_bubble_outline_rounded;
    return Icons.insights_rounded;
}

Color polieSkillColor(String skill) {
    final s = skill.toLowerCase();
    if (s.contains('vocab')) return const Color(0xFFD4822A);
    if (s.contains('grammar')) return const Color(0xFF4A7C59);
    if (s.contains('pronunciation')) return const Color(0xFFE2B93B);
    if (s.contains('conversation')) return const Color(0xFFC4663A);
    return const Color(0xFFD4822A);
}
