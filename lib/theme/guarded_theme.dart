import 'package:flutter/material.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Brand navy from the guarded-screen reference packs
/// (docs/design/references/*/REFERENCE.md, "Type & colour"): primary actions
/// and the selected state use navy; Deny/Stop stay outlined.
const Color kBrandNavy = LingAfriqTokens.navy;
const Color kBrandNavyContainer = LingAfriqTokens.roleLightSurfaceContainer;
const Color kBrandOnNavyContainer = LingAfriqTokens.roleLightOnSurface;

/// Headlines on guarded screens grow with the user's text size up to 160%,
/// so a 200% Arabic title at 320dp still fits; body text is not capped.
const double kGuardedHeadlineMaxScale = 1.6;

/// The guarded screens' theme: the app theme with navy primary tokens and
/// readable disabled switches (track outline and thumb stay visible).
ThemeData guardedTheme(ThemeData base) {
  final cs = base.colorScheme;
  final dark = cs.brightness == Brightness.dark;
  final scheme = cs.copyWith(
    primary: dark ? LingAfriqTokens.roleDarkAccent : kBrandNavy,
    onPrimary: dark ? LingAfriqTokens.roleDarkOnAccent : LingAfriqTokens.onNavy,
    primaryContainer: dark
        ? LingAfriqTokens.roleDarkSurfaceContainer
        : kBrandNavyContainer,
    onPrimaryContainer: dark
        ? LingAfriqTokens.roleDarkOnSurface
        : kBrandOnNavyContainer,
  );
  return base.copyWith(
    colorScheme: scheme,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) {
          return s.contains(WidgetState.selected)
              ? scheme.surface
              : scheme.onSurfaceVariant;
        }
        return s.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) {
          return s.contains(WidgetState.selected)
              ? scheme.onSurfaceVariant
              : scheme.surfaceContainerHighest;
        }
        return s.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.transparent
            : scheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Wraps a guarded screen so its primary actions use brand navy.
class GuardedTheme extends StatelessWidget {
  const GuardedTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme(data: guardedTheme(Theme.of(context)), child: child);
}

/// A headline whose text scale is capped at [kGuardedHeadlineMaxScale].
class GuardedHeadline extends StatelessWidget {
  const GuardedHeadline(this.text, {super.key, required this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: kGuardedHeadlineMaxScale,
    child: Semantics(header: true, child: Text(text, style: style)),
  );
}

/// Formats [t] as HH:mm in West Africa Time (UTC+1), e.g. "10:42 WAT".
String watTime(DateTime t) {
  final w = t.toUtc().add(const Duration(hours: 1));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(w.hour)}:${two(w.minute)} WAT';
}
