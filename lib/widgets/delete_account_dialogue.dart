import 'package:flutter/material.dart';

/// A simple confirmation dialog asking the user to confirm account deletion.
class DeleteAccountDialog {
  static Future<bool?> showDeleteAccountDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text(
            "Are you sure you want to permanently delete your account? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}

/// A dialog that prompts the user to re-enter their password.
class EnterPasswordDialog {
  static Future<String?> show(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Password"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Enter your password",
              hintText: "Password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final password = controller.text.trim();
                Navigator.of(context).pop(password);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }
}
