import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/translation_history_model.dart';
import 'package:lingafriq/services/translation_history_service.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, PolieMode;
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

    // Set mode+language atomically ONCE on screen entry
    useEffect(() {
      chatProvider.setModeAndLanguage(
        mode: PolieMode.translation,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
      return null;
    }, []);

    Future<void> translate() async {
      final text = textController.text.trim();
      if (text.isEmpty) return;

      // Input validation
      if (text.length > 5000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text is too long. Please use fewer than 5000 characters.')),
        );
        return;
      }

      isLoading.value = true;
      HapticFeedback.mediumImpact();

      const maxRetries = 2;
      int retryCount = 0;
      String? lastError;

      while (retryCount <= maxRetries) {
        try {
          // Mode+language already set in useEffect init.
          // Do NOT call setModeAndLanguage per-translation.

          // Build structured prompt for better parsing
          final prompt = '''Translate the following text from $sourceLanguage to $targetLanguage.

Text to translate: "$text"

Please provide your response in this format:
1. Primary Translation: [your main translation]
2. Alternative Translations:
   - [alternative 1]
   - [alternative 2]
   - [alternative 3]
3. Grammar Breakdown:
   - [word]: [part of speech] - [explanation]
4. Cultural Context: [any relevant cultural notes]
5. Usage Note: [when/how to use this phrase]''';

          // Get translation with enhanced prompt
          final response = await chatProvider.sendMessage(prompt);

          // Validate response
          if (response.trim().isEmpty) {
            throw Exception('Empty response received');
          }

          // Parse response to extract components
          final primaryTranslation = _extractPrimaryTranslation(response);
          
          // Validate primary translation - retry if extraction failed
          if (primaryTranslation.isEmpty || primaryTranslation == text) {
            if (retryCount < maxRetries) {
              retryCount++;
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
              continue;
            }
          }
          
          final alternatives = _extractAlternatives(response);
          final grammarBreakdown = _extractGrammarBreakdown(response, text);
          final culturalContext = _extractCulturalContext(response);

          // Create translation entry
          final entry = TranslationEntry(
            id: const uuid.Uuid().v4(),
            sourceText: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            primaryTranslation: primaryTranslation.isNotEmpty ? primaryTranslation : text,
            alternatives: alternatives,
            grammarBreakdown: grammarBreakdown,
            culturalContext: culturalContext,
            timestamp: DateTime.now(),
          );

          translationResult.value = entry;

          // Save to history (non-blocking)
          historyService.addTranslation(entry).catchError((e) {
            debugPrint('Failed to save translation to history: $e');
          });
          
          // Success - exit retry loop
          isLoading.value = false;
          return;
        } catch (e) {
          lastError = e.toString();
          debugPrint('Translation attempt ${retryCount + 1} failed: $e');
          
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(Duration(milliseconds: 1000 * retryCount));
          } else {
            break;
          }
        }
      }
      
      // All retries failed
      isLoading.value = false;
      if (context.mounted) {
        final errorMessage = lastError?.contains('network') == true
            ? 'Network error. Please check your connection.'
            : lastError?.contains('timeout') == true
                ? 'Request timed out. Please try again.'
                : 'Translation failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: translate,
            ),
          ),
        );
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
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintText: 'Enter text to translate...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                        filled: true,
                        fillColor: isDark ? PanAfricanColors.surfaceDark : Theme.of(context).colorScheme.surface,
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
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

  /// Extracts the primary translation from AI response with robust fallbacks
  String _extractPrimaryTranslation(String response) {
    if (response.trim().isEmpty) return '';
    
    final lines = response.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return response.trim();
    
    // Priority patterns (ordered by likelihood)
    final patterns = [
      // Pattern 1: "Translation:", "Primary Translation:", "Result:"
      RegExp(r'(?:primary\s+)?translation\s*:\s*(.+)', caseSensitive: false),
      RegExp(r'result\s*:\s*(.+)', caseSensitive: false),
      // Pattern 2: Numbered with translation indicator
      RegExp(r'^1[\.\)]\s*(.+)', caseSensitive: false),
      // Pattern 3: Text in quotes (single or double)
      RegExp(r'''["「『]([^"」』]+)["」』]'''),
      // Pattern 4: **bold text** (markdown style)
      RegExp(r'\*\*([^*]+)\*\*'),
    ];
    
    for (final pattern in patterns) {
      for (final line in lines) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final result = match.group(1)?.trim() ?? '';
          if (result.isNotEmpty && result.length > 1) {
            return _cleanTranslation(result);
          }
        }
      }
    }
    
    // Pattern: Look for quoted text anywhere in response
    final quotePattern = RegExp(r'''["']([^"']+)["']''');
    for (final line in lines) {
      if (line.toLowerCase().contains('translat')) {
        final match = quotePattern.firstMatch(line);
        if (match != null && (match.group(1)?.length ?? 0) > 1) {
          return _cleanTranslation(match.group(1) ?? '');
        }
      }
    }
    
    // Fallback: Find first substantive line that's not a header
    final headerKeywords = ['alternative', 'grammar', 'cultural', 'context', 
                           'breakdown', 'note', 'usage', 'example'];
    for (final line in lines) {
      final trimmed = line.trim();
      final lower = trimmed.toLowerCase();
      
      // Skip headers and meta lines
      if (trimmed.length < 2) continue;
      if (headerKeywords.any((k) => lower.startsWith(k))) continue;
      if (lower.startsWith('#') || lower.startsWith('*')) continue;
      if (trimmed.endsWith(':')) continue;
      
      // This looks like content
      return _cleanTranslation(trimmed);
    }
    
    // Ultimate fallback: first line
    return _cleanTranslation(lines.first);
  }

  /// Clean up extracted translation text
  String _cleanTranslation(String text) {
    return text
        .replaceAll(RegExp(r'^[\d\.\)\-\*\#]+\s*'), '') // Remove leading numbers/bullets
        .replaceAll(RegExp(r'^(translation|primary|result)\s*:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\*+'), '') // Remove markdown bold
        .replaceAll(RegExp(r'^\s*["\x27]+|["\x27]+\s*$'), '') // Remove surrounding quotes
        .trim();
  }

  /// Extracts alternative translations with robust parsing
  List<TranslationAlternative> _extractAlternatives(String response) {
    final alternatives = <TranslationAlternative>[];
    final seen = <String>{}; // Dedupe
    final lines = response.split('\n');
    bool inAlternativesSection = false;
    
    // Section detection keywords
    final altKeywords = ['alternative', 'variation', 'other ways', 'also say', 
                         'other translation', 'could also be'];
    final endKeywords = ['grammar', 'cultural', 'context', 'breakdown', 
                         'note', 'usage', 'example'];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();
      
      // Detect alternatives section
      if (altKeywords.any((k) => lower.contains(k))) {
        inAlternativesSection = true;
        // Check if the same line contains an alternative after the keyword
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex > 0 && colonIndex < trimmed.length - 2) {
          final afterColon = trimmed.substring(colonIndex + 1).trim();
          if (afterColon.isNotEmpty && !seen.contains(afterColon.toLowerCase())) {
            seen.add(afterColon.toLowerCase());
            alternatives.add(TranslationAlternative(
              translation: _cleanTranslation(afterColon),
              context: _extractContextFromLine(afterColon),
            ));
          }
        }
        continue;
      }
      
      // Stop at next section
      if (inAlternativesSection && endKeywords.any((k) => lower.startsWith(k))) {
        break;
      }
      
      // Extract numbered/bulleted alternatives
      final numberedMatch = RegExp(r'^[\d\-\*\•]+[\.\):\s]+(.+)').firstMatch(trimmed);
      if (numberedMatch != null) {
        final translation = numberedMatch.group(1)?.trim() ?? '';
        if (translation.isNotEmpty && !seen.contains(translation.toLowerCase())) {
          seen.add(translation.toLowerCase());
          alternatives.add(TranslationAlternative(
            translation: _cleanTranslation(translation),
            context: _extractContextFromLine(translation),
          ));
        }
        continue;
      }
      
      // In alternatives section, treat any substantive line as an alternative
      if (inAlternativesSection && !lower.endsWith(':') && trimmed.length > 2) {
        if (!seen.contains(trimmed.toLowerCase())) {
          seen.add(trimmed.toLowerCase());
          alternatives.add(TranslationAlternative(
            translation: _cleanTranslation(trimmed),
            context: _extractContextFromLine(trimmed),
          ));
        }
      }
    }
    
    // Fallback: extract quoted strings
    if (alternatives.isEmpty) {
      final quotePatterns = [
        RegExp(r'''["']([^"']{2,50})["']'''),
        RegExp(r'''「([^」]{2,50})」'''),
        RegExp(r'''\*\*([^*]{2,50})\*\*'''),
      ];
      
      for (final pattern in quotePatterns) {
        final matches = pattern.allMatches(response);
        // Skip first match (likely primary translation)
        for (final match in matches.skip(1).take(5)) {
          final text = match.group(1) ?? '';
          if (text.isNotEmpty && !seen.contains(text.toLowerCase())) {
            seen.add(text.toLowerCase());
            alternatives.add(TranslationAlternative(
              translation: _cleanTranslation(text),
            ));
          }
        }
        if (alternatives.isNotEmpty) break;
      }
    }
    
    // Return max 5 unique alternatives
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

  /// Extracts grammar breakdown with robust parsing and intelligent fallbacks
  List<GrammarBreakdown> _extractGrammarBreakdown(String response, String sourceText) {
    final breakdown = <GrammarBreakdown>[];
    final seen = <String>{}; // Dedupe by word
    final lines = response.split('\n');
    bool inGrammarSection = false;
    
    // Section detection keywords
    final grammarKeywords = ['grammar', 'grammatical', 'breakdown', 'analysis', 
                             'structure', 'morpholog', 'word-by-word'];
    final endKeywords = ['cultural', 'context', 'alternative', 'note', 'usage'];
    
    // Parts of speech patterns (extended for African languages)
    final posPattern = RegExp(
      r'\b(noun|verb|adjective|adverb|pronoun|preposition|conjunction|interjection|'
      r'particle|prefix|suffix|root|stem|tense|aspect|marker|copula|determiner|'
      r'auxiliary|modal|gerund|infinitive|imperative|subjunctive)\b',
      caseSensitive: false,
    );
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();
      
      // Detect grammar section
      if (grammarKeywords.any((k) => lower.contains(k))) {
        inGrammarSection = true;
        continue;
      }
      
      // Stop at next section
      if (inGrammarSection && endKeywords.any((k) => lower.startsWith(k))) {
        break;
      }
      
      // Skip section headers
      if (trimmed.endsWith(':') && trimmed.length < 30) continue;
      
      // Try to extract grammar info from line
      GrammarBreakdown? entry = _parseGrammarLine(trimmed, posPattern);
      
      if (entry != null && !seen.contains(entry.word.toLowerCase())) {
        seen.add(entry.word.toLowerCase());
        breakdown.add(entry);
      }
    }
    
    // Fallback: Create basic breakdown from source text words
    if (breakdown.isEmpty && sourceText.isNotEmpty) {
      final words = sourceText.split(RegExp(r'\s+'))
          .where((w) => w.trim().length > 1)
          .take(8);
      
      for (final word in words) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w\u0080-\uFFFF]'), '');
        if (cleanWord.isNotEmpty && !seen.contains(cleanWord.toLowerCase())) {
          seen.add(cleanWord.toLowerCase());
          breakdown.add(GrammarBreakdown(
            word: cleanWord,
            partOfSpeech: 'word',
            root: _extractRoot(cleanWord),
            explanation: null, // Don't add fake explanations
          ));
        }
      }
    }
    
    return breakdown.take(15).toList(); // Limit to 15 entries
  }

  /// Parse a single line for grammar information
  GrammarBreakdown? _parseGrammarLine(String line, RegExp posPattern) {
    // Pattern 1: "word: part of speech - explanation"
    final colonMatch = RegExp(r'^[\*\-\•]?\s*([^:]+):\s*(.+)').firstMatch(line);
    if (colonMatch != null) {
      final word = colonMatch.group(1)?.trim() ?? '';
      final rest = colonMatch.group(2)?.trim() ?? '';
      
      if (word.isEmpty || word.length > 50) return null;
      
      final posMatch = posPattern.firstMatch(rest);
      final pos = posMatch?.group(1)?.toLowerCase() ?? 'word';
      final explanation = posMatch != null 
          ? rest.replaceFirst(posMatch.group(0) ?? '', '').replaceAll(RegExp(r'^[\s\-–—]+'), '').trim()
          : rest;
      
      return GrammarBreakdown(
        word: _cleanTranslation(word),
        partOfSpeech: pos,
        root: _extractRoot(word),
        explanation: explanation.isNotEmpty ? explanation : null,
      );
    }
    
    // Pattern 2: "word (part of speech): explanation"
    final parenMatch = RegExp(r'^[\*\-\•]?\s*([^\(]+)\(([^)]+)\):?\s*(.*)').firstMatch(line);
    if (parenMatch != null) {
      final word = parenMatch.group(1)?.trim() ?? '';
      final posText = parenMatch.group(2)?.trim() ?? '';
      final explanation = parenMatch.group(3)?.trim();
      
      if (word.isEmpty || word.length > 50) return null;
      
      final posMatch = posPattern.firstMatch(posText);
      final pos = posMatch?.group(1)?.toLowerCase() ?? posText.toLowerCase();
      
      return GrammarBreakdown(
        word: _cleanTranslation(word),
        partOfSpeech: pos.length <= 20 ? pos : 'word',
        root: _extractRoot(word),
        explanation: explanation?.isNotEmpty == true ? explanation : null,
      );
    }
    
    // Pattern 3: Numbered list "1. word - explanation"
    final numberedMatch = RegExp(r'^\d+[\.\)]\s*([^\-–—]+)[\-–—]\s*(.*)').firstMatch(line);
    if (numberedMatch != null) {
      final word = numberedMatch.group(1)?.trim() ?? '';
      final rest = numberedMatch.group(2)?.trim() ?? '';
      
      if (word.isEmpty || word.length > 50) return null;
      
      final posMatch = posPattern.firstMatch(rest);
      final pos = posMatch?.group(1)?.toLowerCase() ?? 'word';
      
      return GrammarBreakdown(
        word: _cleanTranslation(word),
        partOfSpeech: pos,
        root: _extractRoot(word),
        explanation: rest.isNotEmpty ? rest : null,
      );
    }
    
    return null;
  }

  String _extractRoot(String word) {
    // Simple root extraction - in production, use morphological analysis
    return word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
  }

  /// Extracts cultural context with robust parsing
  CulturalContext? _extractCulturalContext(String response) {
    final lines = response.split('\n');
    bool inCulturalSection = false;
    final contextParts = <String>[];
    String? usageNote;
    
    // Section detection keywords
    final culturalKeywords = ['cultural', 'culture', 'significance', 'meaning', 
                              'background', 'tradition'];
    final usageKeywords = ['usage', 'note', 'tip', 'remember', 'important', 
                           'caution', 'warning', 'polite', 'formal', 'informal'];
    final endKeywords = ['alternative', 'grammar', 'breakdown'];
    
    // Cultural topic indicators
    final culturalTopics = ['tradition', 'custom', 'practice', 'etiquette', 
                           'respect', 'honor', 'ceremony', 'ritual', 'elder',
                           'greeting', 'ancestor', 'community', 'family',
                           'blessing', 'proverb', 'saying', 'wisdom', 'social',
                           'polite', 'formal', 'informal', 'appropriate'];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();
      
      // Detect cultural section
      if (culturalKeywords.any((k) => lower.contains(k) && trimmed.endsWith(':'))) {
        inCulturalSection = true;
        continue;
      }
      if (culturalKeywords.any((k) => lower.startsWith(k))) {
        inCulturalSection = true;
        // Check if content follows the header on same line
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex > 0 && colonIndex < trimmed.length - 2) {
          final content = trimmed.substring(colonIndex + 1).trim();
          if (content.isNotEmpty) contextParts.add(content);
        }
        continue;
      }
      
      // Stop at next major section
      if (inCulturalSection && endKeywords.any((k) => lower.startsWith(k))) {
        break;
      }
      
      // Extract content in cultural section
      if (inCulturalSection) {
        // Check for usage notes
        if (usageKeywords.any((k) => lower.contains(k)) && usageNote == null) {
          final colonIndex = trimmed.indexOf(':');
          if (colonIndex > 0) {
            usageNote = trimmed.substring(colonIndex + 1).trim();
          } else {
            usageNote = trimmed;
          }
        } else if (!trimmed.endsWith(':') && trimmed.length > 10) {
          contextParts.add(_cleanTranslation(trimmed));
        }
      }
    }
    
    // Fallback: Search for cultural topic mentions anywhere in response
    if (contextParts.isEmpty) {
      for (final line in lines) {
        final lower = line.toLowerCase();
        if (culturalTopics.any((topic) => lower.contains(topic))) {
          final trimmed = line.trim();
          if (trimmed.length > 20 && trimmed.length < 500) {
            contextParts.add(_cleanTranslation(trimmed));
            if (contextParts.length >= 3) break; // Limit fallback content
          }
        }
      }
    }
    
    // Combine context parts
    final context = contextParts.isNotEmpty 
        ? contextParts.take(5).join(' ').trim()
        : null;
    
    // Clean up usage note
    if (usageNote != null) {
      usageNote = usageNote.replaceAll(RegExp(r'^(usage|note|tip|remember)[:\s]*', caseSensitive: false), '').trim();
      if (usageNote.isEmpty) usageNote = null;
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
                  style: PanAfricanTypography.titleMedium(context).copyWith(
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
              style: PanAfricanTypography.headlineSmall(context).copyWith(
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
                  style: PanAfricanTypography.titleMedium(context).copyWith(
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
                          style: PanAfricanTypography.labelSmall(context).copyWith(
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
                  style: PanAfricanTypography.titleMedium(context).copyWith(
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
                          style: PanAfricanTypography.titleSmall(context).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Chip(
                          label: Text(item.partOfSpeech),
                          backgroundColor: PanAfricanColors.accent.withOpacity(0.1),
                          labelStyle: PanAfricanTypography.labelSmall(context).copyWith(
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
                  style: PanAfricanTypography.titleMedium(context).copyWith(
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
                        style: PanAfricanTypography.bodySmall(context).copyWith(
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

