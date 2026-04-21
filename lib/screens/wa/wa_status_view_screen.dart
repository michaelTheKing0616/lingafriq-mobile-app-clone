import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/wa_status_model.dart';
import '../../providers/wa_status_provider.dart';
import '../../utils/media_url_resolver.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/portrait_video_player.dart';

class WaStatusViewScreen extends ConsumerStatefulWidget {
  const WaStatusViewScreen({super.key, required this.statusId});

  final String statusId;

  @override
  ConsumerState<WaStatusViewScreen> createState() => _WaStatusViewScreenState();
}

class _WaStatusViewScreenState extends ConsumerState<WaStatusViewScreen> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _replyController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _dismiss() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  WaStatusModel? _findStatus(WaStatusState st) {
    for (final s in st.mine) {
      if (s.id == widget.statusId) return s;
    }
    for (final s in st.feed) {
      if (s.id == widget.statusId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(waStatusProvider);
    final status = _findStatus(st);
    final cs = Theme.of(context).colorScheme;

    if (status == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Text(
              'Status not found',
              style: ModernGriotTypography.titleMedium(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
      );
    }

    final resolvedMediaUrl = resolveMediaUrl(status.mediaUrl) ?? status.mediaUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) _dismiss();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _background(),
            _gradientOverlay(),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (status.mediaType == 'image' &&
                              resolvedMediaUrl.trim().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                resolvedMediaUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _fallbackText(status),
                              ),
                            )
                          else if (status.mediaType == 'video' &&
                              status.mediaUrl.trim().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: PortraitPlayerPage(videoUrl: status.mediaUrl),
                            )
                          else
                            _fallbackText(status),
                          if (status.caption.trim().isNotEmpty) ...[
                            SizedBox(height: 14.h),
                            GriotGlassPanel(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              borderRadius: ModernGriotRadius.borderXl,
                              child: Text(
                                status.caption,
                                textAlign: TextAlign.center,
                                style: ModernGriotTypography.bodyMedium(
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _replyBar(cs),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 4.h,
              left: 8.w,
              child: IconButton(
                onPressed: _dismiss,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9E3D00),
            Color(0xFFFF7A35),
            Color(0xFF526124),
          ],
        ),
      ),
    );
  }

  Widget _gradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withAlpha(200),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackText(WaStatusModel status) {
    final text = status.text.trim().isNotEmpty
        ? status.text.trim()
        : (status.caption.trim().isNotEmpty ? status.caption.trim() : '');
    return GriotGlassPanel(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      borderRadius: ModernGriotRadius.borderXl,
      child: Text(
        text.isEmpty ? ' ' : text,
        textAlign: TextAlign.center,
        style: ModernGriotTypography.headlineSmall(
          color: Colors.white.withOpacity(0.95),
        ),
      ),
    );
  }

  Widget _replyBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ClipRRect(
        borderRadius: ModernGriotRadius.borderPill,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: ModernGriotRadius.borderPill,
              border: Border.all(
                color: Colors.white.withAlpha(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Reply...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_replyController.text.trim().isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      _replyController.clear();
                    }
                  },
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white70,
                    size: 22.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

