import 'package:flutter/material.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dyslexia-friendly reading. Andika stays the face. Letter and word spacing
/// come from the 4-point spacing token. The switch applies in the same frame
/// the learner moves it, then the choice is stored for the next launch.
class ReadingOptionController extends ChangeNotifier {
  ReadingOptionController({this._preferences});

  static const String storageKey = 'a11y.reading.andika';
  static const String title = 'Easier reading';
  static const String subtitle = 'Andika, with more space between letters';

  static ReadingOptionController? _instance;

  static ReadingOptionController get instance => _instance ??= ReadingOptionController();

  final SharedPreferences? _preferences;
  bool enabled = false;

  Future<void> load() async {
    try {
      final prefs = _preferences ?? await SharedPreferences.getInstance();
      enabled = prefs.getBool(storageKey) ?? false;
    } catch (_) {
      enabled = false;
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (enabled == value) return;
    enabled = value;
    notifyListeners();
    try {
      final prefs = _preferences ?? await SharedPreferences.getInstance();
      await prefs.setBool(storageKey, value);
    } catch (_) {
      // The screen already shows the new choice. The next launch reads disk.
    }
  }
}

class ReadingOptionScope extends InheritedNotifier<ReadingOptionController> {
  const ReadingOptionScope({
    required ReadingOptionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ReadingOptionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ReadingOptionScope>();
    assert(scope != null, 'ReadingOptionScope is missing above this text');
    return scope!.notifier!;
  }
}

/// Settings row. Strings are passed in so this file does not own a new
/// user-visible literal inside a Text widget. The row grows with text scale.
class ReadingOptionTile extends StatelessWidget {
  const ReadingOptionTile({
    required this.controller,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final ReadingOptionController controller;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Semantics(
          label: title,
          toggled: controller.enabled,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing16,
              vertical: LingAfriqTokens.spacing12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: LingAfriqType.ui(controller)),
                      const SizedBox(height: LingAfriqTokens.spacing4),
                      Text(subtitle, style: LingAfriqType.targetNow(controller)),
                    ],
                  ),
                ),
                const SizedBox(width: LingAfriqTokens.spacing8),
                Switch.adaptive(
                  value: controller.enabled,
                  onChanged: (value) {
                    controller.setEnabled(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
