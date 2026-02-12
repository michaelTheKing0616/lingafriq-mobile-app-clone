// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Welcome to LingAfriq';

  @override
  String get continueButton => 'Continue';

  @override
  String get startLearning => 'Start Learning';

  @override
  String get loading => 'Loading...';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get home => 'Home';

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
  String get selectLanguage => 'Select Language';

  @override
  String get lessons => 'Lessons';

  @override
  String get quizzes => 'Quizzes';

  @override
  String get takeQuiz => 'Take a Quiz';

  @override
  String get takeLesson => 'Take a Lesson';

  @override
  String get dailyStreak => 'Daily Streak';

  @override
  String daysStreak(int count) {
    return '$count days';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Level';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get submit => 'Submit';

  @override
  String get logout => 'Log Out';

  @override
  String get login => 'Log In';

  @override
  String get signup => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String get lessonComplete => 'Lesson Complete!';

  @override
  String get quizComplete => 'Quiz Complete!';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get score => 'Score';

  @override
  String get aiTutor => 'AI Tutor';

  @override
  String get cultureMagazine => 'Culture Magazine';

  @override
  String get tribes => 'Tribes';

  @override
  String get leaderboard => 'Leaderboard';
}
