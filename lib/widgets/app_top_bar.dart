import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/screens/lens/see_it_in_the_wild.dart';

/// Top bar with a Lens entry action on every main tab (P7-915 AC1).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = false,
    this.language = 'yoruba',
    this.lensPreflight,
  });

  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final String language;
  final LensAvailability? lensPreflight;

  static List<Widget> lensActions({
    required BuildContext context,
    required String language,
    LensAvailability? preflight,
  }) {
    return [
      LensTopBarButton(language: language, preflight: preflight),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final merged = <Widget>[
      ...?actions,
      LensTopBarButton(language: language, preflight: lensPreflight),
    ];
    return AppBar(
      title: title != null ? Text(title!) : null,
      automaticallyImplyLeading: showBackButton,
      actions: merged,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class LensTopBarButton extends StatelessWidget {
  const LensTopBarButton({
    super.key,
    required this.language,
    this.preflight,
  });

  final String language;
  final LensAvailability? preflight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: kLensEntryLabel,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: kLensEntryLabel,
          icon: const Icon(Icons.center_focus_strong_outlined),
          onPressed: () {
            HapticFeedback.lightImpact();
            openLensEntry(
              context,
              intent: LensEntryIntent(language: language),
              preflight: preflight,
            );
          },
        ),
      ),
    );
  }
}
