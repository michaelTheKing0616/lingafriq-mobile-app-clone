import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/social_audio/social_audio_room_model.dart';
import '../../providers/social_audio_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../screens/chat/live_classroom_screen_material3.dart';
import 'moderation_screen.dart';
import 'package:intl/intl.dart';

/// Room Detail Screen - View room details and join
class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  SocialAudioRoom? _room;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    try {
      final service = ref.read(socialAudioServiceProvider);
      final room = await service.getRoom(widget.roomId);
      setState(() {
        _room = room;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading room: $e')),
        );
      }
    }
  }

  Future<void> _joinRoom() async {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join rooms')),
      );
      return;
    }

    if (_room == null || !_room!.hasSpace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room is full')),
      );
      return;
    }

    if (!_room!.isLive && !_room!.isScheduled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This room is not currently active')),
      );
      return;
    }

    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      final result = await ref.read(socialAudioProvider.notifier).joinRoom(
            roomId: widget.roomId,
            role: ParticipantRole.listener,
          );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (result != null && mounted) {
        final room = result['room'] as SocialAudioRoom;
        
        // Navigate to LiveKit room with token
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LiveClassroomScreenMaterial3(
              roomId: room.id,
              roomName: room.name,
              livekitToken: result['livekit_token']?.toString(),
              livekitUrl: result['livekit_url']?.toString(),
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to join room. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining room: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _joinRoom,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
              SizedBox(height: 2.h),
              const Text('Room not found'),
              SizedBox(height: 4.h),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_room!.name),
        actions: [
          // Moderation button (if user is host/moderator)
          if (_room?.hostId == ref.read(userProvider)?.id.toString())
            Semantics(
              label: 'Room moderation',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.admin_panel_settings, semanticLabel: 'Moderation'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModerationScreen(roomId: widget.roomId),
                    ),
                  );
                },
                tooltip: 'Moderation',
              ),
            ),
          Semantics(
            label: 'Share room',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.share, semanticLabel: 'Share'),
              onPressed: () {
                final shareText =
                    'Join my LingAfriq practice room! https://lingafriq.com/rooms/${widget.roomId}';
                Clipboard.setData(ClipboardData(text: shareText));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room link copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              tooltip: 'Share Room',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or placeholder
            if (_room!.coverImageUrl != null)
              Image.network(
                _room!.coverImageUrl!,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(isDark),
              )
            else
              _buildPlaceholderCover(isDark),

            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room status and info
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: _room!.isLive
                              ? Colors.green
                              : (_room!.isScheduled ? Colors.blue : Colors.grey),
                          borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
                        ),
                        child: Text(
                          _room!.isLive
                              ? 'LIVE'
                              : (_room!.isScheduled ? 'SCHEDULED' : 'ENDED'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Chip(
                        label: Text('${_room!.currentParticipants}/${_room!.maxParticipants}'),
                        avatar: const Icon(Icons.people, size: 16),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(_room!.language),
                        backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Room name
                  Text(
                    _room!.name,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // Host info
                  if (_room!.hostName != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16.r,
                          backgroundColor: PanAfricanColors.primary,
                          backgroundImage: _room!.hostAvatar != null
                              ? NetworkImage(_room!.hostAvatar!)
                              : null,
                          child: _room!.hostAvatar == null
                              ? Text(
                                  _room!.hostName![0].toUpperCase(),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14.sp),
                                )
                              : null,
                        ),
                        SizedBox(width: 2.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hosted by',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            ),
                            Text(
                              _room!.hostName!,
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  SizedBox(height: 2.h),

                  // Description
                  Text(
                    _room!.description,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(height: 2.h),

                  // Scheduled time
                  if (_room!.isScheduled && _room!.scheduledStartTime != null)
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.blue, size: 20.sp),
                          SizedBox(width: 2.w),
                          Text(
                            'Starts: ${DateFormat('MMM d, y • h:mm a').format(_room!.scheduledStartTime!)}',
                            style: TextStyle(fontSize: 14.sp, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 2.h),

                  // Tags
                  if (_room!.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 2.h,
                      children: _room!.tags.map((tag) => Chip(
                            label: Text(tag),
                            labelStyle: TextStyle(fontSize: 12.sp),
                          )).toList(),
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Room type
                  Chip(
                    label: Text(_getRoomTypeLabel(_room!.type)),
                    backgroundColor: PanAfricanColors.kenteRed.withOpacity(0.1),
                  ),
                  SizedBox(height: 4.h),

                  // Join button
                  Semantics(
                    label: _room!.isLive ? 'Join room' : (_room!.isScheduled ? 'Set reminder' : 'Room ended'),
                    button: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _room!.isLive || _room!.isScheduled ? _joinRoom : null,
                        icon: Icon(_room!.isLive ? Icons.radio : Icons.schedule, semanticLabel: _room!.isLive ? 'Join' : 'Schedule'),
                        label: Text(
                          _room!.isLive
                              ? 'Join Room'
                              : (_room!.isScheduled ? 'Set Reminder' : 'Room Ended'),
                        ),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        backgroundColor: _room!.isLive
                            ? Colors.green
                            : (_room!.isScheduled ? Colors.blue : Colors.grey),
                      ),
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

  Widget _buildPlaceholderCover(bool isDark) {
    return Container(
      width: double.infinity,
      height: 200.h,
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Center(
        child: Icon(
          Icons.radio,
          size: 64.sp,
          color: PanAfricanColors.neutralMedium,
        ),
      ),
    );
  }

  String _getRoomTypeLabel(RoomType type) {
    switch (type) {
      case RoomType.practice:
        return 'Practice';
      case RoomType.lesson:
        return 'Lesson';
      case RoomType.discussion:
        return 'Discussion';
      case RoomType.pronunciation:
        return 'Pronunciation';
      case RoomType.storytelling:
        return 'Storytelling';
      case RoomType.qa:
        return 'Q&A';
      case RoomType.cultural:
        return 'Cultural';
    }
  }
}

