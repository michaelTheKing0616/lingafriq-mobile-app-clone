import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_button.dart';

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({Key? key}) : super(key: key);

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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(Icons.close, color: AppColors.red, size: 0.2.sw),
          ),
          "Are you sure you want to DELETE account?"
              .text
              .center
              .xl2
              .white
              .make()
              .pSymmetric(h: 0.15.sw, v: 24),
          PrimaryButton(
            width: 0.5.sw,
            text: "No",
            color: AppColors.red,
            onTap: () {
              Navigator.of(context).pop(false);
            },
          ),
          16.heightBox,
          PrimaryButton(
            width: 0.5.sw,
            text: "Yes",
            isOutline: true,
            textColor: Colors.white,
            onTap: () {
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
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => const DeleteAccountDialog(),
    );
  }
}

class EnterPasswordDialog extends HookConsumerWidget {
  const EnterPasswordDialog({Key? key}) : super(key: key);

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
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => const EnterPasswordDialog(),
    );
  }
}
