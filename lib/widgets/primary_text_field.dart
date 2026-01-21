import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

class PrimaryTextField extends StatelessWidget {
  const PrimaryTextField({
    Key? key,
    required this.controller,
    required this.title,
    this.validator,
    this.obscureText = false,
    this.focusNode,
    this.nextNode,
    this.onSubmitAction,
    this.keyboardType,
    this.disabled = false,
    this.initialText,
    this.helperText,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
    this.textInputAction,
    this.minLines,
    this.maxLines,
    this.border,
  }) : super(key: key);
  final TextEditingController controller;
  final String title;
  final String? Function(String?)? validator;
  final bool obscureText;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final VoidCallback? onSubmitAction;
  final TextInputType? keyboardType;
  final bool disabled;
  final String? initialText;
  final String? helperText;
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;
  final InputBorder? border;

  @override
  Widget build(BuildContext context) {
    final currentBorder = border ??
        OutlineInputBorder(
          borderSide: const BorderSide(width: 0, color: Colors.transparent),
          borderRadius: BorderRadius.circular(24),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title.text.medium.size(16.sp).color(context.adaptive).make().pOnly(left: 12),
        8.heightBox,
        IgnorePointer(
          ignoring: disabled,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
            child: TextFormField(
              minLines: minLines,
              maxLines: maxLines,
              initialValue: initialText,
              keyboardType: keyboardType,
              focusNode: focusNode,
              obscureText: obscureText,
              controller: controller,
              validator: validator,
              onFieldSubmitted: (_) {
                if (nextNode != null) {
                  FocusScope.of(context).requestFocus(nextNode);
                }
                if (onSubmitAction != null) {
                  onSubmitAction!();
                }
              },
              textAlignVertical: TextAlignVertical.center,
              textInputAction: textInputAction ??
                  (nextNode == null ? TextInputAction.done : TextInputAction.next),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: (maxLines ?? 1) > 1 ? 16 : 0,
                ),
                errorMaxLines: 3,
                fillColor: context.theme.cardColor,
                filled: true,
                border: currentBorder,
                enabledBorder: currentBorder,
                focusedBorder: currentBorder,
                hintText: hintText,
                errorStyle: TextStyle(color: Colors.redAccent.shade400),
                helperText: helperText,
                suffixIcon: suffixIcon,
                prefixIcon: prefixIcon,
                prefixIconColor: AppColors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
