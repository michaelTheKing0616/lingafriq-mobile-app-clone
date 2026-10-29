import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_ig.dart';
import 'app_localizations_ln.dart';
import 'app_localizations_mg.dart';
import 'app_localizations_pcm.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_rw.dart';
import 'app_localizations_sn.dart';
import 'app_localizations_st.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_ti.dart';
import 'app_localizations_tn.dart';
import 'app_localizations_tw.dart';
import 'app_localizations_yo.dart';
import 'app_localizations_zu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ha'),
    Locale('ig'),
    Locale('ln'),
    Locale('mg'),
    Locale('pcm'),
    Locale('pt'),
    Locale('rw'),
    Locale('sn'),
    Locale('st'),
    Locale('sw'),
    Locale('ti'),
    Locale('tn'),
    Locale('tw'),
    Locale('yo'),
    Locale('zu'),
  ];

  /// The app title
  ///
  /// In en, this message translates to:
  /// **'LingAfriq'**
  String get appTitle;

  /// Welcome message shown on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to LingAfriq'**
  String get welcomeMessage;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Start learning button
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get startLearning;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. The app lost the last step. Try again or restart the lesson.'**
  String get errorOccurred;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Learn tab label
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// Games tab label
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language selection label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selection prompt
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Lessons section title
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// Quizzes section title
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// Take quiz button
  ///
  /// In en, this message translates to:
  /// **'Take a Quiz'**
  String get takeQuiz;

  /// Take lesson button
  ///
  /// In en, this message translates to:
  /// **'Take a Lesson'**
  String get takeLesson;

  /// Streak counter label
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get dailyStreak;

  /// Streak days count
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysStreak(int count);

  /// XP earned display
  ///
  /// In en, this message translates to:
  /// **'{count} XP'**
  String xpEarned(int count);

  /// Level label
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// Beginner level
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// Intermediate level
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// Advanced level
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// Correct answer feedback
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// Incorrect answer feedback
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Go on'**
  String get next;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get back;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get done;

  /// Submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// Signup button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Have account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// Congratulations message
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// Lesson completion message
  ///
  /// In en, this message translates to:
  /// **'Lesson Complete!'**
  String get lessonComplete;

  /// Quiz completion message
  ///
  /// In en, this message translates to:
  /// **'Quiz Complete!'**
  String get quizComplete;

  /// Accuracy label
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// Score label
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// AI Tutor feature name
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get aiTutor;

  /// Culture Magazine feature name
  ///
  /// In en, this message translates to:
  /// **'Culture Magazine'**
  String get cultureMagazine;

  /// Tribes feature name
  ///
  /// In en, this message translates to:
  /// **'Tribes'**
  String get tribes;

  /// Leaderboard feature name
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// FLB Heritage archive screen title
  ///
  /// In en, this message translates to:
  /// **'FLB Heritage'**
  String get flbHeritageTitle;

  /// Search field hint on FLB Heritage archive
  ///
  /// In en, this message translates to:
  /// **'Search title, country, or tags'**
  String get flbHeritageSearchHint;

  /// Empty state when no heritage items match
  ///
  /// In en, this message translates to:
  /// **'No entries match your search. Try another keyword or pull to refresh.'**
  String get flbHeritageEmptyMessage;

  /// Error when heritage API and bundle fail
  ///
  /// In en, this message translates to:
  /// **'Could not load the heritage archive. The network or server timed out. Pull to retry.'**
  String get flbHeritageLoadError;

  /// Refresh heritage list button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get flbHeritageRefresh;

  /// Heritage detail screen short title
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get flbHeritageDetailTitle;

  /// Route error when heritage detail has no arguments
  ///
  /// In en, this message translates to:
  /// **'This heritage page is missing. The link did not include an item. Go back and pick another entry.'**
  String get flbHeritageMissingContent;

  /// Tooltip for opening heritage from magazine
  ///
  /// In en, this message translates to:
  /// **'FLB Heritage archive'**
  String get tooltipFlbHeritageArchive;

  /// Tooltip for tribe discovery from magazine
  ///
  /// In en, this message translates to:
  /// **'Tribe discovery'**
  String get tooltipTribeDiscovery;

  /// Drawer item label for heritage archive
  ///
  /// In en, this message translates to:
  /// **'FLB Heritage Archive'**
  String get drawerFlbHeritageArchive;

  /// Tooltip for tribes action on heritage detail
  ///
  /// In en, this message translates to:
  /// **'Tribes'**
  String get tooltipTribes;

  /// Section title for scraped article highlights
  ///
  /// In en, this message translates to:
  /// **'Key takeaways'**
  String get magazineKeyTakeaways;

  /// Related Wikipedia-style topics from scraper
  ///
  /// In en, this message translates to:
  /// **'Related topics'**
  String get magazineRelatedTopics;

  /// Footer for attribution and license text
  ///
  /// In en, this message translates to:
  /// **'Source & license'**
  String get magazineSourceAndLicense;

  /// Reading time chip
  ///
  /// In en, this message translates to:
  /// **'{minutes} min read'**
  String magazineReadingTime(int minutes);

  /// Dismiss game tutorial sheet
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gameTutorialGotIt;

  /// Game tutorial dialog title
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get gameTutorialHowToPlay;

  /// GameKit feedback panel title
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get gamekitFeedbackTitle;

  /// GameKit playing-state hint
  ///
  /// In en, this message translates to:
  /// **'Tap an answer when you are ready.'**
  String get gamekitFeedbackInstructions;

  /// GameKit correct verdict
  ///
  /// In en, this message translates to:
  /// **'Nice one!'**
  String get gamekitFeedbackCorrect;

  /// GameKit wrong verdict
  ///
  /// In en, this message translates to:
  /// **'Not quite — try the next one.'**
  String get gamekitFeedbackWrong;

  /// GameKit pending verdict while server scores
  ///
  /// In en, this message translates to:
  /// **'Checking your answer…'**
  String get gamekitFeedbackPending;

  /// GameKit explanation affordance (P8-904)
  ///
  /// In en, this message translates to:
  /// **'Why was I wrong?'**
  String get gamekitFeedbackWhyWrong;

  /// GameKit practice mode label
  ///
  /// In en, this message translates to:
  /// **'Practice mode'**
  String get gamekitFeedbackPracticeLabel;

  /// P8-911 practice session title
  ///
  /// In en, this message translates to:
  /// **'Practice round'**
  String get gamekitPracticeModeTitle;

  /// P8-911 practice instructions
  ///
  /// In en, this message translates to:
  /// **'Listen, repeat, and compare. Nothing here is scored.'**
  String get gamekitPracticeModeInstructions;

  /// P8-911 practice help (no wrong-answer scoring)
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get gamekitPracticeModeWhyWrong;

  /// P8-911 visible practice banner
  ///
  /// In en, this message translates to:
  /// **'Practice, not scored'**
  String get gamekitPracticeModePracticeLabel;

  /// P8-911 practice audio missing
  ///
  /// In en, this message translates to:
  /// **'Audio is not ready yet. You can still read the phrase.'**
  String get gamekitPracticeModeError;

  /// P8-928 flagship title
  ///
  /// In en, this message translates to:
  /// **'Greeting Gauntlet'**
  String get gamesGreetingGauntletTitle;

  /// P8-928 playing instructions
  ///
  /// In en, this message translates to:
  /// **'Read the scene, pick the greeting and gesture that fit — before the timer runs out.'**
  String get gamesGreetingGauntletInstructions;

  /// P8-928 wrong-answer explanation affordance
  ///
  /// In en, this message translates to:
  /// **'Listen to why that greeting or gesture did not match the moment.'**
  String get gamesGreetingGauntletWhyWrong;

  /// P8-928 practice banner
  ///
  /// In en, this message translates to:
  /// **'Practice — cultural rounds do not affect rank until scoring is verified.'**
  String get gamesGreetingGauntletPracticeLabel;

  /// P8-928 load failure
  ///
  /// In en, this message translates to:
  /// **'We could not load greeting scenarios for this language yet. Try again when you are online.'**
  String get gamesGreetingGauntletError;

  /// P8-915 mastery results screen title
  ///
  /// In en, this message translates to:
  /// **'Round complete'**
  String get gamesGameMasteryResultsTitle;

  /// P8-915 mastery results intro
  ///
  /// In en, this message translates to:
  /// **'Here is how this round touched your skills in the learner model.'**
  String get gamesGameMasteryResultsInstructions;

  /// P8-915 skills list heading
  ///
  /// In en, this message translates to:
  /// **'Skills this round'**
  String get gamesGameMasteryResultsSkillsHeading;

  /// P8-915 flat mastery delta
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get gamesGameMasteryResultsNoChange;

  /// P8-915 positive mastery delta
  ///
  /// In en, this message translates to:
  /// **'Improved'**
  String get gamesGameMasteryResultsImproved;

  /// P8-915 negative mastery delta
  ///
  /// In en, this message translates to:
  /// **'Needs practice'**
  String get gamesGameMasteryResultsDeclined;

  /// P8-915 practice banner
  ///
  /// In en, this message translates to:
  /// **'Practice, not scored'**
  String get gamesGameMasteryResultsPracticeLabel;

  /// P8-915 empty skill delta fallback
  ///
  /// In en, this message translates to:
  /// **'Skill details are still syncing. Your practice was saved.'**
  String get gamesGameMasteryResultsError;

  /// P8-915 dismiss results
  ///
  /// In en, this message translates to:
  /// **'Back to Play'**
  String get gamesGameMasteryResultsDone;

  /// P8-932 mastery map screen title
  ///
  /// In en, this message translates to:
  /// **'Mastery map'**
  String get gamesMasteryMapTitle;

  /// P8-932 mastery map intro
  ///
  /// In en, this message translates to:
  /// **'See which arcade games moved each skill in your learner model.'**
  String get gamesMasteryMapInstructions;

  /// P8-932 per-skill game chips heading
  ///
  /// In en, this message translates to:
  /// **'Games that moved this skill'**
  String get gamesMasteryMapGamesHeading;

  /// P8-932 skill with no learner events
  ///
  /// In en, this message translates to:
  /// **'Not measured'**
  String get gamesMasteryMapNotMeasured;

  /// P8-932 scorer below confidence gate
  ///
  /// In en, this message translates to:
  /// **'Unsure'**
  String get gamesMasteryMapUnsure;

  /// P8-932 practice session row
  ///
  /// In en, this message translates to:
  /// **'Practice, not scored'**
  String get gamesMasteryMapPracticeLabel;

  /// P8-932 load failure
  ///
  /// In en, this message translates to:
  /// **'We could not load your mastery map. Finish a scored arcade round and try again.'**
  String get gamesMasteryMapError;

  /// GameKit scoring error
  ///
  /// In en, this message translates to:
  /// **'We could not score that turn. Try again.'**
  String get gamekitFeedbackError;

  /// GameKit streak celebration
  ///
  /// In en, this message translates to:
  /// **'{count} in a row!'**
  String gamekitFeedbackStreak(int count);

  /// Typing indicator label
  ///
  /// In en, this message translates to:
  /// **'{name} is typing…'**
  String chatPeerTyping(String name);

  /// Label above source language in Polie translation panel
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get polieTranslationSourceLabel;

  /// Label above target language in Polie translation panel
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get polieTranslationTargetLabel;

  /// Toggle label in Polie conversation mode to include English translations.
  ///
  /// In en, this message translates to:
  /// **'English translations'**
  String get polieConversationIncludeEnglishTranslations;

  /// Title for the Polie tutor saved cards list.
  ///
  /// In en, this message translates to:
  /// **'Saved cards'**
  String get polieTutorSavedCards;

  /// Button/tooltip label to save a tutor card.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get polieTutorSaveCard;

  /// Button label to remove a saved tutor card.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get polieTutorRemoveSavedCard;

  /// Empty state message when user has no saved tutor cards.
  ///
  /// In en, this message translates to:
  /// **'No saved cards yet.'**
  String get polieTutorNoSavedCardsYet;

  /// Title for the live/real-time translation screen
  ///
  /// In en, this message translates to:
  /// **'Live translate'**
  String get liveTranslateTitle;

  /// Button label to end a live translation session
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get liveTranslateEndSession;

  /// Status line on live translation screen
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String liveTranslateStatus(Object status);

  /// Label for source captions panel
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get liveTranslateSource;

  /// Label for translated captions panel
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get liveTranslateTranslation;

  /// Text field label for source language input
  ///
  /// In en, this message translates to:
  /// **'Source language (e.g. english)'**
  String get liveTranslateSourceLanguageLabel;

  /// Text field label for target language input
  ///
  /// In en, this message translates to:
  /// **'Target language (e.g. yoruba)'**
  String get liveTranslateTargetLanguageLabel;

  /// Button label to start a live translation session
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get liveTranslateStartSession;

  /// Button label while creating live translation session
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get liveTranslateStarting;

  /// Button label to reconnect live translation session
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get liveTranslateReconnect;

  /// Button label to start listening
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get liveTranslateListen;

  /// Button label to stop listening
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get liveTranslateStopListening;

  /// Button label to interrupt playback and barge in
  ///
  /// In en, this message translates to:
  /// **'Interrupt / barge-in'**
  String get liveTranslateInterruptBargeIn;

  /// Placeholder when no caption is available (ellipsis, not em dash)
  ///
  /// In en, this message translates to:
  /// **'…'**
  String get liveTranslatePlaceholderDash;

  /// Error when speech recognition is not available
  ///
  /// In en, this message translates to:
  /// **'Speech input did not start. This phone cannot run live speech here. Type your phrase or use another device.'**
  String get liveTranslateSpeechUnavailable;

  /// Error when microphone permission is missing
  ///
  /// In en, this message translates to:
  /// **'The mic is blocked. LingAfriq needs the mic to hear you. Open Settings and allow the mic.'**
  String get liveTranslateMicPermissionRequired;

  /// Error when backend returns invalid session payload
  ///
  /// In en, this message translates to:
  /// **'Could not start live translate. The server sent an invalid session. Tap Reconnect and try again.'**
  String get liveTranslateInvalidSession;

  /// Error shown when user tries to listen before starting a session
  ///
  /// In en, this message translates to:
  /// **'Listening is not active yet. You have not started a session. Tap Start session, then speak.'**
  String get liveTranslateStartSessionFirst;

  /// Error shown when socket disconnects
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Your network cut out. Tap reconnect to try again.'**
  String get liveTranslateConnectionLost;

  /// Error shown when socket connection fails
  ///
  /// In en, this message translates to:
  /// **'Could not connect for live translate. The socket failed: {error}. Check your network and tap Reconnect.'**
  String liveTranslateSocketError(Object error);

  /// Fallback error shown when session creation fails
  ///
  /// In en, this message translates to:
  /// **'Could not start a live translate session. The server rejected the request. Wait a moment and try again.'**
  String get liveTranslateSessionFailed;

  /// Error shown when TTS audio playback fails
  ///
  /// In en, this message translates to:
  /// **'Could not play the translation audio. Playback failed: {error}. Tap Hear it again or check your volume.'**
  String liveTranslateCouldNotPlayAudio(Object error);

  /// Fallback error message when a live translate session error has no message
  ///
  /// In en, this message translates to:
  /// **'Live translate hit a session error. Something went wrong on the connection. Leave the session and start again.'**
  String get liveTranslateSessionError;

  /// Default mime type for TTS audio when server does not provide one
  ///
  /// In en, this message translates to:
  /// **'audio/wav'**
  String get liveTranslateDefaultAudioMime;

  /// Title in Word Match Audio game screen.
  ///
  /// In en, this message translates to:
  /// **'Connect the Meaning'**
  String get gameWordMatchConnectMeaningTitle;

  /// Subtitle/instructions in Word Match Audio game screen.
  ///
  /// In en, this message translates to:
  /// **'Tap a word to hear its voice, then match it to its anchor.'**
  String get gameWordMatchConnectMeaningSubtitle;

  /// Right-column header label for meanings in Word Match Audio game.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get gameWordMatchEnglishLabel;

  /// Empty state when a language or level has no verified curriculum content
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get content_coming_soon;

  /// Subtitle under the coming-soon state; states only that verified content is not available
  ///
  /// In en, this message translates to:
  /// **'This content is not available yet.'**
  String get content_not_available_yet;

  /// Short badge on a language or level row that has no verified curriculum content
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get content_coming_soon_badge;

  /// Label for pronunciation practice when no numeric score is shown
  ///
  /// In en, this message translates to:
  /// **'Practice mode'**
  String get pron_practice_mode;

  /// States that pronunciation scoring is not available yet
  ///
  /// In en, this message translates to:
  /// **'Scoring coming soon'**
  String get pron_scoring_soon;

  /// Shown when pronunciation scoring returns 503/retryable; no numeric score is displayed
  ///
  /// In en, this message translates to:
  /// **'We could not score your speech. The scorer is temporarily unavailable. Try again in a moment; no score is shown.'**
  String get pron_unavailable;

  /// Button label to publish reviewed content to learners
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get contentPublishAction;

  /// Success state after content publish completes; must match Publish action wording
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get contentPublishDone;

  /// Persistent disclosure that the historical persona chat is an AI recreation based on sources
  ///
  /// In en, this message translates to:
  /// **'This is an AI recreation based on sources.'**
  String get persona_ai_disclosure;

  /// copy_keys: persona.badge.ai_recreation — persistent non-dismissible persona badge
  ///
  /// In en, this message translates to:
  /// **'AI recreation'**
  String get personaBadgeAiRecreation;

  /// copy_keys: persona.opening.how_built — spoken/read before the first in-character line
  ///
  /// In en, this message translates to:
  /// **'AI version of {personaName} from {sourceSummary}.'**
  String personaOpeningHowBuilt(String personaName, String sourceSummary);

  /// copy_keys: persona.voice.synthesised — label while persona TTS plays
  ///
  /// In en, this message translates to:
  /// **'Synthesised voice'**
  String get personaVoiceSynthesised;

  /// Error shown when a persona mission reply fails; paired with a Retry action
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the persona. The network or server timed out. Retry when you\'re ready.'**
  String get persona_error_retry;

  /// copy_keys: persona.chip.source — opens cited culture card
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get personaChipSource;

  /// copy_keys: persona.chip.inferred — claim not directly documented
  ///
  /// In en, this message translates to:
  /// **'Inferred'**
  String get personaChipInferred;

  /// copy_keys: persona.chip.legend — oral or traditional tradition claim
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get personaChipLegend;

  /// Loading state while claim support is resolved
  ///
  /// In en, this message translates to:
  /// **'Checking sources'**
  String get personaChipLoading;

  /// Documented claim missing dossier source ids
  ///
  /// In en, this message translates to:
  /// **'Source unavailable'**
  String get personaChipNoSource;

  /// Screen reader label for Source chip on persona claims
  ///
  /// In en, this message translates to:
  /// **'Documented claim. Source card ready. Double tap to open it.'**
  String get personaChipSourceSemantics;

  /// Screen reader label for Inferred support on persona claims
  ///
  /// In en, this message translates to:
  /// **'Inferred claim. Drawn from context, not a direct citation.'**
  String get personaChipInferredSemantics;

  /// Screen reader label for Legend support on persona claims
  ///
  /// In en, this message translates to:
  /// **'Legend claim. Oral tradition, not one document.'**
  String get personaChipLegendSemantics;

  /// Screen reader label when documented claim has no source id
  ///
  /// In en, this message translates to:
  /// **'Documented claim. Source card is not ready yet.'**
  String get personaChipNoSourceSemantics;

  /// Sample in-character persona greeting; village voice allowed here only
  ///
  /// In en, this message translates to:
  /// **'Eh, welcome back, friend. The path waits for you today.'**
  String get persona_dialogue_welcome;

  /// copy_keys: label.beta.copy — Beta quality label on learner items
  ///
  /// In en, this message translates to:
  /// **'AI-assisted, machine-checked. Spotted a problem? Tell us.'**
  String get labelBetaCopy;

  /// copy_keys: label.native — short native-verified chip
  ///
  /// In en, this message translates to:
  /// **'Native-verified'**
  String get labelNative;

  /// copy_keys: label.expert — short expert-reviewed chip
  ///
  /// In en, this message translates to:
  /// **'Expert-reviewed'**
  String get labelExpert;

  /// copy_keys: audio.synthetic — tag on TTS audio
  ///
  /// In en, this message translates to:
  /// **'Synthetic voice'**
  String get audioSynthetic;

  /// copy_keys: avatar.semantics.expression — screen reader when idle
  ///
  /// In en, this message translates to:
  /// **'{name} looks {expression}'**
  String avatarSemanticsExpression(String name, String expression);

  /// copy_keys: avatar.semantics.expression — screen reader with activity
  ///
  /// In en, this message translates to:
  /// **'{name} looks {expression} and is {activity}'**
  String avatarSemanticsExpressionActivity(
    String name,
    String expression,
    String activity,
  );

  /// Learner avatar editor screen title (P11-053)
  ///
  /// In en, this message translates to:
  /// **'Your avatar'**
  String get avatarEditorTitle;

  /// Avatar editor rig load failure
  ///
  /// In en, this message translates to:
  /// **'We could not load avatar styles. Try again shortly.'**
  String get avatarEditorLoadError;

  /// Skin tone row label
  ///
  /// In en, this message translates to:
  /// **'Skin tone'**
  String get avatarEditorSkinTone;

  /// No description provided for @avatarEditorSlotHair.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get avatarEditorSlotHair;

  /// No description provided for @avatarEditorSlotHeadwear.
  ///
  /// In en, this message translates to:
  /// **'Headwear'**
  String get avatarEditorSlotHeadwear;

  /// No description provided for @avatarEditorSlotTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get avatarEditorSlotTop;

  /// No description provided for @avatarEditorSlotBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get avatarEditorSlotBottom;

  /// No description provided for @avatarEditorSlotAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessory'**
  String get avatarEditorSlotAccessory;

  /// No description provided for @avatarEditorSlotProp.
  ///
  /// In en, this message translates to:
  /// **'Prop'**
  String get avatarEditorSlotProp;

  /// copy_keys: avatar.item.locked
  ///
  /// In en, this message translates to:
  /// **'Locked — {reason}'**
  String avatarItemLocked(String reason);

  /// No description provided for @avatarItemLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'This look is still locked'**
  String get avatarItemLockedTitle;

  /// copy_keys: avatar.item.note — one-line cultural note
  ///
  /// In en, this message translates to:
  /// **'{note}'**
  String avatarItemNote(String note);

  /// No description provided for @avatarItemLockedReasonGreetings.
  ///
  /// In en, this message translates to:
  /// **'Finish the Greetings & respect can-do to unlock this headwear.'**
  String get avatarItemLockedReasonGreetings;

  /// No description provided for @avatarItemLockedReasonTone.
  ///
  /// In en, this message translates to:
  /// **'Pass a tone checkpoint to unlock this prop.'**
  String get avatarItemLockedReasonTone;

  /// No description provided for @avatarItemLockedReasonCulturalReview.
  ///
  /// In en, this message translates to:
  /// **'This garment unlocks after our cultural review gate clears.'**
  String get avatarItemLockedReasonCulturalReview;

  /// No description provided for @avatarItemLockedReasonIsicholo.
  ///
  /// In en, this message translates to:
  /// **'Isicholo needs cultural context — unlock with guided quest content.'**
  String get avatarItemLockedReasonIsicholo;

  /// No description provided for @avatarItemLockedReasonMastery.
  ///
  /// In en, this message translates to:
  /// **'Earn this look through a mastery milestone, not the shop.'**
  String get avatarItemLockedReasonMastery;

  /// No description provided for @avatarItemLockedReasonStreamPack.
  ///
  /// In en, this message translates to:
  /// **'Extra styles unlock when you complete a chapter can-do.'**
  String get avatarItemLockedReasonStreamPack;

  /// copy_keys: games.arcade_headliners.title
  ///
  /// In en, this message translates to:
  /// **'Headliners'**
  String get gamesArcadeHeadlinersTitle;

  /// copy_keys: games.arcade_headliners.instructions
  ///
  /// In en, this message translates to:
  /// **'Tap a flagship to play — more are on the way.'**
  String get gamesArcadeHeadlinersInstructions;

  /// copy_keys: games.arcade_headliners.practice_label
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get gamesArcadeHeadlinersFeatured;

  /// Headliner tile when elevation card is not Done
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get gamesArcadeHeadlinersComingSoon;

  /// copy_keys: games.arcade_headliners.error
  ///
  /// In en, this message translates to:
  /// **'This game is not ready yet. Try another headliner.'**
  String get gamesArcadeHeadlinersError;

  /// copy_keys: games.arcade_headliners.why_wrong
  ///
  /// In en, this message translates to:
  /// **'We will add a short tip here after you play.'**
  String get gamesArcadeHeadlinersWhyWrong;

  /// copy_keys: duet.start
  ///
  /// In en, this message translates to:
  /// **'Start duet'**
  String get duetStart;

  /// copy_keys: duet.blocked
  ///
  /// In en, this message translates to:
  /// **'Duet unavailable'**
  String get duetBlocked;

  /// copy_keys: stitch.label
  ///
  /// In en, this message translates to:
  /// **'Native correction'**
  String get stitchLabel;

  /// Persistent AI transparency label (EU AI Act Art. 50) on AI chat, tutor, voice and persona screens
  ///
  /// In en, this message translates to:
  /// **'AI-generated: replies and voice come from an AI tutor and can be wrong.'**
  String get aiDisclosureLabel;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'AI-generated content'**
  String get aiDisclosureShort;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Learn how AI is used here'**
  String get aiDisclosureMoreHint;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'About AI in LingAfriq'**
  String get aiDisclosureSheetTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Polie, the tutors and AI personas are not people. Their text and voices are generated by AI. They can be wrong, so check important facts. Avoid sharing private information in chats.'**
  String get aiDisclosureSheetBody;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get aiDisclosureGotIt;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Recordings on this device'**
  String get voiceRetentionTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Your voice is recorded only while you practise, to score pronunciation and turn speech into text. Recordings saved on this phone are deleted automatically.'**
  String get voiceRetentionBody;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Delete recordings automatically'**
  String get voiceRetentionSelectLabel;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Right after scoring'**
  String get voiceRetentionImmediate;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'After 24 hours'**
  String get voiceRetention24h;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'After 7 days'**
  String get voiceRetention7d;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'After 30 days'**
  String get voiceRetention30d;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Delete my recordings now'**
  String get voiceRetentionDeleteNow;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Delete recordings on this device?'**
  String get voiceRetentionConfirmTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Practice recordings saved on this phone will be removed. This can\'t be undone. Recordings you chose to save to your account are not affected.'**
  String get voiceRetentionConfirmBody;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get voiceRetentionConfirmDelete;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No recordings to delete.} =1{1 recording deleted from this device.} other{{count} recordings deleted from this device.}}'**
  String voiceRetentionDeleted(int count);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Subscription terms'**
  String get paywallTermsTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get paywallRowPrice;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Renews'**
  String get paywallRowRenews;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get paywallRowTrial;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get paywallRowCancel;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Premium {premium}/month\nFamily {family}/month\nLifetime {lifetime}, paid once'**
  String paywallPriceValue(String premium, String family, String lifetime);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Charged to your {store} account.'**
  String paywallChargedTo(String store);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Monthly plans renew automatically at the same price until you cancel. Lifetime does not renew.'**
  String get paywallRenewsAuto;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Your plan renews on {date}.'**
  String paywallRenewsOn(String date);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial, then {price}/month unless you cancel at least 24 hours before it ends.'**
  String paywallTrialOffered(int days, String price);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'If a trial is offered, you pay the plan price when it ends unless you cancel at least 24 hours before.'**
  String get paywallTrialGeneric;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Any time in Settings › your name › Subscriptions. You keep access until the paid period ends.'**
  String get paywallCancelApple;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Any time in Google Play › Payments & subscriptions › Subscriptions. You keep access until the paid period ends.'**
  String get paywallCancelGoogle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Free features stay available if you don\'t subscribe or you cancel.'**
  String get paywallFreeStays;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get paywallManage;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get paywallTerms;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get paywallPrivacy;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get reportReasonHarassment;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportReasonSpam;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Hate speech'**
  String get reportReasonHate;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Copyright infringement'**
  String get reportReasonCopyright;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Someone posted your work without permission'**
  String get reportReasonCopyrightHint;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Copyright & takedown'**
  String get settingsCopyright;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Copyright & takedown'**
  String get cpTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'If something on LingAfriq uses your work without permission, tell us. A person reviews every notice.'**
  String get cpIntro;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get cpHowTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'You send a notice with the details below.'**
  String get cpStep1;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'We remove or hide the content quickly and tell the uploader.'**
  String get cpStep2;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'The uploader can send a counter-notice if it was a mistake. Unless you start a court case, the content may return after 10–14 business days.'**
  String get cpStep3;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Repeat infringers'**
  String get cpRepeatTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Accounts with 3 upheld copyright notices are closed. False notices or counter-notices can have legal consequences.'**
  String get cpRepeatBody;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Designated copyright agent'**
  String get cpAgentTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Agent registration in progress. Until then, use this form.'**
  String get cpAgentPending;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Report copyright'**
  String get cpKindNotice;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Counter-notice'**
  String get cpKindCounter;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Your notice'**
  String get cpFormTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Content ID or link on LingAfriq'**
  String get cpFieldTarget;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Describe your original work'**
  String get cpFieldWork;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Describe the removed content'**
  String get cpFieldWorkCounter;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'For example: title, where it was first published, and a link.'**
  String get cpFieldWorkHelp;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Full legal name'**
  String get cpFieldName;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Email for our reply'**
  String get cpFieldEmail;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Signature: type your full name'**
  String get cpFieldSignature;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Statements'**
  String get cpStatementsTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'I believe in good faith this use is not authorised by the owner, its agent or the law.'**
  String get cpStmtGoodFaith;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'This notice is accurate and, under penalty of perjury, I am the owner or authorised to act for the owner.'**
  String get cpStmtAccurate;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Under penalty of perjury, I believe the content was removed by mistake or misidentification.'**
  String get cpStmtMistake;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'I consent to the jurisdiction of the appropriate court and accept service from the claimant.'**
  String get cpStmtJurisdiction;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get cpRequired;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get cpEmailInvalid;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Add a little more detail'**
  String get cpWorkTooShort;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Tick both statements to continue'**
  String get cpStatementsMissing;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Send notice'**
  String get cpSend;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get cpSending;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your notice'**
  String get cpErrorTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Nothing you typed was lost.'**
  String get cpErrorBody;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get cpRetry;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Notice received'**
  String get cpSuccessTitle;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'A person will review it and email you. Keep this reference: {reference}'**
  String cpSuccessBody(String reference);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cpDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'am',
    'ar',
    'en',
    'es',
    'fr',
    'ha',
    'ig',
    'ln',
    'mg',
    'pcm',
    'pt',
    'rw',
    'sn',
    'st',
    'sw',
    'ti',
    'tn',
    'tw',
    'yo',
    'zu',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ha':
      return AppLocalizationsHa();
    case 'ig':
      return AppLocalizationsIg();
    case 'ln':
      return AppLocalizationsLn();
    case 'mg':
      return AppLocalizationsMg();
    case 'pcm':
      return AppLocalizationsPcm();
    case 'pt':
      return AppLocalizationsPt();
    case 'rw':
      return AppLocalizationsRw();
    case 'sn':
      return AppLocalizationsSn();
    case 'st':
      return AppLocalizationsSt();
    case 'sw':
      return AppLocalizationsSw();
    case 'ti':
      return AppLocalizationsTi();
    case 'tn':
      return AppLocalizationsTn();
    case 'tw':
      return AppLocalizationsTw();
    case 'yo':
      return AppLocalizationsYo();
    case 'zu':
      return AppLocalizationsZu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
