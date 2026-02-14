import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/backend_health_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Connection Status Indicator Widget
/// Shows backend connection status to the user
class ConnectionStatusIndicator extends ConsumerWidget {
  final bool showWhenConnected;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? textColor;

  const ConnectionStatusIndicator({
    Key? key,
    this.showWhenConnected = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthService = ref.watch(backendHealthServiceProvider);
    
    return FutureBuilder<BackendConnectionStatus>(
      future: healthService.getConnectionStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        
        // Don't show if connected and showWhenConnected is false
        if (status.isConnected && !showWhenConnected) {
          return const SizedBox.shrink();
        }

        // Show offline or partial connectivity
        if (status.isOffline || status.hasPartialConnectivity) {
          return _ConnectionBanner(
            status: status,
            padding: padding,
            backgroundColor: backgroundColor,
            textColor: textColor,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  final BackendConnectionStatus status;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? textColor;

  const _ConnectionBanner({
    required this.status,
    this.padding,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? 
        (status.isOffline 
            ? Colors.red.withOpacity(0.9)
            : Colors.orange.withOpacity(0.9));
    final txtColor = textColor ?? Theme.of(context).colorScheme.onPrimary;

    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              status.isOffline ? Icons.cloud_off : Icons.warning_amber_rounded,
              color: txtColor,
              size: 20.sp,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                status.isOffline
                    ? 'No internet connection. Some features may be limited.'
                    : 'Limited connectivity. Some features may not work properly.',
                style: TextStyle(
                  color: txtColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (status.hasPartialConnectivity)
              Text(
                '${(status.endpointAvailability * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: txtColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact connection status indicator (icon only)
class CompactConnectionIndicator extends ConsumerWidget {
  const CompactConnectionIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthService = ref.watch(backendHealthServiceProvider);
    
    return FutureBuilder<BackendConnectionStatus>(
      future: healthService.getConnectionStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        
        if (status.isFullyOperational) {
          return const SizedBox.shrink();
        }

        return Tooltip(
          message: status.isOffline
              ? 'Offline'
              : 'Limited connectivity (${(status.endpointAvailability * 100).toStringAsFixed(0)}%)',
          child: Icon(
            status.isOffline ? Icons.cloud_off : Icons.warning_amber_rounded,
            size: 18,
            color: status.isOffline ? Colors.red : Colors.orange,
          ),
        );
      },
    );
  }
}

