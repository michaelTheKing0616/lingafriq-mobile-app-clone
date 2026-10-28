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
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_conversation_composer.dart';

Widget buildPolieConversationModeSurface(PolieModeSurfaceArgs a) {
  final layout = a.layout();
      final l10n = AppLocalizations.of(a.context)!;
      return Container(
        key: a.key,
        color: const Color(0xFFF5F0E8),
        child: Column(
          children: [
            layout.introBanner(introDismissed: a.introDismissed, onDismissIntro: a.onDismissIntro),
            layout.errorBanner(a.modeError),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFD4822A),
                    child: Icon(Icons.smart_toy_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Polie',
                        style: layout.bodyStyle.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Online',
                        style: layout.bodyStyle.copyWith(
                          color: const Color(0xFF4A7C59),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: layout.isTinyPhone ? 88 : 120,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: a.languageRatio.clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7C59),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                // +1 slot reserved for the live streaming bubble when active.
                itemCount: a.conversationMessages.length +
                    (a.conversationStreamingActive ? 1 : 0),
                itemBuilder: (ctx, index) {
                  // Render the live streaming bubble as the last slot.
                  if (a.conversationStreamingActive &&
                      index == a.conversationMessages.length) {
                    final preview = a.conversationStreamingTarget.trim();
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: a.theme.border.withOpacity(0.45),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                preview.isEmpty
                                    ? 'Polie is typing…'
                                    : '$preview▎',
                                style: layout.bodyStyle.copyWith(
                                  color: const Color(0xFF2D1B0E),
                                  fontStyle: preview.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final item = a.conversationMessages[index];
                  if (item.userText != null) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4822A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          item.userText!,
                          style: layout.bodyStyle.copyWith(color: Colors.white),
                        ),
                      ),
                    );
                  }
                  final ai = item.ai!;
                  // Render dedicated error bubble with retry CTA when an AI
                  // turn represents a failed generation.
                  if (ai.isError) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4EC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD4822A).withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 18,
                                  color: Color(0xFFD4822A),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ai.errorMessage ??
                                        'Something went wrong. Try again.',
                                    style: layout.bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: a.isBusy
                                      ? null
                                      : () {
                                          final retryText =
                                              item.userMessageForRetry;
                                          if (retryText != null &&
                                              retryText.trim().isNotEmpty) {
                                            a.onSendConversation(retryText);
                                          }
                                        },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: a.theme.border.withOpacity(0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MarkdownBody(
                                  data: ai.messageTarget,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: layout.bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                    ),
                                    strong: layout.bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    em: layout.bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    listBullet: layout.bodyStyle.copyWith(
                                      color: const Color(0xFF2D1B0E),
                                    ),
                                    code: layout.bodyStyle.copyWith(
                                      color: const Color(0xFF7A4A20),
                                      backgroundColor:
                                          const Color(0xFFF5E5D0),
                                      fontFamily: 'monospace',
                                    ),
                                    blockSpacing: 6,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: () => a.onSpeakText(ai.messageTarget),
                                icon: const Icon(
                                  Icons.volume_up_outlined,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          if (ai.englishTranslation != null &&
                              ai.englishTranslation!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F0E8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: a.theme.border.withOpacity(0.55),
                                ),
                              ),
                              child: Text(
                                ai.englishTranslation!,
                                style: layout.bodyStyle.copyWith(
                                  color: const Color(0xFF3F2A1A),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          if (ai.correction.hasCorrection)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ai.correction.uxFeedbackLine(),
                                    style: layout.bodyStyle.copyWith(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if ((ai.correction.correction ?? '').isNotEmpty)
                                    Text(
                                      ai.correction.correction!,
                                      style: layout.bodyStyle.copyWith(
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (ai.newVocab.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E5D0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New words',
                                    style: layout.bodyStyle.copyWith(
                                      color: const Color(0xFF7A4A20),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: ai.newVocab.take(6).map((v) {
                                      return Tooltip(
                                        message: v.meaning.isEmpty
                                            ? v.word
                                            : '${v.word} — ${v.meaning}',
                                        child: InputChip(
                                          label: Text(
                                            v.word,
                                            style: TextStyle(
                                              fontSize:
                                                  layout.isTinyPhone ? 11 : 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          backgroundColor: Colors.white,
                                          side: BorderSide(
                                            color: const Color(0xFFD4822A)
                                                .withOpacity(0.5),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: a.isBusy
                                              ? null
                                              : () => a.onSpeakText(v.word),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (ai.suggestedReplies.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: ai.suggestedReplies
                                  .take(3)
                                  .map(
                                    (reply) => ActionChip(
                                      label: SizedBox(
                                        width: layout.isTinyPhone ? 140 : null,
                                        child: Text(
                                          reply,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: layout.isTinyPhone ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                      visualDensity: layout.isTinyPhone
                                          ? const VisualDensity(
                                              horizontal: -2,
                                              vertical: -2,
                                            )
                                          : null,
                                      onPressed: a.isBusy
                                          ? null
                                          : () => a.onSendConversation(reply),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: 'Copy',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: ai.messageTarget),
                                  );
                                  if (a.context.mounted) {
                                    ScaffoldMessenger.of(a.context).showSnackBar(
                                      const SnackBar(
                                        duration: Duration(seconds: 1),
                                        content: Text('Copied'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: 'Share',
                                onPressed: () async {
                                  await Share.share(ai.messageTarget);
                                },
                                icon: const Icon(
                                  Icons.ios_share_rounded,
                                  size: 16,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: 'Regenerate',
                                onPressed: a.isBusy
                                    ? null
                                    : () {
                                        // Locate the immediately preceding
                                        // user message and resend it.
                                        for (var i = index - 1; i >= 0; i--) {
                                          final prev =
                                              a.conversationMessages[i];
                                          if (prev.userText != null) {
                                            a.onSendConversation(prev.userText);
                                            return;
                                          }
                                        }
                                      },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            buildPolieConversationComposer(a, layout),
          ],
        ),
      );
}
