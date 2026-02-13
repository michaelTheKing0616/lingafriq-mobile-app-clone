/// Error Recovery Widget
/// Provides error handling with retry functionality for any widget
/// 
/// Features:
/// - Automatic error detection
/// - Retry mechanism
/// - User-friendly error messages
/// - Fallback UI

import 'package:flutter/material.dart';
import '../../core/errors/global_error_handler.dart';
import '../../core/utils/retry_helper.dart';

class ErrorRecoveryWidget extends StatefulWidget {
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? fallback;
  final int maxRetries;
  final Duration retryDelay;

  const ErrorRecoveryWidget({
    Key? key,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.fallback,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  State<ErrorRecoveryWidget> createState() => _ErrorRecoveryWidgetState();
}

class _ErrorRecoveryWidgetState extends State<ErrorRecoveryWidget> {
  int _retryCount = 0;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: widget.errorMessage ?? _error?.toString(),
      onRetry: _handleRetry,
      fallback: widget.fallback,
      child: Builder(
        builder: (context) {
          if (_error != null && _retryCount >= widget.maxRetries) {
            return widget.fallback ?? _buildErrorWidget(context);
          }
          return widget.child;
        },
      ),
    );
  }

  void _handleRetry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });

    if (widget.onRetry != null) {
      // Execute retry with exponential backoff
      RetryHelper.retry(
        operation: () async {
          widget.onRetry!();
          return true;
        },
        maxAttempts: widget.maxRetries - _retryCount,
        initialDelay: widget.retryDelay,
        onRetry: (attempt, error) {
          setState(() {
            _retryCount = attempt;
          });
        },
      ).catchError((error, stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
        return false;
      });
    }
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            widget.errorMessage ?? 'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retryCount < widget.maxRetries ? _handleRetry : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

