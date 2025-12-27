import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'navigation_provider.dart';

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
    if (e is SocketException || e.toString().contains("SocketException")) {
      await showPlatformDialogue(
        title: 'Network Error',
        content: const SelectableText("Seems like, you're not connected to internet"),
      );
      return;
    }

    // Use ErrorConverter for consistent error handling
    final appError = ErrorConverter.toAppError(e);
    final userMessage = ErrorConverter.getUserMessage(appError);

    await showPlatformDialogue(
      title: appError is ApiError && appError.statusCode != null
          ? "Error ${appError.statusCode}"
          : "Error",
      content: SelectableText(userMessage),
    );
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
