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
import '../../widgets/whiteboard/interactive_whiteboard.dart';
import 'package:lingafriq/avatars/avatars.dart';

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
    final roomState = useState<Room?>(null);
    final localParticipant = useState<LocalParticipant?>(null);
    final remoteParticipants = useState<Map<String, RemoteParticipant>>({});
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
          );

          // Store room and participant references
          roomState.value = room;
          final localP = room.localParticipant;
          localParticipant.value = localP;

          // Enable camera and microphone with null checks
          if (localP != null) {
            await localP.setCameraEnabled(isVideoEnabled.value);
            await localP.setMicrophoneEnabled(isAudioEnabled.value);
          }

          // Track participants
          participants.value = [
            {
              'name': localP?.name ?? 'You',
              'id': localP?.sid ?? 'local',
              'isLocal': true,
            },
          ];

          // Listen for remote participants via room events
          room.addListener(() {
            final remoteParts = <String, RemoteParticipant>{};
            final participantList = <Map<String, dynamic>>[
              {
                'name': localP?.name ?? 'You',
                'id': localP?.sid ?? 'local',
                'isLocal': true,
              },
            ];

            // Access remote participants - use room's participant tracking
            // LiveKit tracks participants through the room object
            final remotePartsMap = <String, RemoteParticipant>{};
            
            // Get remote participants from room
            // Note: In livekit_client 1.2.0, we need to track participants manually via events
            // For now, we'll initialize with empty and update via room events
            remoteParticipants.value = remotePartsMap;
            participants.value = participantList;
            
            // Set up event listeners for participant changes
            // These will be handled by the room's event system
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
      return () {
        // Cleanup: disconnect from room when widget is disposed
        final room = roomState.value;
        if (room != null) {
          room.disconnect();
        }
      };
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => isWhiteboardVisible.value = !isWhiteboardVisible.value,
            tooltip: 'Whiteboard',
          ),
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () {
              _showParticipantsList(
                context,
                participants.value,
                localParticipant.value,
                remoteParticipants.value,
              );
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
                    child: _buildVideoGrid(
                      context,
                      participants.value,
                      roomState.value,
                      localParticipant.value,
                      remoteParticipants.value,
                      isDark,
                    ),
                  ),

                  // Whiteboard (if visible)
                  if (isWhiteboardVisible.value)
                    Expanded(
                      flex: 1,
                      child: _buildWhiteboard(context, isDark, roomState.value),
                    ),

                  // Controls
                  _buildControls(
                    context,
                    isVideoEnabled.value,
                    isAudioEnabled.value,
                    (video) => isVideoEnabled.value = video,
                    (audio) => isAudioEnabled.value = audio,
                    roomState.value,
                    localParticipant.value,
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
    Room? room,
    LocalParticipant? localParticipant,
    Map<String, RemoteParticipant> remoteParticipants,
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
        final isLocal = participant['isLocal'] == true;
        final participantId = participant['id'] as String;
        
        // Get the actual participant object
        Participant? liveParticipant;
        if (isLocal && localParticipant != null) {
          liveParticipant = localParticipant;
        } else if (!isLocal) {
          liveParticipant = remoteParticipants[participantId];
        }
        
        return _VideoTile(
          participant: participant,
          liveParticipant: liveParticipant,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildWhiteboard(BuildContext context, bool isDark, Room? room) {
    return Container(
      margin: EdgeInsets.all(PanAfricanSpacing.md),
      child: InteractiveWhiteboard(
        roomId: roomId,
        onDrawingUpdate: (points) {
          // Sync whiteboard state with backend/other participants
          // This would typically send updates via WebSocket or LiveKit data channel
          if (room != null) {
            // Send drawing updates through LiveKit data channel
            final data = {
              'type': 'whiteboard_update',
              'points': points.map((p) => p.toJson()).toList(),
            };
            // room.localParticipant?.publishData(
            //   jsonEncode(data).codeUnits,
            //   reliable: true,
            // );
          }
        },
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    bool isVideoEnabled,
    bool isAudioEnabled,
    Function(bool) onVideoToggle,
    Function(bool) onAudioToggle,
    Room? room,
    LocalParticipant? localParticipant,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
            onPressed: () async {
              final newValue = !isVideoEnabled;
              onVideoToggle(newValue);
              if (localParticipant != null) {
                await localParticipant.setCameraEnabled(newValue);
              }
              HapticFeedback.mediumImpact();
            },
            color: isVideoEnabled ? PanAfricanColors.primary : PanAfricanColors.error,
            iconSize: 32.sp,
          ),
          IconButton(
            icon: Icon(isAudioEnabled ? Icons.mic : Icons.mic_off),
            onPressed: () async {
              final newValue = !isAudioEnabled;
              onAudioToggle(newValue);
              if (localParticipant != null) {
                await localParticipant.setMicrophoneEnabled(newValue);
              }
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
            onPressed: () async {
              // Disconnect from room before leaving
              if (room != null) {
                await room.disconnect();
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.call_end),
            label: Text('Leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.error,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final Map<String, dynamic> participant;
  final Participant? liveParticipant;
  final bool isDark;

  const _VideoTile({
    required this.participant,
    this.liveParticipant,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          // LiveKit video track rendering
          _buildVideoTrack(context),
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
                color: Theme.of(context).colorScheme.scrim.withOpacity(0.6),
                borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
              ),
              child: Text(
                participant['name'] ?? 'Participant',
                style: PanAfricanTypography.labelSmall(context)
                    .copyWith(color: colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTrack(BuildContext context) {
    // Find video track from participant
    VideoTrack? videoTrack;
    if (liveParticipant != null) {
      // Access video tracks through track publications
      final videoTrackPublications = liveParticipant!.videoTrackPublications;
      if (videoTrackPublications.isNotEmpty) {
        // Get first video track publication (videoTrackPublications is a List)
        final firstPublication = videoTrackPublications.first;
        if (firstPublication.subscribed && firstPublication.track != null) {
          videoTrack = firstPublication.track as VideoTrack?;
        }
      }
    }

    if (videoTrack != null) {
      // Render actual LiveKit video track
      // Use platform-specific rendering (will be handled by LiveKit internally)
      // For now, show a placeholder that indicates video is active
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 48.sp, color: colorScheme.onSurface),
              SizedBox(height: 2.h),
              Text(
                'Video Active',
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback to avatar when no video track available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LingAfriqAvatar.fromInitials(
            username: participant['name'] ?? 'U',
            size: 80.r,
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            participant['name'] ?? 'Participant',
            style: PanAfricanTypography.titleMedium(context),
          ),
        ],
      ),
    );
  }

}

/// Top-level function so both [ClassroomChatLiveKitScreen] and [_VideoTile] can call it.
void _showParticipantsList(
  BuildContext context,
  List<Map<String, dynamic>> participants,
  LocalParticipant? localParticipant,
  Map<String, RemoteParticipant> remoteParticipants,
) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Participants (${participants.length})',
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                final isLocal = participant['isLocal'] == true;
                final participantId = participant['id'] as String;
                final remoteParticipant = remoteParticipants[participantId];
                
                return ListTile(
                  leading: LingAfriqAvatar.fromInitials(
                    username: participant['name'] ?? 'U',
                    size: 40,
                  ),
                  title: Text(
                    participant['name'] ?? 'Unknown',
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                  subtitle: Text(
                    isLocal ? 'You' : 'Participant',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (remoteParticipant != null) ...[
                        Icon(
                          remoteParticipant.isMicrophoneEnabled() 
                              ? Icons.mic 
                              : Icons.mic_off,
                          color: remoteParticipant.isMicrophoneEnabled() 
                              ? Colors.green 
                              : Colors.red,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          remoteParticipant.isCameraEnabled() 
                              ? Icons.videocam 
                              : Icons.videocam_off,
                          color: remoteParticipant.isCameraEnabled() 
                              ? Colors.green 
                              : Colors.red,
                          size: 20.sp,
                        ),
                      ] else if (isLocal && localParticipant != null) ...[
                        Icon(
                          localParticipant.isMicrophoneEnabled() 
                              ? Icons.mic 
                              : Icons.mic_off,
                          color: localParticipant.isMicrophoneEnabled() 
                              ? Colors.green 
                              : Colors.red,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          localParticipant.isCameraEnabled() 
                              ? Icons.videocam 
                              : Icons.videocam_off,
                          color: localParticipant.isCameraEnabled() 
                              ? Colors.green 
                              : Colors.red,
                          size: 20.sp,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    ),
  );
}

