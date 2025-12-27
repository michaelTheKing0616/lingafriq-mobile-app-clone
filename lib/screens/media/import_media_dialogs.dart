import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Edit Transcription Dialog
class EditTranscriptionDialog extends StatefulWidget {
  final String initialText;
  final Function(String) onSave;

  const EditTranscriptionDialog({
    Key? key,
    required this.initialText,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditTranscriptionDialog> createState() => _EditTranscriptionDialogState();
}

class _EditTranscriptionDialogState extends State<EditTranscriptionDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text('Edit Transcription'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          maxLines: 10,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            ),
            filled: true,
            fillColor: isDark
                ? PanAfricanColors.surfaceContainerDark
                : PanAfricanColors.surfaceContainerLight,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.pop(context);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

/// Customize Transcription Dialog
class CustomizeTranscriptionDialog extends StatefulWidget {
  final String transcription;
  final Function(Map<String, dynamic>) onCustomize;

  const CustomizeTranscriptionDialog({
    Key? key,
    required this.transcription,
    required this.onCustomize,
  }) : super(key: key);

  @override
  State<CustomizeTranscriptionDialog> createState() => _CustomizeTranscriptionDialogState();
}

class _CustomizeTranscriptionDialogState extends State<CustomizeTranscriptionDialog> {
  final Map<String, dynamic> customizations = {
    'removePunctuation': false,
    'addLineBreaks': false,
    'formatNumbers': false,
    'capitalizeSentences': false,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text('Customize Transcription'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Remove Punctuation'),
              value: customizations['removePunctuation'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['removePunctuation'] = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Add Line Breaks'),
              value: customizations['addLineBreaks'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['addLineBreaks'] = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Format Numbers'),
              value: customizations['formatNumbers'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['formatNumbers'] = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Capitalize Sentences'),
              value: customizations['capitalizeSentences'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['capitalizeSentences'] = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCustomize(customizations);
            Navigator.pop(context);
          },
          child: Text('Apply'),
        ),
      ],
    );
  }
}

