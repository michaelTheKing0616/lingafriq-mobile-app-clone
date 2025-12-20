import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

/// Error boundary widget to catch and display errors gracefully
/// Prevents white screens by showing user-friendly error messages
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.fallback,
    this.errorMessage,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = details.exception.toString();
        });
      }
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildErrorWidget();
    }

    return widget.child;
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                24.heightBox,
                Text(
                  widget.errorMessage ?? 'Something went wrong',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                16.heightBox,
                Text(
                  'Please try again or contact support if the problem persists.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.onRetry != null) ...[
                  32.heightBox,
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = null;
                      });
                      widget.onRetry?.call();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

