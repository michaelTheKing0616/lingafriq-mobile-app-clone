// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tswana (`tn`).
class AppLocalizationsTn extends AppLocalizations {
  AppLocalizationsTn([String locale = 'tn']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'O amogela mo LingAfriq';

  @override
  String get continueButton => 'Tswela pele';

  @override
  String get startLearning => 'Simolola go Ithuta';

  @override
  String get loading => 'Go tsena...';

  @override
  String get errorOccurred => 'Phoso e diregile';

  @override
  String get tryAgain => 'Leka gape';

  @override
  String get home => 'Gae';

  @override
  String get learn => 'Ithuta';

  @override
  String get games => 'Dikgwele';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Dikgato';

  @override
  String get language => 'Puo';

  @override
  String get selectLanguage => 'Kgetha Puo';

  @override
  String get lessons => 'Dithuto';

  @override
  String get quizzes => 'Dipotsiso';

  @override
  String get takeQuiz => 'Tselela Dipotsiso';

  @override
  String get takeLesson => 'Tselela Dithuto';

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
  String get level => 'Seemo';

  @override
  String get beginner => 'Simolola';

  @override
  String get intermediate => 'Gare';

  @override
  String get advanced => 'Godimo';

  @override
  String get correct => 'Nnete!';

  @override
  String get incorrect => 'Ga se nnete';

  @override
  String get next => 'E latelang';

  @override
  String get back => 'Morago';

  @override
  String get skip => 'Skippa';

  @override
  String get cancel => 'Hlakola';

  @override
  String get save => 'Boloka';

  @override
  String get done => 'E fedile';

  @override
  String get submit => 'Romela';

  @override
  String get logout => 'Tswa';

  @override
  String get login => 'Kena';

  @override
  String get signup => 'Ingodisa';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'O lebetse Password?';

  @override
  String get noAccount => 'Ga o na Account?';

  @override
  String get haveAccount => 'O na le Account?';

  @override
  String get congratulations => 'Re a go amogela!';

  @override
  String get lessonComplete => 'Dithuto Di Fedile!';

  @override
  String get quizComplete => 'Dipotsiso Di Fedile!';

  @override
  String get accuracy => 'Nnete';

  @override
  String get score => 'Dintlha';

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
  String get gameWordMatchConnectMeaningTitle => 'Connect the Meaning';

  @override
  String get gameWordMatchConnectMeaningSubtitle =>
      'Tap a word to hear its voice, then match it to its anchor.';

  @override
  String get gameWordMatchEnglishLabel => 'English';
}
