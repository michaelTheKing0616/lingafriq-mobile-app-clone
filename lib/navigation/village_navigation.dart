import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Route name segments (used with [Navigator.pushNamed] and `/` prefix).
abstract final class VillageRouteNames {
  static const hub = 'villages-hub';
  static const languageVillage = 'language-village';
  static const swahiliMap = 'swahili-village-map';
  static const market = 'village-market';
  static const cafe = 'village-cafe';
  static const elderHut = 'elder-hut';
  static const practiceRoomSetup = 'practice-room-setup';
  static const practiceSession = 'practice-session';
  static const practiceCollaborative = 'practice-room-collaborative';
  static const sessionSummary = 'session-summary';
  static const flashcardFocus = 'flashcard-focus';
  static const matchingPairs = 'matching-pairs';
  static const tonalLesson = 'tonal-lesson';
  static const tribeHub = 'tribe-hub';
  static const tribeDiscovery = 'tribe-discovery';
  static const myTribe = 'my-tribe';
  static const tribalDuel = 'tribal-duel';
  static const interTribeLeaderboard = 'inter-tribe-leaderboard';
  static const languageVillagePlace = 'language-village-place';
  static const polieModeSelection = 'polie_mode_selection';
  static const conversationScenarios = 'conversation-scenarios';
}

String _normalizeRouteName(String? routeName) {
  if (routeName == null || routeName.isEmpty) return '';
  return routeName.startsWith('/') ? routeName.substring(1) : routeName;
}

/// Central navigation for village map nodes, hubs, and tribe surfaces.
abstract final class VillageNavigation {
  static String isoCodeForLanguageLabel(String label) {
    final key = label.trim().toLowerCase();
    const map = <String, String>{
      'swahili': 'sw',
      'yoruba': 'yo',
      'wolof': 'wo',
      'amharic': 'am',
      'zulu': 'zu',
      'igbo': 'ig',
      'hausa': 'ha',
      'twi': 'tw',
      'lingala': 'ln',
      'shona': 'sn',
      'somali': 'so',
      'nigerian pidgin': 'pcm',
      'pidgin': 'pcm',
      'afrikaans': 'af',
      'xhosa': 'xh',
      'spanish': 'es',
      'french': 'fr',
      'portuguese': 'pt',
      'arabic': 'ar',
    };
    if (map.containsKey(key)) return map[key]!;
    if (key.length >= 2) return key.substring(0, 2);
    return 'en';
  }

  static void pushHub(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushNamed('/${VillageRouteNames.hub}');
  }

  static void pushLanguageVillage(
    BuildContext context, {
    required String languageDisplayName,
    String? languageCode,
  }) {
    HapticFeedback.mediumImpact();
    final code =
        languageCode ?? isoCodeForLanguageLabel(languageDisplayName);
    Navigator.of(context).pushNamed(
      '/${VillageRouteNames.languageVillage}',
      arguments: <String, dynamic>{
        'languageDisplayName': languageDisplayName,
        'languageCode': code,
      },
    );
  }

  static void pushSwahiliCorridorMap(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed('/${VillageRouteNames.swahiliMap}');
  }

  static void pushTribeHub(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed('/${VillageRouteNames.tribeHub}');
  }

  /// [placeName] matches the English labels on the language-village map.
  static void enterLanguageVillagePlace(
    BuildContext context, {
    required String placeName,
    String? languageDisplayName,
    String? languageCode,
  }) {
    HapticFeedback.mediumImpact();
    final nav = Navigator.of(context);
    switch (placeName) {
      case 'Griot Stage':
        nav.pushNamed(
          '/${VillageRouteNames.languageVillagePlace}',
          arguments: <String, dynamic>{
            'placeName': placeName,
            'languageDisplayName': languageDisplayName,
            'languageCode': languageCode,
          },
        );
        return;
      case 'The Market':
        nav.pushNamed(
          '/${VillageRouteNames.languageVillagePlace}',
          arguments: <String, dynamic>{
            'placeName': placeName,
            'languageDisplayName': languageDisplayName,
            'languageCode': languageCode,
          },
        );
        return;
      case 'Sun Café':
        nav.pushNamed(
          '/${VillageRouteNames.languageVillagePlace}',
          arguments: <String, dynamic>{
            'placeName': placeName,
            'languageDisplayName': languageDisplayName,
            'languageCode': languageCode,
          },
        );
        return;
      case "Elder's Hut":
        nav.pushNamed(
          '/${VillageRouteNames.languageVillagePlace}',
          arguments: <String, dynamic>{
            'placeName': placeName,
            'languageDisplayName': languageDisplayName,
            'languageCode': languageCode,
          },
        );
        return;
      case 'The School':
        nav.pushNamed(
          '/${VillageRouteNames.languageVillagePlace}',
          arguments: <String, dynamic>{
            'placeName': placeName,
            'languageDisplayName': languageDisplayName,
            'languageCode': languageCode,
          },
        );
        return;
      default:
        nav.pushNamed('/${VillageRouteNames.conversationScenarios}');
    }
  }

  /// [englishLabel] matches [SwahiliVillageMapScreen] building titles.
  static void enterSwahiliMapBuilding(
    BuildContext context, {
    required String englishLabel,
  }) {
    HapticFeedback.mediumImpact();
    final nav = Navigator.of(context);
    switch (englishLabel) {
      case "Elder's Hut":
        nav.pushNamed('/${VillageRouteNames.elderHut}');
        return;
      case 'School':
        nav.pushNamed('/${VillageRouteNames.practiceRoomSetup}');
        return;
      case 'Market':
        nav.pushNamed('/${VillageRouteNames.market}');
        return;
      case 'Café':
        nav.pushNamed('/${VillageRouteNames.cafe}');
        return;
      case 'Griot Stage':
        nav.pushNamed('/${VillageRouteNames.polieModeSelection}');
        return;
      default:
        nav.pushNamed('/${VillageRouteNames.conversationScenarios}');
    }
  }

  /// Pops the practice stack until the villages hub (or legacy `villages` route)
  /// is on top; if neither appears, stops at the root route so the stack is
  /// never emptied.
  static void finishPracticeFlowToHub(BuildContext context) {
    HapticFeedback.heavyImpact();
    Navigator.of(context).popUntil((route) {
      if (route.isFirst) return true;
      final name = _normalizeRouteName(route.settings.name);
      return name == VillageRouteNames.hub || name == 'villages';
    });
  }
}
