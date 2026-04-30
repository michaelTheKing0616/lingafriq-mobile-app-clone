import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// `Navigator` arguments for passport named routes (`passport-proctored`, `passport-credential`).
final class PassportRouteArgs {
  PassportRouteArgs._();

  static const String defaultLanguage = 'yoruba';
  static const String defaultProctorMode = 'device_rules';

  static ({String language, String proctorMode}) parseProctored(Object? arguments) {
    if (arguments is! Map) {
      return (language: defaultLanguage, proctorMode: defaultProctorMode);
    }
    final map = Map<String, dynamic>.from(arguments);
    final lang = map['language']?.toString().trim();
    final mode = map['proctorMode']?.toString().trim();
    return (
      language: (lang == null || lang.isEmpty) ? defaultLanguage : lang,
      proctorMode: (mode == null || mode.isEmpty) ? defaultProctorMode : mode,
    );
  }

  /// Returns null when `verifyToken` is missing or blank — caller shows [missingCredentialScaffold].
  static ({String verifyToken, String level, int score})? parseCredential(Object? arguments) {
    if (arguments is! Map) return null;
    final map = Map<String, dynamic>.from(arguments);
    final token = map['verifyToken']?.toString().trim() ?? '';
    if (token.isEmpty) return null;
    final level = map['level']?.toString() ?? 'L1';
    final scoreRaw = map['score'];
    final score = scoreRaw is int ? scoreRaw : int.tryParse(scoreRaw?.toString() ?? '') ?? 0;
    return (verifyToken: token, level: level, score: score);
  }

  static Widget missingCredentialScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.errorOccurred)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Missing verifyToken.\n\n'
              'Use: Navigator.pushNamed(context, "/passport-credential", '
              'arguments: {"verifyToken": "<token>", "level": "L2", "score": 88});',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
