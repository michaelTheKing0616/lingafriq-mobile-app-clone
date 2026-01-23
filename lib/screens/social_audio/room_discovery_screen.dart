import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/social_audio/social_audio_room_model.dart';
import '../../providers/social_audio_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/loading/loading_overlay.dart';
import 'room_detail_screen.dart';
import 'create_room_screen.dart';
import 'scheduled_sessions_screen.dart';

/// Room Discovery Screen - Browse and search for language practice rooms
class RoomDiscoveryScreen extends ConsumerStatefulWidget {
  const RoomDiscoveryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RoomDiscoveryScreen> createState() => _RoomDiscoveryScreenState();
}

class _RoomDiscoveryScreenState extends ConsumerState<RoomDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLanguage;
  RoomType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadRooms() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialAudioProvider.notifier).discoverRooms();
      ref.read(socialAudioProvider.notifier).loadScheduledRooms();
      ref.read(socialAudioProvider.notifier).loadMyRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialAudioProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Practice Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRoomScreen(),
                ),
              );
              // CRITICAL FIX: Convert .then() to async/await for better error handling
              if (context.mounted) {
                _loadRooms();
              }
            },
            tooltip: 'Create Room',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Live', icon: Icon(Icons.radio)),
            Tab(text: 'Scheduled', icon: Icon(Icons.schedule)),
            Tab(text: 'My Rooms', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        child: Column(
          children: [
            // Search and filters
            _buildSearchAndFilters(context, isDark, state),
            // Rooms list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRoomsList(state.discoveredRooms.where((r) => r.isLive).toList(), isDark),
                  _buildRoomsList(state.scheduledRooms, isDark),
                  _buildRoomsList(state.myRooms, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    bool isDark,
    SocialAudioState state,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search rooms...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(socialAudioProvider.notifier).discoverRooms(searchQuery: '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              ),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                ref.read(socialAudioProvider.notifier).discoverRooms(searchQuery: '');
              }
            },
            onSubmitted: (value) {
              ref.read(socialAudioProvider.notifier).discoverRooms(searchQuery: value);
            },
          ),
          SizedBox(height: 2.h),
          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  ),
                  items: ['All', 'Yoruba', 'Swahili', 'Zulu', 'Igbo', 'Hausa']
                      .map((lang) => DropdownMenuItem(
                            value: lang == 'All' ? null : lang,
                            child: Text(lang),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value);
                    ref.read(socialAudioProvider.notifier).discoverRooms(language: value);
                  },
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: DropdownButtonFormField<RoomType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...RoomType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getRoomTypeLabel(type)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value);
                    ref.read(socialAudioProvider.notifier).discoverRooms(type: value);
                  },
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildRoomsList(List<SocialAudioRoom> rooms, bool isDark) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radio, size: 64.sp, color: PanAfricanColors.neutralMedium),
            SizedBox(height: 2.h),
            Text(
              'No rooms available',
              style: TextStyle(fontSize: 16.sp, color: PanAfricanColors.neutralMedium),
            ),
            SizedBox(height: 4.h),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateRoomScreen(),
                  ),
                ).then((_) => _loadRooms());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create First Room'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(socialAudioProvider.notifier).discoverRooms();
        await ref.read(socialAudioProvider.notifier).loadScheduledRooms();
        await ref.read(socialAudioProvider.notifier).loadMyRooms();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildRoomCard(room, isDark);
        },
      ),
    );
  }

  Widget _buildRoomCard(SocialAudioRoom room, bool isDark) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          // CRITICAL FIX: Convert .then() to async/await for better error handling
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailScreen(roomId: room.id),
            ),
          );
          if (context.mounted) {
            _loadRooms();
          }
        },
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Room status indicator
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: room.isLive
                          ? Colors.green
                          : (room.isScheduled ? Colors.blue : Colors.grey),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      room.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Participant count
                  Chip(
                    label: Text('${room.currentParticipants}/${room.maxParticipants}'),
                    avatar: const Icon(Icons.people, size: 16),
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
                  // Language badge
                  Chip(
                    label: Text(room.language),
                    backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                  ),
                  SizedBox(width: 2.w),
                  // Type badge
                  Chip(
                    label: Text(_getRoomTypeLabel(room.type)),
                    backgroundColor: PanAfricanColors.kenteRed.withOpacity(0.1),
                  ),
                  const Spacer(),
                  // Host info
                  if (room.hostName != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12.r,
                          backgroundColor: PanAfricanColors.primary,
                          child: Text(
                            room.hostName![0].toUpperCase(),
                            style: TextStyle(fontSize: 10.sp, color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          room.hostName!,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ],
                    ),
                ],
              ),
              if (room.isScheduled && room.scheduledStartTime != null) ...[
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14.sp, color: Colors.blue),
                    SizedBox(width: 1.w),
                    Text(
                      'Starts ${_formatDateTime(room.scheduledStartTime!)}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'now';
    }
  }
}

