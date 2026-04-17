import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Reusable grid of participant tiles with [VideoTrackRenderer] when a camera track exists.
class LiveKitParticipantGrid extends StatelessWidget {
  const LiveKitParticipantGrid({
    super.key,
    required this.participants,
    this.room,
    this.localParticipant,
    required this.remoteParticipants,
    required this.isDark,
    this.maxTiles = 6,
  });

  final List<Map<String, dynamic>> participants;
  final Room? room;
  final LocalParticipant? localParticipant;
  final Map<String, RemoteParticipant> remoteParticipants;
  final bool isDark;
  final int maxTiles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = participants.take(maxTiles).toList();
    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 48.sp,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Waiting for participants…',
              style: PanAfricanTypography.bodyLarge(context),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: visible.length <= 2 ? 2 : 2,
        crossAxisSpacing: PanAfricanSpacing.sm,
        mainAxisSpacing: PanAfricanSpacing.sm,
        childAspectRatio: 1.15,
      ),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final participant = visible[index];
        final isLocal = participant['isLocal'] == true;
        final participantId = participant['id'] as String;

        Participant? liveParticipant;
        if (isLocal && localParticipant != null) {
          liveParticipant = localParticipant;
        } else if (!isLocal) {
          liveParticipant = remoteParticipants[participantId];
        }

        return LiveKitVideoTile(
          participant: participant,
          liveParticipant: liveParticipant,
          isDark: isDark,
        )
            .animate(delay: (index * 80).ms)
            .fadeIn(duration: 280.ms)
            .scale(begin: const Offset(0.94, 0.94), duration: 280.ms);
      },
    );
  }
}

/// Single participant cell: camera track or avatar fallback.
class LiveKitVideoTile extends StatelessWidget {
  const LiveKitVideoTile({
    super.key,
    required this.participant,
    this.liveParticipant,
    required this.isDark,
  });

  final Map<String, dynamic> participant;
  final Participant? liveParticipant;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          border: Border.all(
            color: PanAfricanColors.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoTrack(context),
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Row(
                children: [
                  if (liveParticipant != null &&
                      participantHasActiveAudio(liveParticipant!)) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: PanAfricanColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: PanAfricanSpacing.xs,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.scrim.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
                      ),
                      child: Text(
                        participant['name']?.toString() ?? 'Participant',
                        style: PanAfricanTypography.labelSmall(context).copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTrack(BuildContext context) {
    VideoTrack? videoTrack;
    if (liveParticipant != null) {
      final trackPublications = liveParticipant!.trackPublications.values;
      final videoPublications = trackPublications
          .where((pub) =>
              pub.subscribed && pub.track != null && pub.track is VideoTrack)
          .toList();
      if (videoPublications.isNotEmpty) {
        videoTrack = videoPublications.first.track as VideoTrack?;
      }
    }

    if (videoTrack != null) {
      return VideoTrackRenderer(videoTrack);
    }

    final name = participant['name']?.toString() ?? 'U';
    return ColoredBox(
      color: isDark
          ? PanAfricanColors.surfaceContainerDark
          : PanAfricanColors.surfaceContainerLight,
      child: Center(
        child: CircleAvatar(
          radius: 28.r,
          backgroundColor: PanAfricanColors.primary,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: PanAfricanTypography.titleLarge(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

bool participantHasActiveAudio(Participant p) {
  for (final pub in p.trackPublications.values) {
    if (pub.kind == TrackType.AUDIO && pub.subscribed && pub.track != null) {
      return true;
    }
  }
  return false;
}
