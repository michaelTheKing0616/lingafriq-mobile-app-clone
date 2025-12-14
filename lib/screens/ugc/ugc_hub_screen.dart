import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/screens/ugc/create_lesson_screen.dart';
import 'package:lingafriq/screens/ugc/create_quiz_screen.dart';
import 'package:lingafriq/screens/ugc/create_story_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Hub screen for User-Generated Content
class UGCHubScreen extends ConsumerStatefulWidget {
  const UGCHubScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UGCHubScreen> createState() => _UGCHubScreenState();
}

class _UGCHubScreenState extends ConsumerState<UGCHubScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Create Content'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share Your Knowledge',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Create and share lessons, quizzes, and stories with the community',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 24.sp),
            
            // Create Lesson Card
            _ContentTypeCard(
              title: 'Create Lesson',
              description: 'Share your knowledge by creating a lesson',
              icon: Icons.menu_book,
              color: Colors.blue,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateLessonScreen()),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lesson created!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 16.sp),
            
            // Create Quiz Card
            _ContentTypeCard(
              title: 'Create Quiz',
              description: 'Test knowledge with interactive quizzes',
              icon: Icons.quiz,
              color: Colors.purple,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateQuizScreen()),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quiz created!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 16.sp),
            
            // Create Story Card
            _ContentTypeCard(
              title: 'Create Story',
              description: 'Share cultural stories and narratives',
              icon: Icons.auto_stories,
              color: Colors.orange,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateStoryScreen()),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Story created!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 24.sp),
            
            // My Content Section
            Text(
              'My Content',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16.sp),
            
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(userGeneratedContentServiceProvider).getUserContent(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Error loading content: ${snapshot.error}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  );
                }
                
                final content = snapshot.data ?? [];
                
                if (content.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.sp),
                      child: Text(
                        'No content created yet. Start creating!',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: content.map((item) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 8.sp),
                      child: ListTile(
                        title: Text(item['title'] ?? 'Untitled'),
                        subtitle: Text(item['type'] ?? 'content'),
                        trailing: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () async {
                            final ugcService = ref.read(userGeneratedContentServiceProvider);
                            await ugcService.shareContent(
                              contentId: item['id'] ?? '',
                              contentType: item['type'] ?? 'lesson',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Content shared!'),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContentTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
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
                      description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


