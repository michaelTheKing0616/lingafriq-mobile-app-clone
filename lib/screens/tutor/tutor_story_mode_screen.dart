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

/// Story Mode with Translation Toggle, Vocabulary Drawer, Interactive Quiz
class TutorStoryModeScreen extends HookConsumerWidget {
  const TutorStoryModeScreen({Key? key}) : super(key: key);

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<Map<String, dynamic>> _generateStoryWithGroq({
      required String theme,
      required String language,
      required String userLevel,
    }) async {
      final groqKey = EnvConfig.groqApiKey;
      if (groqKey.isEmpty) {
        throw Exception(
          'Story mode is unavailable because the AI service is not configured in this build.',
        );
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

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
  ]
}

Quality requirements:
- Include at least 8 vocabulary items.
- Include exactly 5 comprehension questions.
- Keep content age-safe and culturally respectful.
''';

      final resp = await dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.1-70b-versatile',
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
        // Attempt to extract the first JSON object if the model emitted extra text.
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start >= 0 && end > start) {
          final slice = content.substring(start, end + 1);
          return jsonDecode(slice) as Map<String, dynamic>;
        }
        rethrow;
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
              // Header with controls
              _buildHeader(
                context,
                showTranslation.value,
                showVocabulary.value,
                (show) => showTranslation.value = show,
                (show) => showVocabulary.value = show,
                isDark,
              ),

              // Story Content
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
    ), // closes LoadingOverlay
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
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Cultural Stories',
              style: PanAfricanTypography.titleLarge(context),
            ),
          ),
          IconButton(
            icon: Icon(
              showTranslation ? Icons.translate : Icons.translate_outlined,
              color: showTranslation ? PanAfricanColors.primary : null,
            ),
            onPressed: () => onTranslationToggle(!showTranslation),
            tooltip: 'Toggle Translation',
          ),
          IconButton(
            icon: Icon(
              showVocabulary ? Icons.book : Icons.book_outlined,
              color: showVocabulary ? PanAfricanColors.secondary : null,
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
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Generate a Cultural Story',
            style: PanAfricanTypography.headlineMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          TextField(
            controller: themeController,
            decoration: InputDecoration(
              labelText: 'Story Theme',
              hintText: 'e.g., traditional festival, village life, folktale',
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
                  items: availableLanguages.map((lang) {
                    return DropdownMenuItem<AppLanguage>(
                      value: lang,
                      child: Text(
                        lang.displayName,
                        style: PanAfricanTypography.bodyLarge(context),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedLanguage.value = value;
                    }
                  },
                ),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: userLevel,
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
                    if (value != null) onLevelChanged(value);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.xl),
          ElevatedButton(
            onPressed: isLoading ? null : onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Generate Story',
                    style: PanAfricanTypography.labelLarge(context)
                        .copyWith(color: Colors.white),
                  ),
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
  ) {
    return Column(
      children: [
        // Story Text
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['title'] ?? 'Story',
                  style: PanAfricanTypography.headlineMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  showTranslation
                      ? (result['translation'] ?? result['story'] ?? '')
                      : (result['story'] ?? ''),
                  style: PanAfricanTypography.bodyLarge(context),
                ),
              ],
            ),
          ),
        ),

        // Vocabulary Drawer
        if (showVocabulary && result['vocabulary'] != null)
          _VocabularyDrawer(
            vocabulary: result['vocabulary'] as List,
            isDark: isDark,
          ),

        // Comprehension Quiz
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
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanAfricanRadius.lg),
        ),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
            decoration: BoxDecoration(
              color: PanAfricanColors.neutralMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              itemCount: vocabulary.length,
              itemBuilder: (context, index) {
                final vocab = vocabulary[index] as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                  child: ListTile(
                    title: Text(
                      vocab['word'] ?? '',
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                    subtitle: Text(
                      vocab['meaning'] ?? '',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                    trailing: vocab['example'] != null
                        ? IconButton(
                            icon: Icon(Icons.info_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Example'),
                                  content: Text(vocab['example']),
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
      return Container(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: widget.isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          boxShadow: PanAfricanShadows.md,
        ),
        child: ElevatedButton(
          onPressed: () => widget.onIndexChanged(0),
          child: Text('Start Quiz'),
        ),
      );
    }

    final question = widget.questions[widget.currentIndex!] as Map<String, dynamic>;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: widget.isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${widget.currentIndex! + 1} of ${widget.questions.length}',
            style: PanAfricanTypography.titleMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            question['question'] ?? '',
            style: PanAfricanTypography.bodyLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.lg),
          ...(question['options'] as List? ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedAnswer == index;
            final isCorrect = index == (question['answer'] as int?);

            return Card(
              margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
              color: isSelected
                  ? (isCorrect
                      ? PanAfricanColors.success.withOpacity(0.2)
                      : PanAfricanColors.error.withOpacity(0.2))
                  : null,
              child: ListTile(
                title: Text(option),
                trailing: isSelected
                    ? Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? PanAfricanColors.success : PanAfricanColors.error,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    selectedAnswer = index;
                  });
                  Future.delayed(Duration(seconds: 1), () {
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
    );
  }
}

