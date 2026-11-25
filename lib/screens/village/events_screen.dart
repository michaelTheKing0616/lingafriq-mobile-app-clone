import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lingafriq/screens/social_audio/room_detail_screen.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Festival calendar + live cultural sessions — reference: Eventbrite live events list.
class EventsScreen extends HookConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = useState<List<Map<String, dynamic>>>([]);
    final loading = useState(true);
    final gated = useState(false);
    final error = useState<String?>(null);
    final joining = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> load() async {
      loading.value = true;
      error.value = null;
      gated.value = false;
      try {
        final res = await ApiService.get('/api/v2/village/events');
        final data = res.data;
        if (data is Map && data['events_gated'] == true) {
          gated.value = true;
          events.value = [];
          return;
        }
        if (data is Map && data['ok'] == true && data['events'] is List) {
          events.value = (data['events'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          error.value = 'We could not load the festival calendar right now.';
        }
      } catch (_) {
        error.value = 'You are offline. Festival dates will appear when you reconnect.';
      } finally {
        loading.value = false;
      }
    }

    Future<void> joinEvent(String eventId) async {
      joining.value = eventId;
      try {
        final res = await ApiService.post('/api/v2/village/events/$eventId/join');
        final data = res.data;
        if (data is Map &&
            data['ok'] == true &&
            data['room_id'] is String &&
            context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RoomDetailScreen(roomId: data['room_id'] as String),
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This session is not open yet. Check back on the festival date.')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('We could not open the session. Try again in a moment.')),
          );
        }
      } finally {
        joining.value = null;
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text('Cultural events', style: PanAfricanTypography.titleLarge(context)),
      ),
      body: ResponsiveSafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: _body(
            context,
            loading.value,
            gated.value,
            error.value,
            events.value,
            joining.value,
            load,
            joinEvent,
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    bool loading,
    bool gated,
    String? error,
    List<Map<String, dynamic>> events,
    String? joiningId,
    Future<void> Function() reload,
    Future<void> Function(String id) joinEvent,
  ) {
    if (gated) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(
            'Live cultural sessions are for verified adult learners. Ask a guardian to review your account settings.',
            style: PanAfricanTypography.bodyLarge(context),
          ),
        ],
      );
    }
    if (loading && events.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (error != null && events.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(error, style: PanAfricanTypography.bodyLarge(context)),
          SizedBox(height: PanAfricanSpacing.md),
          Semantics(
            button: true,
            label: 'Try again',
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                reload();
              },
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }
    if (events.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(
            'No upcoming festivals yet. Pull to refresh when new dates are published.',
            style: PanAfricanTypography.bodyLarge(context),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.sm,
      ),
      itemCount: events.length,
      separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
      itemBuilder: (context, index) {
        final ev = events[index];
        final id = ev['id']?.toString() ?? '';
        final status = ev['display_status']?.toString() ?? 'upcoming';
        final sessionKind = ev['session_kind']?.toString() ?? 'none';
        final anchor = DateTime.tryParse(ev['anchor_date_utc']?.toString() ?? '');
        final dateLabel = anchor != null
            ? DateFormat.yMMMd().format(anchor.toLocal())
            : '';
        final canJoin = status == 'live' || (status == 'past' && sessionKind == 'replay');
        final statusLabel = status == 'live'
            ? 'Live now'
            : status == 'past'
                ? 'Replay'
                : 'Upcoming';

        return Semantics(
          container: true,
          label: '${ev['name']}, $dateLabel, $statusLabel',
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              onTap: canJoin && joiningId == null
                  ? () {
                      HapticFeedback.lightImpact();
                      joinEvent(id);
                    }
                  : null,
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ev['name']?.toString() ?? '',
                            style: PanAfricanTypography.titleMedium(context),
                          ),
                        ),
                        _StatusChip(label: statusLabel, live: status == 'live'),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      '${ev['language']?.toString().toUpperCase() ?? ''} · $dateLabel',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      ev['summary']?.toString() ?? '',
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                    if (canJoin) ...[
                      SizedBox(height: PanAfricanSpacing.md),
                      Align(
                        alignment: Alignment.centerRight,
                        child: joiningId == id
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Semantics(
                                button: true,
                                label: status == 'past' ? 'Open replay session' : 'Join live session',
                                child: FilledButton.tonal(
                                  onPressed: () => joinEvent(id),
                                  child: Text(status == 'past' ? 'Replay' : 'Join live'),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.live});

  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: live ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
      ),
      child: Text(
        label,
        style: PanAfricanTypography.labelSmall(context).copyWith(
          color: live ? scheme.onErrorContainer : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
