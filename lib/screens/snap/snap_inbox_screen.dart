import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/snap_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';

class SnapInboxScreen extends ConsumerStatefulWidget {
  const SnapInboxScreen({super.key});

  @override
  ConsumerState<SnapInboxScreen> createState() => _SnapInboxScreenState();
}

class _SnapInboxScreenState extends ConsumerState<SnapInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(snapProvider.notifier).loadInbox();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : PanAfricanGradients.kente,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(snapProvider.notifier).loadInbox(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Snap Inbox',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Private visual messages that disappear.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/snap-camera'),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Send snap'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/snap-streaks'),
                        icon: const Icon(Icons.local_fire_department_outlined),
                        label: const Text('Streaks'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (state.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(state.errorMessage!),
                  ),
                if (state.loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ))
                else if (state.inbox.isEmpty)
                  const AppEmptyState(
                    icon: Icons.snapchat_outlined,
                    title: 'No snaps yet',
                    subtitle: 'When friends send snaps, they will appear here.',
                  )
                else
                  ...state.inbox.map(
                    (snap) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? PanAfricanColors.surfaceContainerDark
                            : PanAfricanColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: snap.opened
                              ? PanAfricanColors.neutralLight
                              : PanAfricanColors.accent,
                          child: Icon(
                            snap.opened ? Icons.visibility_outlined : Icons.mark_chat_unread_outlined,
                            color: Colors.black87,
                          ),
                        ),
                        title: Text(snap.caption.isEmpty ? 'Snap message' : snap.caption),
                        subtitle: Text(snap.mediaType.toUpperCase()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await ref.read(snapProvider.notifier).openMessage(snap.id);
                          if (!mounted) return;
                          Navigator.pushNamed(
                            context,
                            '/snap-viewer',
                            arguments: {'snapId': snap.id},
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
