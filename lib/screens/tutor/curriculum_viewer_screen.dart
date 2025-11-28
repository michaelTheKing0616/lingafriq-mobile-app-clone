import 'package:flutter/material.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';

class CurriculumViewerScreen extends StatelessWidget {
  final Map<String, dynamic> curriculum;

  const CurriculumViewerScreen({Key? key, required this.curriculum})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final weeks = (curriculum['weeks'] as List?) ?? [];
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('${curriculum['language']} - ${curriculum['level']}'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: weeks.length,
        itemBuilder: (context, wIndex) {
          final week = weeks[wIndex] as Map<String, dynamic>;
          final lessons = (week['lessons'] as List?) ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: isDark ? Colors.grey[800] : Colors.white,
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
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                  onTap: () {
                    // Navigate to lesson detail
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

