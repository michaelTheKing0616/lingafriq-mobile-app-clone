
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/features/polie_workspace/mode_surface/polie_workspace_mode_surface_args.dart';

Widget buildPolieVocabModeSurface(PolieModeSurfaceArgs a) {
  final layout = a.layout();
return Container(
        key: a.key,
        color: const Color(0xFF0F0A04),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                layout.introBanner(introDismissed: a.introDismissed, onDismissIntro: a.onDismissIntro),
                layout.errorBanner(a.modeError),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: layout.card(
                    color: Colors.white.withValues(alpha: 0.02),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 6,
                            spacing: 10,
                            children: [
                              Text(
                                a.vocabSetName.value,
                                style: layout.bodyStyle.copyWith(
                                  color: const Color(0xFFFAF3E0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${(10 - a.vocabDeckCount).clamp(0, 10)}/10 • $a.vocabDeckCount remaining',
                                style: layout.bodyStyle.copyWith(
                                  color: const Color(0xFFFAF3E0),
                                  fontSize: layout.isTinyPhone ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: ((10 - a.vocabDeckCount).clamp(0, 10)) / 10,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD4822A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final category in const [
                                'Core Daily Words',
                                'Travel',
                                'Food',
                                'Greetings',
                                'Business',
                                'Culture',
                              ])
                                ChoiceChip(
                                  label: Text(
                                    category,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  selected: a.vocabSetName.value == category,
                                  selectedColor: const Color(
                                    0xFFD4822A,
                                  ).withValues(alpha: 0.25),
                                  onSelected: (_) =>
                                      a.vocabSetName.value = category,
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: a.vocabDifficultyTarget.value,
                                    dropdownColor: const Color(0xFF1A130C),
                                    style: layout.bodyStyle.copyWith(
                                      color: const Color(0xFFFAF3E0),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'mixed',
                                        child: Text('Difficulty: Mixed'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'beginner',
                                        child: Text('Difficulty: Beginner'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'intermediate',
                                        child: Text('Difficulty: Intermediate'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'advanced',
                                        child: Text('Difficulty: Advanced'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        a.vocabDifficultyTarget.value = v;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => a.vocabReveal.value = !a.vocabReveal.value,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: layout.isTinyPhone
                            ? (layout.screenWidth - 24).clamp(260, 330).toDouble()
                            : 330,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A130C),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4822A).withValues(alpha: 0.35),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: a.vocabCard == null
                            ? Text(
                                'Tap "Next Word"',
                                style: layout.bodyStyle.copyWith(
                                  color: const Color(0xFFFAF3E0),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (a.vocabReveal.value)
                                    Text(
                                      '${a.vocabCard!.partOfSpeech.toUpperCase()} · ${a.vocabCard!.difficulty.toUpperCase()}',
                                      style: layout.bodyStyle.copyWith(
                                        color: const Color(0xFFF2C14E),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  else
                                    const Center(
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFFF2C14E),
                                        size: 26,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a.vocabCard!.word,
                                          style: GoogleFonts.jetBrainsMono(
                                            color: const Color(0xFFFAF3E0),
                                            fontSize: layout.isTinyPhone ? 44 : 56,
                                            letterSpacing:
                                                layout.isTinyPhone ? 1.0 : 1.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Listen to word',
                                        onPressed: () =>
                                            a.onSpeakText(a.vocabCard!.word),
                                        icon: const Icon(
                                          Icons.volume_up_outlined,
                                          color: Color(0xFFF2C14E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    a.vocabCard!.pronunciation,
                                    style: layout.bodyStyle.copyWith(
                                      color: const Color(0xFFF2C14E),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (!a.vocabReveal.value)
                                    Text(
                                      'Tap to reveal',
                                      style: layout.bodyStyle.copyWith(
                                        color: const Color(0xFFD8C9B7),
                                      ),
                                    ),
                                  if (a.vocabReveal.value) ...[
                                    const SizedBox(height: 10),
                                    layout.card(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    a.vocabCard!.english,
                                                    style: layout.bodyStyle.copyWith(
                                                      color: const Color(
                                                        0xFFFAF3E0,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    a.vocabCard!.example.target,
                                                    style: layout.bodyStyle.copyWith(
                                                      color: const Color(
                                                        0xFFFAF3E0,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    a.vocabCard!.example.english,
                                                    style: layout.bodyStyle.copyWith(
                                                      color: const Color(
                                                        0xFFD8C9B7,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Listen to example',
                                              onPressed: () => a.onSpeakText(
                                                a.vocabCard!.example.target,
                                              ),
                                              icon: const Icon(
                                                Icons.volume_up_outlined,
                                                color: Color(0xFFF2C14E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    layout.card(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          '💡 Memory Peg\n${a.vocabCard!.memoryPeg}',
                                          style: layout.bodyStyle.copyWith(
                                            color: const Color(0xFFF2C14E),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if ((a.vocabCard!.culturalNote ?? '')
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      layout.card(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            '🟢 Cultural Note\n${a.vocabCard!.culturalNote}',
                                            style: layout.bodyStyle.copyWith(
                                              color: const Color(0xFFFAF3E0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: polieSrsButton(
                              a.context,
                              'Again (1m)',
                              Colors.red.shade500,
                              a.isBusy ? null : () => a.onScoreSrs('again'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: polieSrsButton(
                              a.context,
                              'Hard (10m)',
                              Colors.orange.shade600,
                              a.isBusy ? null : () => a.onScoreSrs('hard'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: polieSrsButton(
                              a.context,
                              'Good (1d)',
                              Colors.green.shade600,
                              a.isBusy ? null : () => a.onScoreSrs('good'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: polieSrsButton(
                              a.context,
                              'Easy (4d)',
                              Colors.blue.shade600,
                              a.isBusy ? null : () => a.onScoreSrs('easy'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last SRS choice: ${a.vocabSrsChoice ?? '-'}',
                        style: layout.bodyStyle.copyWith(
                          color: const Color(0xFFFAF3E0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: a.isBusy ? null : a.onLoadVocabCard,
                        style: FilledButton.styleFrom(
                          backgroundColor: a.theme.accent,
                        ),
                        child: Text(a.isBusy ? '...' : 'Next Word'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    
}
