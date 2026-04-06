// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Shona (`sn`).
class AppLocalizationsSn extends AppLocalizations {
  AppLocalizationsSn([String locale = 'sn']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Mauya kuLingAfriq';

  @override
  String get continueButton => 'Enderera';

  @override
  String get startLearning => 'Tanga Kudzidza';

  @override
  String get loading => 'Ari kurodha...';

  @override
  String get errorOccurred => 'Chikanganiso chakaitika';

  @override
  String get tryAgain => 'Edza Zvakare';

  @override
  String get home => 'Kumba';

  @override
  String get learn => 'Dzidza';

  @override
  String get games => 'Mitambo';

  @override
  String get profile => 'Mbiri';

  @override
  String get settings => 'Zvigadziriso';

  @override
  String get language => 'Mutauro';

  @override
  String get selectLanguage => 'Sarudza Mutauro';

  @override
  String get lessons => 'Zvidzidzo';

  @override
  String get quizzes => 'Mibvunzo';

  @override
  String get takeQuiz => 'Tora Mubvunzo';

  @override
  String get takeLesson => 'Tora Chidzidzo';

  @override
  String get dailyStreak => 'Kutevedzana Kwemazuva';

  @override
  String daysStreak(int count) {
    return 'Mazuva $count';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Chikamu';

  @override
  String get beginner => 'Mutangiri';

  @override
  String get intermediate => 'Wepakati';

  @override
  String get advanced => 'Wepamusoro';

  @override
  String get correct => 'Zvakanaka!';

  @override
  String get incorrect => 'Hazvina kunaka';

  @override
  String get next => 'Inotevera';

  @override
  String get back => 'Shure';

  @override
  String get skip => 'Svetuka';

  @override
  String get cancel => 'Kanzura';

  @override
  String get save => 'Sevha';

  @override
  String get done => 'Zvaitwa';

  @override
  String get submit => 'Tumira';

  @override
  String get logout => 'Buda';

  @override
  String get login => 'Pinda';

  @override
  String get signup => 'Nyoresa';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Wakanganwa Password?';

  @override
  String get noAccount => 'Hauna Account?';

  @override
  String get haveAccount => 'Une Account Here?';

  @override
  String get congratulations => 'Makorokoto!';

  @override
  String get lessonComplete => 'Chidzidzo Chapera!';

  @override
  String get quizComplete => 'Mubvunzo Wapera!';

  @override
  String get accuracy => 'Kunyatsoita';

  @override
  String get score => 'Mubairo';

  @override
  String get aiTutor => 'Mudzidzisi weAI';

  @override
  String get cultureMagazine => 'Magazini yeTsika';

  @override
  String get tribes => 'Madzinza';

  @override
  String get leaderboard => 'Bhodhi reVatungamiri';

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
