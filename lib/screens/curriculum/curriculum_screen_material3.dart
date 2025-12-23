import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/curriculum/lesson_detail_screen.dart';

/// Beautiful Material 3 Curriculum Screen
class CurriculumScreenMaterial3 extends HookConsumerWidget {
  const CurriculumScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState('yoruba');
    final selectedLevel = useState('A1');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu'];
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

    // Mock curriculum data - replace with actual provider
    final weeks = useState<List<Map<String, dynamic>>>([]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Curriculum'),
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
        child: Column(
          children: [
            // Language and Level Selectors
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Row(
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
                            ? PanAfricanColors.surfaceDark
                            : PanAfricanColors.surfaceLight,
                      ),
                      items: languages.map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Text(lang.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) selectedLanguage.value = value;
                      },
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedLevel.value,
                      decoration: InputDecoration(
                        labelText: 'Level',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? PanAfricanColors.surfaceDark
                            : PanAfricanColors.surfaceLight,
                      ),
                      items: levels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) selectedLevel.value = value;
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Curriculum Content
            Expanded(
              child: weeks.value.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64.sp,
                            color: PanAfricanColors.neutralMedium,
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            'No curriculum available',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      itemCount: weeks.value.length,
                      itemBuilder: (context, index) {
                        final week = weeks.value[index];
                        return _WeekCard(
                          week: week,
                          isDark: isDark,
                          onTap: () {
                            // Navigate to week details
                          },
                        )
                            .animate(delay: (index * 50).ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.2);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final Map<String, dynamic> week;
  final bool isDark;
  final VoidCallback onTap;

  const _WeekCard({
    required this.week,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lessons = week['lessons'] as List? ?? [];
    final completedLessons = lessons.where((l) => l['completed'] == true).length;
    final progress = lessons.isNotEmpty ? completedLessons / lessons.length : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    week['title'] ?? 'Week ${week['week']}',
                    style: PanAfricanTypography.titleLarge(context),
                  ),
                  Chip(
                    label: Text('${completedLessons}/${lessons.length}'),
                    backgroundColor: PanAfricanColors.primaryContainer.withOpacity(0.3),
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                week['description'] ?? '',
                style: PanAfricanTypography.bodyMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: PanAfricanColors.neutralLight,
                valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                minHeight: 8.h,
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Wrap(
                spacing: PanAfricanSpacing.sm,
                children: lessons.take(3).map((lesson) {
                  return Chip(
                    label: Text(
                      lesson['title'] ?? 'Lesson',
                      style: PanAfricanTypography.labelSmall(context),
                    ),
                    backgroundColor: lesson['completed'] == true
                        ? PanAfricanColors.success.withOpacity(0.2)
                        : PanAfricanColors.neutralLight.withOpacity(0.3),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

