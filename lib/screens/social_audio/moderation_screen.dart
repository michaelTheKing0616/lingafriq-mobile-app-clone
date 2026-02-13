import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/social_audio/social_audio_room_model.dart';
import '../../providers/social_audio_provider.dart';
import '../../services/social_audio/social_audio_service.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/loading/loading_overlay.dart';

/// Moderation Screen - Manage room participants and moderation
class ModerationScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ModerationScreen({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen> {
  List<RoomParticipant> _participants = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(socialAudioServiceProvider);
      final participants = await service.getRoomParticipants(widget.roomId);
      setState(() {
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _moderateUser({
    required String userId,
    required String action,
    String? reason,
  }) async {
    try {
      final service = ref.read(socialAudioServiceProvider);
      await service.moderateRoom(
        roomId: widget.roomId,
        targetUserId: userId,
        action: action,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${action}d successfully')),
        );
      }

      // Reload participants
      await _loadParticipants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showModerationDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Moderate $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic_off),
              title: const Text('Mute'),
              onTap: () {
                Navigator.pop(context);
                _moderateUser(userId: userId, action: 'mute');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Unmute'),
              onTap: () {
                Navigator.pop(context);
                _moderateUser(userId: userId, action: 'unmute');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Promote to Speaker'),
              onTap: () {
                Navigator.pop(context);
                _moderateUser(userId: userId, action: 'promote');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: const Text('Demote to Listener'),
              onTap: () {
                Navigator.pop(context);
                _moderateUser(userId: userId, action: 'demote');
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Remove from Room', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showRemoveConfirmation(userId, userName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmation(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Are you sure you want to remove $userName from this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _moderateUser(userId: userId, action: 'remove', reason: 'Removed by moderator');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Moderation'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                    SizedBox(height: 2.h),
                    Text(_error!),
                    SizedBox(height: 4.h),
                    FilledButton(
                      onPressed: _loadParticipants,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _participants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64.sp, color: PanAfricanColors.neutralMedium),
                        SizedBox(height: 2.h),
                        const Text('No participants'),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadParticipants,
                    child: ListView.builder(
                      padding: EdgeInsets.all(4.w),
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final participant = _participants[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 2.h),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24.r,
                              backgroundColor: _getRoleColor(participant.role),
                              child: Text(
                                participant.userName[0].toUpperCase(),
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16.sp),
                              ),
                            ),
                            title: Text(
                              participant.userName,
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Chip(
                                  label: Text(participant.role.name.toUpperCase()),
                                  labelStyle: TextStyle(fontSize: 10.sp),
                                  backgroundColor: _getRoleColor(participant.role).withOpacity(0.2),
                                ),
                                if (participant.isMuted)
                                  Row(
                                    children: [
                                      Icon(Icons.mic_off, size: 14.sp, color: Colors.red),
                                      SizedBox(width: 1.w),
                                      Text('Muted', style: TextStyle(fontSize: 12.sp, color: Colors.red)),
                                    ],
                                  ),
                                if (participant.isSpeaking)
                                  Row(
                                    children: [
                                      Icon(Icons.mic, size: 14.sp, color: Colors.green),
                                      SizedBox(width: 1.w),
                                      Text('Speaking', style: TextStyle(fontSize: 12.sp, color: Colors.green)),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: participant.role != ParticipantRole.host
                                ? IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => _showModerationDialog(
                                      participant.userId,
                                      participant.userName,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Color _getRoleColor(ParticipantRole role) {
    switch (role) {
      case ParticipantRole.host:
        return Colors.purple;
      case ParticipantRole.moderator:
        return Colors.blue;
      case ParticipantRole.speaker:
        return Colors.green;
      case ParticipantRole.listener:
        return Colors.grey;
    }
  }
}

