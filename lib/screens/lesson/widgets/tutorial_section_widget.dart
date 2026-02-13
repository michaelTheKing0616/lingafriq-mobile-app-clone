import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/audio_player_widget.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/portrait_video_player.dart';
import '../models/lesson_content.dart';

/// Tutorial section widget with rich media support
class TutorialSectionWidget extends ConsumerStatefulWidget {
  final LessonContent content;
  final VoidCallback onContinue;

  const TutorialSectionWidget({
    Key? key,
    required this.content,
    required this.onContinue,
  }) : super(key: key);

  @override
  ConsumerState<TutorialSectionWidget> createState() => _TutorialSectionWidgetState();
}

class _TutorialSectionWidgetState extends ConsumerState<TutorialSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audio player (if available)
                if (widget.content.audioUrl != null && widget.content.audioUrl!.isNotEmpty) ...[
                  Semantics(
                    label: 'Audio player. Listen to tutorial audio.',
                    child: PanAfricanCard(
                      padding: EdgeInsets.all(16.w),
                      child: AudioPlayerWidget(audioUrl: widget.content.audioUrl!),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Video player (if available)
                if (widget.content.videoUrl != null && widget.content.videoUrl!.isNotEmpty) ...[
                  Semantics(
                    label: 'Video player. Watch tutorial video.',
                    child: PanAfricanCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: PanAfricanRadius.lgBR,
                        child: PortraitPlayerPage(videoUrl: widget.content.videoUrl!),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Image (if available)
                if (widget.content.imageUrl != null && widget.content.imageUrl!.isNotEmpty) ...[
                  PanAfricanCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: PanAfricanRadius.lgBR,
                      child: CachedNetworkImage(
                        imageUrl: widget.content.imageUrl!,
                        placeholder: (context, url) => Container(
                          height: 200.h,
                          color: PanAfricanColors.cardDark,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: PanAfricanColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200.h,
                          color: PanAfricanColors.cardDark,
                          child: Icon(
                            Icons.error_outline,
                            color: PanAfricanColors.error,
                            size: 48.sp,
                          ),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Text content
                if (widget.content.text != null && widget.content.text!.isNotEmpty) ...[
                  PanAfricanCard(
                    padding: EdgeInsets.all(20.w),
                    child: Text(
                      widget.content.text!,
                      style: PanAfricanTypography.bodyLarge(context).copyWith(
                        height: 1.6,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Continue button
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Semantics(
              label: 'Continue to next section',
              button: true,
              child: PanAfricanButton(
                width: double.infinity,
                onPressed: widget.onContinue,
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                backgroundColor: PanAfricanColors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
