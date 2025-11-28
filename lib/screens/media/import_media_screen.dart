import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
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

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

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
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: const CircleBorder(),
                        ),
                      ),
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
                        ElevatedButton(
                          onPressed: () => _importFromFile(),
                          style: ElevatedButton.styleFrom(
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Import Options
            Text(
              'Import Options',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16.sp),
            
            // File Import Card
            _buildImportCard(
              context,
              '📄 Import from File',
              'Import text from a file on your device',
              Icons.insert_drive_file_rounded,
              () => _importFromFile(),
              isDark,
            ),
            SizedBox(height: 12.sp),
            
            // URL Import Card
            _buildImportCard(
              context,
              '🌐 Import from URL',
              'Import content from a web article',
              Icons.language_rounded,
              () => _showUrlImportDialog(context, isDark),
              isDark,
            ),
            SizedBox(height: 12.sp),
            
            // Manual Text Input Card
            _buildImportCard(
              context,
              '✍️ Enter Text Manually',
              'Paste or type text to create a lesson',
              Icons.edit_rounded,
              () => _showManualInputDialog(context, isDark),
              isDark,
            ),
            
            if (_importedText != null) ...[
              SizedBox(height: 24.sp),
              // Language Selection
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 12.sp),
              _buildLanguageSelector(context, isDark),
              SizedBox(height: 24.sp),
              
              // Preview Section
              Text(
                'Preview',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 12.sp),
              _buildPreviewCard(context, _importedText!, isDark),
              SizedBox(height: 24.sp),
              
              // Create Lesson Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedLanguage != null ? () => _createLesson(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create Lesson',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
        allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final text = await file.readAsString();
        setState(() {
          _importedText = text;
          _isLoading = false;
        });
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importFromUrl(_urlController.text);
            },
            style: ElevatedButton.styleFrom(
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
          ElevatedButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                setState(() {
                  _importedText = _textController.text;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
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
    // TODO: Implement web scraping or use WebView to extract text
    // For now, show a placeholder
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _importedText = 'Content from URL would be extracted here. This feature requires web scraping implementation.';
      _isLoading = false;
    });
  }

  void _createLesson(BuildContext context) {
    // TODO: Implement lesson creation from imported text
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lesson creation feature coming soon!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
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

