// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Zulu (`zu`).
class AppLocalizationsZu extends AppLocalizations {
  AppLocalizationsZu([String locale = 'zu']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Siyakwamukela ku-LingAfriq';

  @override
  String get continueButton => 'Qhubeka';

  @override
  String get startLearning => 'Qala Ukufunda';

  @override
  String get loading => 'Iyalayisha...';

  @override
  String get errorOccurred => 'Kunephutha elivele';

  @override
  String get tryAgain => 'Zama Futhi';

  @override
  String get home => 'Ikhaya';

  @override
  String get learn => 'Funda';

  @override
  String get games => 'Imidlalo';

  @override
  String get profile => 'Iphrofayili';

  @override
  String get settings => 'Izilungiselelo';

  @override
  String get language => 'Ulimi';

  @override
  String get selectLanguage => 'Khetha Ulimi';

  @override
  String get lessons => 'Izifundo';

  @override
  String get quizzes => 'Imibuzo';

  @override
  String get takeQuiz => 'Yenza Imibuzo';

  @override
  String get takeLesson => 'Yenza Isifundo';

  @override
  String get dailyStreak => 'Ukulandela Kwansuku Zonke';

  @override
  String daysStreak(int count) {
    return 'Izinsuku $count';
  }

  @override
  String xpEarned(int count) {
    return 'XP $count';
  }

  @override
  String get level => 'Izinga';

  @override
  String get beginner => 'Oqalayo';

  @override
  String get intermediate => 'Ophakathi';

  @override
  String get advanced => 'Ophezulu';

  @override
  String get correct => 'Kulungile!';

  @override
  String get incorrect => 'Akukhona';

  @override
  String get next => 'Okulandelayo';

  @override
  String get back => 'Emuva';

  @override
  String get skip => 'Yeqa';

  @override
  String get cancel => 'Khansela';

  @override
  String get save => 'Londoloza';

  @override
  String get done => 'Kwenziwe';

  @override
  String get submit => 'Thumela';

  @override
  String get logout => 'Phuma';

  @override
  String get login => 'Ngena';

  @override
  String get signup => 'Bhalisa';

  @override
  String get email => 'I-imeyili';

  @override
  String get password => 'Iphasiwedi';

  @override
  String get forgotPassword => 'Ukhohlwe Iphasiwedi?';

  @override
  String get noAccount => 'Awunayo i-akhawunti?';

  @override
  String get haveAccount => 'Usunayo i-akhawunti?';

  @override
  String get congratulations => 'Halala!';

  @override
  String get lessonComplete => 'Isifundo Siqediwe!';

  @override
  String get quizComplete => 'Imibuzo Iqediwe!';

  @override
  String get accuracy => 'Ukunemba';

  @override
  String get score => 'Amaphuzu';

  @override
  String get aiTutor => 'Uthisha we-AI';

  @override
  String get cultureMagazine => 'Imagazini Yamasiko';

  @override
  String get tribes => 'Izizwe';

  @override
  String get leaderboard => 'Uhlu Lwabaholi';

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
}
