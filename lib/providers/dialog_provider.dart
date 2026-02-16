import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'navigation_provider.dart';
import '../utils/error_handler.dart';
import '../utils/transport_error_policy.dart';

final dialogProvider = Provider.autoDispose.family<DialogProvider, Object?>((ref, Object? error) {
  return DialogProvider(ref.container, error);
});

class DialogProvider {
  final Object? e;
  final ProviderContainer ref;

  DialogProvider(this.ref, this.e);

  Future<bool?> showPlatformDialogue({
    required String title,
    Widget? content,
    String? action1Text,
    bool? action1OnTap,
    String? action2Text,
    bool? action2OnTap,
  }) {
    final context = ref.read(navigationProvider).navigatorKey.currentContext;
    if (context == null) return Future.value(null);
    return showDialog(
      context: context,
      builder: (context) {
        return (Platform.isAndroid)
            ? AlertDialog(
                title: Text(title),
                content: content,
                actions: <Widget>[
                  if (action2Text != null && action2OnTap != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(action2OnTap),
                      child: Text(action2Text),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(action1OnTap),
                    child: Text(action1Text ?? 'OK'),
                  ),
                ],
              )
            : CupertinoAlertDialog(
                content: content,
                title: Text(title),
                actions: <Widget>[
                  if (action2Text != null && action2OnTap != null)
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(context).pop(action2OnTap),
                      child: Text(action2Text),
                    ),
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(action1OnTap),
                    child: Text(action1Text ?? 'OK'),
                  ),
                ],
              );
      },
    );
  }

  Future<void> showExceptionDialog() async {
    _log("ERROR RUNTIME TYPE ${e.runtimeType}");

    // Use TransportErrorPolicy for DioExceptions to accurately distinguish
    // between network-level failures (no internet) and backend-level failures
    // (server unreachable, timeout, connection refused). Previously, ALL
    // SocketException-containing errors showed "not connected to internet"
    // even when internet was fine but the server was unreachable.
    if (e is DioException) {
      final dioError = e as DioException;
      final String title;
      final String message;
      final targetUrl = dioError.requestOptions.uri.host;

      if (TransportErrorPolicy.isNetworkIssue(dioError)) {
        title = 'Connection Failed';
        message = 'Could not reach the LingAfriq server ($targetUrl). '
            'Please check your internet connection and try again.\n\n'
            'If you are connected to the internet, the server domain '
            'may not be reachable from your current network.';
      } else if (TransportErrorPolicy.isBackendIssue(dioError)) {
        title = 'Server Unavailable';
        message = 'Cannot connect to the LingAfriq server ($targetUrl). '
            'The server may be temporarily down. '
            'Please try again in a few moments.';
      } else {
        // Delegate to ErrorConverter for status-code-specific handling
        final appError = ErrorConverter.toAppError(dioError);
        final userMessage = ErrorConverter.getUserMessage(appError);
        title = _titleForAppError(appError);
        message = userMessage;
      }

      await showPlatformDialogue(
        title: title,
        content: SelectableText(message),
      );
      return;
    }

    // Raw SocketException (not wrapped in DioException) — genuine network issue
    if (e is SocketException) {
      await showPlatformDialogue(
        title: 'Connection Failed',
        content: SelectableText(
          'Could not connect to the server. '
          'Please check your internet connection and try again.\n\n'
          'Error: ${(e as SocketException).message}',
        ),
      );
      return;
    }

    // Use ErrorConverter for all other errors
    final appError = ErrorConverter.toAppError(e);
    final userMessage = ErrorConverter.getUserMessage(appError);
    final title = _titleForAppError(appError);

    await showPlatformDialogue(
      title: title,
      content: SelectableText(userMessage),
    );
  }

  /// Maps an AppError to a user-friendly dialog title.
  String _titleForAppError(AppError appError) {
    if (appError is ApiError) {
      final statusCode = appError.statusCode;
      if (statusCode == 429) return 'Please slow down';
      if (statusCode == 401) return 'Authentication required';
      if (statusCode == 403) return 'Access denied';
      if (statusCode == 404) return 'Not found';
      if (statusCode != null && statusCode >= 500) return 'Server error';
    }
    return 'Oops, an error occurred';
  }

  void showSuccessSnackBar({String? message}) {
    final context = ref.read(navigationProvider).navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message ?? 'Success'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
  }

  void _log(Object message) => log(message.toString(), name: "Error_Provider");
}
