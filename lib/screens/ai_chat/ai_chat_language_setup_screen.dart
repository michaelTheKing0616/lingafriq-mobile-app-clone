import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full-screen language picker for Polie
/// Lets users choose conversation/learning language and primes the model
class AiChatLanguageSetupScreen extends ConsumerStatefulWidget {
  final PolieMode initialMode;
  final VoidCallback? onBack;

  const AiChatLanguageSetupScreen({
    Key? key,
    this.initialMode = PolieMode.translation,
    this.onBack,
  }) : super(key: key);

  @override
  ConsumerState<AiChatLanguageSetupScreen> createState() =>
      _AiChatLanguageSetupScreenState();
}

class _AiChatLanguageSetupScreenState
    extends ConsumerState<AiChatLanguageSetupScreen> {
  late PolieMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  Future<void> _selectLanguage(String language) async {
    final chat = ref.read(groqChatProvider.notifier);
    // Prime mode and language before entering chat
    await chat.setMode(_mode);
    await chat.setLanguageDirection('English', language);
    await chat.setLanguage(language);
    if (!mounted) return;
    await ref.read(navigationProvider).naviateTo(const AiChatScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = ref.read(groqChatProvider.notifier).supportedLanguageOptions;

    return ErrorBoundary(
      errorMessage: 'AI Chat setup is temporarily unavailable',
      onRetry: () => setState(() {}),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1F15) : Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: isDark ? Colors.white : Colors.black87,
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
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Polie will default to this language unless you ask otherwise.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Mode toggle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: SegmentedButton<PolieMode>(
                  segments: const [
                    ButtonSegment(
                      value: PolieMode.translation,
                      icon: Icon(Icons.translate_rounded),
                      label: Text('Translator'),
                    ),
                    ButtonSegment(
                      value: PolieMode.tutor,
                      icon: Icon(Icons.school_rounded),
                      label: Text('Tutor'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      setState(() {
                        _mode = selection.first;
                      });
                    }
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              // Language grid
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(4.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    mainAxisSpacing: 3.w,
                    crossAxisSpacing: 3.w,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final name = lang['name'] ?? '';
                    final flag = lang['flag'] ?? '🌍';

                    return InkWell(
                      onTap: () => _selectLanguage(name),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3325)
                              : const Color(0xFFF5F7F5),
                          borderRadius:
                              BorderRadius.circular(DesignSystem.radiusXL),
                          border: Border.all(
                            color: const Color(0xFF00A86B).withOpacity(0.2),
                            width: 1.2,
                          ),
                          boxShadow: DesignSystem.shadowMedium,
                        ),
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              flag,
                              style: TextStyle(fontSize: 32.sp),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              _mode == PolieMode.translation
                                  ? 'Translate with Polie'
                                  : 'Tutor me in this',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
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
}

