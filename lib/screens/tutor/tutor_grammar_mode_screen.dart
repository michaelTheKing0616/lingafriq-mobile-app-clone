import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Grammar Explanation Mode Screen
class TutorGrammarModeScreen extends HookConsumerWidget {
  const TutorGrammarModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicController = useTextEditingController();
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final userLevel = useState('A1');
    final isLoading = useState(false);
    final grammarResult = useState<Map<String, dynamic>?>(null);
    final localizationService = useMemoized(() => DynamicLocalizationService());
    final availableLanguages = AppLanguage.values;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<Map<String, dynamic>> _generateGrammarWithGroq({
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
        if (parsed == null || parsed.isEmpty) throw Exception('AI returned an invalid format. Please try again.');
        return {
          'canonicalRule': parsed['canonicalRule']?.toString() ?? '',
          'examples': (parsed['examples'] is List) ? parsed['examples'] : const [],
          'commonMistakes':
              (parsed['commonMistakes'] is List) ? parsed['commonMistakes'] : const [],
          'practice': (parsed['practice'] is List) ? parsed['practice'] : const [],
        };
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      final resp = await dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.1-70b-versatile',
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
        throw Exception('AI returned an invalid format. Please try again.');
      }

      // Normalize and defend against shape drift.
      return {
        'canonicalRule': parsed['canonicalRule']?.toString() ?? '',
        'examples': (parsed['examples'] is List) ? parsed['examples'] : const [],
        'commonMistakes':
            (parsed['commonMistakes'] is List) ? parsed['commonMistakes'] : const [],
        'practice': (parsed['practice'] is List) ? parsed['practice'] : const [],
      };
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
          grammarResult.value = await _generateGrammarWithGroq(
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
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Topic Input
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Grammar Topic',
                hintText: 'e.g., verb conjugation, noun cases, tenses',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                filled: true,
                fillColor: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
              ),
              style: PanAfricanTypography.bodyLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),

            // Language and Level Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<AppLanguage>(
                    value: selectedLanguage.value,
                    decoration: InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? PanAfricanColors.surfaceContainerDark
                          : PanAfricanColors.surfaceContainerLight,
                    ),
                    items: availableLanguages.map((lang) => DropdownMenuItem<AppLanguage>(
                      value: lang,
                      child: Text(
                        lang.name.substring(0, 1).toUpperCase() + lang.name.substring(1),
                      ),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) selectedLanguage.value = value;
                    },
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: userLevel.value,
                    decoration: InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? PanAfricanColors.surfaceContainerDark
                          : PanAfricanColors.surfaceContainerLight,
                    ),
                    items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) userLevel.value = value;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.lg),

            // Explain Button
            ElevatedButton(
              onPressed: isLoading.value ? null : explainGrammar,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
              ),
              child: isLoading.value
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Explain Grammar',
                      style: PanAfricanTypography.labelLarge(context)
                          .copyWith(color: Colors.white),
                    ),
            ),
            SizedBox(height: PanAfricanSpacing.xl),

            // Grammar Result
            if (grammarResult.value != null)
              _buildGrammarResult(
                context,
                grammarResult.value!,
                isDark,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
          ],
        ), // closes Column
      ), // closes SingleChildScrollView
    ), // closes Container
  ); // closes LoadingOverlay
  }

  Widget _buildGrammarResult(
    BuildContext context,
    Map<String, dynamic> result,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Canonical Rule
          Text(
            'Rule',
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            result['canonicalRule'] ?? '',
            style: PanAfricanTypography.bodyLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.lg),

          // Examples
          if (result['examples'] != null && (result['examples'] as List).isNotEmpty) ...[
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Examples',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['examples'] as List).map((example) {
              final ex = example as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                child: ListTile(
                  title: Text(
                    ex['target'] ?? '',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  subtitle: Text(
                    ex['translation'] ?? '',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ),
              );
            }),
          ],

          // Common Mistakes
          if (result['commonMistakes'] != null &&
              (result['commonMistakes'] as List).isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Common Mistakes',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['commonMistakes'] as List).map((mistake) {
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: PanAfricanColors.warning,
                      size: 20.sp,
                    ),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Expanded(
                      child: Text(
                        mistake,
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Practice Exercises
          if (result['practice'] != null && (result['practice'] as List).isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Practice',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['practice'] as List).map((exercise) {
              final ex = exercise as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex['prompt'] ?? '',
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.xs),
                      Text(
                        'Answer: ${ex['answer'] ?? ''}',
                        style: PanAfricanTypography.bodySmall(context)
                            .copyWith(color: PanAfricanColors.primary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ], // closes Column children
      ), // closes Column
    ); // closes Container
  }
}

