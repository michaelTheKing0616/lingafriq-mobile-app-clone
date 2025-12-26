/// ErrorHandler Integration Example
/// Shows the pattern for integrating ErrorHandler across all screens
/// 
/// Copy this pattern to all screens requiring error handling

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/error_handler.dart';
import '../../services/monitoring/sentry_service.dart';

/// Example Screen with ErrorHandler Integration
class ExampleScreenWithErrorHandler extends HookConsumerWidget {
  const ExampleScreenWithErrorHandler({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final data = useState<Map<String, dynamic>?>(null);

    Future<void> loadData() async {
      try {
        isLoading.value = true;
        // Your API call here
        // final result = await api.getData();
        // data.value = result;
      } catch (e) {
        // ERRORHANDLER INTEGRATION - Pattern to apply everywhere
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
        // SENTRY INTEGRATION - Log all errors
        SentryService().captureException(
          e,
          context: {
            'screen': 'ExampleScreenWithErrorHandler',
            'action': 'loadData',
          },
        );
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> submitData(Map<String, dynamic> formData) async {
      try {
        isLoading.value = true;
        // Your API call here
        // await api.submitData(formData);
        if (context.mounted) {
          ErrorHandler.showSuccess(context, 'Data submitted successfully!');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
        SentryService().captureException(
          e,
          context: {
            'screen': 'ExampleScreenWithErrorHandler',
            'action': 'submitData',
          },
        );
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> loadDataWithRetry() async {
      // ERRORHANDLER WITH RETRY - For critical operations
      final result = await ErrorHandler.handleErrorWithRetry(
        context: context,
        action: () async {
          // Your API call here
          // return await api.getData();
          return {};
        },
        errorMessage: 'Failed to load data. Would you like to retry?',
      );

      if (result != null) {
        // data.value = result;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Example Screen')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: loadData,
              child: Text('Load Data'),
            ),
            ElevatedButton(
              onPressed: () => submitData({}),
              child: Text('Submit Data'),
            ),
            ElevatedButton(
              onPressed: loadDataWithRetry,
              child: Text('Load with Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Key Points:
/// 1. Always wrap async operations in try-catch
/// 2. Check context.mounted before showing dialogs/snackbars
/// 3. Use ErrorHandler.showError() for user-friendly messages
/// 4. Use SentryService().captureException() for error tracking
/// 5. Use ErrorHandler.handleErrorWithRetry() for critical operations
/// 6. Always set loading states in finally blocks

