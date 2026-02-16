import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import '../../models/seasonal_event_model.dart';
import '../../widgets/animations/smooth_transitions.dart';
import '../../utils/api_service.dart';
import '../../config/api_contract.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Seasonal Events Screen
class SeasonalEventsScreen extends HookConsumerWidget {
  const SeasonalEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEvents = useState<List<SeasonalEvent>>([]);
    final upcomingEvents = useState<List<SeasonalEvent>>([]);
    final isLoading = useState(true);
    final loadError = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> loadEvents() async {
      isLoading.value = true;
      loadError.value = null;
      try {
        // Try to load from backend API first
        final response = await ApiService.get(ApiContract.events.list);
        
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          List<dynamic> eventsList = [];
          
          if (data is List) {
            eventsList = data;
          } else if (data is Map && data['data'] != null) {
            eventsList = data['data'] is List ? data['data'] : [];
          }
          
          final loadedEvents = eventsList
              .map((e) => SeasonalEvent.fromJson(e as Map<String, dynamic>))
              .toList();
          
          activeEvents.value = loadedEvents.where((e) => e.isActive).toList();
          upcomingEvents.value = loadedEvents.where((e) => e.isUpcoming).toList();
        } else {
          // Fallback to hardcoded events if API fails
          activeEvents.value = SeasonalEventDefinitions.activeEvents;
          upcomingEvents.value = SeasonalEventDefinitions.upcomingEvents;
        }
      } catch (e) {
        // Fallback to hardcoded events on error
        loadError.value = e.toString();
        activeEvents.value = SeasonalEventDefinitions.activeEvents;
        upcomingEvents.value = SeasonalEventDefinitions.upcomingEvents;
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      loadEvents();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seasonal Events',
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeEvents.value.isNotEmpty) ...[
              Text(
                'Active Events',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              ...activeEvents.value.map((event) => _EventCard(event: event, isActive: true, isDark: isDark)),
              SizedBox(height: PanAfricanSpacing.lg),
            ],
            if (upcomingEvents.value.isNotEmpty) ...[
              Text(
                'Upcoming Events',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              ...upcomingEvents.value.map((event) => _EventCard(event: event, isActive: false, isDark: isDark)),
            ],
            if (activeEvents.value.isEmpty && upcomingEvents.value.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 64.sp,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      SizedBox(height: PanAfricanSpacing.md),
                      Text(
                        'No events at the moment',
                        style: PanAfricanTypography.bodyLarge(
                          context,
                          color: PanAfricanColors.neutralMedium,
                        ),
                      ),
                      SizedBox(height: PanAfricanSpacing.xs),
                      Text(
                        'Check back soon for exciting events!',
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SeasonalEvent event;
  final bool isActive;
  final bool isDark;

  const _EventCard({
    required this.event,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${event.name}. ${event.description}. ${isActive ? "Active" : "Upcoming"}. Tap for details.',
      button: true,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          SmoothPageRoute(
            child: _EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          border: Border.all(
            color: isActive
                ? PanAfricanColors.success
                : (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? PanAfricanShadows.md : PanAfricanShadows.sm,
        ),
        child: Stack(
          children: [
            if (isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: PanAfricanRadius.lgBR,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        PanAfricanColors.success.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: PanAfricanColors.secondary.withOpacity(0.15),
                          borderRadius: PanAfricanRadius.mdBR,
                        ),
                        child: Center(
                          child: Text(event.icon, style: TextStyle(fontSize: 28.sp)),
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.name,
                                    style: PanAfricanTypography.titleMedium(context),
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: PanAfricanSpacing.xs,
                                      vertical: PanAfricanSpacing.xxxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PanAfricanColors.success,
                                      borderRadius: PanAfricanRadius.roundBR,
                                    ),
                                    child: Text(
                                      'LIVE',
                                      style: PanAfricanTypography.labelSmall(
                                        context,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: PanAfricanSpacing.xxs),
                            Text(
                              event.description,
                              style: PanAfricanTypography.bodySmall(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.xs,
                          vertical: PanAfricanSpacing.xxxs,
                        ),
                        decoration: BoxDecoration(
                          color: PanAfricanColors.tertiary.withOpacity(0.15),
                          borderRadius: PanAfricanRadius.roundBR,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 14.sp,
                              color: PanAfricanColors.tertiary,
                            ),
                            SizedBox(width: PanAfricanSpacing.xxxs),
                            Text(
                              '${event.xpMultiplier}× XP',
                              style: PanAfricanTypography.labelSmall(
                                context,
                                color: PanAfricanColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (event.featuredLanguages.isNotEmpty) ...[
                        SizedBox(width: PanAfricanSpacing.sm),
                        Icon(
                          Icons.language_rounded,
                          size: 14.sp,
                          color: PanAfricanColors.neutralMedium,
                        ),
                        SizedBox(width: PanAfricanSpacing.xxxs),
                        Expanded(
                          child: Text(
                            event.featuredLanguages.join(', '),
                            style: PanAfricanTypography.labelSmall(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.hourglass_bottom_rounded : Icons.calendar_today_rounded,
                        size: 14.sp,
                        color: isActive ? PanAfricanColors.success : PanAfricanColors.neutralMedium,
                      ),
                      SizedBox(width: PanAfricanSpacing.xxxs),
                      Text(
                        isActive
                            ? 'Ends in: ${_formatDuration(event.timeRemaining)}'
                            : 'Starts: ${DateFormat('MMM d, y').format(event.startDate)}',
                        style: PanAfricanTypography.labelSmall(
                          context,
                          color: isActive ? PanAfricanColors.success : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }
}

class _EventDetailScreen extends StatelessWidget {
  final SeasonalEvent event;

  const _EventDetailScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          event.name,
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with gradient
            Container(
              decoration: BoxDecoration(
                gradient: PanAfricanGradients.celebration,
                borderRadius: PanAfricanRadius.lgBR,
                boxShadow: PanAfricanShadows.md,
              ),
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.icon, style: TextStyle(fontSize: 56.sp)),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    event.description,
            style: PanAfricanTypography.bodyLarge(context, color: colorScheme.onPrimary),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.sm,
                      vertical: PanAfricanSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: PanAfricanRadius.roundBR,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: colorScheme.onPrimary,
                          size: 20.sp,
                        ),
                        SizedBox(width: PanAfricanSpacing.xxs),
                        Text(
                          '${event.xpMultiplier}× XP Multiplier',
                          style: PanAfricanTypography.titleSmall(context, color: colorScheme.onPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (event.featuredLanguages.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                  borderRadius: PanAfricanRadius.lgBR,
                  border: Border.all(
                    color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                  ),
                  boxShadow: PanAfricanShadows.sm,
                ),
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Languages',
                      style: PanAfricanTypography.titleMedium(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Wrap(
                      spacing: PanAfricanSpacing.xs,
                      runSpacing: PanAfricanSpacing.xs,
                      children: event.featuredLanguages.map((lang) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PanAfricanSpacing.sm,
                              vertical: PanAfricanSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: PanAfricanColors.primaryContainer,
                              borderRadius: PanAfricanRadius.roundBR,
                            ),
                            child: Text(
                              lang,
                              style: PanAfricanTypography.labelMedium(
                                context,
                                color: PanAfricanColors.onPrimaryContainer,
                              ),
                            ),
                          )).toList(),
                    ),
                  ],
                ),
              ),
            ],
            if (event.specialRewards.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                  borderRadius: PanAfricanRadius.lgBR,
                  border: Border.all(
                    color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                  ),
                  boxShadow: PanAfricanShadows.sm,
                ),
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Special Rewards',
                      style: PanAfricanTypography.titleMedium(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    ...event.specialRewards.entries.map((entry) => Padding(
                          padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: PanAfricanColors.secondary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: PanAfricanColors.secondary,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: PanAfricanSpacing.sm),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: PanAfricanTypography.bodyMedium(context),
                                ),
                              ),
                              Text(
                                entry.value.toString(),
                                style: PanAfricanTypography.titleSmall(
                                  context,
                                  color: PanAfricanColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

