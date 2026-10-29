import 'package:flutter/widgets.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// [AppLocalizations] for [context], falling back to English when the
/// widget is hosted without the app's localisation delegates (embeds, tests).
AppLocalizations l10nOf(BuildContext context) =>
    AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('en'));
