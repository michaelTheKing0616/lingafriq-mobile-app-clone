import 'package:flutter/material.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:livekit_client/livekit_client.dart';

/// LiveKit Classroom Chat with Video/Audio and Whiteboard
class ClassroomChatLiveKitScreen extends HookConsumerWidget {
  final String roomId;
  final String roomName;

  const ClassroomChatLiveKitScreen({
    Key? key,
    required this.roomId,
    required this.roomName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideoEnabled = useState(true);
    final isAudioEnabled = useState(true);
    final isWhiteboardVisible = useState(false);
    final participants = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> joinClassroom() async {
      try {
        // Get LiveKit token from backend
        final response = await ApiService.get(
          '${AppConfig.chatClassroomToken}/$roomId',
        );

        if (response.statusCode == 200) {
          final token = response.data['data']['token'];
          final url = response.data['data']['url'] ?? AppConfig.liveKitUrl;

          // Initialize LiveKit Room with token and URL
          final room = Room();
          await room.connect(
            url,
            token,
            roomOptions: const RoomOptions(
              defaultAudioOptions: AudioCaptureOptions(
                echoCancellation: true,
                noiseSuppression: true,
                autoGainControl: true,
              ),
              defaultVideoOptions: VideoCaptureOptions(
                resolution: VideoPreset.h720.resolution,
                fps: 30,
              ),
            ),
          );

          // Enable camera and microphone
          await room.localParticipant.setCameraEnabled(isVideoEnabled.value);
          await room.localParticipant.setMicrophoneEnabled(isAudioEnabled.value);

          // Track participants
          final localP = room.localParticipant;
          participants.value = [
            {
              'name': localP.name ?? 'You',
              'id': localP.sid,
              'isLocal': true,
            },
          ];

          // Listen for remote participants
          room.addListener(() {
            final participantList = <Map<String, dynamic>>[
              {
                'name': localP.name ?? 'You',
                'id': localP.sid,
                'isLocal': true,
              },
            ];

            for (final participant in room.remoteParticipants.values) {
              participantList.add({
                'name': participant.name ?? 'Participant',
                'id': participant.sid,
                'isLocal': false,
              });
            }

            participants.value = participantList;
          });

          isLoading.value = false;
        }
      } catch (e) {
        isLoading.value = false;
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }

    useEffect(() {
      joinClassroom();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.whiteboard),
            onPressed: () => isWhiteboardVisible.value = !isWhiteboardVisible.value,
            tooltip: 'Whiteboard',
          ),
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () {
              // Show participants list
            },
            tooltip: 'Participants',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: isLoading.value
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Video Grid
                  Expanded(
                    flex: isWhiteboardVisible.value ? 2 : 3,
                    child: _buildVideoGrid(context, participants.value, isDark),
                  ),

                  // Whiteboard (if visible)
                  if (isWhiteboardVisible.value)
                    Expanded(
                      flex: 1,
                      child: _buildWhiteboard(context, isDark),
                    ),

                  // Controls
                  _buildControls(
                    context,
                    isVideoEnabled.value,
                    isAudioEnabled.value,
                    (video) => isVideoEnabled.value = video,
                    (audio) => isAudioEnabled.value = audio,
                    isDark,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoGrid(
    BuildContext context,
    List<Map<String, dynamic>> participants,
    bool isDark,
  ) {
    if (participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64.sp,
              color: PanAfricanColors.neutralMedium,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Waiting for participants...',
              style: PanAfricanTypography.bodyLarge(context),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: participants.length <= 2 ? 1 : 2,
        crossAxisSpacing: PanAfricanSpacing.sm,
        mainAxisSpacing: PanAfricanSpacing.sm,
        childAspectRatio: 16 / 9,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _VideoTile(
          participant: participant,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildWhiteboard(BuildContext context, bool isDark) {
    return Container(
      margin: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.md,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              size: 48.sp,
              color: PanAfricanColors.neutralMedium,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              'Whiteboard',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              'Interactive whiteboard coming soon',
              style: PanAfricanTypography.bodySmall(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    bool isVideoEnabled,
    bool isAudioEnabled,
    Function(bool) onVideoToggle,
    Function(bool) onAudioToggle,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        boxShadow: PanAfricanShadows.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(isVideoEnabled ? Icons.videocam : Icons.videocam_off),
            onPressed: () {
              onVideoToggle(!isVideoEnabled);
              HapticFeedback.mediumImpact();
            },
            color: isVideoEnabled ? PanAfricanColors.primary : PanAfricanColors.error,
            iconSize: 32.sp,
          ),
          IconButton(
            icon: Icon(isAudioEnabled ? Icons.mic : Icons.mic_off),
            onPressed: () {
              onAudioToggle(!isAudioEnabled);
              HapticFeedback.mediumImpact();
            },
            color: isAudioEnabled ? PanAfricanColors.primary : PanAfricanColors.error,
            iconSize: 32.sp,
          ),
          IconButton(
            icon: Icon(Icons.screen_share),
            onPressed: () {
              // Screen sharing
            },
            color: PanAfricanColors.primary,
            iconSize: 32.sp,
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Leave classroom
              Navigator.pop(context);
            },
            icon: Icon(Icons.call_end),
            label: Text('Leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final Map<String, dynamic> participant;
  final bool isDark;

  const _VideoTile({
    required this.participant,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        border: Border.all(
          color: PanAfricanColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Video placeholder - replace with actual LiveKit video track
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40.r,
                  backgroundColor: PanAfricanColors.primary,
                  child: Text(
                    (participant['name'] ?? 'U')[0].toUpperCase(),
                    style: PanAfricanTypography.headlineSmall(context)
                        .copyWith(color: Colors.white),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  participant['name'] ?? 'Participant',
                  style: PanAfricanTypography.titleMedium(context),
                ),
              ],
            ),
          ),
          // Name overlay
          Positioned(
            bottom: PanAfricanSpacing.sm,
            left: PanAfricanSpacing.sm,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.sm,
                vertical: PanAfricanSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
              ),
              child: Text(
                participant['name'] ?? 'Participant',
                style: PanAfricanTypography.labelSmall(context)
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

