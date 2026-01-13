import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/offline_content_provider.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/widgets/animated/animated_card.dart';
import 'package:lingafriq/widgets/animated/animated_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Screen for managing offline content downloads
class OfflineContentScreen extends ConsumerWidget {
  const OfflineContentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineContent = ref.watch(offlineContentProvider);
    final subscription = ref.watch(subscriptionProvider);
    final hasOfflineAccess = subscription.hasFeature('offline_mode');

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
                  // Navigate to subscription screen
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
              final code = language['code'] ?? '';
              final name = language['name'] ?? code;
              final flag = language['flag'] ?? '';
              final isDownloaded =
                  offlineContent.downloadedLanguages.contains(code);
              return AnimatedCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AfricanTheme.primaryGreen.withOpacity(0.1),
                    child: Text(
                      flag,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text('~50 MB'),
                  trailing: isDownloaded
                      ? IconButton(
                          icon: const Icon(Icons.delete_rounded),
                          color: Colors.red,
                          onPressed: () {
                            ref
                                .read(offlineContentProvider.notifier)
                                .deleteLanguage(code);
                          },
                        )
                      : AnimatedButton(
                          text: 'Download',
                          onPressed: offlineContent.isDownloading
                              ? null
                              : () {
                                  ref
                                      .read(offlineContentProvider.notifier)
                                      .downloadLanguage(code);
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
          ],
        ),
      ),
    );
  }
}

