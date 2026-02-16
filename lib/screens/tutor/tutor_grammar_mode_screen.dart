import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show AppLanguage;
import 'package:lingafriq/config/url_constants.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Normalizes the grammar result from AI to ensure all required fields exist.
Map<String, dynamic> normalizeGrammarResult(Map<String, dynamic> parsed) {
  return {
    'canonicalRule': parsed['canonicalRule']?.toString() ?? '',
    'grammarTree': parsed['grammarTree']?.toString() ?? '',
    'sentenceAnatomy': (parsed['sentenceAnatomy'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    'compareENFR': parsed['compareENFR']?.toString() ?? '',
    'examples': (parsed['examples'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    'commonMistakes': (parsed['commonMistakes'] as List?)?.cast<String>() ?? [],
    'practice': (parsed['practice'] as List?)?.cast<Map<String, dynamic>>() ?? [],
  };
}

/// Common grammar topics for autocomplete (African languages + general).
const List<String> _kGrammarTopicSuggestions = [
  'Verb conjugation', 'Present tense', 'Past tense', 'Future tense',
  'Noun classes', 'Noun agreement', 'Plural formation', 'Subject markers',
  'Object markers', 'Possessive pronouns', 'Demonstratives', 'Adjectives',
  'Word order', 'Questions', 'Negation', 'Imperative mood', 'Conditionals',
  'Relative clauses', 'Tone and meaning', 'Honorifics', 'Greetings',
  'Politeness markers', 'Proverbs and idioms',
];

/// Grammar Explanation Mode Screen — knowledge card, topic autocomplete, lesson view, Try It drawer.
class TutorGrammarModeScreen extends HookConsumerWidget {
  const TutorGrammarModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicController = useTextEditingController();
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final userLevel = useState('A1');
    final isLoading = useState(false);
    final grammarResult = useState<Map<String, dynamic>?>(null);
    final availableLanguages = AppLanguage.values;
    final topicInput = useState('');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTopics = _kGrammarTopicSuggestions
        .where((s) =>
            s.toLowerCase().contains(topicInput.value.trim().toLowerCase()))
        .toList();

    Future<Map<String, dynamic>> generateGrammarWithGroq({
      required String topic,
      required String language,
      required String userLevel,
    }) async {
      final groqKey = EnvConfig.groqApiKey;
      final useBackend = groqKey.isEmpty ||
          groqKey.trim().isEmpty ||
          groqKey == 'YOUR_GROQ_API_KEY' ||
          groqKey.startsWith('YOUR_');
      final prompt = '''
You are Polie, an elite African language tutor.
Generate a world-class grammar explanation for the following topic.

LANGUAGE: $language
CEFR_LEVEL: $userLevel
TOPIC: $topic

Return STRICT JSON ONLY (no markdown, no code fences) in this exact shape:
{
  "canonicalRule": "1-3 sentence rule explanation, concise but complete",
  "grammarTree": "A short syntax tree or structure diagram in text (e.g. S -> NP VP, or one line per level). Show how a typical sentence in this topic is structured.",
  "sentenceAnatomy": [
    {"part": "exact word or phrase from an example", "label": "Subject|Verb|Object|Modifier|Particle|etc.", "colorHint": "subject"},
    {"part": "...", "label": "...", "colorHint": "verb"}
  ],
  "compareENFR": "2-4 sentences: how this grammar differs in English vs French vs $language (word order, markers, etc.).",
  "examples": [
    {"target": "Example sentence in $language (with correct diacritics if applicable)", "translation": "English translation"},
    {"target": "...", "translation": "..."}
  ],
  "commonMistakes": ["Mistake 1", "Mistake 2", "Mistake 3"],
  "practice": [
    {"prompt": "Exercise prompt", "answer": "Correct answer"},
    {"prompt": "Exercise prompt", "answer": "Correct answer"}
  ]
}

Quality requirements:
- Use correct orthography/diacritics for Yoruba/Igbo/Twi.
- Examples must be realistic and culturally appropriate.
- Practice must be answerable and aligned to the rule.
''';

      // Use backend proxy when app has no Groq key or placeholder
      if (useBackend) {
        final resp = await ApiService.post(
          '/api/ai/chat/completion',
          data: {
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'systemPrompt': 'You output only valid JSON. Never include markdown or commentary.',
            'temperature': 0.2,
            'max_tokens': 900,
          },
        );
        if (resp.statusCode != 200 || resp.data == null) {
          throw Exception('AI request failed. Please try again.');
        }
        final content = (resp.data is Map)
            ? (resp.data['content']?.toString() ?? '')
            : '';
        if (content.trim().isEmpty) throw Exception('AI returned an empty response. Please try again.');
        Map<String, dynamic>? parsed;
        try {
          parsed = jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}');
          if (start >= 0 && end > start) {
            parsed = jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
          }
        }
        if (parsed == null || parsed.isEmpty) {
          return {
            'canonicalRule': content.trim(),
            'examples': const [],
            'commonMistakes': const [],
            'practice': const [],
          };
        }
        return normalizeGrammarResult(parsed);
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      final resp = await dio.post(
        UrlConstants.groqChatCompletions,
        data: {
          'model': 'llama-3.3-70b-versatile',
          'temperature': 0.2,
          'max_tokens': 900,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You output only valid JSON. Never include markdown or commentary.',
            },
            {'role': 'user', 'content': prompt},
          ],
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $groqKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (resp.statusCode != 200) {
        throw Exception('AI request failed (${resp.statusCode}). Please try again.');
      }

      final content = (resp.data is Map)
          ? (resp.data['choices']?[0]?['message']?['content']?.toString() ?? '')
          : '';

      if (content.trim().isEmpty) {
        throw Exception('AI returned an empty response. Please try again.');
      }

      Map<String, dynamic>? parsed;
      try {
        parsed = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        // Attempt to extract the first JSON object if the model emitted extra text.
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start >= 0 && end > start) {
          parsed = jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
        }
      }

      if (parsed == null || parsed.isEmpty) {
        return {
          'canonicalRule': content.trim(),
          'examples': const [],
          'commonMistakes': const [],
          'practice': const [],
        };
      }
      return normalizeGrammarResult(parsed);
    }

    Future<void> explainGrammar() async {
      if (topicController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a grammar topic')),
        );
        return;
      }

      isLoading.value = true;
      await safeAsync(
        context: context,
        operation: () async {
          grammarResult.value = await generateGrammarWithGroq(
            topic: topicController.text,
            language: selectedLanguage.value.name,
            userLevel: userLevel.value,
          );
        },
        errorContext: 'explainGrammar',
        showError: true,
      );
      isLoading.value = false;
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Generating grammar explanation...',
        child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PolieColors.primary,
                PolieColors.primaryDark,
                PolieColors.obsidian,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PolieSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PolieGlassCard(
                    padding: EdgeInsets.all(PolieSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: topicController,
                          onChanged: (v) => topicInput.value = v,
                          decoration: InputDecoration(
                            hintText: 'e.g., verb conjugation, noun cases, tenses',
                            hintStyle: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: PolieTypography.body(context),
                        ),
                        if (filteredTopics.isNotEmpty) ...[
                          SizedBox(height: PolieSpacing.sm),
                          Text(
                            'Suggestions',
                            style: PolieTypography.label(context).copyWith(
                              color: PolieColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: PolieSpacing.xs),
                          Wrap(
                            spacing: PolieSpacing.xs,
                            runSpacing: PolieSpacing.xs,
                            children: filteredTopics.take(8).map((topic) {
                              return Semantics(
                                label: 'Select topic: $topic',
                                button: true,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    topicController.text = topic;
                                    topicInput.value = topic;
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: PolieSpacing.sm,
                                      vertical: PolieSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PolieColors.royalAmethyst.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(PolieRadius.pill),
                                      border: Border.all(
                                        color: PolieColors.royalAmethyst.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      topic,
                                      style: PolieTypography.bodySmall(context),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: PolieSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: PolieLanguagePill(
                          label: selectedLanguage.value.name,
                          regionTag: SupportedLanguages.getCountry(selectedLanguage.value.code),
                          isSelected: true,
                          accentColor: polieAccentForLanguage(
                            SupportedLanguages.getKeyFromCode(selectedLanguage.value.code) ?? selectedLanguage.value.name.toLowerCase(),
                          ),
                          onTap: () => _showLanguagePicker(context, availableLanguages, selectedLanguage.value, (v) => selectedLanguage.value = v),
                        ),
                      ),
                      SizedBox(width: PolieSpacing.sm),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm),
                          decoration: BoxDecoration(
                            color: PolieColors.surfaceContainerLight,
                            borderRadius: BorderRadius.circular(PolieRadius.md),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: userLevel.value,
                              isExpanded: true,
                              dropdownColor: PolieColors.surfaceContainer,
                              items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                                  .map((l) => DropdownMenuItem(value: l, child: Text(l, style: PolieTypography.label(context))))
                                  .toList(),
                              onChanged: (v) { if (v != null) userLevel.value = v; },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PolieSpacing.lg),
                  Center(
                    child: Semantics(
                      label: 'Generate grammar explanation',
                      button: true,
                      child: PoliePrimaryButton(
                        label: 'Explain Grammar',
                        loading: isLoading.value,
                        enabled: !isLoading.value,
                        icon: Icons.menu_book_rounded,
                        onPressed: explainGrammar,
                      ),
                    ),
                  ),
                  if (grammarResult.value != null) ...[
                    SizedBox(height: PolieSpacing.xl),
                    _buildGrammarResult(context, grammarResult.value!, isDark, userLevel.value)
                        .animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    List<AppLanguage> languages,
    AppLanguage current,
    void Function(AppLanguage) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? PolieColors.surfaceContainer : Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
        ),
        padding: EdgeInsets.symmetric(vertical: PolieSpacing.lg),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select language', style: PolieTypography.h2(ctx)),
              SizedBox(height: PolieSpacing.md),
              ...languages.map((lang) => ListTile(
                title: Text(lang.name, style: PolieTypography.body(ctx)),
                onTap: () { HapticFeedback.selectionClick(); onSelected(lang); Navigator.pop(ctx); },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showTryItDrawer(BuildContext context, List<dynamic> practice, String userLevel) {
    if (practice.isEmpty) return;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TryItDrawerContent(
        practice: practice,
        userLevel: userLevel,
      ),
    );
  }

  Widget _buildGrammarResult(
    BuildContext context,
    Map<String, dynamic> result,
    bool isDark,
    String userLevel,
  ) {
    final practiceList = result['practice'] is List ? result['practice'] as List : <dynamic>[];
    return PolieGlassCard(
      hasGlow: true,
      glowColor: PolieColors.goldEmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Rule', style: PolieTypography.h2(context))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.xs),
                decoration: BoxDecoration(
                  color: PolieColors.goldEmber.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(PolieRadius.pill),
                  border: Border.all(color: PolieColors.goldEmber.withOpacity(0.5)),
                ),
                child: Text(
                  'Lesson view',
                  style: PolieTypography.label(context).copyWith(
                    color: PolieColors.goldEmber,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.sm),
          Text(result['canonicalRule'] ?? '', style: PolieTypography.body(context)),
          if (result['grammarTree'] != null && (result['grammarTree'] as String).trim().isNotEmpty) ...[
            SizedBox(height: PolieSpacing.md),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.sm),
            Text('Structure', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.xs),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(PolieSpacing.md),
              decoration: BoxDecoration(
                color: PolieColors.obsidian.withOpacity(0.5),
                borderRadius: BorderRadius.circular(PolieRadius.sm),
                border: Border.all(color: PolieColors.goldEmber.withOpacity(0.3)),
              ),
              child: SelectableText(
                result['grammarTree'].toString().trim(),
                style: PolieTypography.bodySmall(context).copyWith(height: 1.4),
              ),
            ),
          ],
          if (result['sentenceAnatomy'] != null && (result['sentenceAnatomy'] as List).isNotEmpty) ...[
            SizedBox(height: PolieSpacing.md),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.sm),
            Text('Sentence anatomy', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.xs),
            Wrap(
              spacing: PolieSpacing.xs,
              runSpacing: PolieSpacing.xs,
              children: (result['sentenceAnatomy'] as List).map((e) {
                final m = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
                final part = m['part']?.toString() ?? '';
                final label = m['label']?.toString() ?? '';
                final hint = (m['colorHint']?.toString() ?? '').toLowerCase();
                Color color = PolieColors.royalAmethyst;
                if (hint.contains('subject')) {
                  color = PolieColors.electricTeal;
                } else if (hint.contains('verb')) {
                  color = PolieColors.goldEmber;
                } else if (hint.contains('object')) {
                  color = PolieColors.royalAmethyst;
                }
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.xs),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PolieRadius.sm),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text('$part ($label)', style: PolieTypography.bodySmall(context).copyWith(color: color)),
                );
              }).toList(),
            ),
          ],
          if (result['compareENFR'] != null && (result['compareENFR'] as String).trim().isNotEmpty) ...[
            SizedBox(height: PolieSpacing.md),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.sm),
            Text('Compare EN / FR', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.xs),
            Container(
              padding: EdgeInsets.all(PolieSpacing.sm),
              decoration: BoxDecoration(
                color: PolieColors.electricTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(PolieRadius.sm),
                border: Border.all(color: PolieColors.electricTeal.withOpacity(0.3)),
              ),
              child: Text(result['compareENFR'].toString().trim(), style: PolieTypography.bodySmall(context)),
            ),
          ],
          SizedBox(height: PolieSpacing.lg),
          if (result['examples'] != null && (result['examples'] as List).isNotEmpty) ...[
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.md),
            Text('Examples', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.sm),
            ...(result['examples'] as List).map((example) {
              final ex = example as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: PolieSpacing.sm),
                child: Container(
                  padding: EdgeInsets.all(PolieSpacing.sm),
                  decoration: BoxDecoration(
                    color: PolieColors.surfaceContainerLight,
                    borderRadius: BorderRadius.circular(PolieRadius.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex['target'] ?? '', style: PolieTypography.body(context)),
                      if (ex['translation'] != null && ex['translation'].toString().isNotEmpty)
                        Text(ex['translation'] ?? '', style: PolieTypography.bodySmall(context)),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (result['commonMistakes'] != null && (result['commonMistakes'] as List).isNotEmpty) ...[
            SizedBox(height: PolieSpacing.lg),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.md),
            Text('Common Mistakes', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.sm),
            ...(result['commonMistakes'] as List).map((mistake) => Padding(
              padding: EdgeInsets.only(bottom: PolieSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: PolieColors.error, size: 20),
                  SizedBox(width: PolieSpacing.xs),
                  Expanded(child: Text(mistake.toString(), style: PolieTypography.bodySmall(context))),
                ],
              ),
            )),
          ],
          if (result['practice'] != null && (result['practice'] as List).isNotEmpty) ...[
            SizedBox(height: PolieSpacing.lg),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.md),
            Row(
              children: [
                Text('Practice', style: PolieTypography.label(context)),
                SizedBox(width: PolieSpacing.md),
                Text(
                  'Level $userLevel',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: PolieSpacing.sm),
            ...(result['practice'] as List).map((exercise) {
              final ex = exercise as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: PolieSpacing.sm),
                child: Container(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  decoration: BoxDecoration(
                    color: PolieColors.royalAmethyst.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(PolieRadius.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex['prompt'] ?? '', style: PolieTypography.body(context)),
                      SizedBox(height: PolieSpacing.xs),
                      Text('Answer: ${ex['answer'] ?? ''}', style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.royalAmethyst)),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: PolieSpacing.sm),
            Center(
              child: PoliePrimaryButton(
                label: 'Try It',
                icon: Icons.touch_app_rounded,
                onPressed: () => _showTryItDrawer(context, practiceList, userLevel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Try It drawer — micro-exercise: prompt, user input, reveal answer.
class _TryItDrawerContent extends StatefulWidget {
  final List<dynamic> practice;
  final String userLevel;

  const _TryItDrawerContent({
    required this.practice,
    required this.userLevel,
  });

  @override
  State<_TryItDrawerContent> createState() => _TryItDrawerContentState();
}

class _TryItDrawerContentState extends State<_TryItDrawerContent> {
  late int _index;
  final _answerController = TextEditingController();
  var _revealed = false;

  @override
  void initState() {
    super.initState();
    _index = 0;
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _current {
    final list = widget.practice;
    if (list.isEmpty) return {};
    final i = _index % list.length;
    return list[i] is Map<String, dynamic>
        ? list[i] as Map<String, dynamic>
        : {};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prompt = _current['prompt']?.toString() ?? '';
    final answer = _current['answer']?.toString() ?? '';
    final hasNext = widget.practice.length > 1;

    return Container(
      padding: EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
        border: Border.all(color: PolieColors.royalAmethyst.withOpacity(0.3)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Try It',
                  style: PolieTypography.h2(context),
                ),
                SizedBox(width: PolieSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: PolieColors.goldEmber.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(PolieRadius.pill),
                  ),
                  child: Text(
                    '${_index + 1}/${widget.practice.length}',
                    style: PolieTypography.bodySmall(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: PolieSpacing.md),
            PolieGlassCard(
              padding: EdgeInsets.all(PolieSpacing.md),
              child: Text(prompt, style: PolieTypography.body(context)),
            ),
            SizedBox(height: PolieSpacing.md),
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                hintStyle: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(PolieRadius.md)),
                filled: true,
                fillColor: isDark ? PolieColors.obsidian.withOpacity(0.5) : Theme.of(context).colorScheme.surface.withOpacity(0.9),
              ),
              style: PolieTypography.body(context),
              maxLines: 2,
            ),
            SizedBox(height: PolieSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PoliePrimaryButton(
                    label: _revealed ? 'Correct answer' : 'Reveal answer',
                    icon: _revealed ? Icons.check_circle : Icons.visibility,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _revealed = true);
                    },
                  ),
                ),
                if (hasNext) ...[
                  SizedBox(width: PolieSpacing.sm),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_rounded, color: PolieColors.royalAmethyst),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _answerController.clear();
                      setState(() {
                        _index = (_index + 1) % widget.practice.length;
                        _revealed = false;
                      });
                    },
                  ),
                ],
              ],
            ),
            if (_revealed)
              Padding(
                padding: EdgeInsets.only(top: PolieSpacing.md),
                child: PolieGlassCard(
                  hasGlow: true,
                  glowColor: PolieColors.electricTeal,
                  padding: EdgeInsets.all(PolieSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Answer', style: PolieTypography.label(context)),
                      SizedBox(height: PolieSpacing.xs),
                      Text(answer, style: PolieTypography.body(context)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

