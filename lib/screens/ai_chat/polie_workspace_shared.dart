import 'package:flutter/material.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';

class ModeChipItem {
  final PolieMode mode;
  final String icon;
  final String label;
  const ModeChipItem({required this.mode, required this.icon, required this.label});
}

class ModeTheme {
  final Color background;
  final Color card;
  final Color title;
  final Color body;
  final Color border;
  final Color accent;
  const ModeTheme({
    required this.background,
    required this.card,
    required this.title,
    required this.body,
    required this.border,
    required this.accent,
  });
}

class AltItem {
  final String text;
  final String note;
  const AltItem({required this.text, required this.note});
}

String normalizeInitialRoleplayScene(String? raw) {
  const allowed = <String>{
    'Market',
    'Restaurant',
    'Meeting Elder',
    'Job Interview',
    'Family Dinner',
  };
  if (raw == null) return 'Market';
  final normalized = raw.trim();
  if (allowed.contains(normalized)) return normalized;
  return 'Market';
}
