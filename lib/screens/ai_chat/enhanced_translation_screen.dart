import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/translation_history_model.dart';
import 'package:lingafriq/services/translation_history_service.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, PolieMode;
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart' as uuid;

/// Enhanced Translation Screen
/// Shows multiple alternatives, grammar breakdown, and cultural context
class EnhancedTranslationScreen extends HookConsumerWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final String? initialText;

  const EnhancedTranslationScreen({
    Key? key,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.initialText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController(text: initialText ?? '');
    final translationResult = useState<TranslationEntry?>(null);
    final isLoading = useState(false);
    final showAlternatives = useState(true);
    final showGrammar = useState(true);
    final showCultural = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyService = ref.read(translationHistoryServiceProvider);
    final chatProvider = ref.read(groqChatProvider.notifier);

    Future<void> translate() async {
      final text = textController.text.trim();
      if (text.isEmpty) return;

      isLoading.value = true;
      HapticFeedback.mediumImpact();

      try {
        // Set translation mode
        await chatProvider.setMode(PolieMode.translation);
        await chatProvider.setLanguageDirection(sourceLanguage, targetLanguage);

        // Get translation with enhanced prompt
        final response = await chatProvider.sendMessage(
          'Translate this with grammar breakdown, cultural context, and 3-5 alternative translations: "$text"',
        );

        // Parse response to extract translation, alternatives, grammar, and cultural context
        // This is a simplified version - in production, you'd parse the AI response more carefully
        final primaryTranslation = _extractPrimaryTranslation(response);
        final alternatives = _extractAlternatives(response);
        final grammarBreakdown = _extractGrammarBreakdown(response, text);
        final culturalContext = _extractCulturalContext(response);

        // Create translation entry
        final entry = TranslationEntry(
          id: const uuid.Uuid().v4(),
          sourceText: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          primaryTranslation: primaryTranslation,
          alternatives: alternatives,
          grammarBreakdown: grammarBreakdown,
          culturalContext: culturalContext,
          timestamp: DateTime.now(),
        );

        translationResult.value = entry;

        // Save to history
        await historyService.addTranslation(entry);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Translation failed: ${e.toString()}')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Translation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (translationResult.value != null)
            IconButton(
              icon: Icon(
                translationResult.value!.isFavorite ? Icons.star : Icons.star_border,
              ),
              onPressed: () async {
                await historyService.toggleFavorite(translationResult.value!.id);
                translationResult.value = translationResult.value!.copyWith(
                  isFavorite: !translationResult.value!.isFavorite,
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Input Section
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter text to translate...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                        filled: true,
                        fillColor: isDark ? PanAfricanColors.surfaceDark : Colors.white,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    ElevatedButton.icon(
                      onPressed: isLoading.value ? null : translate,
                      icon: isLoading.value
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.translate),
                      label: Text('Translate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                      ),
                    ),
                  ],
                ),
              ),

              // Results Section
              Expanded(
                child: translationResult.value == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.translate, size: 64.sp, color: PanAfricanColors.neutralMedium),
                            SizedBox(height: PanAfricanSpacing.md),
                            Text(
                              'Enter text to translate',
                              style: PanAfricanTypography.bodyLarge(context),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(PanAfricanSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Primary Translation
                            _PrimaryTranslationCard(
                              entry: translationResult.value!,
                              isDark: isDark,
                            )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.1),
                            SizedBox(height: PanAfricanSpacing.lg),

                            // Toggle Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: FilterChip(
                                    label: Text('Alternatives'),
                                    selected: showAlternatives.value,
                                    onSelected: (val) => showAlternatives.value = val,
                                  ),
                                ),
                                SizedBox(width: PanAfricanSpacing.sm),
                                Expanded(
                                  child: FilterChip(
                                    label: Text('Grammar'),
                                    selected: showGrammar.value,
                                    onSelected: (val) => showGrammar.value = val,
                                  ),
                                ),
                                SizedBox(width: PanAfricanSpacing.sm),
                                Expanded(
                                  child: FilterChip(
                                    label: Text('Culture'),
                                    selected: showCultural.value,
                                    onSelected: (val) => showCultural.value = val,
                                  ),
                                ),
                              ],
                            )
                                .animate(delay: 100.ms)
                                .fadeIn(duration: 300.ms),
                            SizedBox(height: PanAfricanSpacing.lg),

                            // Alternatives
                            if (showAlternatives.value && translationResult.value!.alternatives.isNotEmpty)
                              _AlternativesCard(
                                alternatives: translationResult.value!.alternatives,
                                isDark: isDark,
                              )
                                  .animate(delay: 200.ms)
                                  .fadeIn(duration: 300.ms)
                                  .slideX(begin: 0.1),

                            // Grammar Breakdown
                            if (showGrammar.value && translationResult.value!.grammarBreakdown.isNotEmpty) ...[
                              SizedBox(height: PanAfricanSpacing.lg),
                              _GrammarBreakdownCard(
                                breakdown: translationResult.value!.grammarBreakdown,
                                isDark: isDark,
                              )
                                  .animate(delay: 300.ms)
                                  .fadeIn(duration: 300.ms)
                                  .slideX(begin: -0.1),
                            ],

                            // Cultural Context
                            if (showCultural.value && translationResult.value!.culturalContext != null) ...[
                              SizedBox(height: PanAfricanSpacing.lg),
                              _CulturalContextCard(
                                context: translationResult.value!.culturalContext!,
                                isDark: isDark,
                              )
                                  .animate(delay: 400.ms)
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.1),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractPrimaryTranslation(String response) {
    // Enhanced extraction with multiple patterns
    final lines = response.split('\n');
    
    // Pattern 1: "Translation:" or "Primary Translation:"
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('translation:') || lower.contains('primary translation:') ||
          lower.contains('primary:')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          return parts.skip(1).join(':').trim();
        }
      }
    }
    
    // Pattern 2: Look for text in quotes after "translation"
    final quotePattern = RegExp(r'''["']([^"']+)["']''');
    for (final line in lines) {
      if (line.toLowerCase().contains('translation')) {
        final match = quotePattern.firstMatch(line);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }
    }
    
    // Pattern 3: First non-empty line that looks like a translation
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && 
          !trimmed.toLowerCase().startsWith('alternative') &&
          !trimmed.toLowerCase().startsWith('grammar') &&
          !trimmed.toLowerCase().startsWith('cultural') &&
          !trimmed.contains(':')) {
        return trimmed;
      }
    }
    
    return response.split('\n').first.trim();
  }

  List<TranslationAlternative> _extractAlternatives(String response) {
    final alternatives = <TranslationAlternative>[];
    final lines = response.split('\n');
    bool inAlternativesSection = false;
    
    for (final line in lines) {
      final trimmed = line.trim();
      final lower = trimmed.toLowerCase();
      
      // Detect alternatives section
      if (lower.contains('alternative') || lower.contains('variation')) {
        inAlternativesSection = true;
        continue;
      }
      
      // Stop at next section
      if (inAlternativesSection && 
          (lower.contains('grammar') || lower.contains('cultural') || 
           lower.contains('context'))) {
        break;
      }
      
      // Extract numbered alternatives
      if (inAlternativesSection || trimmed.startsWith(RegExp(r'^\d+[\.\)]'))) {
        final match = RegExp(r'^\d+[\.\)]\s*(.+)').firstMatch(trimmed);
        if (match != null) {
          final translation = match.group(1)?.trim() ?? '';
          if (translation.isNotEmpty) {
            alternatives.add(TranslationAlternative(
              translation: translation,
              context: _extractContextFromLine(trimmed),
            ));
          }
        }
      }
    }
    
    // If no structured alternatives found, try to extract from response
    if (alternatives.isEmpty) {
      final quotePattern = RegExp(r'''["']([^"']+)["']''');
      final matches = quotePattern.allMatches(response);
      for (final match in matches.skip(1).take(5)) {
        alternatives.add(TranslationAlternative(
          translation: match.group(1) ?? '',
        ));
      }
    }
    
    return alternatives.take(5).toList();
  }

  String? _extractContextFromLine(String line) {
    // Extract context in parentheses or after dash
    final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(line);
    if (parenMatch != null) {
      return parenMatch.group(1);
    }
    final dashMatch = RegExp(r'—\s*(.+)').firstMatch(line);
    if (dashMatch != null) {
      return dashMatch.group(1);
    }
    return null;
  }

  List<GrammarBreakdown> _extractGrammarBreakdown(String response, String sourceText) {
    final breakdown = <GrammarBreakdown>[];
    final lines = response.split('\n');
    bool inGrammarSection = false;
    final words = sourceText.split(RegExp(r'\s+'));
    
    for (final line in lines) {
      final trimmed = line.trim();
      final lower = trimmed.toLowerCase();
      
      // Detect grammar section
      if (lower.contains('grammar') || lower.contains('grammatical')) {
        inGrammarSection = true;
        continue;
      }
      
      // Stop at next section
      if (inGrammarSection && 
          (lower.contains('cultural') || lower.contains('context') ||
           lower.contains('alternative'))) {
        break;
      }
      
      // Extract grammar information
      if (inGrammarSection || trimmed.contains(':')) {
        // Pattern: "word: part of speech - explanation"
        final colonMatch = RegExp(r'^([^:]+):\s*(.+)').firstMatch(trimmed);
        if (colonMatch != null) {
          final word = colonMatch.group(1)?.trim() ?? '';
          final rest = colonMatch.group(2)?.trim() ?? '';
          
          // Extract part of speech
          final posMatch = RegExp(r'(noun|verb|adjective|adverb|pronoun|preposition|conjunction|interjection)', 
              caseSensitive: false).firstMatch(rest);
          final pos = posMatch?.group(1)?.toLowerCase() ?? 'unknown';
          
          // Extract explanation (everything after POS)
          final explanation = posMatch != null 
              ? rest.replaceFirst(posMatch.group(0) ?? '', '').trim()
              : rest;
          
          if (word.isNotEmpty) {
            breakdown.add(GrammarBreakdown(
              word: word,
              partOfSpeech: pos,
              root: _extractRoot(word),
              explanation: explanation.isNotEmpty ? explanation : null,
            ));
          }
        }
      }
    }
    
    // If no structured breakdown found, create basic breakdown from words
    if (breakdown.isEmpty && words.isNotEmpty) {
      for (final word in words.take(10)) {
        if (word.trim().isNotEmpty) {
          breakdown.add(GrammarBreakdown(
            word: word.trim(),
            partOfSpeech: 'unknown',
            root: word.trim().toLowerCase(),
            explanation: 'Grammar analysis for "${word.trim()}"',
          ));
        }
      }
    }
    
    return breakdown;
  }

  String _extractRoot(String word) {
    // Simple root extraction - in production, use morphological analysis
    return word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
  }

  CulturalContext? _extractCulturalContext(String response) {
    final lines = response.split('\n');
    bool inCulturalSection = false;
    String? context;
    String? usageNote;
    
    for (final line in lines) {
      final trimmed = line.trim();
      final lower = trimmed.toLowerCase();
      
      // Detect cultural section
      if (lower.contains('cultural') || lower.contains('culture')) {
        inCulturalSection = true;
        continue;
      }
      
      // Extract context
      if (inCulturalSection) {
        if (context == null && trimmed.isNotEmpty && 
            !trimmed.toLowerCase().startsWith('usage') &&
            !trimmed.toLowerCase().startsWith('note')) {
          context = trimmed;
        } else if (lower.contains('usage') || lower.contains('note')) {
          usageNote = trimmed;
        }
      }
    }
    
    // Also check for cultural information in the general response
    if (context == null) {
      final culturalKeywords = ['tradition', 'custom', 'practice', 'etiquette', 
                                'respect', 'honor', 'ceremony', 'ritual'];
      for (final line in lines) {
        for (final keyword in culturalKeywords) {
          if (line.toLowerCase().contains(keyword)) {
            context = line.trim();
            break;
          }
        }
        if (context != null) break;
      }
    }
    
    if (context != null || usageNote != null) {
      return CulturalContext(
        context: context,
        usageNote: usageNote,
      );
    }
    
    return null;
  }
}

class _PrimaryTranslationCard extends StatelessWidget {
  final TranslationEntry entry;
  final bool isDark;

  const _PrimaryTranslationCard({
    required this.entry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate, color: PanAfricanColors.primary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Translation',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              entry.sourceText,
              style: PanAfricanTypography.bodyLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              entry.primaryTranslation,
              style: PanAfricanTypography.headlineSmall(context)?.copyWith(
                fontWeight: FontWeight.bold,
                color: PanAfricanColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternativesCard extends StatelessWidget {
  final List<TranslationAlternative> alternatives;
  final bool isDark;

  const _AlternativesCard({
    required this.alternatives,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route, color: PanAfricanColors.secondary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Alternative Translations',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...alternatives.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: PanAfricanColors.secondary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: PanAfricanTypography.labelSmall(context)?.copyWith(
                            color: PanAfricanColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Text(
                        entry.value.translation,
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GrammarBreakdownCard extends StatelessWidget {
  final List<GrammarBreakdown> breakdown;
  final bool isDark;

  const _GrammarBreakdownCard({
    required this.breakdown,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: PanAfricanColors.accent),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Grammar Breakdown',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...breakdown.map((item) {
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.word,
                          style: PanAfricanTypography.titleSmall(context)?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Chip(
                          label: Text(item.partOfSpeech),
                          backgroundColor: PanAfricanColors.accent.withOpacity(0.1),
                          labelStyle: PanAfricanTypography.labelSmall(context)?.copyWith(
                            color: PanAfricanColors.accent,
                          ),
                        ),
                      ],
                    ),
                    if (item.explanation != null) ...[
                      SizedBox(height: PanAfricanSpacing.xs),
                      Text(
                        item.explanation!,
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CulturalContextCard extends StatelessWidget {
  final CulturalContext context;
  final bool isDark;

  const _CulturalContextCard({
    required this.context,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: PanAfricanColors.tertiary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Cultural Context',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            if (this.context.context != null) ...[
              Text(
                this.context.context!,
                style: PanAfricanTypography.bodyMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
            ],
            if (this.context.usageNote != null) ...[
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                decoration: BoxDecoration(
                  color: PanAfricanColors.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20.sp, color: PanAfricanColors.tertiary),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Text(
                        this.context.usageNote!,
                        style: PanAfricanTypography.bodySmall(context)?.copyWith(
                          color: PanAfricanColors.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

