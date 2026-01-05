import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'import_media_dialogs.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';

/// Enhanced Import Media Screen with Transcription Preview, Lesson Generation Preview, Edit/Customize
class ImportMediaScreenEnhanced extends HookConsumerWidget {
  const ImportMediaScreenEnhanced({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = useState<PlatformFile?>(null);
    final languageController = useTextEditingController(text: 'yoruba');
    final transcriptionResult = useState<Map<String, dynamic>?>(null);
    final lessonResult = useState<Map<String, dynamic>?>(null);
    final isUploading = useState(false);
    final isTranscribing = useState(false);
    final isGeneratingLesson = useState(false);
    final showTranscriptionPreview = useState(false);
    final showLessonPreview = useState(false);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> pickFile() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.media,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          selectedFile.value = result.files.single;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: ${e.toString()}')),
        );
      }
    }

    Future<void> _pollTranscription(String mediaId) async {
      for (int i = 0; i < 30; i++) {
        await Future.delayed(Duration(seconds: 2));
        try {
          final response = await ApiService.get(Api.mediaDetails(mediaId));

          if (response.statusCode == 200) {
            final media = response.data['data'];
            if (media['processing_status'] == 'completed' && media['transcription'] != null) {
              transcriptionResult.value = {
                'transcription': media['transcription'],
                'translation': media['translation'],
                'mediaId': mediaId,
              };
              showTranscriptionPreview.value = true;
              break;
            } else if (media['processing_status'] == 'failed') {
              throw Exception('Transcription failed');
            }
          }
        } catch (e) {
          // Continue polling
        }
      }
    }

    Future<void> uploadAndTranscribe() async {
      if (selectedFile.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a file first')),
        );
        return;
      }

      isUploading.value = true;
      try {
        // Upload file
        final uploadResponse = await ApiService.uploadFile(
          Api.mediaUpload(),
          selectedFile.value!.path!,
          additionalData: {
            'title': selectedFile.value!.name,
            'language': languageController.text,
          },
        );

        if (uploadResponse.statusCode == 200) {
          final mediaId = uploadResponse.data['data']['_id'];
          
          // Start transcription
          isTranscribing.value = true;
          final transcribeResponse = await ApiService.post(
            Api.mediaTranscribe(mediaId),
            data: {
              'language': languageController.text,
            },
          );

          if (transcribeResponse.statusCode == 202) {
            // Poll for transcription result
            await _pollTranscription(mediaId);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload/transcription failed: ${e.toString()}')),
        );
      } finally {
        isUploading.value = false;
        isTranscribing.value = false;
      }
    }

    Future<void> generateLesson() async {
      if (transcriptionResult.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please transcribe media first')),
        );
        return;
      }

      isGeneratingLesson.value = true;
      try {
        final mediaId = transcriptionResult.value!['mediaId'];
        final response = await ApiService.post(
          Api.mediaGenerateLesson(mediaId),
          data: {
            'language': languageController.text,
            'userLevel': 'A1',
          },
        );

        if (response.statusCode == 200) {
          lessonResult.value = response.data['data'];
          showLessonPreview.value = true;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lesson generation failed: ${e.toString()}')),
        );
      } finally {
        isGeneratingLesson.value = false;
      }
    }

    final isLoading = useState(false);
    
    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Processing media...',
      child: Scaffold(
        appBar: AppBar(
          title: Text('Import Media'),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                // File Picker
                _buildFilePicker(
                  context,
                  selectedFile.value,
                  pickFile,
                  isDark,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Language Selector
                TextField(
                  controller: languageController,
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
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Upload & Transcribe Button
                ElevatedButton.icon(
                  onPressed: (isUploading.value || isTranscribing.value) ? null : uploadAndTranscribe,
                  icon: (isUploading.value || isTranscribing.value)
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.upload_file),
                  label: Text(
                    isTranscribing.value
                        ? 'Transcribing...'
                        : isUploading.value
                            ? 'Uploading...'
                            : 'Upload & Transcribe',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xl),

                // Transcription Preview
                if (showTranscriptionPreview.value && transcriptionResult.value != null)
                  _buildTranscriptionPreview(
                    context,
                    transcriptionResult.value!,
                    showTranscriptionPreview.value,
                    (show) => showTranscriptionPreview.value = show,
                    isDark,
                    (updatedResult) {
                      transcriptionResult.value = updatedResult;
                    },
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),

                // Edit Transcription Button
                if (transcriptionResult.value != null && !showTranscriptionPreview.value)
                  TextButton.icon(
                    onPressed: () => showTranscriptionPreview.value = true,
                    icon: Icon(Icons.edit),
                    label: Text('Edit Transcription'),
                  ),

                // Generate Lesson Button
                if (transcriptionResult.value != null && !showLessonPreview.value) ...[
                  SizedBox(height: PanAfricanSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: isGeneratingLesson.value ? null : generateLesson,
                    icon: isGeneratingLesson.value
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.auto_stories),
                    label: Text(
                      isGeneratingLesson.value
                          ? 'Generating Lesson...'
                          : 'Generate Lesson',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PanAfricanColors.secondary,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                    ),
                  ),
                ],

                // Lesson Preview
                if (showLessonPreview.value && lessonResult.value != null)
                  _buildLessonPreview(
                    context,
                    lessonResult.value!,
                    showLessonPreview.value,
                    (show) => showLessonPreview.value = show,
                    isDark,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(
    BuildContext context,
    PlatformFile? file,
    VoidCallback onPick,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          border: Border.all(
            color: PanAfricanColors.primary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: PanAfricanShadows.md,
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64.sp,
              color: PanAfricanColors.primary,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              file?.name ?? 'Tap to select audio/video file',
              style: PanAfricanTypography.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            if (file != null) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                style: PanAfricanTypography.bodySmall(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionPreview(
    BuildContext context,
    Map<String, dynamic> result,
    bool isExpanded,
    Function(bool) onToggle,
    bool isDark,
    Function(Map<String, dynamic>) onUpdateResult,
  ) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: ExpansionTile(
        title: Text(
          'Transcription Preview',
          style: PanAfricanTypography.titleMedium(context),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onToggle,
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original Text',
                  style: PanAfricanTypography.labelMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  result['transcription'] ?? '',
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                if (result['translation'] != null) ...[
                  SizedBox(height: PanAfricanSpacing.md),
                  Divider(),
                  SizedBox(height: PanAfricanSpacing.md),
                  Text(
                    'Translation',
                    style: PanAfricanTypography.labelMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    result['translation'],
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ],
                SizedBox(height: PanAfricanSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditTranscriptionDialog(
                            initialText: result['transcription'] ?? '',
                            onSave: (editedText) {
                              onUpdateResult({
                                ...result,
                                'transcription': editedText,
                              });
                            },
                          ),
                        );
                      },
                      icon: Icon(Icons.edit),
                      label: Text('Edit'),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => CustomizeTranscriptionDialog(
                            transcription: result['transcription'] ?? '',
                            onCustomize: (customized) {
                              // Apply customizations
                            },
                          ),
                        );
                      },
                      icon: Icon(Icons.tune),
                      label: Text('Customize'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPreview(
    BuildContext context,
    Map<String, dynamic> lesson,
    bool isExpanded,
    Function(bool) onToggle,
    bool isDark,
  ) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: ExpansionTile(
        title: Text(
          'Generated Lesson Preview',
          style: PanAfricanTypography.titleMedium(context),
        ),
        subtitle: Text(lesson['title'] ?? 'Lesson'),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onToggle,
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lesson['sections'] != null)
                  ...(lesson['sections'] as List).map((section) {
                    final sec = section as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                      child: ListTile(
                        leading: Icon(_getIconForSectionType(sec['type'])),
                        title: Text(sec['type'] ?? ''),
                        subtitle: Text(
                          sec['content'] ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }),
                SizedBox(height: PanAfricanSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Show edit dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Edit Lesson'),
                            content: Text('Lesson editing will be available in a future update.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.edit),
                      label: Text('Edit'),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Save lesson to backend
                        try {
                          final ugcService = ref.read(userGeneratedContentServiceProvider);
                          
                          // Convert sections to content string
                          final sections = lesson['sections'] as List? ?? [];
                          final contentString = sections.map((s) {
                            final sec = s as Map<String, dynamic>;
                            return '${sec['type']}: ${sec['content']}';
                          }).join('\n\n');

                          final result = await ugcService.createLesson(
                            language: languageController.text,
                            title: lesson['title']?.toString() ?? 'Generated Lesson',
                            content: contentString,
                            description: 'Lesson generated from imported media',
                            tags: ['imported', 'media-generated'],
                          );

                          if (result != null) {
                            // Link media to lesson
                            if (transcriptionResult.value?['mediaId'] != null) {
                              try {
                                await ApiService.post(
                                  'media/${transcriptionResult.value!['mediaId']}/link-lesson',
                                  data: {
                                    'lesson_id': result['id'],
                                  },
                                );
                              } catch (e) {
                                // Non-critical error
                                debugPrint('Failed to link media to lesson: $e');
                              }
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lesson saved successfully!'),
                                  backgroundColor: Colors.green,
                                  action: SnackBarAction(
                                    label: 'View',
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } else {
                            throw Exception('Failed to save lesson');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save lesson: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.save),
                      label: Text('Save Lesson'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForSectionType(String? type) {
    switch (type) {
      case 'introduction':
        return Icons.info;
      case 'vocabulary':
        return Icons.book;
      case 'grammar':
        return Icons.menu_book;
      case 'practice':
        return Icons.fitness_center;
      case 'cultural':
        return Icons.public;
      default:
        return Icons.description;
    }
  }
}

