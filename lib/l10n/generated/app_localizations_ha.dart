// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppLocalizationsHa extends AppLocalizations {
  AppLocalizationsHa([String locale = 'ha']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Barka da zuwa LingAfriq';

  @override
  String get continueButton => 'Ci gaba';

  @override
  String get startLearning => 'Fara Koyo';

  @override
  String get loading => 'Ana lodawa...';

  @override
  String get errorOccurred => 'Kuskure ya faru';

  @override
  String get tryAgain => 'Sake Gwadawa';

  @override
  String get home => 'Gida';

  @override
  String get learn => 'Koyo';

  @override
  String get games => 'Wasanni';

  @override
  String get profile => 'Bayani';

  @override
  String get settings => 'Saituna';

  @override
  String get language => 'Harshe';

  @override
  String get selectLanguage => 'Zaɓi Harshe';

  @override
  String get lessons => 'Darussa';

  @override
  String get quizzes => 'Gwaje-gwaje';

  @override
  String get takeQuiz => 'Yi Gwaji';

  @override
  String get takeLesson => 'Yi Darasi';

  @override
  String get dailyStreak => 'Jerin Kullum';

  @override
  String daysStreak(int count) {
    return 'Ranaku $count';
  }

  @override
  String xpEarned(int count) {
    return 'XP $count';
  }

  @override
  String get level => 'Matsayi';

  @override
  String get beginner => 'Farko';

  @override
  String get intermediate => 'Tsakiya';

  @override
  String get advanced => 'Babba';

  @override
  String get correct => 'Daidai!';

  @override
  String get incorrect => 'Kuskure';

  @override
  String get next => 'Na gaba';

  @override
  String get back => 'Koma';

  @override
  String get skip => 'Tsallake';

  @override
  String get cancel => 'Soke';

  @override
  String get save => 'Ajiye';

  @override
  String get done => 'An gama';

  @override
  String get submit => 'Aika';

  @override
  String get logout => 'Fita';

  @override
  String get login => 'Shiga';

  @override
  String get signup => 'Yi rajista';

  @override
  String get email => 'Imel';

  @override
  String get password => 'Kalmar sirri';

  @override
  String get forgotPassword => 'An manta Kalmar Sirri?';

  @override
  String get noAccount => 'Ba ka da asusu?';

  @override
  String get haveAccount => 'Ka riga ka sami asusu?';

  @override
  String get congratulations => 'Taya murna!';

  @override
  String get lessonComplete => 'An Kammala Darasi!';

  @override
  String get quizComplete => 'An Kammala Gwaji!';

  @override
  String get accuracy => 'Daidaito';

  @override
  String get score => 'Maki';

  @override
  String get aiTutor => 'Malamin AI';

  @override
  String get cultureMagazine => 'Mujallar Al\'ada';

  @override
  String get tribes => 'Kabilu';

  @override
  String get leaderboard => 'Jadawali na Jagora';

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
  String get gameWordMatchConnectMeaningTitle => 'Connect the Meaning';

  @override
  String get gameWordMatchConnectMeaningSubtitle =>
      'Tap a word to hear its voice, then match it to its anchor.';

  @override
  String get gameWordMatchEnglishLabel => 'English';
}
