import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/snap_provider.dart';
import 'package:lingafriq/screens/snap/ui/snap_theme.dart';

class SnapStreaksScreen extends ConsumerStatefulWidget {
  const SnapStreaksScreen({super.key});

  @override
  ConsumerState<SnapStreaksScreen> createState() => _SnapStreaksScreenState();
}

class _SnapStreaksScreenState extends ConsumerState<SnapStreaksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(snapProvider.notifier).loadStreaks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: SnapUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: SnapUi.scaffoldBg(isDark),
        title: const Text('Streaks'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SnapUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Text('Streak', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Exchange snaps daily to keep your streak alive.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (state.streaks.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SnapUi.cardBg(isDark),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('No active streaks yet.'),
            ),
          ...state.streaks.map(
            (item) {
              final userName = (item['peer_username'] ?? item['username'] ?? 'Friend').toString();
              final countRaw = item['streak_count'];
              final count = countRaw is num ? countRaw.toInt() : int.tryParse('$countRaw') ?? 0;
              final expiring = item['expiring_soon'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SnapUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person_outline)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(expiring ? 'Expiring soon' : '$count day streak'),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, '/snap-camera'),
                      style: FilledButton.styleFrom(backgroundColor: SnapUi.accent()),
                      child: const Icon(Icons.camera_alt, size: 18),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
