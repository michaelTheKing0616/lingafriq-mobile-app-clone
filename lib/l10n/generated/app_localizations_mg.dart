// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malagasy (`mg`).
class AppLocalizationsMg extends AppLocalizations {
  AppLocalizationsMg([String locale = 'mg']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Tongasoa eto amin\'ny LingAfriq';

  @override
  String get continueButton => 'Manohy';

  @override
  String get startLearning => 'Manomboka Mianatra';

  @override
  String get loading => 'Mampiditra...';

  @override
  String get errorOccurred => 'Nisy olana nitranga';

  @override
  String get tryAgain => 'Andramo Indray';

  @override
  String get home => 'Trano';

  @override
  String get learn => 'Mianatra';

  @override
  String get games => 'Lalao';

  @override
  String get profile => 'Tantara';

  @override
  String get settings => 'Fifanarahana';

  @override
  String get language => 'Fiteny';

  @override
  String get selectLanguage => 'Mifidy Fiteny';

  @override
  String get lessons => 'Lesona';

  @override
  String get quizzes => 'Fanontaniana';

  @override
  String get takeQuiz => 'Maka Fanontaniana';

  @override
  String get takeLesson => 'Maka Lesona';

  @override
  String get dailyStreak => 'Andro isan\'andro';

  @override
  String daysStreak(int count) {
    return 'Andro $count';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Ambaratonga';

  @override
  String get beginner => 'Mpitomboka';

  @override
  String get intermediate => 'Antony';

  @override
  String get advanced => 'Ambony';

  @override
  String get correct => 'Marina!';

  @override
  String get incorrect => 'Tsy marina';

  @override
  String get next => 'Manaraka';

  @override
  String get back => 'Miverina';

  @override
  String get skip => 'Mandalo';

  @override
  String get cancel => 'Avelao';

  @override
  String get save => 'Tahiry';

  @override
  String get done => 'Vita';

  @override
  String get submit => 'Alefa';

  @override
  String get logout => 'Mivoaka';

  @override
  String get login => 'Miditra';

  @override
  String get signup => 'Misoratra anarana';

  @override
  String get email => 'Email';

  @override
  String get password => 'Tenimiafina';

  @override
  String get forgotPassword => 'Hadino ny Tenimiafina?';

  @override
  String get noAccount => 'Tsy manana Account?';

  @override
  String get haveAccount => 'Manana Account?';

  @override
  String get congratulations => 'Arahabaina!';

  @override
  String get lessonComplete => 'Lesona Vita!';

  @override
  String get quizComplete => 'Fanontaniana Vita!';

  @override
  String get accuracy => 'Marina';

  @override
  String get score => 'Isan\'ny';

  @override
  String get aiTutor => 'Mpampianatra AI';

  @override
  String get cultureMagazine => 'Gazety Kolontsaina';

  @override
  String get tribes => 'Foko';

  @override
  String get leaderboard => 'Tabilao Mpitondra';

  @override
  String get flbHeritageTitle => 'FLB Heritage';

  @override
  String get flbHeritageSearchHint => 'Search title, country, or tags';

  @override
  String get flbHeritageEmptyMessage =>
      'No entries match your search. Try another keyword or pull to refresh.';

  @override
  String get flbHeritageLoadError =>
      'Could not load heritage archive. Pull to retry.';

  @override
  String get flbHeritageRefresh => 'Refresh';

  @override
  String get flbHeritageDetailTitle => 'Heritage';

  @override
  String get flbHeritageMissingContent => 'Missing heritage content';

  @override
  String get tooltipFlbHeritageArchive => 'FLB Heritage archive';

  @override
  String get tooltipTribeDiscovery => 'Tribe discovery';

  @override
  String get drawerFlbHeritageArchive => 'FLB Heritage Archive';

  @override
  String get tooltipTribes => 'Tribes';

  @override
  String get magazineKeyTakeaways => 'Key takeaways';

  @override
  String get magazineRelatedTopics => 'Related topics';

  @override
  String get magazineSourceAndLicense => 'Source & license';

  @override
  String magazineReadingTime(int minutes) {
    return '$minutes min read';
  }

  @override
  String get gameTutorialGotIt => 'Got it';

  @override
  String get gameTutorialHowToPlay => 'How to play';

  @override
  String chatPeerTyping(String name) {
    return '$name is typing…';
  }

  @override
  String get polieTranslationSourceLabel => 'From';

  @override
  String get polieTranslationTargetLabel => 'To';

  @override
  String get polieConversationIncludeEnglishTranslations =>
      'English translations';

  @override
  String get polieTutorSavedCards => 'Saved cards';

  @override
  String get polieTutorSaveCard => 'Save';

  @override
  String get polieTutorRemoveSavedCard => 'Remove';

  @override
  String get polieTutorNoSavedCardsYet => 'No saved cards yet.';

  @override
  String get liveTranslateTitle => 'Live translate';

  @override
  String get liveTranslateEndSession => 'End session';

  @override
  String liveTranslateStatus(Object status) {
    return 'Status: $status';
  }

  @override
  String get liveTranslateSource => 'Source';

  @override
  String get liveTranslateTranslation => 'Translation';

  @override
  String get liveTranslateSourceLanguageLabel =>
      'Source language (e.g. english)';

  @override
  String get liveTranslateTargetLanguageLabel =>
      'Target language (e.g. yoruba)';

  @override
  String get liveTranslateStartSession => 'Start session';

  @override
  String get liveTranslateStarting => 'Starting…';

  @override
  String get liveTranslateReconnect => 'Reconnect';

  @override
  String get liveTranslateListen => 'Listen';

  @override
  String get liveTranslateStopListening => 'Stop listening';

  @override
  String get liveTranslateInterruptBargeIn => 'Interrupt / barge-in';

  @override
  String get liveTranslatePlaceholderDash => '—';

  @override
  String get liveTranslateSpeechUnavailable =>
      'Speech recognition not available on this device.';

  @override
  String get liveTranslateMicPermissionRequired =>
      'Microphone permission is required.';

  @override
  String get liveTranslateInvalidSession => 'Invalid session from server.';

  @override
  String get liveTranslateStartSessionFirst => 'Start a session first.';

  @override
  String get liveTranslateConnectionLost =>
      'Connection lost. Tap Reconnect to continue.';

  @override
  String liveTranslateSocketError(Object error) {
    return 'Socket error: $error';
  }

  @override
  String get liveTranslateSessionFailed => 'Session failed';

  @override
  String liveTranslateCouldNotPlayAudio(Object error) {
    return 'Could not play translation audio: $error';
  }

  @override
  String get liveTranslateSessionError => 'Session error';

  @override
  String get liveTranslateDefaultAudioMime => 'audio/wav';

  @override
  String get gameWordMatchConnectMeaningTitle => 'Connect the Meaning';

  @override
  String get gameWordMatchConnectMeaningSubtitle =>
      'Tap a word to hear its voice, then match it to its anchor.';

  @override
  String get gameWordMatchEnglishLabel => 'English';
}
