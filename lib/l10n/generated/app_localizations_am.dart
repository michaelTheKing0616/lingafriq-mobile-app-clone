// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'ወደ LingAfriq እንኳን በደህና መጡ';

  @override
  String get continueButton => 'ቀጥል';

  @override
  String get startLearning => 'መማር ጀምር';

  @override
  String get loading => 'በመጫን ላይ...';

  @override
  String get errorOccurred => 'ስህተት ተከስቷል';

  @override
  String get tryAgain => 'እንደገና ሞክር';

  @override
  String get home => 'መነሻ';

  @override
  String get learn => 'ተማር';

  @override
  String get games => 'ጨዋታዎች';

  @override
  String get profile => 'ፕሮፋይል';

  @override
  String get settings => 'ቅንብሮች';

  @override
  String get language => 'ቋንቋ';

  @override
  String get selectLanguage => 'ቋንቋ ምረጥ';

  @override
  String get lessons => 'ትምህርቶች';

  @override
  String get quizzes => 'ፈተናዎች';

  @override
  String get takeQuiz => 'ፈተና ውሰድ';

  @override
  String get takeLesson => 'ትምህርት ውሰድ';

  @override
  String get dailyStreak => 'የየቀኑ ተከታታይነት';

  @override
  String daysStreak(int count) {
    return '$count ቀናት';
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
  String get intermediate => 'መካከለኛ';

  @override
  String get advanced => 'የላቀ';

  @override
  String get correct => 'ትክክል!';

  @override
  String get incorrect => 'ስህተት';

  @override
  String get next => 'ቀጣይ';

  @override
  String get back => 'ተመለስ';

  @override
  String get skip => 'እለፍ';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get save => 'አስቀምጥ';

  @override
  String get done => 'ተጠናቀቀ';

  @override
  String get submit => 'አስገባ';

  @override
  String get logout => 'ውጣ';

  @override
  String get login => 'ግባ';

  @override
  String get signup => 'ተመዝገብ';

  @override
  String get email => 'ኢሜይል';

  @override
  String get password => 'የይለፍ ቃል';

  @override
  String get forgotPassword => 'የይለፍ ቃል ረሱ?';

  @override
  String get noAccount => 'መለያ የለዎትም?';

  @override
  String get haveAccount => 'መለያ አለዎት?';

  @override
  String get congratulations => 'እንኳን ደስ አለዎት!';

  @override
  String get lessonComplete => 'ትምህርት ተጠናቀቀ!';

  @override
  String get quizComplete => 'ፈተና ተጠናቀቀ!';

  @override
  String get accuracy => 'ትክክለኛነት';

  @override
  String get score => 'ውጤት';

  @override
  String get aiTutor => 'የAI አስተማሪ';

  @override
  String get cultureMagazine => 'የባህል መጽሔት';

  @override
  String get tribes => 'ጎሳዎች';

  @override
  String get leaderboard => 'የመሪዎች ሰሌዳ';

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
