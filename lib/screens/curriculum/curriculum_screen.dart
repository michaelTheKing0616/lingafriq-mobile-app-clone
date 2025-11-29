import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/providers/curriculum_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CurriculumScreen extends ConsumerStatefulWidget {
  const CurriculumScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends ConsumerState<CurriculumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurriculum();
    });
  }

  Future<void> _loadCurriculum() async {
    try {
      await ref.read(curriculumProvider.notifier).loadCurriculumFromBundle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading curriculum: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final curriculum = ref.watch(curriculumProvider.notifier).curriculum;
    final selectedLanguage = ref.watch(curriculumProvider.notifier).selectedLanguage;
    final isLoading = ref.watch(curriculumProvider.select((state) => state.isLoading));
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Comprehensive Curriculum'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black87),
            onPressed: _loadCurriculum,
            tooltip: 'Reload Curriculum',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : curriculum == null
              ? _buildEmptyState(context, isDark)
              : _buildCurriculumContent(context, curriculum, selectedLanguage, isDark),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64.sp,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16.sp),
          Text(
            'No curriculum loaded',
            style: TextStyle(
              fontSize: 18.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.sp),
          ElevatedButton(
            onPressed: _loadCurriculum,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Load Curriculum'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumContent(
    BuildContext context,
    Curriculum curriculum,
    String? selectedLanguage,
    bool isDark,
  ) {
    return Column(
      children: [
        // Language Selection
        Container(
          padding: EdgeInsets.all(16.sp),
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 12.sp),
              Wrap(
                spacing: 8.sp,
                runSpacing: 8.sp,
                children: curriculum.meta.languages.map((lang) {
                  final isSelected = selectedLanguage == lang;
                  return FilterChip(
                    label: Text(lang.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(curriculumProvider.notifier).setSelectedLanguage(lang);
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
              ),
            ],
          ),
        ),

        // Levels and Units
        if (selectedLanguage != null)
          Expanded(
            child: _buildLevelsView(context, selectedLanguage, isDark),
          )
        else
          Expanded(
            child: Center(
              child: Text(
                'Select a language to view curriculum',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLevelsView(BuildContext context, String language, bool isDark) {
    final levels = ref.read(curriculumProvider.notifier).getLevelsForLanguage(language);

    return ListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        return _buildLevelCard(context, level, language, isDark);
      },
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    CurriculumLevel level,
    String language,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
        childrenPadding: EdgeInsets.all(16.sp),
        leading: Container(
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            level.level,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        title: Text(
          'Level ${level.level}',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.sp),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: level.calculatedProgress,
                minHeight: 8,
                backgroundColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
            SizedBox(height: 4.sp),
            Text(
              '${(level.calculatedProgress * 100).toInt()}% complete • ${level.units.length} units',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        children: level.units.map((unit) {
          return _buildUnitCard(context, unit, language, level.level, isDark);
        }).toList(),
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    CurriculumUnit unit,
    String language,
    String level,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A4A35) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A5A45) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Unit ${unit.unit}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(width: 8.sp),
              if (unit.isCompleted)
                Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20.sp),
            ],
          ),
          SizedBox(height: 4.sp),
          Text(
            unit.title,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          SizedBox(height: 12.sp),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: unit.calculatedProgress,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF3A5A45) : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
          SizedBox(height: 12.sp),
          ...unit.lessons.map((lesson) {
            return _buildLessonTile(context, lesson, language, level, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildLessonTile(
    BuildContext context,
    CurriculumLesson lesson,
    String language,
    String level,
    bool isDark,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      leading: Container(
        width: 40.sp,
        height: 40.sp,
        decoration: BoxDecoration(
          color: lesson.isCompleted
              ? AppColors.primaryGreen.withOpacity(0.2)
              : (isDark ? const Color(0xFF3A5A45) : Colors.grey[200]),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: lesson.isCompleted
              ? Icon(Icons.check, color: AppColors.primaryGreen, size: 20.sp)
              : Text(
                  '${lesson.vocab.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
        ),
      ),
      title: Text(
        lesson.title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        '${lesson.vocab.length} words • ${lesson.exercises.length} exercises',
        style: TextStyle(
          fontSize: 12.sp,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          lesson.isCompleted ? Icons.undo : Icons.play_circle_outline,
          color: lesson.isCompleted
              ? AppColors.primaryGreen
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        onPressed: () {
          if (!lesson.isCompleted) {
            ref.read(curriculumProvider.notifier).markLessonComplete(
                  language,
                  level,
                  lesson.id,
                );
            // TODO: Navigate to lesson screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Starting lesson: ${lesson.title}'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
        },
      ),
    );
  }
}


