// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tigrinya (`ti`).
class AppLocalizationsTi extends AppLocalizations {
  AppLocalizationsTi([String locale = 'ti']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'እንኳን ደህና መጡ ናብ LingAfriq';

  @override
  String get continueButton => 'ቀጥል';

  @override
  String get startLearning => 'ምምሃር ጀምር';

  @override
  String get loading => 'እንተጻወተ...';

  @override
  String get errorOccurred => 'ጌጋ ተፈጢሩ';

  @override
  String get tryAgain => 'ከምኡ ደጊምካ ፈትን';

  @override
  String get home => 'ኣብ ቤት';

  @override
  String get learn => 'ምምሃር';

  @override
  String get games => 'ጸወታታት';

  @override
  String get profile => 'መግለጺ';

  @override
  String get settings => 'ምርጫታት';

  @override
  String get language => 'ቋንቋ';

  @override
  String get selectLanguage => 'ቋንቋ ምረጽ';

  @override
  String get lessons => 'ትምህርትታት';

  @override
  String get quizzes => 'መፈተንታት';

  @override
  String get takeQuiz => 'መፈተንቲ ወስድ';

  @override
  String get takeLesson => 'ትምህርቲ ወስድ';

  @override
  String get dailyStreak => 'ዕለታዊ ምቁር';

  @override
  String daysStreak(int count) {
    return '$count መዓልቲ';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'ደረጃ';

  @override
  String get beginner => 'ጀማሪ';

  @override
  String get intermediate => 'መንግስታዊ';

  @override
  String get advanced => 'ላዕለዋይ';

  @override
  String get correct => 'ቅኑዕ!';

  @override
  String get incorrect => 'ዘይቅኑዕ';

  @override
  String get next => 'ቀጺሉ';

  @override
  String get back => 'ንድሕሪት';

  @override
  String get skip => 'ምሸላ';

  @override
  String get cancel => 'ኣብርሓ';

  @override
  String get save => 'ኣሕዝን';

  @override
  String get done => 'ዝተፈጸመ';

  @override
  String get submit => 'ስደድ';

  @override
  String get logout => 'ውጻእ';

  @override
  String get login => 'እተው';

  @override
  String get signup => 'ተመዝግብ';

  @override
  String get email => 'ኢመይል';

  @override
  String get password => 'ዘለላ';

  @override
  String get forgotPassword => 'ዘለላ ረሲዕካ?';

  @override
  String get noAccount => 'ኣካውንት የብልካን?';

  @override
  String get haveAccount => 'ኣካውንት ኣለካ?';

  @override
  String get congratulations => 'እንቋዕ!';

  @override
  String get lessonComplete => 'ትምህርቲ ተዛዚሙ!';

  @override
  String get quizComplete => 'መፈተንቲ ተዛዚሙ!';

  @override
  String get accuracy => 'ትክክለኛነት';

  @override
  String get score => 'ነጥቢ';

  @override
  String get aiTutor => 'AI መምህር';

  @override
  String get cultureMagazine => 'ዓውደ ባህሊ';

  @override
  String get tribes => 'ዓሌታት';

  @override
  String get leaderboard => 'ዝለዓለ ዝርዝር';

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
}
