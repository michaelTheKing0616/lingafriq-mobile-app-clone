import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_tx_helpers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_language_sheet.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_layout.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_args.dart';


Widget buildPolieConversationComposer(PolieModeSurfaceArgs a, PolieModeSurfaceLayout layout) {
  final l10n = AppLocalizations.of(a.context)!;
  return Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Style:',
                          style: layout.bodyStyle.copyWith(
                            color: const Color(0xFF2D1B0E),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        ...const ['formal', 'humorous', 'witty', 'terse', 'lengthy']
                            .map(
                              (s) => ChoiceChip(
                                label: Text(
                                  s[0].toUpperCase() + s.substring(1),
                                ),
                                selected: a.conversationResponseStyle.value == s,
                                selectedColor: a.theme.accent.withOpacity(0.2),
                                onSelected: a.isBusy
                                    ? null
                                    : (_) => a.conversationResponseStyle.value = s,
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Switch(
                        value: a.conversationIncludeEnglishTranslations.value,
                        onChanged: a.isBusy
                            ? null
                            : (v) => a.conversationIncludeEnglishTranslations.value = v,
                        activeColor: a.theme.accent,
                      ),
                      Expanded(
                        child: Text(
                          l10n.polieConversationIncludeEnglishTranslations,
                          style: layout.bodyStyle.copyWith(
                            color: const Color(0xFF2D1B0E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: a.conversationInput,
                          decoration: polieInputDecoration(a.theme, 'Type a message...')
                              .copyWith(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(color: a.theme.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(color: a.theme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(
                                    color: a.theme.accent,
                                    width: 1.3,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: a.isBusy
                            ? null
                            : () => a.onToggleConversationVoiceInput(),
                        style: IconButton.styleFrom(
                          backgroundColor: a.conversationVoiceListening
                              ? const Color(0xFFD4822A)
                              : Colors.white,
                          foregroundColor: a.conversationVoiceListening
                              ? Colors.white
                              : null,
                        ),
                        tooltip: a.conversationVoiceListening
                            ? 'Stop listening'
                            : 'Speak in ${a.translationTargetLang.value}',
                        icon: Icon(
                          a.conversationVoiceListening
                              ? Icons.stop_rounded
                              : Icons.mic_none_rounded,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: a.isBusy ? null : a.onSendConversation,
                        style: FilledButton.styleFrom(
                          backgroundColor: a.theme.accent,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: Text(a.isBusy ? '...' : '➤'),
                      ),
                    ],
                  ),
                ],
              ),
            );
}
