import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, PolieMode;
import 'package:lingafriq/services/hybrid_polie/hybrid_polie_orchestrator.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show AppLanguage;
import 'package:lingafriq/services/vocabulary/vocabulary_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Translation Mode — Afro-futurist UI. Dual language pills, glass canvas, Adaptive/Literal tabs.
class TutorTranslationModeScreen extends HookConsumerWidget {
  const TutorTranslationModeScreen({Key? key}) : super(key: key);

  static String _displayName(AppLanguage lang) => lang.name;
  static String? _regionTag(AppLanguage lang) => SupportedLanguages.getCountry(lang.code);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final sourceLanguage = useState<AppLanguage>(AppLanguage.english);
    final targetLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final translationType = useState<String>('adaptive');
    final isLoading = useState(false);
    final translationResult = useState<Map<String, dynamic>?>(null);
    final availableLanguages = AppLanguage.values;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isListening = useState(false);
    final resultViewMode = useState<String>('stacked');
    final speech = useMemoized(() => stt.SpeechToText(), []);

    Future<void> translate() async {
      if (textController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter text to translate')),
        );
        return;
      }
      isLoading.value = true;
      try {
        final groqProvider = ref.read(groqChatProvider.notifier);
        final orchestrator = HybridPolieOrchestrator();
        final response = await orchestrator.orchestrate(
          userMessage: textController.text,
          mode: PolieMode.translation,
          targetLanguage: targetLanguage.value.name,
          sourceLanguage: sourceLanguage.value.name,
          groqProvider: groqProvider,
        );

        if (response.model != 'fallback' && response.output.trim().isNotEmpty) {
          translationResult.value = {
            'translation': response.output,
            'confidence': response.confidence,
            'model': response.model,
            'diacriticsCorrected': response.diacriticsCorrected,
            'metadata': response.metadata,
          };
          return;
        }

        // Hybrid orchestrator returned fallback — use Groq LLM as final fallback.
        // This ensures translation works whenever the user has a valid Groq API key,
        // even if backend translation, HuggingFace, and offline services all fail.
        final srcName = sourceLanguage.value.name;
        final tgtName = targetLanguage.value.name;
        final groqTranslation = await groqProvider.sendMessage(
          'Translate the following text from $srcName to $tgtName. '
          'Output ONLY the translation with correct diacritics, nothing else:\n\n'
          '${textController.text}',
          systemPromptOverride:
            'You are a precise translator. Translate from $srcName to $tgtName. '
            'Output ONLY the translated text with correct orthography and diacritics. '
            'Do not add explanations, notes, or formatting — just the translation.',
        );

        if (groqTranslation.trim().isNotEmpty) {
          translationResult.value = {
            'translation': groqTranslation.trim(),
            'confidence': 0.80,
            'model': 'groq-llm-fallback',
            'diacriticsCorrected': false,
            'metadata': <String, dynamic>{'fallback': true},
          };
          return;
        }

        // Both orchestrator and Groq failed
        throw Exception(
          'Translation is temporarily unavailable. Please ensure you are online and the AI services are configured.',
        );
      } catch (e) {
        if (context.mounted) ErrorHandler.showError(context, e);
        translationResult.value = null;
      } finally {
        isLoading.value = false;
      }
    }

    void swapLanguages() {
      HapticFeedback.lightImpact();
      final from = sourceLanguage.value;
      sourceLanguage.value = targetLanguage.value;
      targetLanguage.value = from;
    }

    Future<void> toggleVoiceInput() async {
      if (isListening.value) {
        await speech.stop();
        isListening.value = false;
        return;
      }
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is needed for voice input')),
          );
        }
        return;
      }
      final available = await speech.initialize(
        onStatus: (s) => isListening.value = s == 'listening',
        onError: (_) => isListening.value = false,
      );
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition is not available on this device')),
          );
        }
        return;
      }
      HapticFeedback.lightImpact();
      await speech.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            final current = textController.text;
            final newText = current.isEmpty ? words : '$current $words';
            textController.text = newText;
            textController.selection = TextSelection.collapsed(offset: newText.length);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: sourceLanguage.value.code,
      );
      isListening.value = true;
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Translating...',
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
                  _buildTranslationTypeToggle(context, translationType.value, (type) {
                    HapticFeedback.selectionClick();
                    translationType.value = type;
                  }, isDark),
                  SizedBox(height: PolieSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: PolieLanguagePill(
                          label: _displayName(sourceLanguage.value),
                          regionTag: _regionTag(sourceLanguage.value),
                          isSelected: true,
                          accentColor: polieAccentForLanguage(sourceLanguage.value.name),
                          onTap: () => _showLanguagePicker(
                            context,
                            availableLanguages,
                            sourceLanguage.value,
                            (lang) => sourceLanguage.value = lang,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: swapLanguages,
                        icon: Icon(Icons.swap_horiz_rounded, color: PolieColors.royalAmethyst),
                        tooltip: 'Swap languages',
                      ),
                      Expanded(
                        child: PolieLanguagePill(
                          label: _displayName(targetLanguage.value),
                          regionTag: _regionTag(targetLanguage.value),
                          isSelected: true,
                          accentColor: polieAccentForLanguage(
                            SupportedLanguages.getKeyFromCode(targetLanguage.value.code) ??
                                targetLanguage.value.name.toLowerCase(),
                          ),
                          onTap: () => _showLanguagePicker(
                            context,
                            availableLanguages,
                            targetLanguage.value,
                            (lang) => targetLanguage.value = lang,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PolieSpacing.lg),
                  PolieGlassCard(
                    padding: EdgeInsets.all(PolieSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: textController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: 'Type or use voice input...',
                                  hintStyle: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: PolieTypography.body(context),
                              ),
                            ),
                            IconButton(
                              onPressed: () => toggleVoiceInput(),
                              icon: Icon(
                                isListening.value ? Icons.mic_rounded : Icons.mic_none_rounded,
                                color: isListening.value ? PolieColors.error : PolieColors.electricTeal,
                                size: 28,
                              ),
                              tooltip: isListening.value ? 'Stop listening' : 'Voice input',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: PolieSpacing.lg),
                  Center(
                    child: PoliePrimaryButton(
                      label: 'Translate',
                      loading: isLoading.value,
                      enabled: !isLoading.value,
                      icon: Icons.translate_rounded,
                      onPressed: translate,
                    ),
                  ),
                  if (translationResult.value != null) ...[
                    SizedBox(height: PolieSpacing.xl),
                    _buildResultViewToggle(context, resultViewMode.value, (mode) {
                      HapticFeedback.selectionClick();
                      resultViewMode.value = mode;
                    }),
                    SizedBox(height: PolieSpacing.sm),
                    _buildTranslationResult(
                      context,
                      ref,
                      textController.text.trim(),
                      targetLanguage.value,
                      translationResult.value!,
                      isDark,
                      resultViewMode.value,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationTypeToggle(
    BuildContext context,
    String currentType,
    void Function(String) onChanged,
    bool isDark,
  ) {
    return PolieGlassCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: _PolieToggleChip(
              label: 'Adaptive',
              isSelected: currentType == 'adaptive',
              onTap: () => onChanged('adaptive'),
            ),
          ),
          Expanded(
            child: _PolieToggleChip(
              label: 'Literal',
              isSelected: currentType == 'literal',
              onTap: () => onChanged('literal'),
            ),
          ),
        ],
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
          color: Theme.of(ctx).brightness == Brightness.dark
              ? PolieColors.surfaceContainer
              : Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
        ),
        padding: EdgeInsets.symmetric(vertical: PolieSpacing.lg),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select language', style: PolieTypography.h2(ctx)),
              SizedBox(height: PolieSpacing.md),
              ...languages.map((lang) {
                final isSelected = lang == current;
                return ListTile(
                  title: Text(
                    lang.name,
                    style: PolieTypography.body(ctx).copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? PolieColors.royalAmethyst : null,
                    ),
                  ),
                  subtitle: SupportedLanguages.getCountry(lang.code) != null
                      ? Text(
                          SupportedLanguages.getCountry(lang.code)!,
                          style: PolieTypography.bodySmall(ctx),
                        )
                      : null,
                  onTap: () {
                    onSelected(lang);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultViewToggle(
    BuildContext context,
    String currentMode,
    void Function(String) onChanged,
  ) {
    return PolieGlassCard(
      padding: EdgeInsets.symmetric(vertical: PolieSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: _PolieToggleChip(
              label: 'Stacked',
              isSelected: currentMode == 'stacked',
              onTap: () => onChanged('stacked'),
            ),
          ),
          Expanded(
            child: _PolieToggleChip(
              label: 'Side by side',
              isSelected: currentMode == 'sideBySide',
              onTap: () => onChanged('sideBySide'),
            ),
          ),
        ],
      ),
    );
  }

  static List<Map<String, String>> _getPhraseBreakdowns(Map<String, dynamic> result) {
    final meta = result['metadata'];
    if (meta is! Map) return [];
    final list = meta['phraseBreakdowns'];
    if (list is! List || list.isEmpty) return [];
    return list
        .map((e) => e is Map ? Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))) : null)
        .whereType<Map<String, String>>()
        .toList();
  }

  Widget _buildTranslationResult(
    BuildContext context,
    WidgetRef ref,
    String sourceText,
    AppLanguage targetLang,
    Map<String, dynamic> result,
    bool isDark,
    String viewMode,
  ) {
    final translatedText = result['translation'] ?? result['adaptiveTranslation'] ?? '';
    final isSideBySide = viewMode == 'sideBySide';
    return PolieGlassCard(
      hasGlow: true,
      glowColor: PolieColors.electricTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Translation', style: PolieTypography.h2(context)),
          SizedBox(height: PolieSpacing.md),
          if (isSideBySide && sourceText.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Source', style: PolieTypography.label(context)),
                      SizedBox(height: PolieSpacing.xs),
                      Text(sourceText, style: PolieTypography.body(context)),
                    ],
                  ),
                ),
                SizedBox(width: PolieSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Translation', style: PolieTypography.label(context)),
                      SizedBox(height: PolieSpacing.xs),
                      Text(translatedText, style: PolieTypography.body(context)),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            if (!isSideBySide) Text(translatedText, style: PolieTypography.body(context)),
          ],
          if (_getPhraseBreakdowns(result).isNotEmpty) ...[
            SizedBox(height: PolieSpacing.lg),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.sm),
            Text('Tap a phrase for breakdown', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.xs),
            _TapToHighlightPhraseBreakdown(phrases: _getPhraseBreakdowns(result)),
          ],
          if (result['grammarNotes'] != null) ...[
            SizedBox(height: PolieSpacing.lg),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.md),
            Text('Grammar notes', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.sm),
            Text(result['grammarNotes'], style: PolieTypography.bodySmall(context)),
          ],
          if (result['examples'] != null && (result['examples'] as List).isNotEmpty) ...[
            SizedBox(height: PolieSpacing.lg),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.md),
            Text('Examples', style: PolieTypography.label(context)),
            SizedBox(height: PolieSpacing.sm),
            ...(result['examples'] as List).map((e) => Padding(
                  padding: EdgeInsets.only(bottom: PolieSpacing.xs),
                  child: Text('• $e', style: PolieTypography.bodySmall(context)),
                )),
          ],
          if (sourceText.isNotEmpty && translatedText.isNotEmpty) ...[
            SizedBox(height: PolieSpacing.lg),
            Divider(color: PolieColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: PolieSpacing.sm),
            _SaveToVocabularyButton(
              sourceText: sourceText,
              translatedText: translatedText,
              targetLanguage: targetLang.name,
              vocabularyService: ref.read(vocabularyServiceProvider),
            ),
          ],
        ],
      ),
    );
  }
}

class _SaveToVocabularyButton extends StatefulWidget {
  final String sourceText;
  final String translatedText;
  final String targetLanguage;
  final VocabularyService vocabularyService;

  const _SaveToVocabularyButton({
    required this.sourceText,
    required this.translatedText,
    required this.targetLanguage,
    required this.vocabularyService,
  });

  @override
  State<_SaveToVocabularyButton> createState() => _SaveToVocabularyButtonState();
}

class _SaveToVocabularyButtonState extends State<_SaveToVocabularyButton> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveToVocabularyBank() async {
    if (_saved || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.vocabularyService.addWord(
        word: widget.sourceText,
        language: widget.targetLanguage,
        translation: widget.translatedText,
        enrichWithAI: false,
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Vocabulary Bank')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save to vocabulary')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PoliePrimaryButton(
        label: _saved ? 'Saved to Vocabulary Bank' : 'Save to Vocabulary Bank',
        icon: _saved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
        loading: _saving,
        enabled: !_saved && !_saving,
        onPressed: _saveToVocabularyBank,
      ),
    );
  }
}

/// Tap-to-highlight phrase breakdown: shows target phrases; tap reveals source + note.
class _TapToHighlightPhraseBreakdown extends StatefulWidget {
  final List<Map<String, String>> phrases;

  const _TapToHighlightPhraseBreakdown({required this.phrases});

  @override
  State<_TapToHighlightPhraseBreakdown> createState() => _TapToHighlightPhraseBreakdownState();
}

class _TapToHighlightPhraseBreakdownState extends State<_TapToHighlightPhraseBreakdown> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: PolieSpacing.xs,
      runSpacing: PolieSpacing.xs,
      children: [
        for (int i = 0; i < widget.phrases.length; i++) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedIndex = _selectedIndex == i ? null : i);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.xs),
              decoration: BoxDecoration(
                color: _selectedIndex == i
                    ? PolieColors.royalAmethyst.withOpacity(0.25)
                    : PolieColors.surfaceContainer,
                borderRadius: BorderRadius.circular(PolieRadius.sm),
                border: _selectedIndex == i
                    ? Border.all(color: PolieColors.royalAmethyst, width: 1)
                    : null,
              ),
              child: Text(
                widget.phrases[i]['targetPhrase'] ?? '',
                style: PolieTypography.bodySmall(context).copyWith(
                  color: _selectedIndex == i ? PolieColors.electricTealLight : null,
                ),
              ),
            ),
          ),
        ],
        if (_selectedIndex != null && _selectedIndex! < widget.phrases.length) ...[
          SizedBox(width: double.infinity, height: PolieSpacing.sm),
          PolieGlassCard(
            padding: EdgeInsets.all(PolieSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Source: ${widget.phrases[_selectedIndex!]['sourcePhrase'] ?? ''}', style: PolieTypography.bodySmall(context)),
                if ((widget.phrases[_selectedIndex!]['note'] ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: PolieSpacing.xs),
                    child: Text(widget.phrases[_selectedIndex!]['note']!, style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.goldEmber)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PolieToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PolieToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PolieRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: PolieTypography.label(context).copyWith(
              color: isSelected ? PolieColors.royalAmethyst : PolieColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
