// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kinyarwanda (`rw`).
class AppLocalizationsRw extends AppLocalizations {
  AppLocalizationsRw([String locale = 'rw']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Murakaza neza kuri LingAfriq';

  @override
  String get continueButton => 'Komeza';

  @override
  String get startLearning => 'Tangira Kwiga';

  @override
  String get loading => 'Birenga...';

  @override
  String get errorOccurred => 'Ikosa ryabaye';

  @override
  String get tryAgain => 'Gerageza Nanone';

  @override
  String get home => 'Murugo';

  @override
  String get learn => 'Jya';

  @override
  String get games => 'Imikino';

  @override
  String get profile => 'Inyandiko';

  @override
  String get settings => 'Gucunga';

  @override
  String get language => 'Ururimi';

  @override
  String get selectLanguage => 'Hitamo Ururimi';

  @override
  String get lessons => 'Ibiganiro';

  @override
  String get quizzes => 'Ibibazo';

  @override
  String get takeQuiz => 'Gira Ibibazo';

  @override
  String get takeLesson => 'Gira Ibiganiro';

  @override
  String get dailyStreak => 'Kugeza Buri Munsi';

  @override
  String daysStreak(int count) {
    return 'Iminsi $count';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Urwego';

  @override
  String get beginner => 'Gutangira';

  @override
  String get intermediate => 'Hagati';

  @override
  String get advanced => 'Hejuru';

  @override
  String get correct => 'Byemewe!';

  @override
  String get incorrect => 'Ntibyemewe';

  @override
  String get next => 'Ikurikira';

  @override
  String get back => 'Inyuma';

  @override
  String get skip => 'Simbuka';

  @override
  String get cancel => 'Kureka';

  @override
  String get save => 'Bika';

  @override
  String get done => 'Byarangiye';

  @override
  String get submit => 'Ohereza';

  @override
  String get logout => 'Sohoka';

  @override
  String get login => 'Injira';

  @override
  String get signup => 'Kwiyandikisha';

  @override
  String get email => 'Email';

  @override
  String get password => 'Ijambo ry\'ibanga';

  @override
  String get forgotPassword => 'Wibagiwe Ijambo ry\'ibanga?';

  @override
  String get noAccount => 'Ntugira Account?';

  @override
  String get haveAccount => 'Ufite Account?';

  @override
  String get congratulations => 'Twishimiye!';

  @override
  String get lessonComplete => 'Ibiganiro Byarangiye!';

  @override
  String get quizComplete => 'Ibibazo Byarangiye!';

  @override
  String get accuracy => 'Ukuri';

  @override
  String get score => 'Inyandiko';

  @override
  String get aiTutor => 'Umwarimu wa AI';

  @override
  String get cultureMagazine => 'Magazine y\'Ubwoba';

  @override
  String get tribes => 'Abantu';

  @override
  String get leaderboard => 'Inyandiko y\'Abayobozi';

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
