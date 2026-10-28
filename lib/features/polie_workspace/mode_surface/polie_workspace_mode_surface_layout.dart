import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';

class PolieModeSurfaceLayout {
  PolieModeSurfaceLayout(this.context, this.theme, this.mode);
  final BuildContext context;
  final ModeTheme theme;
  final PolieMode mode;
  late final double screenWidth = MediaQuery.sizeOf(context).width;
  late final bool isPhone = screenWidth < 700;
  late final bool isTinyPhone = screenWidth < 390;
  late final double basePad = isTinyPhone ? 8.0 : 12.0;
  late final TextStyle bodyStyle = GoogleFonts.nunito(color: theme.body, fontSize: 14);
  late final TextStyle monoStyle = GoogleFonts.jetBrainsMono(color: theme.title, fontSize: 13.5);
  Widget card(Widget child, {Color? color}) => Container(
    decoration: BoxDecoration(
      color: color ?? theme.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.border),
    ),
    child: child,
  );
  Widget errorBanner(String? modeError) {
    if (modeError == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(modeError, style: bodyStyle)),
      ]),
    );
  }
  static const modeDescriptions = <PolieMode, String>{
    PolieMode.translation: 'Precision tool. Split-panel translation with dynamic output updates.',
    PolieMode.tutor: 'Interactive classroom notebook with flip cards and inline feedback.',
    PolieMode.roleplay: 'Dark cinematic stage with scene-first character cards and live coaching.',
    PolieMode.conversation: 'WhatsApp-style chat with a patient friend. The only bubble-chat mode.',
    PolieMode.vocab: 'Museum word theater: one dramatic word, dark focus, SRS actions.',
    PolieMode.review: 'Personal coach dashboard with animated bars and clear next steps.',
  };
  static const modeIcons = <PolieMode, String>{
    PolieMode.translation: '\u21C4',
    PolieMode.tutor: '\uD83D\uDCD6',
    PolieMode.roleplay: '\uD83C\uDFAD',
    PolieMode.conversation: '\uD83D\uDCAC',
    PolieMode.vocab: '\u2726',
    PolieMode.review: '\uD83D\uDCCA',
  };
  Widget introBanner({required Set<String> introDismissed, required void Function(String) onDismissIntro}) {
    if (mode == PolieMode.conversation || introDismissed.contains(mode.name)) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accent.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(modeIcons[mode] ?? '', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.name[0].toUpperCase() + mode.name.substring(1),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: theme.title)),
                const SizedBox(height: 2),
                Text(modeDescriptions[mode] ?? '', style: GoogleFonts.nunito(fontSize: 12.5, color: theme.body)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onDismissIntro(mode.name),
            child: Icon(Icons.close_rounded, size: 18, color: theme.body.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
