// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nigerian Pidgin (`pcm`).
class AppLocalizationsPcm extends AppLocalizations {
  AppLocalizationsPcm([String locale = 'pcm']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'You don land for LingAfriq!';

  @override
  String get continueButton => 'Continue';

  @override
  String get startLearning => 'Start to Learn';

  @override
  String get loading => 'E dey load...';

  @override
  String get errorOccurred => 'Wahala happen';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get home => 'House';

  @override
  String get learn => 'Learn';

  @override
  String get games => 'Games';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Choose Language';

  @override
  String get lessons => 'Lessons';

  @override
  String get quizzes => 'Quiz';

  @override
  String get takeQuiz => 'Do Quiz';

  @override
  String get takeLesson => 'Do Lesson';

  @override
  String get dailyStreak => 'Everyday Progress';

  @override
  String daysStreak(int count) {
    return '$count Days';
  }

  @override
  String xpEarned(int count) {
    return 'XP $count';
  }

  @override
  String get level => 'Level';

  @override
  String get beginner => 'JJC';

  @override
  String get intermediate => 'Middle';

  @override
  String get advanced => 'Boss Level';

  @override
  String get correct => 'E correct!';

  @override
  String get incorrect => 'E no correct';

  @override
  String get next => 'Next One';

  @override
  String get back => 'Go Back';

  @override
  String get skip => 'Skip Am';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save Am';

  @override
  String get done => 'Done';

  @override
  String get submit => 'Submit';

  @override
  String get logout => 'Comot';

  @override
  String get login => 'Enter';

  @override
  String get signup => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'You forget Password?';

  @override
  String get noAccount => 'You no get account?';

  @override
  String get haveAccount => 'You get account already?';

  @override
  String get congratulations => 'Well done!';

  @override
  String get lessonComplete => 'Lesson Don Finish!';

  @override
  String get quizComplete => 'Quiz Don Finish!';

  @override
  String get accuracy => 'How Correct';

  @override
  String get score => 'Score';

  @override
  String get aiTutor => 'AI Teacher';

  @override
  String get cultureMagazine => 'Culture Magazine';

  @override
  String get tribes => 'Tribes';

  @override
  String get leaderboard => 'Top People';

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
}
