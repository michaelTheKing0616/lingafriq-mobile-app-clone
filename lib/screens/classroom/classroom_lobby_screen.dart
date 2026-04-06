import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class ClassroomLobbyScreen extends ConsumerWidget {
  const ClassroomLobbyScreen({super.key});

  static const _filters = ['All', 'Starting Soon', 'My Languages'];

  static final _rooms = [
    _RoomData('Yoruba Conversations', 'Adeola K.', 'Yoruba', 23, true, true),
    _RoomData('Swahili for Travel', 'Amina N.', 'Swahili', 15, false, false),
    _RoomData('Zulu Pronunciation', 'Sipho M.', 'Zulu', 8, true, false),
    _RoomData('Hausa Greetings 101', 'Fatima B.', 'Hausa', 31, false, true),
    _RoomData('Igbo Tonal Practice', 'Chidi O.', 'Igbo', 12, true, false),
    _RoomData('Amharic Script Lab', 'Selam T.', 'Amharic', 19, false, false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      floatingActionButton: GriotFab(
        icon: Icons.mic_rounded,
        heroTag: 'host_room',
        onPressed: () {},
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Rooms',
                      style: ModernGriotTypography.headlineMedium(
                        context: context,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Join a live conversation or host your own',
                      style: ModernGriotTypography.bodyMedium(
                        context: context,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _FilterRow(filters: _filters),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _RoomCard(room: _rooms[index]),
                  childCount: _rooms.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 80.h)),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatefulWidget {
  const _FilterRow({required this.filters});
  final List<String> filters;

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.filters.length, (i) {
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GriotChip(
              label: widget.filters[i],
              selected: _selected == i,
              onTap: () => setState(() => _selected = i),
            ),
          );
        }),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
  final _RoomData room;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotCard(
      surfaceLevel: 1,
      onTap: () {},
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (room.isLive) ...[
                _LivePulseBadge(),
                SizedBox(width: 6.w),
              ],
              if (room.isTrending)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.secondaryContainer,
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded,
                          size: 12.sp,
                          color: ModernGriotColors.onSecondaryContainer),
                      SizedBox(width: 3.w),
                      Text(
                        'HOT',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: ModernGriotColors.onSecondaryContainer,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(25),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Text(
              room.language,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            room.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ModernGriotTypography.titleSmall(context: context),
          ),
          SizedBox(height: 4.h),
          Text(
            room.instructor,
            style: ModernGriotTypography.bodySmall(context: context),
          ),
          const Spacer(),
          Row(
            children: [
              _OverlappingAvatars(count: min(room.participants, 4)),
              SizedBox(width: 6.w),
              Text(
                '${room.participants}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivePulseBadge extends StatefulWidget {
  @override
  State<_LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<_LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = 1.0 + _ctrl.value * 0.3;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withAlpha((200 + 55 * _ctrl.value).round()),
            borderRadius: ModernGriotRadius.borderPill,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withAlpha((40 * scale).round()),
                blurRadius: 8 * scale,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.r,
                height: 6.r,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars({required this.count});
  final int count;

  static const _colors = [
    Color(0xFFE8A87C),
    Color(0xFF85DCB0),
    Color(0xFF8BBEE8),
    Color(0xFFE088A8),
  ];

  @override
  Widget build(BuildContext context) {
    final avatarSize = 22.r;
    final overlap = 8.w;

    return SizedBox(
      width: avatarSize + (count - 1) * (avatarSize - overlap),
      height: avatarSize,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: _colors[i % _colors.length],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 12.sp,
                color: Colors.white.withAlpha(200),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RoomData {
  final String title;
  final String instructor;
  final String language;
  final int participants;
  final bool isLive;
  final bool isTrending;

  const _RoomData(
    this.title,
    this.instructor,
    this.language,
    this.participants,
    this.isLive,
    this.isTrending,
  );
}
