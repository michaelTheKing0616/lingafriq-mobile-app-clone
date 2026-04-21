// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lingala (`ln`).
class AppLocalizationsLn extends AppLocalizations {
  AppLocalizationsLn([String locale = 'ln']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Boyei na LingAfriq';

  @override
  String get continueButton => 'Landela';

  @override
  String get startLearning => 'Yamba Koyekola';

  @override
  String get loading => 'Ezalaka...';

  @override
  String get errorOccurred => 'Likambo lisali';

  @override
  String get tryAgain => 'Zongela';

  @override
  String get home => 'Ndako';

  @override
  String get learn => 'Yekola';

  @override
  String get games => 'Miziki';

  @override
  String get profile => 'Lisolo';

  @override
  String get settings => 'Bisalisi';

  @override
  String get language => 'Lokota';

  @override
  String get selectLanguage => 'Pona Lokota';

  @override
  String get lessons => 'Malongi';

  @override
  String get quizzes => 'Mituna';

  @override
  String get takeQuiz => 'Zwa Mituna';

  @override
  String get takeLesson => 'Zwa Malongi';

  @override
  String get dailyStreak => 'Mokolo na Mokolo';

  @override
  String daysStreak(int count) {
    return 'Mikolo $count';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Ntina';

  @override
  String get beginner => 'Ebandi';

  @override
  String get intermediate => 'Kati';

  @override
  String get advanced => 'Likolo';

  @override
  String get correct => 'Ezali malamu!';

  @override
  String get incorrect => 'Ezali te';

  @override
  String get next => 'Elandi';

  @override
  String get back => 'Maboko';

  @override
  String get skip => 'Kopasola';

  @override
  String get cancel => 'Koboya';

  @override
  String get save => 'Kobomba';

  @override
  String get done => 'Esali';

  @override
  String get submit => 'Kotinda';

  @override
  String get logout => 'Kobima';

  @override
  String get login => 'Kokota';

  @override
  String get signup => 'Komikanda';

  @override
  String get email => 'Email';

  @override
  String get password => 'Banda';

  @override
  String get forgotPassword => 'Olibosana Banda?';

  @override
  String get noAccount => 'Ozali na Account te?';

  @override
  String get haveAccount => 'Ozali na Account?';

  @override
  String get congratulations => 'Félicitations!';

  @override
  String get lessonComplete => 'Malongi Esali!';

  @override
  String get quizComplete => 'Mituna Esali!';

  @override
  String get accuracy => 'Bomoto';

  @override
  String get score => 'Ntina';

  @override
  String get aiTutor => 'Moyekoli ya AI';

  @override
  String get cultureMagazine => 'Magazine ya Mwasi';

  @override
  String get tribes => 'Bisika';

  @override
  String get leaderboard => 'Lisolo ya Bakonzi';

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
