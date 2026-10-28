import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/screens/chat/tribe_chat_screen.dart';

/// Village circles list — reference: WhatsApp Communities member list + Discord server sidebar.
class CirclesScreen extends HookConsumerWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = useState<List<Map<String, dynamic>>>([]);
    final loading = useState(true);
    final error = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> load() async {
      loading.value = true;
      error.value = null;
      try {
        final res = await ApiService.get('/api/v2/circles');
        final data = res.data;
        if (data is Map && data['ok'] == true && data['circles'] is List) {
          circles.value = (data['circles'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          error.value = 'We could not load your circles right now.';
        }
      } catch (_) {
        error.value = 'You are offline. Your circles will appear when you reconnect.';
      } finally {
        loading.value = false;
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
        title: Text('Your circles', style: PanAfricanTypography.titleLarge(context)),
      ),
      body: ResponsiveSafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: _body(context, loading.value, error.value, circles.value, load),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    bool loading,
    String? error,
    List<Map<String, dynamic>> circles,
    Future<void> Function() reload,
  ) {
    if (loading && circles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (error != null && circles.isEmpty) {
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
    if (circles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(
            'Start a study circle or join a language village to learn together.',
            style: PanAfricanTypography.bodyLarge(context),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        vertical: PanAfricanSpacing.sm,
        horizontal: PanAfricanSpacing.md,
      ),
      itemCount: circles.length,
      separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.xs),
      itemBuilder: (context, index) {
        final c = circles[index];
        final name = c['name']?.toString() ?? 'Circle';
        final status = c['status']?.toString() ?? 'draft';
        final count = c['member_count'] ?? 0;
        final max = c['max_members'] ?? 50;
        final id = c['id']?.toString() ?? '';
        final subtitle = status == 'open'
            ? '$count of $max members · Open'
            : status == 'full'
                ? 'Full — $count members'
                : '$count members · Opens at ${c['min_open'] ?? 5}';

        return Semantics(
          button: true,
          label: '$name, $subtitle',
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              onTap: id.isEmpty
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TribeChatScreen(
                            tribeId: id,
                            tribeName: name,
                            circleMode: true,
                          ),
                        ),
                      );
                    },
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: PanAfricanColors.primary,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: PanAfricanTypography.labelLarge(context).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: PanAfricanTypography.titleMedium(context)),
                          SizedBox(height: PanAfricanSpacing.xxs),
                          Text(subtitle, style: PanAfricanTypography.bodySmall(context)),
                        ],
                      ),
                    ),
                    if (status == 'pending-approval')
                      Icon(Icons.hourglass_top, color: Theme.of(context).colorScheme.error),
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
