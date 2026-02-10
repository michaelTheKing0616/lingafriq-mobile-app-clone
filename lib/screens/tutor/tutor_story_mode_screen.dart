import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/config/url_constants.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Story Mode — cultural banner, paragraph reveal, tap-for-translation, TTS narration, moral card, save to library, alternate endings.
class TutorStoryModeScreen extends HookConsumerWidget {
  const TutorStoryModeScreen({Key? key}) : super(key: key);

  static const String _kSavedStoriesKey = 'polie_saved_stories';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = useTextEditingController();
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final userLevel = useState('A1');
    final isLoading = useState(false);
    final storyResult = useState<Map<String, dynamic>?>(null);
    final showTranslation = useState(false);
    final showVocabulary = useState(false);
    final currentQuizIndex = useState<int?>(null);
    final localizationService = useMemoized(() => DynamicLocalizationService());
    final availableLanguages = AppLanguage.values;
    final flutterTts = useMemoized(() => FlutterTts());
    final revealedParagraphs = useState(1);
    final savedToLibrary = useState(false);
    final alternateEnding = useState<String?>(null);
    final isLoadingAlternate = useState(false);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    String ttsLocaleForLanguage(String code) {
      const localeMap = {
        'yo': 'yo-NG',
        'ig': 'ig-NG',
        'ha': 'ha-NG',
        'sw': 'sw-KE',
        'zu': 'zu-ZA',
        'xh': 'xh-ZA',
        'af': 'af-ZA',
        'am': 'am-ET',
        'en': 'en-US',
        'fr': 'fr-FR',
      };
      return localeMap[code] ?? code;
    }

    Future<void> speakParagraph(String text, String languageCode) async {
      try {
        await flutterTts.stop();
        await flutterTts.setLanguage(ttsLocaleForLanguage(languageCode));
        await flutterTts.setVolume(1.0);
        await flutterTts.setSpeechRate(0.45);
        await flutterTts.speak(text);
      } catch (_) {}
    }

    Future<Map<String, dynamic>> _generateStoryWithGroq({
      required String theme,
      required String language,
      required String userLevel,
    }) async {
      final groqKey = EnvConfig.groqApiKey;
      final useBackend = groqKey.isEmpty ||
          groqKey.trim().isEmpty ||
          groqKey == 'YOUR_GROQ_API_KEY' ||
          groqKey.startsWith('YOUR_');
      final prompt = '''
You are Polie, an elite African language tutor and storyteller.
Create a culturally authentic short story based on the provided theme.

TARGET_LANGUAGE: $language
CEFR_LEVEL: $userLevel
THEME: $theme

Return STRICT JSON ONLY (no markdown, no code fences) with this exact shape:
{
  "title": "Short, compelling title in $language",
  "story": "Story text in $language. Use correct orthography/diacritics for Yoruba/Igbo/Twi. 4-8 short paragraphs.",
  "translation": "Accurate English translation of the story (same structure).",
  "vocabulary": [
    {"term": "word/phrase in $language", "translation": "English", "partOfSpeech": "noun|verb|adj|adv|phrase", "example": "Example sentence in $language"},
    {"term": "...", "translation": "...", "partOfSpeech": "...", "example": "..."}
  ],
  "comprehension": [
    {"question": "Question in English about the story", "options": ["A", "B", "C", "D"], "correctIndex": 0, "explanation": "1 sentence explanation"},
    {"question": "...", "options": ["A", "B", "C", "D"], "correctIndex": 2, "explanation": "..."}
  ],
  "moralOrCulturalContext": "1-2 sentences on the moral or cultural meaning of the story."
}

Quality requirements:
- Include at least 8 vocabulary items.
- Include exactly 5 comprehension questions.
- Keep content age-safe and culturally respectful.
''';

      if (useBackend) {
        final resp = await ApiService.post(
          '/api/ai/chat/completion',
          data: {
            'messages': [{'role': 'user', 'content': prompt}],
            'systemPrompt': 'You output only valid JSON. Never include markdown or commentary.',
            'temperature': 0.35,
            'max_tokens': 1400,
          },
        );
        if (resp.statusCode != 200 || resp.data == null) {
          throw Exception('AI request failed. Please try again.');
        }
        final content = (resp.data is Map)
            ? (resp.data['content']?.toString() ?? '')
            : '';
        if (content.trim().isEmpty) throw Exception('AI returned an empty response. Please try again.');
        try {
          return jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}');
          if (start >= 0 && end > start) {
            return jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
          }
          return {
            'title': 'Story',
            'story': content.trim(),
            'translation': content.trim(),
            'vocabulary': <Object>[],
            'comprehension': <Object>[],
          };
        }
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      final resp = await dio.post(
        UrlConstants.groqChatCompletions,
        data: {
          'model': 'llama-3.3-70b-versatile',
          'temperature': 0.35,
          'max_tokens': 1400,
          'messages': [
            {
              'role': 'system',
              'content': 'You output only valid JSON. Never include markdown or commentary.',
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

      try {
        return jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start >= 0 && end > start) {
          final slice = content.substring(start, end + 1);
          return jsonDecode(slice) as Map<String, dynamic>;
        }
        return {
          'title': 'Story',
          'story': content.trim(),
          'translation': content.trim(),
          'vocabulary': <Object>[],
          'comprehension': <Object>[],
        };
      }
    }

    Future<void> generateStory() async {
      if (themeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a story theme')),
        );
        return;
      }

      isLoading.value = true;
      await safeAsync(
        context: context,
        operation: () async {
          final result = await _generateStoryWithGroq(
            theme: themeController.text.trim(),
            language: selectedLanguage.value.name,
            userLevel: userLevel.value,
          );

          storyResult.value = result;
          revealedParagraphs.value = 1;
          savedToLibrary.value = false;
          alternateEnding.value = null;
        },
        errorContext: 'generateStory',
        showError: true,
      );
      isLoading.value = false;
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Generating story...',
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PolieColors.primary,
                PolieColors.primaryDark,
                PolieColors.obsidian,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  context,
                  showTranslation.value,
                  showVocabulary.value,
                  (show) => showTranslation.value = show,
                  (show) => showVocabulary.value = show,
                  isDark,
                ),
                Expanded(
                  child: storyResult.value != null
                      ? _buildStoryContent(
                          context,
                          storyResult.value!,
                          showTranslation.value,
                          showVocabulary.value,
                          currentQuizIndex.value,
                          (index) => currentQuizIndex.value = index,
                          isDark,
                          revealedParagraphs.value,
                          () => revealedParagraphs.value = revealedParagraphs.value + 1,
                          savedToLibrary.value,
                          () async {
                            if (savedToLibrary.value) return;
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              final saved = prefs.getStringList(_kSavedStoriesKey) ?? [];
                              final story = storyResult.value!;
                              final entry = jsonEncode({'title': story['title'], 'story': story['story'], 'translation': story['translation'], 'ts': DateTime.now().toIso8601String()});
                              saved.add(entry);
                              await prefs.setStringList(_kSavedStoriesKey, saved);
                              savedToLibrary.value = true;
                              HapticFeedback.mediumImpact();
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to library')));
                            } catch (_) {}
                          },
                          alternateEnding.value,
                          isLoadingAlternate.value,
                          () async {
                            if (storyResult.value == null) return;
                            isLoadingAlternate.value = true;
                            try {
                              final theme = storyResult.value!['title'] ?? 'Story';
                              final storyText = storyResult.value!['story'] ?? '';
                              final resp = await ApiService.post('/api/ai/chat/completion', data: {
                                'messages': [{'role': 'user', 'content': 'Write a short alternate ending (2-4 sentences) for this story. Story title: $theme. Story text (end): ${storyText.length > 200 ? storyText.substring(storyText.length - 200) : storyText}. Return only the alternate ending text, no JSON.'}],
                                'temperature': 0.4,
                                'max_tokens': 200,
                              });
                              if (resp.statusCode == 200 && resp.data != null) {
                                final content = (resp.data is Map) ? (resp.data['content']?.toString() ?? '') : resp.data.toString();
                                if (content.isNotEmpty) alternateEnding.value = content.trim();
                              }
                            } catch (_) {}
                            isLoadingAlternate.value = false;
                          },
                          (String text) => speakParagraph(text, selectedLanguage.value.code),
                        )
                      : _buildStoryInput(
                          context,
                          themeController,
                          selectedLanguage,
                          availableLanguages,
                          userLevel.value,
                          (level) => userLevel.value = level,
                          isLoading.value,
                          generateStory,
                          isDark,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool showTranslation,
    bool showVocabulary,
    Function(bool) onTranslationToggle,
    Function(bool) onVocabularyToggle,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Cultural Stories',
              style: PolieTypography.h2(context),
            ),
          ),
          IconButton(
            icon: Icon(
              showTranslation ? Icons.translate_rounded : Icons.translate_outlined,
              color: showTranslation ? PolieColors.electricTeal : PolieColors.textSecondary,
            ),
            onPressed: () => onTranslationToggle(!showTranslation),
            tooltip: 'Toggle Translation',
          ),
          IconButton(
            icon: Icon(
              showVocabulary ? Icons.menu_book_rounded : Icons.menu_book_outlined,
              color: showVocabulary ? PolieColors.goldEmber : PolieColors.textSecondary,
            ),
            onPressed: () => onVocabularyToggle(!showVocabulary),
            tooltip: 'Vocabulary',
          ),
        ],
      ),
    );
  }

  Widget _buildStoryInput(
    BuildContext context,
    TextEditingController themeController,
    ValueNotifier<AppLanguage> selectedLanguage,
    List<AppLanguage> availableLanguages,
    String userLevel,
    Function(String) onLevelChanged,
    bool isLoading,
    VoidCallback onGenerate,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Generate a Cultural Story',
            style: PolieTypography.h2(context),
          ),
          SizedBox(height: PolieSpacing.md),
          PolieGlassCard(
            padding: EdgeInsets.all(PolieSpacing.md),
            child: TextField(
              controller: themeController,
              decoration: InputDecoration(
                labelText: 'Story Theme',
                hintText: 'e.g., traditional festival, village life, folktale',
                border: InputBorder.none,
                filled: false,
              ),
              style: PolieTypography.body(context),
            ),
          ),
          SizedBox(height: PolieSpacing.md),
          Row(
            children: [
              Expanded(
                child: PolieGlassCard(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.xs),
                  child: DropdownButtonFormField<AppLanguage>(
                    value: selectedLanguage.value,
                    dropdownColor: PolieColors.surfaceContainer,
                    decoration: InputDecoration(labelText: 'Language', border: InputBorder.none),
                    style: PolieTypography.body(context),
                    items: availableLanguages.map((lang) => DropdownMenuItem<AppLanguage>(
                      value: lang,
                      child: Text(lang.displayName, style: PolieTypography.body(context)),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) selectedLanguage.value = value;
                    },
                  ),
                ),
              ),
              SizedBox(width: PolieSpacing.md),
              Expanded(
                child: PolieGlassCard(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.xs),
                  child: DropdownButtonFormField<String>(
                    value: userLevel,
                    dropdownColor: PolieColors.surfaceContainer,
                    decoration: InputDecoration(labelText: 'Level', border: InputBorder.none),
                    style: PolieTypography.body(context),
                    items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onLevelChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.xl),
          PoliePrimaryButton(
            label: 'Generate Story',
            onPressed: isLoading ? null : onGenerate,
            loading: isLoading,
            icon: Icons.auto_stories_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(
    BuildContext context,
    Map<String, dynamic> result,
    bool showTranslation,
    bool showVocabulary,
    int? currentQuizIndex,
    Function(int?) onQuizIndexChanged,
    bool isDark,
    int revealedParagraphs,
    VoidCallback onRevealNext,
    bool savedToLibrary,
    VoidCallback onSaveToLibrary,
    String? alternateEnding,
    bool isLoadingAlternate,
    VoidCallback onGenerateAlternateEnding,
    void Function(String)? onSpeakParagraph,
  ) {
    final storyText = (result['story'] ?? '') as String;
    final translationText = (result['translation'] ?? '') as String;
    final paragraphs = storyText.split(RegExp(r'\n\s*\n')).where((s) => s.trim().isNotEmpty).toList();
    final translationParagraphs = translationText.split(RegExp(r'\n\s*\n')).where((s) => s.trim().isNotEmpty).toList();
    final toShow = paragraphs.take(revealedParagraphs).toList();
    final hasMore = revealedParagraphs < paragraphs.length;
    final vocab = (result['vocabulary'] as List?) ?? [];
    final moral = result['moralOrCulturalContext']?.toString();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PolieSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cultural story banner with animated art
                _CulturalStoryBanner(
                  title: result['title'] ?? 'Story',
                  isDark: isDark,
                ),
                SizedBox(height: PolieSpacing.lg),
                // Paragraph-by-paragraph reveal
                ...toShow.asMap().entries.map((entry) {
                  final i = entry.key;
                  final para = entry.value;
                  final transPara = i < translationParagraphs.length ? translationParagraphs[i] : '';
                  return Padding(
                    padding: EdgeInsets.only(bottom: PolieSpacing.md),
                    child: PolieGlassCard(
                      padding: EdgeInsets.all(PolieSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _TapToTranslateParagraph(
                              text: para,
                              translation: transPara,
                              showTranslation: showTranslation,
                              vocabulary: vocab,
                            ),
                          ),
                          if (onSpeakParagraph != null)
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onSpeakParagraph!(para);
                              },
                              icon: Icon(Icons.record_voice_over_rounded, color: PolieColors.goldEmber, size: 22.sp),
                              tooltip: 'Listen',
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                if (hasMore)
                  Center(
                    child: PoliePrimaryButton(
                      label: 'Reveal next paragraph',
                      icon: Icons.keyboard_arrow_down_rounded,
                      onPressed: onRevealNext,
                    ),
                  ),
                if (moral != null && moral.isNotEmpty) ...[
                  SizedBox(height: PolieSpacing.lg),
                  PolieGlassCard(
                    hasGlow: true,
                    glowColor: PolieColors.royalAmethyst,
                    padding: EdgeInsets.all(PolieSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volunteer_activism_rounded, color: PolieColors.royalAmethyst, size: 20.sp),
                            SizedBox(width: PolieSpacing.xs),
                            Text('Moral & cultural context', style: PolieTypography.label(context)),
                          ],
                        ),
                        SizedBox(height: PolieSpacing.sm),
                        Text(moral, style: PolieTypography.body(context)),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: PoliePrimaryButton(
                        label: savedToLibrary ? 'Saved' : 'Save to library',
                        icon: savedToLibrary ? Icons.check_circle : Icons.bookmark_add_rounded,
                        onPressed: savedToLibrary ? null : onSaveToLibrary,
                        enabled: !savedToLibrary,
                      ),
                    ),
                    SizedBox(width: PolieSpacing.sm),
                    Expanded(
                      child: PoliePrimaryButton(
                        label: alternateEnding != null ? 'Alternate ending' : 'Alternate ending',
                        icon: Icons.lightbulb_outline_rounded,
                        loading: isLoadingAlternate,
                        onPressed: isLoadingAlternate ? null : onGenerateAlternateEnding,
                      ),
                    ),
                  ],
                ),
                if (alternateEnding != null && alternateEnding!.isNotEmpty) ...[
                  SizedBox(height: PolieSpacing.md),
                  PolieGlassCard(
                    hasGlow: true,
                    glowColor: PolieColors.electricTeal,
                    padding: EdgeInsets.all(PolieSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alternate ending', style: PolieTypography.label(context)),
                        SizedBox(height: PolieSpacing.sm),
                        Text(alternateEnding!, style: PolieTypography.body(context)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showVocabulary && vocab.isNotEmpty)
          _VocabularyDrawer(
            vocabulary: vocab,
            isDark: isDark,
          ),
        if (result['comprehension'] != null &&
            (result['comprehension'] as List).isNotEmpty)
          _ComprehensionQuiz(
            questions: result['comprehension'] as List,
            currentIndex: currentQuizIndex,
            onIndexChanged: onQuizIndexChanged,
            isDark: isDark,
          ),
      ],
    );
  }
}

/// Cultural story banner with gradient and geometric pattern (animated cultural art).
class _CulturalStoryBanner extends StatelessWidget {
  final String title;
  final bool isDark;

  const _CulturalStoryBanner({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return PolieGlassCard(
      hasGlow: true,
      glowColor: PolieColors.goldEmber,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: PolieSpacing.lg, horizontal: PolieSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PolieColors.goldEmber.withOpacity(0.15),
                    PolieColors.royalAmethyst.withOpacity(0.1),
                    PolieColors.primaryDark,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_stories_rounded, size: 40.sp, color: PolieColors.goldEmber),
                  SizedBox(height: PolieSpacing.sm),
                  Text(
                    title,
                    style: PolieTypography.h2(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: PolieSpacing.xs),
                  Text(
                    'Cultural Story',
                    style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textSecondary),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.2,
                child: CustomPaint(
                  size: Size(120.w, 80.w),
                  painter: _GeometricPatternPainter(color: PolieColors.goldEmber),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  final Color color;

  _GeometricPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (int i = 0; i < 6; i++) {
      final r = (size.shortestSide / 2) * (1 - i * 0.12);
      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paragraph text with tap-for-translation on words (from vocabulary or show translation line).
class _TapToTranslateParagraph extends StatelessWidget {
  final String text;
  final String translation;
  final bool showTranslation;
  final List vocabulary;

  const _TapToTranslateParagraph({
    required this.text,
    required this.translation,
    required this.showTranslation,
    required this.vocabulary,
  });

  @override
  Widget build(BuildContext context) {
    if (showTranslation && translation.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: PolieTypography.body(context)),
          SizedBox(height: PolieSpacing.sm),
          Text(
            translation,
            style: PolieTypography.bodySmall(context).copyWith(
              color: PolieColors.electricTeal,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
    final words = text.split(RegExp(r'\s+'));
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: words.map((word) {
        final clean = word.replaceAll(RegExp(r'[^\w\s]'), '');
        final vocabMatch = vocabulary.cast<Map<String, dynamic>>().where((v) =>
            (v['term'] ?? v['word'] ?? '').toString().toLowerCase().contains(clean.toLowerCase()) ||
            clean.toLowerCase().contains((v['term'] ?? v['word'] ?? '').toString().toLowerCase())).toList();
        return GestureDetector(
          onTap: () {
            if (vocabMatch.isEmpty) return;
            HapticFeedback.lightImpact();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: PolieColors.surfaceContainer,
                title: Text(vocabMatch.first['term'] ?? word, style: PolieTypography.label(ctx)),
                content: Text(
                  (vocabMatch.first['translation'] ?? vocabMatch.first['meaning'] ?? translation).toString(),
                  style: PolieTypography.body(ctx),
                ),
              ),
            );
          },
          child: Text(
            '$word ',
            style: PolieTypography.body(context).copyWith(
              decoration: vocabMatch.isNotEmpty ? TextDecoration.underline : null,
              decorationColor: PolieColors.electricTeal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VocabularyDrawer extends StatelessWidget {
  final List vocabulary;
  final bool isDark;

  const _VocabularyDrawer({
    required this.vocabulary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: PolieColors.surfaceGlassDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.lg)),
        border: Border.all(color: PolieColors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: PolieSpacing.sm),
            decoration: BoxDecoration(
              color: PolieColors.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(PolieSpacing.md),
              itemCount: vocabulary.length,
              itemBuilder: (context, index) {
                final vocab = vocabulary[index] as Map<String, dynamic>;
                return Container(
                  margin: EdgeInsets.only(bottom: PolieSpacing.sm),
                  padding: EdgeInsets.symmetric(vertical: PolieSpacing.xs),
                  decoration: BoxDecoration(
                    color: PolieColors.royalAmethyst.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                  ),
                  child: ListTile(
                    title: Text(
                      (vocab['word'] ?? vocab['term'] ?? '').toString(),
                      style: PolieTypography.body(context),
                    ),
                    subtitle: Text(
                      (vocab['meaning'] ?? vocab['translation'] ?? '').toString(),
                      style: PolieTypography.bodySmall(context),
                    ),
                    trailing: vocab['example'] != null
                        ? IconButton(
                            icon: Icon(Icons.info_outline_rounded, color: PolieColors.electricTeal),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: PolieColors.surfaceContainer,
                                  title: Text('Example', style: PolieTypography.label(context)),
                                  content: Text(
                                    vocab['example'].toString(),
                                    style: PolieTypography.body(context),
                                  ),
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComprehensionQuiz extends StatefulWidget {
  final List questions;
  final int? currentIndex;
  final Function(int?) onIndexChanged;
  final bool isDark;

  const _ComprehensionQuiz({
    required this.questions,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.isDark,
  });

  @override
  State<_ComprehensionQuiz> createState() => _ComprehensionQuizState();
}

class _ComprehensionQuizState extends State<_ComprehensionQuiz> {
  int? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    if (widget.currentIndex == null || widget.currentIndex! >= widget.questions.length) {
      return Padding(
        padding: EdgeInsets.all(PolieSpacing.md),
        child: PolieGlassCard(
          child: Center(
            child: PoliePrimaryButton(
              label: 'Start Quiz',
              onPressed: () => widget.onIndexChanged(0),
              icon: Icons.quiz_rounded,
            ),
          ),
        ),
      );
    }

    final question = widget.questions[widget.currentIndex!] as Map<String, dynamic>;

    return Padding(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: PolieGlassCard(
        hasGlow: true,
        glowColor: PolieColors.electricTeal,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${widget.currentIndex! + 1} of ${widget.questions.length}',
            style: PolieTypography.label(context),
          ),
          SizedBox(height: PolieSpacing.md),
          Text(
            question['question'] ?? '',
            style: PolieTypography.body(context),
          ),
          SizedBox(height: PolieSpacing.lg),
          ...(question['options'] as List? ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedAnswer == index;
            final rawCorrect = question['correctIndex'] ?? question['answer'];
            final correctIdx = rawCorrect is int ? rawCorrect : (rawCorrect is num ? rawCorrect.toInt() : null);
            final isCorrect = correctIdx != null && index == correctIdx;

            return Container(
              margin: EdgeInsets.only(bottom: PolieSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isCorrect
                        ? PolieColors.success.withOpacity(0.2)
                        : PolieColors.error.withOpacity(0.2))
                    : PolieColors.surfaceGlassDark,
                borderRadius: BorderRadius.circular(PolieRadius.md),
              ),
              child: ListTile(
                title: Text(option.toString(), style: PolieTypography.body(context)),
                trailing: isSelected
                    ? Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isCorrect ? PolieColors.success : PolieColors.error,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    selectedAnswer = index;
                  });
                  Future.delayed(const Duration(seconds: 1), () {
                    if (widget.currentIndex! < widget.questions.length - 1) {
                      widget.onIndexChanged(widget.currentIndex! + 1);
                      setState(() {
                        selectedAnswer = null;
                      });
                    } else {
                      widget.onIndexChanged(null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Quiz completed!')),
                      );
                    }
                  });
                },
              ),
            );
          }),
        ],
        ),
      ),
    );
  }
}

