// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'E kaabo si LingAfriq';

  @override
  String get continueButton => 'Tesiwaju';

  @override
  String get startLearning => 'Bere Kiko';

  @override
  String get loading => 'N gbe wole...';

  @override
  String get errorOccurred => 'Asise kan sele';

  @override
  String get tryAgain => 'Gbiyanju Leekansi';

  @override
  String get home => 'Ile';

  @override
  String get learn => 'Ko';

  @override
  String get games => 'Ere';

  @override
  String get profile => 'Akosilè';

  @override
  String get settings => 'Eto';

  @override
  String get language => 'Ede';

  @override
  String get selectLanguage => 'Yan Ede';

  @override
  String get lessons => 'Eko';

  @override
  String get quizzes => 'Idanwo';

  @override
  String get takeQuiz => 'Se Idanwo';

  @override
  String get takeLesson => 'Ko Eko';

  @override
  String get dailyStreak => 'Itesiwaju Ojoojumo';

  @override
  String daysStreak(int count) {
    return 'Ojo $count';
  }

  @override
  String xpEarned(int count) {
    return 'XP $count';
  }

  @override
  String get level => 'Ipele';

  @override
  String get beginner => 'Alabere';

  @override
  String get intermediate => 'Aarin';

  @override
  String get advanced => 'Agbayan';

  @override
  String get correct => 'O to!';

  @override
  String get incorrect => 'Ko to';

  @override
  String get next => 'To n bo';

  @override
  String get back => 'Pada';

  @override
  String get skip => 'Fo';

  @override
  String get cancel => 'Fagile';

  @override
  String get save => 'Fipamo';

  @override
  String get done => 'Pari';

  @override
  String get submit => 'Fowosi';

  @override
  String get logout => 'Jade';

  @override
  String get login => 'Wole';

  @override
  String get signup => 'Forukosile';

  @override
  String get email => 'Imeeli';

  @override
  String get password => 'Oro asina';

  @override
  String get forgotPassword => 'Se o gbagbe Oro Asina?';

  @override
  String get noAccount => 'O ni akole?';

  @override
  String get haveAccount => 'Se o ni akole tele?';

  @override
  String get congratulations => 'Ku oriire!';

  @override
  String get lessonComplete => 'Eko Pari!';

  @override
  String get quizComplete => 'Idanwo Pari!';

  @override
  String get accuracy => 'Dedede';

  @override
  String get score => 'Iye';

  @override
  String get aiTutor => 'Oluko AI';

  @override
  String get cultureMagazine => 'Iwe Asa';

  @override
  String get tribes => 'Eya';

  @override
  String get leaderboard => 'Atojo Asaju';

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
