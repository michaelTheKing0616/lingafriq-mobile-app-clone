import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lingafriq/services/quiz/diacritic_grader.dart';

/// Copy keys: keyboard.tone.high, keyboard.tone.low (P4-141).
class DiacriticKeyboardCopy {
  const DiacriticKeyboardCopy({
    this.toneHigh = 'High tone',
    this.toneLow = 'Low tone',
    this.toneMid = 'Mid tone',
    this.dotBelow = 'Dot below',
    this.kbdHint =
        'Use your device keyboard; diacritic shortcuts are not available for this language.',
    this.noLayoutLogged = 'No diacritic keyboard layout for this language.',
  });

  final String toneHigh;
  final String toneLow;
  final String toneMid;
  final String dotBelow;
  /// Copy key: `kbd.hint` (EP-§6.7).
  final String kbdHint;
  final String noLayoutLogged;

  String labelForCopyKey(String copyKey) {
    switch (copyKey) {
      case 'keyboard.tone.high':
        return toneHigh;
      case 'keyboard.tone.low':
        return toneLow;
      case 'keyboard.tone.mid':
        return toneMid;
      case 'keyboard.dot_below':
        return dotBelow;
      default:
        return copyKey;
    }
  }
}

class DiacriticKeyboardMark {
  const DiacriticKeyboardMark({
    required this.copyKey,
    required this.insert,
    required this.a11yLabel,
  });

  final String copyKey;
  final String insert;
  final String a11yLabel;
}

class DiacriticKeyboardLayout {
  const DiacriticKeyboardLayout({
    required this.letters,
    required this.marks,
  });

  final List<String> letters;
  final List<DiacriticKeyboardMark> marks;
}

class DiacriticKeyboardLayouts {
  DiacriticKeyboardLayouts(this._byLanguage);

  final Map<String, DiacriticKeyboardLayout> _byLanguage;

  static const assetPath = 'assets/data/keyboard/layouts.json';

  DiacriticKeyboardLayout? forLanguage(String languageId) =>
      _byLanguage[languageId.trim().toLowerCase()];

  static DiacriticKeyboardLayouts fromJsonString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final layouts = decoded['layouts'] as Map<String, dynamic>;
    final byLang = <String, DiacriticKeyboardLayout>{};
    for (final entry in layouts.entries) {
      final body = entry.value as Map<String, dynamic>;
      final letters = (body['letters'] as List<dynamic>).cast<String>();
      final marks = (body['marks'] as List<dynamic>)
          .map((m) {
            final map = m as Map<String, dynamic>;
            return DiacriticKeyboardMark(
              copyKey: map['copy_key'] as String,
              insert: map['insert'] as String,
              a11yLabel: map['a11y'] as String,
            );
          })
          .toList();
      byLang[entry.key] = DiacriticKeyboardLayout(letters: letters, marks: marks);
    }
    return DiacriticKeyboardLayouts(byLang);
  }

  static Future<DiacriticKeyboardLayouts> loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return fromJsonString(raw);
    } catch (error, stack) {
      developer.log(
        'LayoutMissing: $assetPath ($error)',
        name: 'DiacriticKeyboardBar',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

/// Inserts [chunk] at the selection and normalises composed tone/dot pairs to NFC.
void insertDiacriticAtSelection(TextEditingController controller, String chunk) {
  final text = controller.text;
  final selection = controller.selection;
  final start = selection.start >= 0 ? selection.start : text.length;
  final end = selection.end >= 0 ? selection.end : text.length;
  final before = text.substring(0, start);
  final after = text.substring(end);
  final merged = nfc('$before$chunk');
  controller.text = '$merged$after';
  controller.selection = TextSelection.collapsed(offset: merged.length);
}

enum DiacriticKeyboardBarState { visible, hidden, noLayout }

/// Per-language diacritic bar above the system keyboard (EP-§6.7).
class DiacriticKeyboardBar extends StatefulWidget {
  const DiacriticKeyboardBar({
    super.key,
    required this.languageId,
    required this.focusNode,
    required this.controller,
    required this.layouts,
    this.copy = const DiacriticKeyboardCopy(),
    this.onLayoutMissing,
  });

  final String languageId;
  final FocusNode focusNode;
  final TextEditingController controller;
  final DiacriticKeyboardLayouts layouts;
  final DiacriticKeyboardCopy copy;
  final void Function(String languageId)? onLayoutMissing;

  @override
  State<DiacriticKeyboardBar> createState() => _DiacriticKeyboardBarState();
}

class _DiacriticKeyboardBarState extends State<DiacriticKeyboardBar> {
  String? _loggedMissingFor;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant DiacriticKeyboardBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
    if (oldWidget.languageId != widget.languageId) {
      _loggedMissingFor = null;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  DiacriticKeyboardBarState _resolveState() {
    if (!widget.focusNode.hasFocus) return DiacriticKeyboardBarState.hidden;
    if (widget.layouts.forLanguage(widget.languageId) == null) {
      return DiacriticKeyboardBarState.noLayout;
    }
    return DiacriticKeyboardBarState.visible;
  }

  void _reportMissingLayoutOnce() {
    if (_loggedMissingFor == widget.languageId) return;
    _loggedMissingFor = widget.languageId;
    widget.onLayoutMissing?.call(widget.languageId);
    developer.log(
      'LayoutMissing: no diacritic keyboard for "${widget.languageId}"',
      name: 'DiacriticKeyboardBar',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _resolveState();
    if (state == DiacriticKeyboardBarState.noLayout) {
      _reportMissingLayoutOnce();
      final theme = Theme.of(context);
      return Semantics(
        label: widget.copy.kbdHint,
        child: Padding(
          key: const ValueKey('diacritic-bar-noLayout'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            widget.copy.kbdHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    if (state != DiacriticKeyboardBarState.visible) {
      return const SizedBox(
        key: ValueKey('diacritic-bar-hidden'),
        height: 0,
      );
    }

    final layout = widget.layouts.forLanguage(widget.languageId)!;
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest;

    return Material(
      key: const ValueKey('diacritic-bar-visible'),
      color: surface,
      elevation: 1,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final letter in layout.letters)
                _KeyButton(
                  label: letter,
                  semanticsLabel: letter,
                  onPressed: () =>
                      insertDiacriticAtSelection(widget.controller, letter),
                ),
              for (final mark in layout.marks)
                _KeyButton(
                  label: widget.copy.labelForCopyKey(mark.copyKey),
                  semanticsLabel: mark.a11yLabel,
                  onPressed: () =>
                      insertDiacriticAtSelection(widget.controller, mark.insert),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        height: 48,
        width: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: FittedBox(child: Text(label)),
        ),
      ),
    );
  }
}
