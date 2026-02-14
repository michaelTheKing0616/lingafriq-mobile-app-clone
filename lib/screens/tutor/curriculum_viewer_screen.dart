import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/screens/curriculum/lesson_detail_screen.dart';
import 'package:lingafriq/models/curriculum_model.dart';

class CurriculumViewerScreen extends StatelessWidget {
  final Map<String, dynamic> curriculum;

  const CurriculumViewerScreen({super.key, required this.curriculum});

  @override
  Widget build(BuildContext context) {
    final weeks = (curriculum['weeks'] as List?) ?? [];
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('${curriculum['language']} - ${curriculum['level']}'),
        backgroundColor: PanAfricanColors.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: weeks.length,
        itemBuilder: (context, wIndex) {
          final week = weeks[wIndex] as Map<String, dynamic>;
          final lessons = (week['lessons'] as List?) ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: isDark ? Colors.grey[800] : Theme.of(context).colorScheme.surface,
            child: ExpansionTile(
              title: Text(
                'Week ${week['week']}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.adaptive,
                ),
              ),
              children: lessons.map<Widget>((lesson) {
                final lessonMap = lesson as Map<String, dynamic>;
                return ListTile(
                  title: Text(
                    lessonMap['title'] ?? 'Untitled Lesson',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: context.adaptive,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lessonMap['objectives'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Objectives:',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: context.adaptive54,
                          ),
                        ),
                        ...((lessonMap['objectives'] as List?) ?? [])
                            .map((obj) => Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 4),
                                  child: Text(
                                    '• $obj',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: context.adaptive54,
                                    ),
                                  ),
                                )),
                      ],
                      if (lessonMap['vocab'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Vocabulary: ${(lessonMap['vocab'] as List?)?.length ?? 0} words',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: PanAfricanColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: PanAfricanColors.primary,
                  ),
                  onTap: () {
                    // Convert lesson map to CurriculumLesson object
                    try {
                      final lessonObj = CurriculumLesson.fromMap({
                        'id': lessonMap['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        'title': lessonMap['title'] ?? 'Untitled Lesson',
                        'vocab': lessonMap['vocab'] ?? [],
                        'exercises': lessonMap['exercises'] ?? [],
                        'grammar': lessonMap['grammar'],
                        'dialogue': lessonMap['dialogue'],
                        'duration_min': lessonMap['duration_min'],
                        'is_completed': lessonMap['is_completed'] ?? false,
                        'objectives': lessonMap['objectives'] ?? [],
                      });
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonDetailScreen(
                            lesson: lessonObj,
                            language: curriculum['language'] ?? 'Unknown',
                            level: curriculum['level'] ?? 'Beginner',
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error loading lesson: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

