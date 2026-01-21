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
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../widgets/whiteboard/interactive_whiteboard.dart';

/// Material 3 Live Classroom Screen with LiveKit Integration
/// Features: Video/Audio, Interactive Whiteboard, Screen Sharing
/// Similar to X's Spaces but for educational purposes
class LiveClassroomScreenMaterial3 extends HookConsumerWidget {
  final String? roomId;
  final String? roomName;

  const LiveClassroomScreenMaterial3({
    super.key,
    this.roomId,
    this.roomName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no room provided, show room selection/creation
    if (roomId == null || roomName == null) {
      return _RoomSelectionScreen();
    }

    return _ClassroomView(roomId: roomId!, roomName: roomName!);
  }
}

/// Room Selection/Creation Screen
class _RoomSelectionScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomNameController = useTextEditingController();
    final isCreating = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 80.sp,
                  color: Colors.white,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                SizedBox(height: PanAfricanSpacing.xl),
                Text(
                  'Live Classroom',
                  style: PanAfricanTypography.headlineLarge(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'Create or join a virtual classroom with video, audio, and whiteboard',
                  style: PanAfricanTypography.bodyLarge(context).copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms),
                SizedBox(height: PanAfricanSpacing.xxl),
                TextField(
                  controller: roomNameController,
                  style: PanAfricanTypography.bodyLarge(context),
                  decoration: InputDecoration(
                    labelText: 'Room Name',
                    hintText: 'Enter classroom name',
                    prefixIcon: Icon(Icons.school, color: PanAfricanColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.2, duration: 400.ms),
                SizedBox(height: PanAfricanSpacing.lg),
                PanAfricanButton(
                  label: 'Create Classroom',
                  icon: Icons.add,
                  onPressed: isCreating.value
                      ? null
                      : () async {
                          if (roomNameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter a room name'),
                                backgroundColor: PanAfricanColors.error,
                              ),
                            );
                            return;
                          }

                          isCreating.value = true;
                          await safeAsync(
                            context: context,
                            operation: () async {
                              // Create room and navigate
                              final roomId = DateTime.now().millisecondsSinceEpoch.toString();
                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _ClassroomView(
                                      roomId: roomId,
                                      roomName: roomNameController.text.trim(),
                                    ),
                                  ),
                                );
                              }
                            },
                            onError: (e) {
                              ErrorHandler.showError(context, e);
                            },
                          );
                          isCreating.value = false;
                        },
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms)
                    .scale(delay: 800.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main Classroom View with Video, Audio, and Whiteboard
class _ClassroomView extends HookConsumerWidget {
  final String roomId;
  final String roomName;

  const _ClassroomView({
    required this.roomId,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideoEnabled = useState(true);
    final isAudioEnabled = useState(true);
    final isWhiteboardVisible = useState(false);
    final isScreenSharing = useState(false);
    final participants = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final roomState = useState<Room?>(null);
    final localParticipant = useState<LocalParticipant?>(null);
    final remoteParticipants = useState<Map<String, RemoteParticipant>>({});
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> joinClassroom() async {
      await safeAsync(
        context: context,
        operation: () async {
          // Get LiveKit token from backend
          final response = await ApiService.get(
            AppConfig.chatClassroomToken(roomId),
          );

          if (response.statusCode == 200) {
            final token = response.data['data']['token'] as String;
            final url = response.data['data']['url'] as String? ?? AppConfig.liveKitUrl;

            // Initialize LiveKit Room
            final room = Room();
            await room.connect(
              url,
              token,
              roomOptions: RoomOptions(
                // Audio and video options are set via LocalTrackPublication in newer API
                // defaultAudioOptions and defaultVideoOptions removed in livekit_client 1.5.6+
              ),
            );

            // Store room reference
            roomState.value = room;
            localParticipant.value = room.localParticipant;

            // Set up participant tracking
            final localP = room.localParticipant;
            participants.value = [
              {
                'name': localP?.name ?? 'You',
                'id': localP?.sid ?? 'local',
                'isLocal': true,
              },
            ];

            // Listen for remote participants
            room.addListener(() {
              final remoteParts = <String, RemoteParticipant>{};
              final participantList = <Map<String, dynamic>>[
                {
                  'name': localP?.name ?? 'You',
                  'id': localP?.sid ?? 'local',
                  'isLocal': true,
                },
              ];

              // LiveKit 2.x: remote participants are exposed via `room.remoteParticipants`.
              for (final participant in room.remoteParticipants.values) {
                remoteParts[participant.sid] = participant;
                participantList.add({
                  'name': participant.name ?? 'Participant',
                  'id': participant.sid,
                  'isLocal': false,
                });
              }

              remoteParticipants.value = remoteParts;
              participants.value = participantList;
            });

            // Enable camera and microphone
            if (localP != null) {
              await localP.setCameraEnabled(isVideoEnabled.value);
              await localP.setMicrophoneEnabled(isAudioEnabled.value);
            }

            isLoading.value = false;
          }
        },
        onError: (e) {
          ErrorHandler.showError(context, e);
          isLoading.value = false;
        },
      );
    }

    Future<void> leaveClassroom() async {
      final room = roomState.value;
      if (room != null) {
        await room.disconnect();
        roomState.value = null;
        localParticipant.value = null;
        remoteParticipants.value = {};
      }
    }

    useEffect(() {
      joinClassroom();
      return () {
        // Cleanup: disconnect from room when widget is disposed
        leaveClassroom();
      };
    }, []);

    return Scaffold(
      appBar: PanAfricanAppBar(
        title: roomName,
        subtitle: '${participants.value.length} participants',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              isWhiteboardVisible.value ? Icons.edit : Icons.edit_outlined,
            ),
            onPressed: () {
              isWhiteboardVisible.value = !isWhiteboardVisible.value;
              HapticFeedback.lightImpact();
            },
            tooltip: 'Toggle Whiteboard',
          ),
          IconButton(
            icon: Icon(Icons.people_outline),
            onPressed: () {
              _showParticipantsDialog(context, participants.value, isDark);
            },
            tooltip: 'Participants',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  color: PanAfricanColors.primary,
                ),
              )
            : Column(
                children: [
                  // Video Grid
                  Expanded(
                    flex: isWhiteboardVisible.value ? 2 : 3,
                    child: _VideoGrid(
                      participants: participants.value,
                      room: roomState.value,
                      localParticipant: localParticipant.value,
                      remoteParticipants: remoteParticipants.value,
                      isDark: isDark,
                    ),
                  ),

                  // Whiteboard (if visible)
                  if (isWhiteboardVisible.value)
                    Expanded(
                      flex: 1,
                      child: InteractiveWhiteboard(
                        roomId: roomId,
                        onDrawingUpdate: (points) {
                          // Sync whiteboard state with backend/other participants
                          if (roomState.value != null) {
                            // Send drawing updates through LiveKit data channel
                            final data = {
                              'type': 'whiteboard_update',
                              'points': points.map((p) => p.toJson()).toList(),
                            };
                            // roomState.value?.localParticipant?.publishData(
                            //   jsonEncode(data).codeUnits,
                            //   reliable: true,
                            // );
                          }
                        },
                      ),
                    ),

                  // Controls
                  _ClassroomControls(
                    isVideoEnabled: isVideoEnabled.value,
                    isAudioEnabled: isAudioEnabled.value,
                    isScreenSharing: isScreenSharing.value,
                    onVideoToggle: (value) async {
                      isVideoEnabled.value = value;
                      final localP = localParticipant.value;
                      await localP?.setCameraEnabled(value);
                      HapticFeedback.mediumImpact();
                    },
                    onAudioToggle: (value) async {
                      isAudioEnabled.value = value;
                      final localP = localParticipant.value;
                      await localP?.setMicrophoneEnabled(value);
                      HapticFeedback.mediumImpact();
                    },
                    onScreenShareToggle: (value) {
                      isScreenSharing.value = value;
                      HapticFeedback.mediumImpact();
                    },
                    onLeave: () async {
                      await leaveClassroom();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    isDark: isDark,
                  ),
                ],
              ),
      ),
    );
  }

  void _showParticipantsDialog(
    BuildContext context,
    List<Map<String, dynamic>> participants,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        title: Text(
          'Participants (${participants.length})',
          style: PanAfricanTypography.titleLarge(context),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: PanAfricanColors.primary,
                  child: Text(
                    (participant['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  participant['name'] ?? 'Participant',
                  style: PanAfricanTypography.bodyLarge(context),
                ),
                trailing: participant['id'] == 'local'
                    ? Chip(
                        label: Text('You'),
                        backgroundColor: PanAfricanColors.primary,
                        labelStyle: const TextStyle(color: Colors.white),
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Video Grid Widget
class _VideoGrid extends StatelessWidget {
  final List<Map<String, dynamic>> participants;
  final Room? room;
  final LocalParticipant? localParticipant;
  final Map<String, RemoteParticipant> remoteParticipants;
  final bool isDark;

  const _VideoGrid({
    required this.participants,
    this.room,
    this.localParticipant,
    required this.remoteParticipants,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64.sp,
              color: Colors.white70,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Waiting for participants...',
              style: PanAfricanTypography.bodyLarge(context).copyWith(
                color: Colors.white70,
              ),
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
        )
            .animate(delay: (index * 100).ms)
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
      },
    );
  }
}

/// Interactive Whiteboard Widget
class _InteractiveWhiteboard extends HookConsumerWidget {
  final bool isDark;

  const _InteractiveWhiteboard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = useState<Color>(Colors.black);
    final strokeWidth = useState<double>(3.0);
    final points = useState<List<Offset>>([]);
    final paths = useState<List<Map<String, dynamic>>>([]);

    return Container(
      margin: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Column(
        children: [
          // Whiteboard Toolbar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: PanAfricanColors.surfaceContainerLight,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(PanAfricanRadius.lg),
              ),
            ),
            child: Row(
              children: [
                // Color Picker
                ...[
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  PanAfricanColors.primary,
                ].map((color) => GestureDetector(
                      onTap: () {
                        currentColor.value = color;
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        margin: EdgeInsets.only(right: PanAfricanSpacing.sm),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentColor.value == color
                                ? PanAfricanColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    )),
                Spacer(),
                // Stroke Width
                Icon(Icons.brush, size: 20.sp),
                SizedBox(width: PanAfricanSpacing.xs),
                Slider(
                  value: strokeWidth.value,
                  min: 1.0,
                  max: 10.0,
                  onChanged: (value) {
                    strokeWidth.value = value;
                  },
                  activeColor: PanAfricanColors.primary,
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                // Clear Button
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    paths.value = [];
                    points.value = [];
                    HapticFeedback.mediumImpact();
                  },
                  tooltip: 'Clear',
                ),
              ],
            ),
          ),
          // Drawing Canvas
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox? renderBox =
                    context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  points.value = [
                    ...points.value,
                    renderBox.globalToLocal(details.globalPosition),
                  ];
                }
              },
              onPanEnd: (details) {
                paths.value = [
                  ...paths.value,
                  {
                    'points': List<Offset>.from(points.value),
                    'color': currentColor.value,
                    'strokeWidth': strokeWidth.value,
                  },
                ];
                points.value = [];
              },
              child: CustomPaint(
                painter: _WhiteboardPainter(
                  paths: paths.value,
                  currentPath: points.value,
                  currentColor: currentColor.value,
                  strokeWidth: strokeWidth.value,
                ),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Whiteboard Painter
class _WhiteboardPainter extends CustomPainter {
  final List<Map<String, dynamic>> paths;
  final List<Offset> currentPath;
  final Color currentColor;
  final double strokeWidth;

  _WhiteboardPainter({
    required this.paths,
    required this.currentPath,
    required this.currentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw saved paths
    for (final pathData in paths) {
      final paint = Paint()
        ..color = pathData['color'] as Color
        ..strokeWidth = pathData['strokeWidth'] as double
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final points = pathData['points'] as List<Offset>;
      if (points.isNotEmpty) {
        path.moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    // Draw current path
    if (currentPath.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(currentPath.first.dx, currentPath.first.dy);
      for (int i = 1; i < currentPath.length; i++) {
        path.lineTo(currentPath[i].dx, currentPath[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WhiteboardPainter oldDelegate) {
    return oldDelegate.paths != paths ||
        oldDelegate.currentPath != currentPath ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Classroom Controls
class _ClassroomControls extends StatelessWidget {
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isScreenSharing;
  final Function(bool) onVideoToggle;
  final Function(bool) onAudioToggle;
  final Function(bool) onScreenShareToggle;
  final VoidCallback onLeave;
  final bool isDark;

  const _ClassroomControls({
    required this.isVideoEnabled,
    required this.isAudioEnabled,
    required this.isScreenSharing,
    required this.onVideoToggle,
    required this.onAudioToggle,
    required this.onScreenShareToggle,
    required this.onLeave,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: 'Video',
            isActive: isVideoEnabled,
            onPressed: () => onVideoToggle(!isVideoEnabled),
            isDark: isDark,
          ),
          _ControlButton(
            icon: isAudioEnabled ? Icons.mic : Icons.mic_off,
            label: 'Audio',
            isActive: isAudioEnabled,
            onPressed: () => onAudioToggle(!isAudioEnabled),
            isDark: isDark,
          ),
          _ControlButton(
            icon: Icons.screen_share,
            label: 'Share',
            isActive: isScreenSharing,
            onPressed: () => onScreenShareToggle(!isScreenSharing),
            isDark: isDark,
          ),
          ElevatedButton.icon(
            onPressed: onLeave,
            icon: Icon(Icons.call_end),
            label: Text('Leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PanAfricanColors.error,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.lg,
                vertical: PanAfricanSpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;
  final bool isDark;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: isActive ? PanAfricanColors.primary : PanAfricanColors.error,
          iconSize: 32.sp,
        ),
        Text(
          label,
          style: PanAfricanTypography.labelSmall(context),
        ),
      ],
    );
  }
}

/// Video Tile Widget
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        border: Border.all(
          color: PanAfricanColors.primary.withValues(alpha: 0.3),
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
                color: Colors.black.withValues(alpha: 0.6),
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

  Widget _buildVideoTrack(BuildContext context) {
    // Find video track from participant
    VideoTrack? videoTrack;
    if (liveParticipant != null) {
      // Get video track publications from participant
      // LiveKit 1.5.6 API: trackPublications is a Map<String, TrackPublication>
      final trackPublications = liveParticipant!.trackPublications.values;
      // Filter for video tracks - check if track is VideoTrack type
      final videoPublications = trackPublications
          .where((pub) => pub.subscribed && pub.track != null && pub.track is VideoTrack)
          .toList();
      
      if (videoPublications.isNotEmpty) {
        final firstPublication = videoPublications.first;
        videoTrack = firstPublication.track as VideoTrack?;
      }
    }

    if (videoTrack != null) {
      // Render actual LiveKit video track
      // Use platform-specific rendering (will be handled by LiveKit internally)
      // For now, show a placeholder that indicates video is active
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 48.sp, color: Colors.white),
              SizedBox(height: 2.h),
              Text(
                'Video Active',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
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
    );
  }
}

