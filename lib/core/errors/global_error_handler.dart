import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_exceptions.dart';

/// Global error handler widget
/// Catches and handles all unhandled errors in the app
class GlobalErrorHandler extends StatefulWidget {
  final Widget child;

  const GlobalErrorHandler({
    super.key,
    required this.child,
  });

  @override
  State<GlobalErrorHandler> createState() => _GlobalErrorHandlerState();
}

class _GlobalErrorHandlerState extends State<GlobalErrorHandler> {
  @override
  void initState() {
    super.initState();
    
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _handleError(details.exception, details.stack);
    };

    // Handle platform errors (async errors outside Flutter)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleError(error, stack);
      return true;
    };
  }

  void _handleError(dynamic error, StackTrace? stack) {
    final exception = ExceptionHandler.handleError(error);
    
    debugPrint('🚨 Global Error Handler: ${exception.message}');
    if (stack != null) {
      debugPrint('Stack trace: $stack');
    }

    // In production, you might want to:
    // - Send to crash reporting service (Firebase Crashlytics)
    // - Log to analytics
    // - Show user-friendly error message
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Error boundary widget for catching widget errors
/// Note: Flutter doesn't have true error boundaries like React.
/// This widget provides error handling for specific error scenarios.
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap child in error handling
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          final exception = ExceptionHandler.handleError(e);
          final userMessage = ExceptionHandler.getUserFriendlyMessage(exception);

          return _ErrorFallback(
            message: errorMessage ?? userMessage,
            onRetry: onRetry,
            fallback: fallback,
          );
        }
      },
    );
  }
}

class _ErrorFallback extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Widget? fallback;

  const _ErrorFallback({
    required this.message,
    this.onRetry,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (fallback != null) return fallback!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

