import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/wa_status_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';

class WaStatusViewScreen extends ConsumerStatefulWidget {
  const WaStatusViewScreen({super.key, required this.statusId});

  final String statusId;

  @override
  ConsumerState<WaStatusViewScreen> createState() => _WaStatusViewScreenState();
}

class _WaStatusViewScreenState extends ConsumerState<WaStatusViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(waStatusProvider.notifier).markViewed(widget.statusId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waStatusProvider);
    dynamic status;
    for (final item in [...state.mine, ...state.feed]) {
      if (item.id == widget.statusId) {
        status = item;
        break;
      }
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: status == null
              ? const AppEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Status unavailable',
                  subtitle: 'This status may have expired or is no longer visible.',
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.caption.isEmpty
                                  ? (status.text.isEmpty ? 'Status update' : status.text)
                                  : status.caption,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Type: ${status.mediaType}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            if ((status.text as String).isNotEmpty)
                              Text(
                                status.text,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      height: 1.45,
                                    ),
                              ),
                          ],
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
