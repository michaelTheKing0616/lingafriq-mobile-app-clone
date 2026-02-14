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
    'removeExtraSpaces': true,
    'normalizeWhitespace': true,
    'fixCommonErrors': true,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune, color: PanAfricanColors.primary),
          SizedBox(width: PanAfricanSpacing.sm),
          Text('Customize Transcription'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Formatting',
              style: PanAfricanTypography.titleSmall(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            SwitchListTile(
              title: Text('Remove Punctuation'),
              subtitle: Text('Remove all punctuation marks'),
              value: customizations['removePunctuation'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['removePunctuation'] = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Add Line Breaks'),
              subtitle: Text('Add line breaks after sentences'),
              value: customizations['addLineBreaks'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['addLineBreaks'] = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Format Numbers'),
              subtitle: Text('Format numbers consistently'),
              value: customizations['formatNumbers'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['formatNumbers'] = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Capitalize Sentences'),
              subtitle: Text('Capitalize first letter of sentences'),
              value: customizations['capitalizeSentences'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['capitalizeSentences'] = value;
                });
              },
            ),
            Divider(),
            Text(
              'Text Cleaning',
              style: PanAfricanTypography.titleSmall(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            SwitchListTile(
              title: Text('Remove Extra Spaces'),
              subtitle: Text('Remove multiple consecutive spaces'),
              value: customizations['removeExtraSpaces'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['removeExtraSpaces'] = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Normalize Whitespace'),
              subtitle: Text('Standardize all whitespace characters'),
              value: customizations['normalizeWhitespace'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['normalizeWhitespace'] = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Fix Common Errors'),
              subtitle: Text('Auto-correct common transcription errors'),
              value: customizations['fixCommonErrors'] as bool,
              onChanged: (value) {
                setState(() {
                  customizations['fixCommonErrors'] = value;
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
        ElevatedButton.icon(
          onPressed: () {
            widget.onCustomize(customizations);
            Navigator.pop(context);
          },
          icon: Icon(Icons.check),
          label: Text('Apply'),
          style: ElevatedButton.styleFrom(
            backgroundColor: PanAfricanColors.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}

/// Enhanced Edit Lesson Dialog with full production-ready features
class EditLessonDialog extends StatefulWidget {
  final Map<String, dynamic> initialLesson;
  final Function(Map<String, dynamic>) onSave;

  const EditLessonDialog({
    Key? key,
    required this.initialLesson,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditLessonDialog> createState() => _EditLessonDialogState();
}

class _EditLessonDialogState extends State<EditLessonDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<Map<String, dynamic>> _sections;
  final Map<String, dynamic> _metadata = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialLesson['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialLesson['description'] ?? widget.initialLesson['content'] ?? '');
    _sections = List<Map<String, dynamic>>.from(widget.initialLesson['sections'] ?? []);
    _metadata.addAll(Map<String, dynamic>.from(widget.initialLesson['metadata'] ?? {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 0.9.sh),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              decoration: BoxDecoration(
                gradient: PanAfricanGradients.forest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(PanAfricanRadius.lg),
                  topRight: Radius.circular(PanAfricanRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: Theme.of(context).colorScheme.onPrimary),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Expanded(
                    child: Text(
                      'Edit Lesson',
                      style: PanAfricanTypography.titleLarge(context).copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Lesson Title',
                        hintText: 'Enter lesson title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? PanAfricanColors.surfaceContainerDark
                            : PanAfricanColors.surfaceContainerLight,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    // Description
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter lesson description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? PanAfricanColors.surfaceContainerDark
                            : PanAfricanColors.surfaceContainerLight,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                    // Sections Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sections',
                          style: PanAfricanTypography.titleMedium(context),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _addSection(context),
                          icon: Icon(Icons.add, size: 18.sp),
                          label: Text('Add Section'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PanAfricanColors.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(
                              horizontal: PanAfricanSpacing.md,
                              vertical: PanAfricanSpacing.sm,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    // Sections List
                    ..._sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      return Card(
                        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                        child: ListTile(
                          leading: Icon(_getIconForSectionType(section['type'])),
                          title: Text(section['title'] ?? section['type'] ?? 'Section ${index + 1}'),
                          subtitle: Text(
                            section['content'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: 20.sp),
                                onPressed: () => _editSection(context, index, section),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20.sp, color: PanAfricanColors.error),
                                onPressed: () {
                                  setState(() {
                                    _sections.removeAt(index);
                                  });
                                },
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    if (_sections.isEmpty)
                      Container(
                        padding: EdgeInsets.all(PanAfricanSpacing.xl),
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 48.sp, color: PanAfricanColors.neutralMedium),
                            SizedBox(height: PanAfricanSpacing.md),
                            Text(
                              'No sections yet',
                              style: PanAfricanTypography.bodyMedium(context),
                            ),
                            SizedBox(height: PanAfricanSpacing.xs),
                            Text(
                              'Add sections to organize your lesson content',
                              style: PanAfricanTypography.bodySmall(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Footer Actions
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                border: Border(
                  top: BorderSide(color: PanAfricanColors.neutralLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: PanAfricanSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onSave({
                        ...widget.initialLesson,
                        'title': _titleController.text,
                        'description': _descriptionController.text,
                        'content': _descriptionController.text,
                        'sections': _sections,
                        'metadata': _metadata,
                      });
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.save),
                    label: Text('Save Lesson'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PanAfricanColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSectionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'introduction':
      case 'intro':
        return Icons.info;
      case 'vocabulary':
      case 'vocab':
        return Icons.book;
      case 'grammar':
        return Icons.menu_book;
      case 'practice':
      case 'exercise':
        return Icons.fitness_center;
      case 'cultural':
      case 'culture':
        return Icons.public;
      case 'conversation':
      case 'dialogue':
        return Icons.chat_bubble;
      case 'quiz':
      case 'assessment':
        return Icons.quiz;
      default:
        return Icons.description;
    }
  }

  void _editSection(BuildContext context, int index, Map<String, dynamic> section) {
    final TextEditingController titleController = TextEditingController(text: section['title'] ?? '');
    final TextEditingController contentController = TextEditingController(text: section['content'] ?? '');
    final TextEditingController typeController = TextEditingController(text: section['type'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Section'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Section Title'),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              TextField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: 'Section Type',
                  hintText: 'e.g., vocabulary, grammar, practice',
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: InputDecoration(labelText: 'Section Content'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _sections[index] = {
                  ...section,
                  'title': titleController.text,
                  'type': typeController.text,
                  'content': contentController.text,
                };
              });
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addSection(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final TextEditingController typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Section'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Section Title'),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              TextField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: 'Section Type',
                  hintText: 'e.g., vocabulary, grammar, practice',
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: InputDecoration(labelText: 'Section Content'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _sections.add({
                  'title': titleController.text,
                  'type': typeController.text,
                  'content': contentController.text,
                });
              });
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

