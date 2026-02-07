import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart' hide ErrorBoundary;
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';
import 'package:lingafriq/services/polie_content_generator.dart';
import 'package:lingafriq/providers/navigation_provider.dart';

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
  /// Media uploaded to backend (for transcription/translation/lesson)
  String? _uploadedMediaId;
  String _processingStatus = 'idle'; // idle | pending | processing | completed | failed
  String? _processingError;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Unable to load media import. Please check your connection and try again.',
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
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.forest,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: PanAfricanShadows.lg,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(PanAfricanIcons.back, color: Colors.white),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(PanAfricanIcons.menu, color: Colors.white),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final scaffoldState = Scaffold.of(context);
                            scaffoldState.openDrawer();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    const Icon(
                      Icons.upload_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      'Media Import',
                      style: PanAfricanTypography.headlineMedium(context, color: Colors.white),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      'Share your content with the community',
                      style: PanAfricanTypography.bodyMedium(context, color: Colors.white.withOpacity(0.9)),
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
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                children: [
                  // Upload Card
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.xl),
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      borderRadius: PanAfricanRadius.xlBR,
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
                          Icons.image_rounded,
                          size: 64.sp,
                          color: PanAfricanColors.primary,
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        Text(
                          'Upload Media',
                          style: PanAfricanTypography.titleLarge(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          'Drag and drop or click to browse',
                          style: PanAfricanTypography.bodyMedium(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),
                        FilledButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _importFromFile();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: PanAfricanColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg, vertical: PanAfricanSpacing.sm),
                            shape: RoundedRectangleBorder(
                              borderRadius: PanAfricanRadius.roundBR,
                            ),
                          ),
                          child: Text('Select Files', style: PanAfricanTypography.labelLarge(context, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                  // Supported Formats
                  Text(
                    'Supported Formats',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _FormatCard(
                          title: 'Images',
                          formats: 'JPG, PNG, WEBP',
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Expanded(
                        child: _FormatCard(
                          title: 'Videos',
                          formats: 'MP4, MOV',
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Expanded(
                        child: _FormatCard(
                          title: 'Audio',
                          formats: 'MP3, WAV, M4A',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Text(
                    'Text (TXT) is read directly. Images/audio/video are uploaded, transcribed, translated, and can become lessons.',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Text('Target language', style: PanAfricanTypography.titleSmall(context)),
                  SizedBox(height: PanAfricanSpacing.xs),
                  _buildLanguageSelector(context, isDark),
                  if (_processingStatus == 'pending' || _processingStatus == 'processing') ...[
                    SizedBox(height: PanAfricanSpacing.lg),
                    LinearProgressIndicator(color: PanAfricanColors.primary),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      'Transcribing and translating…',
                      style: PanAfricanTypography.bodyMedium(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
                    ),
                  ],
                  if (_processingError != null) ...[
                    SizedBox(height: PanAfricanSpacing.md),
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      decoration: BoxDecoration(
                        color: PanAfricanColors.error.withOpacity(0.15),
                        borderRadius: PanAfricanRadius.lgBR,
                      ),
                      child: Row(
                        children: [
                          Icon(PanAfricanIcons.error, color: PanAfricanColors.error, size: 20.sp),
                          SizedBox(width: PanAfricanSpacing.sm),
                          Expanded(child: Text(_processingError!, style: PanAfricanTypography.bodySmall(context, color: PanAfricanColors.error))),
                        ],
                      ),
                    ),
                  ],
                  if (_importedText != null && _importedText!.isNotEmpty) ...[
                    SizedBox(height: PanAfricanSpacing.lg),
                    _buildPreviewCard(context, _importedText!, isDark),
                    SizedBox(height: PanAfricanSpacing.md),
                    FilledButton(
                      onPressed: _isLoading ? null : () {
                        HapticFeedback.mediumImpact();
                        _createLesson(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg, vertical: PanAfricanSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: PanAfricanRadius.roundBR,
                        ),
                      ),
                      child: Text('Create lesson', style: PanAfricanTypography.labelLarge(context, color: Colors.white)),
                    ),
                  ],
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
                color: PanAfricanColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PanAfricanColors.primary, size: 24.sp),
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
      spacing: PanAfricanSpacing.xs,
      runSpacing: PanAfricanSpacing.xs,
      children: languages.map((lang) {
        final isSelected = _selectedLanguage == lang;
        return FilterChip(
          label: Text(lang, style: PanAfricanTypography.labelMedium(context, color: isSelected ? Colors.white : (isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight))),
          selected: isSelected,
          onSelected: (selected) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedLanguage = selected ? lang : null;
            });
          },
          selectedColor: PanAfricanColors.primary,
          checkmarkColor: Colors.white,
          backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        );
      }).toList(),
    );
  }

  Widget _buildPreviewCard(BuildContext context, String text, bool isDark) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.length > 200 ? '${text.substring(0, 200)}...' : text,
            style: PanAfricanTypography.bodyMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            '${text.split(' ').length} words',
            style: PanAfricanTypography.labelSmall(context),
          ),
        ],
      ),
    );
  }

  /// Backend-supported media extensions (upload → transcribe/translate → lesson)
  static const List<String> _uploadExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg',
    'mp3', 'wav', 'ogg', 'webm', 'aac', 'm4a',
    'mp4', 'mov',
  ];

  Future<void> _importFromFile() async {
    setState(() => _isLoading = true);
    _processingError = null;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', ..._uploadExtensions],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isLoading = false);
        return;
      }

      final path = result.files.single.path!;
      final name = result.files.single.name;
      final ext = (name.split('.').lastOrNull ?? '').toLowerCase();

      // Text: read directly (safe; no binary)
      if (ext == 'txt') {
        final file = File(path);
        final bytes = await file.length();
        if (bytes > 2 * 1024 * 1024) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Text file too large. Use a file under 2 MB.')),
            );
          }
          return;
        }
        final text = await file.readAsString();
        setState(() {
          _importedText = text;
          _uploadedMediaId = null;
          _processingStatus = 'idle';
          _isLoading = false;
        });
        return;
      }

      // Image/Audio/Video: upload to backend for transcription/translation/lesson
      if (!_uploadExtensions.contains(ext)) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supported: TXT (direct), or images/audio/video (upload for transcription).'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await ApiService.initialize();
      final resp = await ApiService.uploadFile(
        'media/upload',
        path,
        additionalData: {
          'title': name,
          if (_selectedLanguage != null) 'language': _selectedLanguage!,
        },
      );

      if (resp.statusCode != 201 && resp.statusCode != 200) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resp.data is Map ? (resp.data['message'] ?? resp.data['error'] ?? 'Upload failed').toString() : 'Upload failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = resp.data is Map ? resp.data as Map<String, dynamic> : null;
      final media = data?['data'] is Map ? data!['data'] as Map<String, dynamic> : data;
      final id = media?['_id']?.toString() ?? media?['id']?.toString();
      if (id == null || id.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload succeeded but server did not return media ID.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      setState(() {
        _uploadedMediaId = id;
        _processingStatus = 'pending';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploaded. Transcribing and translating…'),
            backgroundColor: PanAfricanColors.primary,
          ),
        );
      }
      _pollMediaStatus();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pollMediaStatus() async {
    if (_uploadedMediaId == null) return;
    _pollTimer?.cancel();
    final id = _uploadedMediaId!;

    Future<void> check() async {
      try {
        await ApiService.initialize();
        final resp = await ApiService.get('media/$id/analysis');
        if (resp.statusCode != 200 || resp.data == null) return;
        final data = resp.data is Map ? resp.data as Map<String, dynamic> : null;
        final analysis = data?['data'] is Map ? data!['data'] as Map<String, dynamic> : data;
        final status = analysis?['processing_status']?.toString();
        final transcription = analysis?['transcription']?.toString();
        final translation = analysis?['translation']?.toString();
        final error = analysis?['processing_error']?.toString();

        if (!mounted) return;
        if (status == 'completed') {
          _pollTimer?.cancel();
          setState(() {
            _processingStatus = 'completed';
            _importedText = (transcription ?? translation ?? '').trim();
            _processingError = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transcription and translation ready.'), backgroundColor: PanAfricanColors.primary),
            );
          }
          return;
        }
        if (status == 'failed') {
          _pollTimer?.cancel();
          setState(() {
            _processingStatus = 'failed';
            _processingError = error ?? 'Processing failed';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_processingError ?? 'Processing failed'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        setState(() => _processingStatus = status ?? 'processing');
      } catch (_) {
        // Ignore poll errors; will retry next tick
      }
    }

    await check();
    if (!mounted || _processingStatus == 'completed' || _processingStatus == 'failed') return;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => check());
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
              backgroundColor: PanAfricanColors.primary,
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
              backgroundColor: PanAfricanColors.primary,
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

    if (_uploadedMediaId != null) {
      _createLessonFromBackendMedia(context);
      return;
    }
    _createLessonWithPolie(context);
  }

  Future<void> _createLessonFromBackendMedia(BuildContext context) async {
    if (_uploadedMediaId == null || _selectedLanguage == null) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.initialize();
      final resp = await ApiService.post(
        'media/$_uploadedMediaId/generate-lesson',
        data: {
          'language': _selectedLanguage!,
          'userLevel': 'A1',
        },
      );
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data is Map ? resp.data as Map<String, dynamic> : null;
        final lessonData = data?['data'] ?? data;
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson created successfully!'),
              backgroundColor: PanAfricanColors.primary,
              action: SnackBarAction(
                label: 'View',
                onPressed: () {},
              ),
            ),
          );
          final lessonId = lessonData is Map ? lessonData['id'] ?? lessonData['_id'] : null;
          if (lessonId != null) {
            Navigator.pushNamed(context, '/lesson-detail', arguments: {'lessonId': lessonId})
                .catchError((_) => Navigator.pushNamed(context, '/curriculum'));
          } else {
            Navigator.pushNamed(context, '/curriculum').catchError((_) {});
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resp.data is Map ? (resp.data['message'] ?? resp.data['error'] ?? 'Failed to create lesson').toString() : 'Failed to create lesson'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _createLessonWithPolie(BuildContext context) async {
    setState(() => _isLoading = true);
    
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      
      // Generate a structured lesson from the imported text
      final lessonContent = await polieGenerator.generateGameContent(
        gameType: 'lesson_creation',
        language: _selectedLanguage!,
        additionalContext: 'Create a structured language lesson from this content:\n\n$_importedText',
      );
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        // Show success message and offer to save/navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lesson created successfully!'),
            backgroundColor: PanAfricanColors.primary,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to lesson detail screen if lesson ID is available
                final lessonId = lessonContent['lesson_id']?.toString();
                if (lessonId != null) {
                  Navigator.pushNamed(
                    context,
                    '/lesson-detail',
                    arguments: {'lessonId': lessonId},
                  ).catchError((e) {
                    // Fallback to curriculum screen if lesson detail route doesn't exist
                    Navigator.pushNamed(
                      context,
                      '/curriculum',
                    );
                  });
                } else {
                  // Navigate to curriculum screen to view all lessons
                  Navigator.pushNamed(
                    context,
                    '/curriculum',
                  );
                }
              },
            ),
          ),
        );
      }
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
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: PanAfricanTypography.labelLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Text(
            formats,
            style: PanAfricanTypography.labelSmall(context),
          ),
        ],
      ),
    );
  }
}

