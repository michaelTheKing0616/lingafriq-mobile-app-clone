import 'package:flutter/material.dart';
import 'package:lingafriq/services/sync/outbox_service.dart';

/// Visible sync state. Offline is never labelled synced.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({
    super.key,
    required this.online,
    required this.syncing,
    required this.pending,
    required this.failed,
    this.onRetry,
  });

  final bool online;
  final bool syncing;
  final int pending;
  final int failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final visibility = syncVisibility(
      online: online,
      syncing: syncing,
      pending: pending,
      failed: failed,
    );
    final label = _label(visibility);
    final color = _color(visibility);
    return Semantics(
      container: true,
      label: label,
      liveRegion: true,
      child: Material(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(_icon(visibility), color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (visibility == SyncVisibility.failed)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Retry'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(SyncVisibility visibility) {
    switch (visibility) {
      case SyncVisibility.synced:
        return 'Synced';
      case SyncVisibility.pending:
        return 'Pending $pending';
      case SyncVisibility.syncing:
        return 'Syncing';
      case SyncVisibility.failed:
        return 'Failed $failed';
      case SyncVisibility.offline:
        return 'Offline';
    }
  }

  IconData _icon(SyncVisibility visibility) {
    switch (visibility) {
      case SyncVisibility.synced:
        return Icons.cloud_done;
      case SyncVisibility.pending:
        return Icons.cloud_upload;
      case SyncVisibility.syncing:
        return Icons.sync;
      case SyncVisibility.failed:
        return Icons.error_outline;
      case SyncVisibility.offline:
        return Icons.cloud_off;
    }
  }

  Color _color(SyncVisibility visibility) {
    switch (visibility) {
      case SyncVisibility.synced:
        return const Color(0xFF1B7F4E);
      case SyncVisibility.pending:
        return const Color(0xFF1D4E89);
      case SyncVisibility.syncing:
        return const Color(0xFF1D4E89);
      case SyncVisibility.failed:
        return const Color(0xFF9B2335);
      case SyncVisibility.offline:
        return const Color(0xFF8A5A00);
    }
  }
}
