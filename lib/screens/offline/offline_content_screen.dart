import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/offline_content_provider.dart';
import 'package:lingafriq/providers/offline_download_provider.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/models/offline/local_lesson.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/widgets/animated/animated_card.dart';
import 'package:lingafriq/widgets/animated/animated_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/subscription/subscription_screen.dart';

/// Screen for managing offline content downloads
class OfflineContentScreen extends ConsumerWidget {
  const OfflineContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineContent = ref.watch(offlineContentProvider);
    final subscriptionNotifier = ref.read(subscriptionProvider.notifier);
    final hasOfflineAccess = subscriptionNotifier.hasFeature('offline_mode');

    if (!hasOfflineAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offline Mode')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16.h),
              Text(
                'Offline Mode Requires Premium',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Subscribe to Premium to download content for offline use',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24.h),
              AnimatedButton(
                text: 'View Plans',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Content'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        color: AfricanTheme.primaryGreen,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        ref.read(offlineContentProvider.notifier).getFormattedSize(),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideX(begin: -0.1),
            SizedBox(height: 24.h),
            Text(
              'Download Languages',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms),
            SizedBox(height: 16.h),
            ...SupportedLanguages.getLanguageOptions().map((language) {
              final languageCode = language['code']!;
              final isDownloaded = offlineContent.downloadedLanguages.contains(languageCode);
              return AnimatedCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AfricanTheme.primaryGreen.withOpacity(0.1),
                    child: Text(
                      language['flag']!,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  ),
                  title: Text(language['name']!),
                  subtitle: Text('~50 MB'),
                  trailing: isDownloaded
                      ? IconButton(
                          icon: const Icon(Icons.delete_rounded),
                          color: Colors.red,
                          onPressed: () {
                            ref.read(offlineContentProvider.notifier).deleteLanguage(languageCode);
                          },
                        )
                      : AnimatedButton(
                          text: 'Download',
                          onPressed: offlineContent.isDownloading
                              ? null
                              : () {
                                  ref.read(offlineContentProvider.notifier).downloadLanguage(languageCode);
                                },
                        ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.1);
            }),
            if (offlineContent.isDownloading) ...[
              SizedBox(height: 24.h),
              LinearProgressIndicator(
                value: offlineContent.downloadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AfricanTheme.primaryGreen),
              ),
              SizedBox(height: 8.h),
              Text(
                'Downloading... ${(offlineContent.downloadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 32.h),
            _buildDownloadedLessonsSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadedLessonsSection(BuildContext context, WidgetRef ref) {
    final offlineDownloadState = ref.watch(offlineDownloadProvider);
    final offlineDownloadNotifier = ref.read(offlineDownloadProvider.notifier);
    final downloadedCount = offlineDownloadNotifier.getDownloadedCount();
    final db = LocalDatabaseService();

    if (downloadedCount == 0) {
      return const SizedBox.shrink();
    }

    final downloadedLessonIds = offlineDownloadState.downloadedLessonIds.toList();
    final lessons = downloadedLessonIds
        .map((id) => db.getLesson(id))
        .whereType<LocalLesson>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Downloads',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms),
        SizedBox(height: 8.h),
        FutureBuilder<int>(
          future: offlineDownloadNotifier.getStorageSizeBytes(),
          builder: (context, snapshot) {
            final storageSize = snapshot.data ?? 0;
            final formattedSize = _formatBytes(storageSize);
            return Text(
              '$downloadedCount ${downloadedCount == 1 ? 'lesson' : 'lessons'} downloaded • $formattedSize',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            );
          },
        )
            .animate()
            .fadeIn(delay: 150.ms),
        SizedBox(height: 16.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            final lessonId = lesson.id;
            final lessonTitle = lesson.title;
            final isDownloading = offlineDownloadState.isDownloading &&
                offlineDownloadState.currentDownloadingLessonId == lessonId;
            final progress = offlineDownloadState.downloadProgress[lessonId];

            return AnimatedCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AfricanTheme.primaryGreen.withOpacity(0.1),
                  child: Icon(
                    Icons.book_rounded,
                    color: AfricanTheme.primaryGreen,
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  lessonTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lesson.language.isNotEmpty)
                      Text(
                        '${lesson.language} • ${lesson.level}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (isDownloading && progress != null) ...[
                      SizedBox(height: 4.h),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AfricanTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_rounded),
                  color: Colors.red,
                  onPressed: isDownloading
                      ? null
                      : () => _showDeleteConfirmationDialog(
                            context,
                            ref,
                            lessonId,
                            lessonTitle,
                          ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (200 + (index * 50)).ms)
                .slideX(begin: -0.1);
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
    String lessonTitle,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text(
          'Are you sure you want to delete "$lessonTitle"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(offlineDownloadProvider.notifier).deleteLesson(lessonId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$lessonTitle" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete lesson: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

