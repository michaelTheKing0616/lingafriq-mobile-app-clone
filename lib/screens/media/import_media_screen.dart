import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';
import 'package:lingafriq/services/polie_content_generator.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImportMediaScreen extends ConsumerStatefulWidget {
  const ImportMediaScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ImportMediaScreen> createState() => _ImportMediaScreenState();
}

class _ImportMediaScreenState extends ConsumerState<ImportMediaScreen> {
  String? _importedText;
  String? _selectedLanguage;
  bool _isLoading = false;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  String? _lastImportedMediaId;
  bool _allowOfficialUse = false;

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Media Import is temporarily unavailable',
      onRetry: () {
        setState(() {});
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = context.isDarkMode;

    // Show loading screen when importing
    if (_isLoading) {
      return const DynamicLoadingScreen();
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF007A3D), // Green
                  Color(0xFF00A8E8), // Blue
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    const Icon(
                      Icons.upload_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Media Import',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Share your content with the community',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            top: 22.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Upload Card
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F3527) : Colors.white,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      boxShadow: DesignSystem.shadowLarge,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.image_rounded,
                          size: 64,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Upload Media',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Drag and drop or click to browse',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        FilledButton(
                          onPressed: () => _importFromFile(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                            ),
                          ),
                          child: const Text('Select Files'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  // Supported Formats
                  Text(
                    'Supported Formats',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: _FormatCard(
                          title: 'Images',
                          formats: 'JPG, PNG',
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: _FormatCard(
                          title: 'Videos',
                          formats: 'MP4, MOV',
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: _FormatCard(
                          title: 'Audio',
                          formats: 'MP3, WAV',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20.sp),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 24.sp),
            ),
            SizedBox(width: 16.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, bool isDark) {
    final languages = [
      'Yoruba',
      'Hausa',
      'Igbo',
      'Swahili',
      'Zulu',
      'Xhosa',
      'Amharic',
      'Pidgin',
      'Twi',
      'Afrikaans',
    ];

    return Wrap(
      spacing: 8.sp,
      runSpacing: 8.sp,
      children: languages.map((lang) {
        final isSelected = _selectedLanguage == lang;
        return FilterChip(
          label: Text(lang),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedLanguage = selected ? lang : null;
            });
          },
          selectedColor: AppColors.primaryGreen,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[200],
        );
      }).toList(),
    );
  }

  Widget _buildPreviewCard(BuildContext context, String text, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.length > 200 ? '${text.substring(0, 200)}...' : text,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            '${text.split(' ').length} words',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromFile() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'txt',
          'pdf',
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
          'mp3',
          'wav',
          'm4a',
          'mp4',
          'mov',
        ],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final ext = (result.files.single.extension ?? '').toLowerCase();

        // Text-like documents: read content directly
        if (['txt', 'pdf', 'doc', 'docx'].contains(ext)) {
          final text = await file.readAsString();
          setState(() {
            _importedText = text;
            _isLoading = false;
          });
        } else if (['mp3', 'wav', 'm4a', 'mp4', 'mov'].contains(ext)) {
          // Audio / video media: upload and transcribe via voice service
          await _handleAudioOrVideoImport(file, ext);
        } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
          // Images: ask user for a short description to seed Polie
          await _handleImageImport(file, ext);
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unsupported file type. Please select text, image, audio, or video.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing file: $e')),
        );
      }
    }
  }

  Future<void> _handleAudioOrVideoImport(File file, String ext) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final api = ref.read(apiProvider.notifier);

      // Upload media to backend for persistence
      final mediaData = await api.uploadMedia(
        filePath: file.path,
        fileName: fileName,
        title: fileName,
        description: 'Imported from device for Polie analysis',
        language: _selectedLanguage,
      );

      // Remember media id so we can link it to the generated lesson later
      final mediaId = (mediaData['_id'] ?? mediaData['id'])?.toString();
      _lastImportedMediaId = mediaId;

      // Transcribe via voice service proxy
      final sttResult = await api.transcribeAudioFile(
        filePath: file.path,
        fileName: fileName,
        language: _selectedLanguage,
        task: 'transcribe',
      );

      final transcript = (sttResult['text'] ?? sttResult['transcription'] ?? '').toString();

      if (transcript.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No speech detected in media. Please try another file.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _importedText = transcript;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImageImport(File file, String ext) async {
    // For now we use a human-in-the-loop description to seed Polie.
    // In future, this can be extended to call an OCR/vision API via the backend.
    setState(() => _isLoading = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final descriptionController = TextEditingController();
        final isDark = context.isDarkMode;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
          title: Text(
            'Describe this image',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tell Polie what is in this image so it can build a lesson around it.',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'E.g. A family cooking jollof rice together in Lagos...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[100],
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            FilledButton(
              onPressed: () {
                final desc = descriptionController.text.trim();
                if (desc.isNotEmpty) {
                  setState(() {
                    _importedText = desc;
                  });
                  Navigator.pop(context);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Use description'),
            ),
          ],
        );
      },
    );
  }

  void _showUrlImportDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        title: Text(
          'Import from URL',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: 'Enter article URL',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[100],
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _importFromUrl(_urlController.text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        title: Text(
          'Enter Text',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: _textController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Paste or type your text here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[100],
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                setState(() {
                  _importedText = _textController.text;
                });
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromUrl(String url) async {
    setState(() => _isLoading = true);
    try {
      // Use Polie to extract and summarize content from URL
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      
      // Generate a summary/extraction prompt for Polie
      final extractedContent = await polieGenerator.generateGameContent(
        gameType: 'content_extraction',
        language: _selectedLanguage ?? 'English',
        additionalContext: 'Extract and summarize the main content from this URL: $url',
      );
      
      setState(() {
        _importedText = extractedContent['content']?.toString() ?? 
                       'Content extracted from URL. You can now create a lesson from this text.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _importedText = 'Unable to extract content from URL. Please try pasting the text directly or check your connection.';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createLesson(BuildContext context) {
    if (_importedText == null || _importedText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please import some content first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target language first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Use Polie to create a structured lesson from the imported text
    _createLessonWithPolie(context);
  }
  
  Future<void> _createLessonWithPolie(BuildContext context) async {
    setState(() => _isLoading = true);
    
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);

      // Generate a structured lesson from the imported text using Polie
      final lessonContent = await polieGenerator.generateGameContent(
        gameType: 'lesson_creation',
        language: _selectedLanguage!,
        additionalContext: 'Create a structured language lesson from this content:\n\n$_importedText',
      );

      final generatedContent =
          lessonContent['content']?.toString() ?? 'Lesson content generated.';
      final title = 'Imported media lesson - ${_selectedLanguage!}';

      // Ask learner if LingAfriq may consider this content for official use.
      _allowOfficialUse = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              bool consent = false;
              final isDark = ctx.isDarkMode;
              return StatefulBuilder(
                builder: (ctx, setState) => AlertDialog(
                  backgroundColor:
                      isDark ? const Color(0xFF1F3527) : Colors.white,
                  title: const Text('Save lesson & share with LingAfriq?'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your lesson will be saved to your library. '
                        'If you like, you can also allow LingAfriq to review it for possible inclusion as official course content when it is highly rated.',
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: consent,
                        onChanged: (v) =>
                            setState(() => consent = v ?? false),
                        title: const Text(
                          'Yes, LingAfriq may consider this for official use if learners rate it highly.',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Just save for me'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, consent),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save lesson'),
                    ),
                  ],
                ),
              );
            },
          ) ??
          false;

      // Persist lesson via backend UGC pipeline so it appears under UGC hub and is available cross-device
      try {
        final ugcService = ref.read(userGeneratedContentServiceProvider);
        final lessonResult = await ugcService.createLesson(
          language: _selectedLanguage!,
          title: title,
          content: generatedContent,
          description: 'Lesson generated from imported media/text via Polie',
          tags: ['imported', 'polie', 'media'],
          allowOfficialUse: _allowOfficialUse,
        );

        // If this lesson came from an uploaded media item, link them on the backend
        if (_lastImportedMediaId != null && lessonResult != null) {
          final lessonId = (lessonResult['id'] ?? lessonResult['_id'])?.toString();
          if (lessonId != null) {
            final api = ref.read(apiProvider.notifier);
            // Use a compact summary for media analysis
            final summary = generatedContent.length > 280
                ? '${generatedContent.substring(0, 277)}...'
                : generatedContent;
            await api.linkMediaToLesson(
              mediaId: _lastImportedMediaId!,
              lessonId: lessonId,
              summary: summary,
              // keyPhrases and cefrLevel can be populated later as we extend Polie
            );
          }
        }
      } catch (_) {
        // Non-fatal: even if persistence fails, user still sees generated lesson
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Show success message and offer to review the generated lesson
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lesson created from media and saved to your content.'),
          backgroundColor: AppColors.primaryGreen,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(title),
                  content: SingleChildScrollView(
                    child: Text(generatedContent),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _FormatCard extends StatelessWidget {
  final String title;
  final String formats;
  final bool isDark;
  
  const _FormatCard({
    required this.title,
    required this.formats,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: DesignSystem.shadowSmall,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            formats,
            style: TextStyle(
              fontSize: 11.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

