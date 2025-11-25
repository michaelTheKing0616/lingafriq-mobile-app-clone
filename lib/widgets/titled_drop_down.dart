import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';

class TitledDropDown<T> extends StatelessWidget {
  final String title;
  final String? hint;
  final ValueChanged<T?>? onChanged;
  final List<String> titles;
  final List<T> items;
  final T? value;
  const TitledDropDown({
    Key? key,
    required this.title,
    this.hint,
    this.onChanged,
    required this.titles,
    required this.items,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title.text.medium.size(16.sp).color(context.adaptive).make().pOnly(left: 12),
        8.heightBox,
        DropdownButtonFormField<T>(
          value: value,
          dropdownColor: context.cardColor,
          menuMaxHeight: 0.6.sh,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            fillColor: context.cardColor,
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          hint: Text(
            hint ?? "Select $title",
            style: TextStyle(color: context.adaptive54),
          ),
          items: items.asMap().entries.map((e) {
            final key = e.key;
            final title = titles[key];
            return DropdownMenuItem(
              value: e.value,
              child: Text(title),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: true,
          // underline: Container(),
          validator: (value) => Validators.emptyValidator((value ?? "") as String),
        ),
      ],
    );
  }
}
