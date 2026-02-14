import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/social_audio/social_audio_room_model.dart';
import '../../providers/social_audio_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/loading/loading_overlay.dart';
import 'room_detail_screen.dart';
import 'package:intl/intl.dart';

/// Scheduled Sessions Screen - View and manage scheduled rooms
class ScheduledSessionsScreen extends ConsumerStatefulWidget {
  const ScheduledSessionsScreen({super.key});

  @override
  ConsumerState<ScheduledSessionsScreen> createState() => _ScheduledSessionsScreenState();
}

class _ScheduledSessionsScreenState extends ConsumerState<ScheduledSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialAudioProvider.notifier).loadScheduledRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialAudioProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Sessions'),
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        child: state.scheduledRooms.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 64.sp, color: PanAfricanColors.neutralMedium),
                    SizedBox(height: 2.h),
                    Text(
                      'No scheduled sessions',
                      style: TextStyle(fontSize: 16.sp, color: PanAfricanColors.neutralMedium),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(socialAudioProvider.notifier).loadScheduledRooms();
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: state.scheduledRooms.length,
                  itemBuilder: (context, index) {
                    final room = state.scheduledRooms[index];
                    return _buildScheduledRoomCard(room, isDark);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildScheduledRoomCard(SocialAudioRoom room, bool isDark) {
    final timeUntil = room.scheduledStartTime?.difference(DateTime.now());

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailScreen(roomId: room.id),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
                    ),
                    child: Text(
                      'SCHEDULED',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                room.description,
                style: TextStyle(fontSize: 14.sp),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16.sp, color: Colors.blue),
                  SizedBox(width: 1.w),
                  Text(
                    room.scheduledStartTime != null
                        ? DateFormat('MMM d, y • h:mm a').format(room.scheduledStartTime!)
                        : 'TBD',
                    style: TextStyle(fontSize: 14.sp, color: Colors.blue),
                  ),
                  if (timeUntil != null && timeUntil.inDays > 0) ...[
                    SizedBox(width: 2.w),
                    Text(
                      '(${timeUntil.inDays}d ${timeUntil.inHours % 24}h)',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Chip(
                    label: Text(room.language),
                    backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                  ),
                  SizedBox(width: 2.w),
                  Chip(
                    label: Text('${room.currentParticipants} going'),
                    avatar: const Icon(Icons.people, size: 16),
                  ),
                  const Spacer(),
                  if (room.hostName != null)
                    Text(
                      'by ${room.hostName}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

