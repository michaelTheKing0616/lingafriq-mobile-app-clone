
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_args.dart';

Widget buildPolieRoleplayModeSurface(PolieModeSurfaceArgs a) {
  final layout = a.layout();
      final sceneSubtitle = <String, String>{
        'Market': 'Bargain for goods with a friendly vendor',
        'Restaurant': 'Order naturally and ask follow-up questions',
        'Meeting Elder': 'Use respectful phrases and proper tone',
        'Job Interview': 'Answer clearly and confidently',
        'Family Dinner': 'Keep the tone warm and social',
      };
      return Container(
        key: a.key,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A04), Color(0xFF1A130C)],
          ),
        ),
        child: Column(
          children: [
            layout.introBanner(introDismissed: a.introDismissed, onDismissIntro: a.onDismissIntro),
            layout.errorBanner(a.modeError),
            Container(
              width: double.infinity,
              height: layout.isPhone ? 124 : 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8E2E09), Color(0xFFE09A18)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'At the ${a.roleplayScene.value}',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: layout.isPhone ? 26 : 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Change Scene'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sceneSubtitle[a.roleplayScene.value] ??
                          'Practice natural conversation in a.context',
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 24, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (ctx, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(
                    opacity: (1 - (value / 24)).clamp(0, 1),
                    child: child,
                  ),
                );
              },
              child: layout.card(
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFD4822A),
                        child: Text(
                          'MB',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mama Bisi',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Friendly, patient vendor',
                              style: GoogleFonts.nunito(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(
                              'Bilingual',
                              style: TextStyle(fontSize: layout.isTinyPhone ? 11 : 12),
                            ),
                            backgroundColor: const Color(0xFF2BDB8C),
                            visualDensity: layout.isTinyPhone
                                ? const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  )
                                : null,
                          ),
                          Chip(
                            label: Text(
                              'Hints',
                              style: TextStyle(fontSize: layout.isTinyPhone ? 11 : 12),
                            ),
                            visualDensity: layout.isTinyPhone
                                ? const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  )
                                : null,
                          ),
                          Chip(
                            label: Text(
                              'Immersion',
                              style: TextStyle(fontSize: layout.isTinyPhone ? 11 : 12),
                            ),
                            visualDensity: layout.isTinyPhone
                                ? const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: layout.card(
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: a.roleplayMessages.length,
                  itemBuilder: (ctx, index) {
                    final item = a.roleplayMessages[index];
                    if (item.userText != null) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4663A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.userText!,
                            style: layout.bodyStyle.copyWith(color: Colors.white),
                          ),
                        ),
                      );
                    }
                    final ai = item.ai!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15110D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4822A).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  ai.characterResponse.targetLang,
                                  style: layout.bodyStyle.copyWith(
                                    color: const Color(0xFFFAF3E0),
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
                                tooltip: 'Listen',
                                onPressed: () => a.onSpeakText(
                                  ai.characterResponse.targetLang,
                                ),
                                icon: const Icon(
                                  Icons.volume_up_outlined,
                                  color: Color(0xFFF2C14E),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'English: ${ai.characterResponse.english}',
                            style: layout.bodyStyle.copyWith(
                              color: const Color(0xFFD8C9B7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ai.coaching.feedbackType.toUpperCase()} • ${ai.coaching.userAccuracy}',
                            style: layout.bodyStyle.copyWith(
                              color: const Color(0xFFF2C14E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ai.coaching.feedback,
                            style: layout.bodyStyle.copyWith(
                              color: const Color(0xFFF2E6D7),
                            ),
                          ),
                          if ((ai.coaching.betterPhrasing ?? '').isNotEmpty)
                            Text(
                              'Try: ${ai.coaching.betterPhrasing}',
                              style: layout.monoStyle.copyWith(
                                color: const Color(0xFFFAF3E0),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                color: Colors.black.withValues(alpha: 0.28),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: a.roleplayInput,
                    style: const TextStyle(color: Color(0xFFFAF3E0)),
                    decoration: polieInputDecoration(a.theme, 'Speak your line...')
                        .copyWith(
                          hintStyle: const TextStyle(color: Color(0xFFD8C9B7)),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  icon: const Icon(Icons.mic_none_rounded, color: Colors.white),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: a.isBusy ? null : a.onSendRoleplay,
                  style: FilledButton.styleFrom(
                    backgroundColor: a.theme.accent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: Text(a.isBusy ? '...' : '🌐'),
                ),
              ],
            ),
          ],
        ),
      );
    
}
