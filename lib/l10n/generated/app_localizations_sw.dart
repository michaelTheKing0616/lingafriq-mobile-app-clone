// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Karibu LingAfriq';

  @override
  String get continueButton => 'Endelea';

  @override
  String get startLearning => 'Anza Kujifunza';

  @override
  String get loading => 'Inapakia...';

  @override
  String get errorOccurred => 'Kosa limefanyika';

  @override
  String get tryAgain => 'Jaribu Tena';

  @override
  String get home => 'Nyumbani';

  @override
  String get learn => 'Jifunze';

  @override
  String get games => 'Michezo';

  @override
  String get profile => 'Wasifu';

  @override
  String get settings => 'Mipangilio';

  @override
  String get language => 'Lugha';

  @override
  String get selectLanguage => 'Chagua Lugha';

  @override
  String get lessons => 'Masomo';

  @override
  String get quizzes => 'Maswali';

  @override
  String get takeQuiz => 'Fanya Mtihani';

  @override
  String get takeLesson => 'Fanya Somo';

  @override
  String get dailyStreak => 'Mfululizo wa Kila Siku';

  @override
  String daysStreak(int count) {
    return 'Siku $count';
  }

  @override
  String xpEarned(int count) {
    return 'XP $count';
  }

  @override
  String get level => 'Kiwango';

  @override
  String get beginner => 'Mwanzo';

  @override
  String get intermediate => 'Wastani';

  @override
  String get advanced => 'Juu';

  @override
  String get correct => 'Sahihi!';

  @override
  String get incorrect => 'Si sahihi';

  @override
  String get next => 'Ifuatayo';

  @override
  String get back => 'Rudi';

  @override
  String get skip => 'Ruka';

  @override
  String get cancel => 'Ghairi';

  @override
  String get save => 'Hifadhi';

  @override
  String get done => 'Imekwisha';

  @override
  String get submit => 'Tuma';

  @override
  String get logout => 'Ondoka';

  @override
  String get login => 'Ingia';

  @override
  String get signup => 'Jiandikishe';

  @override
  String get email => 'Barua pepe';

  @override
  String get password => 'Neno la siri';

  @override
  String get forgotPassword => 'Umesahau Neno la Siri?';

  @override
  String get noAccount => 'Huna akaunti?';

  @override
  String get haveAccount => 'Una akaunti tayari?';

  @override
  String get congratulations => 'Hongera!';

  @override
  String get lessonComplete => 'Somo Limekwisha!';

  @override
  String get quizComplete => 'Mtihani Umekwisha!';

  @override
  String get accuracy => 'Usahihi';

  @override
  String get score => 'Alama';

  @override
  String get aiTutor => 'Mwalimu wa AI';

  @override
  String get cultureMagazine => 'Jarida la Utamaduni';

  @override
  String get tribes => 'Makabila';

  @override
  String get leaderboard => 'Orodha ya Viongozi';

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
