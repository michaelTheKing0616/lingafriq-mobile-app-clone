import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/error_handler.dart' hide ErrorBoundary;
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_screen.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full-screen language picker for Polie
/// Lets users choose conversation/learning language and primes the model
class AiChatLanguageSetupScreen extends ConsumerStatefulWidget {
  final PolieMode initialMode;
  final VoidCallback? onBack;
  final Function(String language, String languageName)? onLanguageSelected;

  const AiChatLanguageSetupScreen({
    super.key,
    this.initialMode = PolieMode.translation,
    this.onBack,
    this.onLanguageSelected,
  });

  @override
  ConsumerState<AiChatLanguageSetupScreen> createState() =>
      _AiChatLanguageSetupScreenState();
}

class _AiChatLanguageSetupScreenState
    extends ConsumerState<AiChatLanguageSetupScreen> {
  late PolieMode _mode;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  Future<void> _selectLanguage(String language) async {
    if (!mounted) return;
    
    try {
      final chat = ref.read(groqChatProvider.notifier);
      // Atomically set mode + language so the correct chat history key
      // (ai_chat_history_groq_{mode}_{language}) is used for loading.
      // This avoids the race condition where sequential setMode/setLanguage
      // would save/load with intermediate (wrong) keys.
      await chat.setModeAndLanguage(
        mode: _mode,
        targetLanguage: language,
        sourceLanguage: 'English',
      );
      if (!mounted) return;
      
      // If callback provided, call it (for roleplay scenario selection)
      if (widget.onLanguageSelected != null) {
        widget.onLanguageSelected!(language, language);
        return;
      }
      
      // Otherwise, navigate to the unified Polie workspace
      Navigator.push(
        context,
        SmoothPageRoute(
          child: PolieWorkspaceScreen(
            sourceLanguage: 'English',
            targetLanguage: language,
            initialMode: _mode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight;
    final textSecondary =
        isDark ? PolieColors.textSecondary : PolieColors.textSecondaryLight;
    final languages = ref.read(groqChatProvider.notifier).supportedLanguageOptions;
    final filteredLanguages = languages.where((lang) {
      final name = (lang['name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return name.contains(query);
    }).toList();

    return ErrorBoundary(
      errorMessage: 'Unable to load AI Chat setup. Please check your connection and try again.',
      onRetry: () => setState(() {}),
      child: Scaffold(
        backgroundColor:
            isDark ? PolieColors.obsidian : PolieColors.surfaceContainerLight,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(PolieSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: textPrimary,
                      onPressed: widget.onBack ??
                          () {
                            Navigator.of(context).pop();
                          },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your language',
                            style: PolieTypography.h2(context).copyWith(
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Polie will default to this language unless you ask otherwise.',
                            style: PolieTypography.bodySmall(context).copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Mode display (read-only, shows selected mode)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: PolieSpacing.md,
                  vertical: PolieSpacing.sm,
                ),
                child: Container(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? PolieColors.surfaceContainer
                        : PolieColors.surfaceContainerLight,
                    borderRadius: BorderRadius.circular(PolieRadius.lg),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
                    ),
                    boxShadow: PolieElevation.level1(context),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getModeIcon(_mode),
                        color: PolieColors.electricTeal,
                        size: 20.sp,
                      ),
                      SizedBox(width: PolieSpacing.xs),
                      Text(
                        _getModeName(_mode),
                        style: PolieTypography.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(width: PolieSpacing.xs),
                      Text(
                        'Mode',
                        style: PolieTypography.bodySmall(context).copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Language grid
              Padding(
                padding: EdgeInsets.fromLTRB(
                  PolieSpacing.md,
                  PolieSpacing.xs,
                  PolieSpacing.md,
                  PolieSpacing.xs,
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: PolieTypography.body(context).copyWith(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search language...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: isDark
                        ? PolieColors.surfaceContainer
                        : PolieColors.surfaceContainerLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.lg),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.lg),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredLanguages.isEmpty
                    ? Center(
                        child: Text(
                          'No language matches "$_searchQuery"',
                          style: PolieTypography.body(context).copyWith(color: textSecondary),
                        ),
                      )
                    : GridView.builder(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    mainAxisSpacing: PolieSpacing.sm,
                    crossAxisSpacing: PolieSpacing.sm,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: filteredLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = filteredLanguages[index];
                    final name = lang['name'] ?? '';
                    final flag = lang['flag'] ?? '🌍';
                    final accent = polieAccentForLanguage(name);

                    return InkWell(
                      onTap: () => _selectLanguage(name),
                      borderRadius: BorderRadius.circular(PolieRadius.xl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? PolieColors.surfaceContainer
                              : PolieColors.surfaceContainerLight,
                          borderRadius:
                              BorderRadius.circular(PolieRadius.xl),
                          border: Border.all(
                            color: accent.withOpacity(0.2),
                            width: 1.2,
                          ),
                          boxShadow: PolieElevation.level1(context),
                        ),
                        padding: EdgeInsets.all(PolieSpacing.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              flag,
                              style: TextStyle(fontSize: 32.sp),
                            ),
                            SizedBox(height: PolieSpacing.xs),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: PolieTypography.body(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: PolieSpacing.xxxs),
                            Text(
                              _getModeDescription(_mode, name),
                              textAlign: TextAlign.center,
                              style: PolieTypography.bodySmall(context).copyWith(
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(PolieMode mode) {
    switch (mode) {
      case PolieMode.translation:
        return Icons.translate_rounded;
      case PolieMode.tutor:
        return Icons.school_rounded;
      case PolieMode.roleplay:
        return Icons.theater_comedy_rounded;
      case PolieMode.conversation:
        return Icons.chat_bubble_outline_rounded;
      case PolieMode.vocab:
        return Icons.book_rounded;
      case PolieMode.review:
        return Icons.refresh_rounded;
      case PolieMode.pronunciation:
        return Icons.record_voice_over_rounded;
      case PolieMode.grammar:
        return Icons.rule_folder_outlined;
    }
  }

  String _getModeName(PolieMode mode) {
    switch (mode) {
      case PolieMode.translation:
        return 'Translation';
      case PolieMode.tutor:
        return 'Tutor';
      case PolieMode.roleplay:
        return 'Roleplay';
      case PolieMode.conversation:
        return 'Conversation';
      case PolieMode.vocab:
        return 'Vocabulary';
      case PolieMode.review:
        return 'Review';
      case PolieMode.pronunciation:
        return 'Pronunciation';
      case PolieMode.grammar:
        return 'Grammar';
    }
  }

  String _getModeDescription(PolieMode mode, String language) {
    switch (mode) {
      case PolieMode.translation:
        return 'Translate with Polie';
      case PolieMode.tutor:
        return 'Learn $language with Polie';
      case PolieMode.roleplay:
        return 'Practice $language scenarios';
      case PolieMode.conversation:
        return 'Chat in $language';
      case PolieMode.vocab:
        return 'Learn $language words';
      case PolieMode.review:
        return 'Review $language';
      case PolieMode.pronunciation:
        return 'Practice $language pronunciation';
      case PolieMode.grammar:
        return 'Practice $language grammar';
    }
  }
}

