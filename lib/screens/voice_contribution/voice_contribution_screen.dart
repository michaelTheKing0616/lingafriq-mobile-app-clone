import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

/// Voice Contribution Screen
/// Allows native speakers to volunteer their voices for African languages
class VoiceContributionScreen extends HookConsumerWidget {
  const VoiceContributionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState('yoruba');
    final selectedCategory = useState('words');
    final prompts = useState<List<Map<String, dynamic>>>([]);
    final selectedPrompt = useState<Map<String, dynamic>?>(null);
    final audioFile = useState<File?>(null);
    final isRecording = useState(false);
    final isSubmitting = useState(false);
    final userStats = useState<Map<String, dynamic>?>(null);
    final isLoading = useState(true);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'afrikaans', 'nigerian_pidgin', 'pidgin'];
    final categories = [
      {'value': 'words', 'label': 'Words', 'icon': Icons.text_fields},
      {'value': 'phrases', 'label': 'Phrases', 'icon': Icons.chat_bubble},
      {'value': 'sentences', 'label': 'Sentences', 'icon': Icons.subject},
      {'value': 'greetings', 'label': 'Greetings', 'icon': Icons.waving_hand},
      {'value': 'proverbs', 'label': 'Proverbs', 'icon': Icons.auto_awesome},
      {'value': 'questions', 'label': 'Questions', 'icon': Icons.help},
      {'value': 'numbers', 'label': 'Numbers', 'icon': Icons.numbers},
      {'value': 'corrections', 'label': 'Corrections', 'icon': Icons.edit},
    ];

    Future<void> loadPrompts() async {
      isLoading.value = true;
      try {
        final user = ref.read(userProvider);
        if (user == null) {
          prompts.value = [];
          return;
        }

        final response = await ApiService.get(
          '/api/voice/contributions/prompts',
          queryParameters: {
            'language': selectedLanguage.value,
            'category': selectedCategory.value,
            'count': 10,
          },
        );

        if (response.statusCode == 200 && response.data['prompts'] != null) {
          prompts.value = List<Map<String, dynamic>>.from(response.data['prompts']);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load prompts: ${e.toString()}')),
        );
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> loadUserStats() async {
      try {
        final user = ref.read(userProvider);
        if (user == null) {
          userStats.value = null;
          return;
        }

        final userId = user.id.toString();
        
        final response = await ApiService.get(
          '/api/voice/contributions/stats/$userId',
        );

        if (response.statusCode == 200) {
          userStats.value = response.data;
        }
      } catch (e) {
        // Silent fail
      }
    }

    Future<void> pickAudioFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        audioFile.value = File(result.files.single.path!);
      }
    }

    Future<void> submitContribution() async {
      if (selectedPrompt.value == null || audioFile.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a prompt and record audio')),
        );
        return;
      }

      isSubmitting.value = true;
      try {
        final user = ref.read(userProvider);
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to submit a contribution')),
          );
          return;
        }

        // Upload file
        final response = await ApiService.uploadFile(
          '/api/voice/contributions',
          audioFile.value!.path,
          additionalData: {
            'promptId': selectedPrompt.value!['id'],
            'language': selectedLanguage.value,
            'category': selectedCategory.value,
            'promptText': selectedPrompt.value!['text'],
            'promptTranslation': selectedPrompt.value!['translation'] ?? '',
          },
          fileFieldName: 'audio',
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thank you for your contribution! 🎉'),
              backgroundColor: PanAfricanColors.success,
            ),
          );
          
          // Reset
          selectedPrompt.value = null;
          audioFile.value = null;
          loadPrompts();
          loadUserStats();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')),
        );
      } finally {
        isSubmitting.value = false;
      }
    }

    useEffect(() {
      loadPrompts();
      loadUserStats();
      return null;
    }, [selectedLanguage.value, selectedCategory.value]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Contributions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (userStats.value != null)
            IconButton(
              icon: Icon(Icons.star),
              tooltip: 'Your Stats',
              onPressed: () {
                _showStatsDialog(context, userStats.value!, isDark);
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                PanAfricanCard(
                  hasGlow: true,
                  glowColor: PanAfricanColors.secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mic, color: PanAfricanColors.secondary, size: 32.sp),
                          SizedBox(width: PanAfricanSpacing.sm),
                          Expanded(
                            child: Text(
                              'Contribute Your Voice',
                              style: PanAfricanTypography.titleLarge(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Text(
                        'Help us build authentic African language voices! Record culturally-accurate words, phrases, and sentences with correct accents and tones. Your contributions help train our AI and preserve linguistic heritage.',
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Row(
                        children: [
                          PanAfricanBadge(
                            label: 'Earn Rewards',
                            icon: Icons.stars,
                            color: PanAfricanColors.secondary,
                          ),
                          SizedBox(width: PanAfricanSpacing.sm),
                          PanAfricanBadge(
                            label: 'Preserve Heritage',
                            icon: Icons.public,
                            color: PanAfricanColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Language & Category Selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                        items: languages.map((lang) {
                          return DropdownMenuItem(
                            value: lang,
                            child: Text(lang.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedLanguage.value = value;
                            selectedPrompt.value = null;
                            audioFile.value = null;
                          }
                        },
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory.value,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? PanAfricanColors.surfaceContainerDark
                              : PanAfricanColors.surfaceContainerLight,
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['value'] as String,
                            child: Row(
                              children: [
                                Icon(cat['icon'] as IconData, size: 18.sp),
                                SizedBox(width: PanAfricanSpacing.xs),
                                Text(cat['label'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedCategory.value = value;
                            selectedPrompt.value = null;
                            audioFile.value = null;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Prompts List
                Text(
                  'Select a Prompt',
                  style: PanAfricanTypography.titleMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.sm),

                if (isLoading.value)
                  Center(child: CircularProgressIndicator())
                else if (prompts.value.isEmpty)
                  PanAfricanCard(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.record_voice_over, size: 48.sp, color: PanAfricanColors.neutralMedium),
                          SizedBox(height: PanAfricanSpacing.sm),
                          Text(
                            'No prompts available',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...prompts.value.map((prompt) {
                    final isSelected = selectedPrompt.value?['id'] == prompt['id'];
                    return PanAfricanCard(
                      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                      hasGradientBorder: isSelected,
                      onTap: () {
                        selectedPrompt.value = prompt;
                        HapticFeedback.mediumImpact();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prompt['text'] ?? '',
                                      style: PanAfricanTypography.titleMedium(context),
                                    ),
                                    if (prompt['translation'] != null) ...[
                                      SizedBox(height: PanAfricanSpacing.xs),
                                      Text(
                                        prompt['translation'],
                                        style: PanAfricanTypography.bodySmall(context),
                                      ),
                                    ],
                                    if (prompt['instructions'] != null) ...[
                                      SizedBox(height: PanAfricanSpacing.xs),
                                      Container(
                                        padding: EdgeInsets.all(PanAfricanSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: PanAfricanColors.info.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 14.sp, color: PanAfricanColors.info),
                                            SizedBox(width: PanAfricanSpacing.xxs),
                                            Expanded(
                                              child: Text(
                                                prompt['instructions'],
                                                style: PanAfricanTypography.labelSmall(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: PanAfricanColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms);
                  }),

                SizedBox(height: PanAfricanSpacing.lg),

                // Audio File Selection
                if (selectedPrompt.value != null) ...[
                  PanAfricanCard(
                    backgroundColor: audioFile.value != null
                        ? PanAfricanColors.success.withOpacity(0.1)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record or Upload Audio',
                          style: PanAfricanTypography.titleMedium(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: pickAudioFile,
                                icon: Icon(audioFile.value != null ? Icons.check : Icons.upload),
                                label: Text(
                                  audioFile.value != null
                                      ? 'Change Audio File'
                                      : 'Select Audio File',
                                ),
                              ),
                            ),
                            SizedBox(width: PanAfricanSpacing.sm),
                            if (audioFile.value != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Play audio preview
                                  },
                                  icon: Icon(Icons.play_arrow),
                                  label: Text('Preview'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PanAfricanColors.primary,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (audioFile.value != null) ...[
                          SizedBox(height: PanAfricanSpacing.sm),
                          Text(
                            'Selected: ${audioFile.value!.path.split('/').last}',
                            style: PanAfricanTypography.bodySmall(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),

                  // Submit Button
                  PanAfricanButton(
                    label: isSubmitting.value ? 'Submitting...' : 'Submit Contribution',
                    icon: Icons.send,
                    onPressed: isSubmitting.value ? null : submitContribution,
                    hasGradient: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context, Map<String, dynamic> stats, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Your Contribution Stats'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stats['totals'] != null) ...[
                Text('Total Approved: ${stats['totals']['approved']}', 
                    style: PanAfricanTypography.bodyLarge(context)),
                Text('Total Pending: ${stats['totals']['pending']}',
                    style: PanAfricanTypography.bodyMedium(context)),
              ],
              if (stats['contributorLevel'] != null) ...[
                SizedBox(height: PanAfricanSpacing.md),
                Text('Level: ${stats['contributorLevel']['level']} ${stats['contributorLevel']['badge']}',
                    style: PanAfricanTypography.titleMedium(context)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

