import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// TODO: add image_gallery_saver to pubspec.yaml to enable save to gallery
// import 'package:image_gallery_saver/image_gallery_saver.dart';

class ShareProgressScreen extends HookConsumerWidget {
  final String cardType; // 'daily_streak', 'weekly_stats', 'achievement'

  const ShareProgressScreen({
    super.key,
    this.cardType = 'daily_streak',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalKey = useMemoized(() => GlobalKey());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> shareCard() async {
      try {
        final RenderRepaintBoundary boundary =
            globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/share_progress_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out my progress on LingAfriq!',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }

    Future<void> saveToGallery() async {
      // TODO: add image_gallery_saver package and uncomment to enable save to gallery
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save to gallery not available — add image_gallery_saver package')),
      );
      return;
      // try {
      //   final RenderRepaintBoundary boundary =
      //       globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      //   final image = await boundary.toImage(pixelRatio: 3.0);
      //   final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      //   final pngBytes = byteData!.buffer.asUint8List();
      //   final result = await ImageGallerySaver.saveImage(pngBytes);
      //   if (result['isSuccess'] == true) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Saved to gallery!')),
      //     );
      //   }
      // } catch (e) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error saving: $e')),
      //   );
      // }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: globalKey,
                    child: _buildProgressCard(context, cardType, isDark),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(PolieSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: saveToGallery,
                        icon: Icon(Icons.download_rounded),
                        label: Text('Save'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PolieColors.textPrimary,
                          side: BorderSide(color: PolieColors.textPrimary),
                        ),
                      ),
                    ),
                    SizedBox(width: PolieSpacing.md),
                    Expanded(
                      child: PoliePrimaryButton(
                        label: 'Share',
                        icon: Icons.share_rounded,
                        onPressed: shareCard,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: PolieColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Text(
              'Share Progress',
              style: PolieTypography.h1(context).copyWith(
                color: PolieColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, String type, bool isDark) {
    switch (type) {
      case 'daily_streak':
        return _buildStreakCard(context, isDark);
      case 'weekly_stats':
        return _buildWeeklyStatsCard(context, isDark);
      case 'achievement':
        return _buildAchievementCard(context, isDark);
      default:
        return _buildStreakCard(context, isDark);
    }
  }

  Widget _buildStreakCard(BuildContext context, bool isDark) {
    return Container(
      width: 400.w,
      height: 600.h,
      padding: EdgeInsets.all(PolieSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PolieColors.primary,
            PolieColors.royalAmethyst,
          ],
        ),
        borderRadius: BorderRadius.circular(PolieRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 120.sp,
            color: PolieColors.goldEmber,
          ),
          SizedBox(height: PolieSpacing.xl),
          Text(
            '🔥 30 Day Streak! 🔥',
            style: PolieTypography.h1(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 32.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'I\'ve been learning every day!',
            style: PolieTypography.body(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              fontSize: 18.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PolieSpacing.xl),
          Container(
            padding: EdgeInsets.all(PolieSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(PolieRadius.md),
            ),
            child: Text(
              'LingAfriq',
              style: PolieTypography.body(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard(BuildContext context, bool isDark) {
    return Container(
      width: 400.w,
      height: 600.h,
      padding: EdgeInsets.all(PolieSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PolieColors.electricTeal,
            PolieColors.royalAmethyst,
          ],
        ),
        borderRadius: BorderRadius.circular(PolieRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'This Week',
            style: PolieTypography.h2(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: PolieSpacing.xl),
          _buildStatRow(context, 'Lessons', '15', Icons.school_rounded),
          SizedBox(height: PolieSpacing.md),
          _buildStatRow(context, 'XP Earned', '2,450', Icons.star_rounded),
          SizedBox(height: PolieSpacing.md),
          _buildStatRow(context, 'Words Learned', '120', Icons.book_rounded),
          SizedBox(height: PolieSpacing.xl),
          Container(
            padding: EdgeInsets.all(PolieSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(PolieRadius.md),
            ),
            child: Text(
              'LingAfriq',
              style: PolieTypography.body(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 32),
        SizedBox(width: PolieSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: PolieTypography.body(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            Text(
              value,
              style: PolieTypography.h2(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, bool isDark) {
    return Container(
      width: 400.w,
      height: 600.h,
      padding: EdgeInsets.all(PolieSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PolieColors.goldEmber,
            PolieColors.error,
          ],
        ),
        borderRadius: BorderRadius.circular(PolieRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 120.sp,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          SizedBox(height: PolieSpacing.xl),
          Text(
            'Achievement Unlocked!',
            style: PolieTypography.h1(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'Polyglot Master',
            style: PolieTypography.h2(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 24.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'Learned 5 languages!',
            style: PolieTypography.body(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              fontSize: 18.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PolieSpacing.xl),
          Container(
            padding: EdgeInsets.all(PolieSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(PolieRadius.md),
            ),
            child: Text(
              'LingAfriq',
              style: PolieTypography.body(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
