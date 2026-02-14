import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 0.3.sw,
            height: 0.3.sw,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Icon(Icons.close, color: PanAfricanColors.error, size: 0.2.sw),
          ),
          "Are you sure you want to DELETE account?"
              .text
              .center
              .xl2
              .white
              .make()
              .pSymmetric(h: 0.15.sw, v: 24),
          PanAfricanButton(
            width: 0.5.sw,
            label: "No",
            isOutlined: true,
            backgroundColor: PanAfricanColors.primary,
            foregroundColor: PanAfricanColors.primary,
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          16.heightBox,
          PanAfricanButton(
            width: 0.5.sw,
            label: "Yes",
            backgroundColor: PanAfricanColors.error,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  static Future showDeleteAccountDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withOpacity(0.85),
      builder: (context) => const DeleteAccountDialog(),
    );
  }
}

class EnterPasswordDialog extends HookConsumerWidget {
  const EnterPasswordDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    return Material(
      color: Colors.transparent,
      child: CupertinoAlertDialog(
        title: const Text('Confirmation'),
        content: CupertinoTextField(
          controller: controller,
          placeholder: 'Enter Current Password',
          obscureText: true,
        ).pOnly(top: 24),
        actions: <Widget>[
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Delete Now'),
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    );
  }

  static Future show(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withOpacity(0.85),
      builder: (context) => const EnterPasswordDialog(),
    );
  }
}
