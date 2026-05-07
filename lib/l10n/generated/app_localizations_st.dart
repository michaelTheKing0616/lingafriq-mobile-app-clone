// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Southern Sotho (`st`).
class AppLocalizationsSt extends AppLocalizations {
  AppLocalizationsSt([String locale = 'st']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Rea amohela LingAfriq';

  @override
  String get continueButton => 'Tsoela pele';

  @override
  String get startLearning => 'Qala ho Ithuta';

  @override
  String get loading => 'Ho kenya...';

  @override
  String get errorOccurred => 'Phoso e etsahetse';

  @override
  String get tryAgain => 'Leka hape';

  @override
  String get home => 'Lehae';

  @override
  String get learn => 'Ithuta';

  @override
  String get games => 'Lipapali';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Litlhophiso';

  @override
  String get language => 'Puo';

  @override
  String get selectLanguage => 'Khetha Puo';

  @override
  String get lessons => 'Lithuto';

  @override
  String get quizzes => 'Lipotso';

  @override
  String get takeQuiz => 'Nka Lipotso';

  @override
  String get takeLesson => 'Nka Lithuto';

  @override
  String get dailyStreak => 'Letsatsi ka Letsatsi';

  @override
  String daysStreak(int count) {
    return 'Matsatsi $count';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Sebaka';

  @override
  String get beginner => 'Qalo';

  @override
  String get intermediate => 'Bohareng';

  @override
  String get advanced => 'E Phahameng';

  @override
  String get correct => 'Nete!';

  @override
  String get incorrect => 'Ha e ne';

  @override
  String get next => 'E latelang';

  @override
  String get back => 'Morao';

  @override
  String get skip => 'Skippa';

  @override
  String get cancel => 'Hlakola';

  @override
  String get save => 'Boloka';

  @override
  String get done => 'E felile';

  @override
  String get submit => 'Romella';

  @override
  String get logout => 'Tsoa';

  @override
  String get login => 'Kena';

  @override
  String get signup => 'Ingodisa';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'U lebetse Password?';

  @override
  String get noAccount => 'Ha u na Account?';

  @override
  String get haveAccount => 'U na le Account?';

  @override
  String get congratulations => 'Rea u lebohela!';

  @override
  String get lessonComplete => 'Lithuto Li Felile!';

  @override
  String get quizComplete => 'Lipotso Li Felile!';

  @override
  String get accuracy => 'Nnete';

  @override
  String get score => 'Lintlha';

  @override
  String get aiTutor => 'Moruti wa AI';

  @override
  String get cultureMagazine => 'Magazine ya Setso';

  @override
  String get tribes => 'Metse';

  @override
  String get leaderboard => 'Tafole ya Balebeli';

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
