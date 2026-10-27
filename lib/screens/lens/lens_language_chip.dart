import 'package:flutter/material.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copy key: [lens.language.chip]
const String lensLanguageChipSemanticsLabel = 'Target language';

/// Resolves profile language codes for Lens (no free-text language field).
List<String> lensProfileLanguageCodes({
  ProfileModel? profile,
  SharedPreferences? prefs,
}) {
  final codes = <String>{};
  void add(String? raw) {
    final n = normalizeLensLanguageCode(raw);
    if (n != null) codes.add(n);
  }

  add(profile?.learningLanguage);
  if (prefs != null) {
    add(prefs.getString('learning_language'));
    final list = prefs.getStringList('profile_learning_languages');
    if (list != null) {
      for (final item in list) {
        add(item);
      }
    }
  }

  if (codes.isEmpty) {
    codes.add('yoruba');
  }
  final sorted = codes.toList()..sort();
  return sorted;
}

String? normalizeLensLanguageCode(String? raw) {
  final t = raw?.trim().toLowerCase();
  if (t == null || t.isEmpty) return null;
  return t;
}

String lensLanguageDisplayLabel(String code) {
  final c = normalizeLensLanguageCode(code) ?? code;
  if (c.length <= 3) return c.toUpperCase();
  return c[0].toUpperCase() + c.substring(1);
}

class LensLanguageChip extends StatelessWidget {
  const LensLanguageChip({
    super.key,
    required this.selectedCode,
    required this.profileCodes,
    required this.onSelected,
  });

  final String selectedCode;
  final List<String> profileCodes;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final codes = profileCodes.isEmpty
        ? [normalizeLensLanguageCode(selectedCode) ?? 'yoruba']
        : profileCodes;

    return Semantics(
      label: lensLanguageChipSemanticsLabel,
      button: true,
      child: ActionChip(
        label: Text(lensLanguageDisplayLabel(selectedCode)),
        avatar: const Icon(Icons.translate, size: 18),
        onPressed: codes.length <= 1
            ? null
            : () async {
                final picked = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final code in codes)
                            ListTile(
                              title: Text(lensLanguageDisplayLabel(code)),
                              selected: code == selectedCode,
                              onTap: () => Navigator.pop(ctx, code),
                            ),
                        ],
                      ),
                    );
                  },
                );
                if (picked != null && picked != selectedCode) {
                  onSelected(picked);
                }
              },
      ),
    );
  }
}
