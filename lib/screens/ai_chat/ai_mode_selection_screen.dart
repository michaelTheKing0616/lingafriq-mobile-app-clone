import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'ai_chat_screen.dart';

/// Beautiful Material 3 Mode Selection Screen
class AIModeSelectionScreen extends StatelessWidget {
  final String language;
  final String languageName;

  const AIModeSelectionScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  final List<Map<String, dynamic>> modes = const [
    {
      'id': 'translate',
      'title': 'Translation',
      'description': 'Translate text with grammar notes',
      'icon': Icons.translate,
      'color': 0xFF1CB0F6, // kenteBlue
    },
    {
      'id': 'explain',
      'title': 'Grammar',
      'description': 'Learn grammar rules and examples',
      'icon': Icons.menu_book,
      'color': 0xFF1B7340, // primary
    },
    {
      'id': 'pronunciation',
      'title': 'Pronunciation',
      'description': 'Perfect your pronunciation',
      'icon': Icons.record_voice_over,
      'color': 0xFFEB8937, // tertiary
    },
    {
      'id': 'story',
      'title': 'Stories',
      'description': 'Cultural stories with vocabulary',
      'icon': Icons.auto_stories,
      'color': 0xFFC4413A, // kenteRed
    },
    {
      'id': 'dialogue',
      'title': 'Dialogue',
      'description': 'Practice conversations',
      'icon': Icons.chat_bubble_outline,
      'color': 0xFF16A085, // kitengeTeal
    },
    {
      'id': 'assess',
      'title': 'Assessment',
      'description': 'Test your proficiency',
      'icon': Icons.assessment,
      'color': 0xFFF7CB46, // secondary
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Mode - $languageName'),
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'How would you like to learn?',
                      style: PanAfricanTypography.headlineMedium(context),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      'Select a mode to start your $languageName journey',
                      style: PanAfricanTypography.bodyMedium(context),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                  ],
                ),
              ),

              // Mode Cards Grid
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(PanAfricanSpacing.lg),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: PanAfricanSpacing.md,
                    mainAxisSpacing: PanAfricanSpacing.md,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: modes.length,
                  itemBuilder: (context, index) {
                    final mode = modes[index];
                    return _ModeCard(
                      mode: mode,
                      language: language,
                      languageName: languageName,
                      isDark: isDark,
                    )
                        .animate(delay: (index * 100).ms)
                        .fadeIn(duration: 300.ms)
                        .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1));
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

class _ModeCard extends StatelessWidget {
  final Map<String, dynamic> mode;
  final String language;
  final String languageName;
  final bool isDark;

  const _ModeCard({
    required this.mode,
    required this.language,
    required this.languageName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(mode['color'] as int);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          SmoothPageRoute(
            child: AIChatScreen(
              language: language,
              languageName: languageName,
              mode: mode['id'] as String,
              modeName: mode['title'] as String,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          boxShadow: PanAfricanShadows.md,
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mode['icon'] as IconData,
                color: color,
                size: 40.sp,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              mode['title'] as String,
              style: PanAfricanTypography.titleMedium(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
              child: Text(
                mode['description'] as String,
                style: PanAfricanTypography.bodySmall(context),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

