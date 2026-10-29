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
  /// **'Plus Monthly {premium}/month\nPlus Family {family}/month\nPlus Lifetime {lifetime}, paid once'**
  String paywallPriceValue(String premium, String family, String lifetime);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Charged to your {store} account.'**
  String paywallChargedTo(String store);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Plus Monthly and Plus Family renew automatically at the same price until you cancel. Plus Lifetime does not renew.'**
  String get paywallRenewsAuto;

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Your plan renews on {date}.'**
  String paywallRenewsOn(String date);

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial of Plus Monthly, then {price}/month unless you cancel at least 24 hours before it ends.'**
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

  /// Compliance batch 1 UI
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get reportReasonTitle;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSecAppearance;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSecNotifications;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsSecAudio;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecSecurity;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSecAccount;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get settingsSecLearning;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Offline & Sync'**
  String get settingsSecOffline;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSecAbout;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark theme'**
  String get settingsDarkModeSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPush;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get settingsPushSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Daily reminders'**
  String get settingsDailyReminders;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Get reminded to practise daily'**
  String get settingsDailyRemindersSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSoundEffects;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Play sound effects during lessons'**
  String get settingsSoundEffectsSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Tutor voice styles'**
  String get settingsVoiceStyles;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Synthetic, non-identifying voices (opt-in)'**
  String get settingsVoiceStylesSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in'**
  String get settingsBiometric;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Use biometrics to sign in quickly'**
  String get settingsBiometricSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Encrypt cached data'**
  String get settingsEncryptCache;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Encrypt sensitive data stored on this device'**
  String get settingsEncryptCacheSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settingsEditProfile;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get settingsEditProfileSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get settingsChangePasswordSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get settingsPrivacy;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Manage your privacy preferences'**
  String get settingsPrivacySub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Micro-mentor reports'**
  String get settingsMentorReports;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Review safety reports (staff)'**
  String get settingsMentorReportsSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Learning goals'**
  String get settingsGoals;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Set your daily learning goals'**
  String get settingsGoalsSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Study reminders'**
  String get settingsStudyReminders;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Choose when to be reminded'**
  String get settingsStudyRemindersSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Sync settings'**
  String get settingsSync;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Choose what to sync'**
  String get settingsSyncSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Cache management'**
  String get settingsCache;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'View and manage cached data'**
  String get settingsCacheSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsDownloads;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Unit size, Wi-Fi and delete'**
  String get settingsDownloadsSub;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelp;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogoutConfirm;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Features guide'**
  String get settingsFeaturesGuide;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'How games work'**
  String get settingsGamesTour;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Low bandwidth'**
  String get lowBandwidthTitle;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'On because Data Saver is on'**
  String get lowBandwidthAutoOn;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'On until you turn it off'**
  String get lowBandwidthManualOn;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get lowBandwidthOff;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Exit lesson'**
  String get lessonExit;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Leave this lesson?'**
  String get lessonQuitTitle;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'You\'re doing well. A few more minutes finishes this lesson.'**
  String get lessonQuitBody;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Keep learning'**
  String get lessonKeepLearning;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'End lesson'**
  String get lessonEndSession;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Preparing your lesson'**
  String get lessonPreparing;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Let\'s try that again'**
  String get lessonLoadFailedTitle;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get lessonRetry;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Lesson progress. Section {current} of {total}. {percent} percent complete.'**
  String lessonProgressLabel(int current, int total, int percent);

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Section {current} of {total}'**
  String lessonSectionLabel(int current, int total);

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'Continue to next section'**
  String get lessonContinueNext;

  /// Lesson flow screen
  ///
  /// In en, this message translates to:
  /// **'{count} Points'**
  String pointsCount(int count);

  /// Lesson quit sheet
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 section left} other{{count} sections left}}'**
  String lessonQuitRemaining(int count);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get homeSearchLanguagesLabel;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Search Languages'**
  String get homeSearchLanguagesAction;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get homeOpenMenu;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenu;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Featured Languages'**
  String get homeFeaturedLanguages;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'No languages yet'**
  String get homeNoLanguagesTitle;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'We\'re still adding languages for your region. Search to see what\'s available, or check back soon.'**
  String get homeNoLanguagesBody;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'{name} is coming soon. We\'re putting the finishing touches on it.'**
  String homeComingSoonSnack(String name);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get homeOfflineTitle;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Check your connection. We\'ll reload your languages as soon as you\'re back online.'**
  String get homeOfflineBody;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get homeTryAgain;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Loading your languages...'**
  String get homeLoadingLanguages;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get homeComingSoon;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'{percent}% Complete'**
  String homePercentComplete(int percent);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get homeStartLearning;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'{name} language card, coming soon, not available yet'**
  String homeCardLocked(String name);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'{name} language card, {percent}% complete'**
  String homeCardProgress(String name, int percent);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'{name} language card, start learning'**
  String homeCardStart(String name);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'{name} picture'**
  String homeFlag(String name);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Waiting for a guardian'**
  String get homeGuardianTitle;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Lessons are open. Chat, Village, and purchases stay paused until a guardian approves.'**
  String get homeGuardianBody;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Waiting for a guardian. Lessons are open, but chat, Village, and purchases stay paused until a guardian approves.'**
  String get homeGuardianLabel;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String homeWelcomeBack(String name);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Learner'**
  String get homeLearner;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Pick a language and start your streak today.'**
  String get homeStreakNone;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'You\'re one day in, keep your streak alive today.'**
  String get homeStreakOne;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'You\'re on a {count}-day streak, keep it going!'**
  String homeStreakMany(int count);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String homeStreakBadge(int count);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} days streak}}'**
  String homeStreakSemantics(int count);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Daily goals'**
  String get homeDailyGoals;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal progress: {percent}%'**
  String homeGoalRing(int percent);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get homeGoalCaption;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Today\'s word: {word}, “welcome” in {language}'**
  String homeWordOfDay(String word, String language);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Hausa'**
  String get homeLangHausa;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Pidgin'**
  String get homeLangPidgin;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get homeLangSwahili;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Yorùbá'**
  String get homeLangYoruba;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Zulu'**
  String get homeLangZulu;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Igbo'**
  String get homeLangIgbo;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Continue {name}'**
  String homeContinueTitle(String name);

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Continue {name}, {percent}% complete'**
  String homeContinueLabel(String name, int percent);

  /// homeErrorTitle
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your languages'**
  String get homeErrorTitle;

  /// homeErrorBody
  ///
  /// In en, this message translates to:
  /// **'That one\'s on us. Your progress is safe, so try again in a moment.'**
  String get homeErrorBody;

  /// homeKidsTitle
  ///
  /// In en, this message translates to:
  /// **'Kids mode is on'**
  String get homeKidsTitle;

  /// homeKidsBody
  ///
  /// In en, this message translates to:
  /// **'Every lesson is open. Chat, Village and purchases are switched off.'**
  String get homeKidsBody;

  /// homeKidsLabel
  ///
  /// In en, this message translates to:
  /// **'Kids mode is on. Every lesson is open. Chat, Village and purchases are switched off.'**
  String get homeKidsLabel;

  /// lessonNewPhrase
  ///
  /// In en, this message translates to:
  /// **'New phrase'**
  String get lessonNewPhrase;

  /// lessonExampleLabel
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get lessonExampleLabel;

  /// lessonListen
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get lessonListen;

  /// lessonListenSlowly
  ///
  /// In en, this message translates to:
  /// **'Listen slowly'**
  String get lessonListenSlowly;

  /// lessonTutorialAudio
  ///
  /// In en, this message translates to:
  /// **'Tutorial audio'**
  String get lessonTutorialAudio;

  /// lessonTutorialVideo
  ///
  /// In en, this message translates to:
  /// **'Tutorial video'**
  String get lessonTutorialVideo;

  /// lessonQuestionOf
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String lessonQuestionOf(int current, int total);

  /// lessonQuestionProgress
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}. {percent} percent complete.'**
  String lessonQuestionProgress(int current, int total, int percent);

  /// lessonPrevious
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get lessonPrevious;

  /// lessonPreviousQuestion
  ///
  /// In en, this message translates to:
  /// **'Previous question'**
  String get lessonPreviousQuestion;

  /// lessonCheck
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get lessonCheck;

  /// lessonCheckAnswer
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get lessonCheckAnswer;

  /// lessonNext
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get lessonNext;

  /// lessonNextQuestion
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get lessonNextQuestion;

  /// lessonFinish
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get lessonFinish;

  /// lessonFinishQuiz
  ///
  /// In en, this message translates to:
  /// **'Finish quiz'**
  String get lessonFinishQuiz;

  /// lessonPickFirst
  ///
  /// In en, this message translates to:
  /// **'Pick an answer first, then we\'ll check it together.'**
  String get lessonPickFirst;

  /// lessonCorrectTitle
  ///
  /// In en, this message translates to:
  /// **'Nice work!'**
  String get lessonCorrectTitle;

  /// lessonCorrectBody
  ///
  /// In en, this message translates to:
  /// **'That\'s right. Keep the streak going.'**
  String get lessonCorrectBody;

  /// lessonIncorrectTitle
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get lessonIncorrectTitle;

  /// lessonCorrectAnswer
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String lessonCorrectAnswer(String answer);

  /// lessonOptionLabel
  ///
  /// In en, this message translates to:
  /// **'Answer option {letter}: {text}.'**
  String lessonOptionLabel(String letter, String text);

  /// lessonOptionSelected
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get lessonOptionSelected;

  /// lessonQuestionLabel
  ///
  /// In en, this message translates to:
  /// **'Question. {question}'**
  String lessonQuestionLabel(String question);

  /// lessonHintLabel
  ///
  /// In en, this message translates to:
  /// **'Hint: {hint}'**
  String lessonHintLabel(String hint);

  /// lessonFunFact
  ///
  /// In en, this message translates to:
  /// **'Fun fact'**
  String get lessonFunFact;

  /// lessonNotReadyTitle
  ///
  /// In en, this message translates to:
  /// **'This part isn\'t ready yet'**
  String get lessonNotReadyTitle;

  /// lessonNotReadyBody
  ///
  /// In en, this message translates to:
  /// **'We\'re still preparing these questions. Please check back in a moment.'**
  String get lessonNotReadyBody;

  /// lessonLoadFailedBody
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Your progress is saved.'**
  String get lessonLoadFailedBody;

  /// lessonAvatarLabel
  ///
  /// In en, this message translates to:
  /// **'Your profile, {points}'**
  String lessonAvatarLabel(String points);

  /// lcMsgGreat
  ///
  /// In en, this message translates to:
  /// **'You\'re building real conversational confidence.'**
  String get lcMsgGreat;

  /// lcMsgGood
  ///
  /// In en, this message translates to:
  /// **'That lesson moved you forward. Well done.'**
  String get lcMsgGood;

  /// lcMsgSteady
  ///
  /// In en, this message translates to:
  /// **'Every session strengthens memory. Keep going.'**
  String get lcMsgSteady;

  /// lcMsgReview
  ///
  /// In en, this message translates to:
  /// **'A short review next time will lock these in.'**
  String get lcMsgReview;

  /// lcMsgNoQuiz
  ///
  /// In en, this message translates to:
  /// **'You met new phrases today. They\'ll come back in your next quiz.'**
  String get lcMsgNoQuiz;

  /// lcStatXp
  ///
  /// In en, this message translates to:
  /// **'XP earned'**
  String get lcStatXp;

  /// lcStatAccuracy
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get lcStatAccuracy;

  /// lcStatTime
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get lcStatTime;

  /// lcNoQuizValue
  ///
  /// In en, this message translates to:
  /// **'Not quizzed'**
  String get lcNoQuizValue;

  /// lcPercent
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String lcPercent(int value);

  /// lcTimeMinSec
  ///
  /// In en, this message translates to:
  /// **'{m}m {s}s'**
  String lcTimeMinSec(int m, int s);

  /// lcTimeSec
  ///
  /// In en, this message translates to:
  /// **'{s}s'**
  String lcTimeSec(int s);

  /// lcBestRun
  ///
  /// In en, this message translates to:
  /// **'Best run: {count} in a row'**
  String lcBestRun(int count);

  /// lcComboBonus
  ///
  /// In en, this message translates to:
  /// **'Combo bonus +{xp} XP'**
  String lcComboBonus(int xp);

  /// lcContinue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get lcContinue;

  /// lcShare
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get lcShare;

  /// lcContinueA11y
  ///
  /// In en, this message translates to:
  /// **'Continue to next lesson'**
  String get lcContinueA11y;

  /// lcShareA11y
  ///
  /// In en, this message translates to:
  /// **'Share your result'**
  String get lcShareA11y;

  /// lcOffline
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your progress is saved on this phone, and sharing will be back when you reconnect.'**
  String get lcOffline;

  /// lcSummaryA11y
  ///
  /// In en, this message translates to:
  /// **'Lesson complete. {xp} XP earned. Accuracy {accuracy}. Time {time}.'**
  String lcSummaryA11y(int xp, String accuracy, String time);

  /// lcHeroA11y
  ///
  /// In en, this message translates to:
  /// **'Amara and Kofi cheering'**
  String get lcHeroA11y;

  /// profOverview
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get profOverview;

  /// profAccount
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profAccount;

  /// profWallet
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get profWallet;

  /// profStreakDays
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String profStreakDays(num count);

  /// profStreakLabel
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get profStreakLabel;

  /// profStreakZero
  ///
  /// In en, this message translates to:
  /// **'Start today'**
  String get profStreakZero;

  /// profXpValue
  ///
  /// In en, this message translates to:
  /// **'{count} XP'**
  String profXpValue(int count);

  /// profXpLabel
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get profXpLabel;

  /// profRankValue
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String profRankValue(int rank);

  /// profRankLabel
  ///
  /// In en, this message translates to:
  /// **'Global rank'**
  String get profRankLabel;

  /// profRankNone
  ///
  /// In en, this message translates to:
  /// **'Not ranked yet'**
  String get profRankNone;

  /// profLevelLabel
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get profLevelLabel;

  /// profLevelNone
  ///
  /// In en, this message translates to:
  /// **'Just starting'**
  String get profLevelNone;

  /// profPrivateValue
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get profPrivateValue;

  /// profPrivateHint
  ///
  /// In en, this message translates to:
  /// **'Your profile is private, so your rank stays hidden from others.'**
  String get profPrivateHint;

  /// profLearning
  ///
  /// In en, this message translates to:
  /// **'Learning {language}'**
  String profLearning(String language);

  /// profEdit
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profEdit;

  /// profChangePassword
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profChangePassword;

  /// profFeedback
  ///
  /// In en, this message translates to:
  /// **'Give us feedback'**
  String get profFeedback;

  /// profAbout
  ///
  /// In en, this message translates to:
  /// **'Who we are'**
  String get profAbout;

  /// profPolicy
  ///
  /// In en, this message translates to:
  /// **'Privacy and user policy'**
  String get profPolicy;

  /// profDelete
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get profDelete;

  /// profDeleted
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get profDeleted;

  /// profLoading
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get profLoading;

  /// profErrorTitle
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your profile'**
  String get profErrorTitle;

  /// profErrorBody
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Nothing you\'ve learned is lost.'**
  String get profErrorBody;

  /// profRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get profRetry;

  /// profOffline
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing your saved profile.'**
  String get profOffline;

  /// profNgwenya
  ///
  /// In en, this message translates to:
  /// **'Ngwenya'**
  String get profNgwenya;

  /// profCowries
  ///
  /// In en, this message translates to:
  /// **'Cowries'**
  String get profCowries;

  /// profBeads
  ///
  /// In en, this message translates to:
  /// **'Beads'**
  String get profBeads;

  /// profOpenLeaderboard
  ///
  /// In en, this message translates to:
  /// **'Open the leaderboard'**
  String get profOpenLeaderboard;

  /// pgTitle
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get pgTitle;

  /// pgThisWeek
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get pgThisWeek;

  /// pgMinutes
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String pgMinutes(int count);

  /// pgVsUp
  ///
  /// In en, this message translates to:
  /// **'{count} min more than last week'**
  String pgVsUp(int count);

  /// pgVsDown
  ///
  /// In en, this message translates to:
  /// **'{count} min less than last week'**
  String pgVsDown(int count);

  /// pgVsSame
  ///
  /// In en, this message translates to:
  /// **'Same as last week'**
  String get pgVsSame;

  /// pgWordsLearned
  ///
  /// In en, this message translates to:
  /// **'Words learned'**
  String get pgWordsLearned;

  /// pgKnownWords
  ///
  /// In en, this message translates to:
  /// **'Words you know'**
  String get pgKnownWords;

  /// pgListening
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get pgListening;

  /// pgSpeaking
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get pgSpeaking;

  /// pgHours
  ///
  /// In en, this message translates to:
  /// **'{value} h'**
  String pgHours(String value);

  /// pgDaily
  ///
  /// In en, this message translates to:
  /// **'Minutes per day'**
  String get pgDaily;

  /// pgCalendar
  ///
  /// In en, this message translates to:
  /// **'Last 4 weeks'**
  String get pgCalendar;

  /// pgActiveDays
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No active days yet} =1{1 active day} other{{count} active days}}'**
  String pgActiveDays(num count);

  /// pgActivities
  ///
  /// In en, this message translates to:
  /// **'Time by activity'**
  String get pgActivities;

  /// pgActLessons
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get pgActLessons;

  /// pgActQuizzes
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get pgActQuizzes;

  /// pgActGames
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get pgActGames;

  /// pgActChat
  ///
  /// In en, this message translates to:
  /// **'Chat practice'**
  String get pgActChat;

  /// pgActStories
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get pgActStories;

  /// pgActReading
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get pgActReading;

  /// pgActWriting
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get pgActWriting;

  /// pgActOther
  ///
  /// In en, this message translates to:
  /// **'Other practice'**
  String get pgActOther;

  /// pgOfflineCount
  ///
  /// In en, this message translates to:
  /// **'Offline days count too.'**
  String get pgOfflineCount;

  /// pgOffline
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing progress saved on this device.'**
  String get pgOffline;

  /// pgEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'Your progress starts here'**
  String get pgEmptyTitle;

  /// pgEmptyBody
  ///
  /// In en, this message translates to:
  /// **'Finish a lesson and your minutes, words and active days will appear here.'**
  String get pgEmptyBody;

  /// pgLoading
  ///
  /// In en, this message translates to:
  /// **'Loading your progress…'**
  String get pgLoading;

  /// pgErrorTitle
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your progress'**
  String get pgErrorTitle;

  /// pgErrorBody
  ///
  /// In en, this message translates to:
  /// **'Your progress is safe on this device. Try again in a moment.'**
  String get pgErrorBody;

  /// pgRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get pgRetry;

  /// pgPrivate
  ///
  /// In en, this message translates to:
  /// **'Your progress is private. Only you can see it.'**
  String get pgPrivate;

  /// pgDayA11y
  ///
  /// In en, this message translates to:
  /// **'{day}: {count} minutes'**
  String pgDayA11y(String day, int count);

  /// pgCalA11y
  ///
  /// In en, this message translates to:
  /// **'Activity calendar: {summary}'**
  String pgCalA11y(String summary);

  /// pgOverviewTitle
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get pgOverviewTitle;

  /// profTitle
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profTitle;

  /// profClose
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get profClose;

  /// profThisWeek
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get profThisWeek;

  /// profSeeProgress
  ///
  /// In en, this message translates to:
  /// **'See all progress'**
  String get profSeeProgress;

  /// profDayA11y
  ///
  /// In en, this message translates to:
  /// **'{day}: {status}'**
  String profDayA11y(String day, String status);

  /// profDayDone
  ///
  /// In en, this message translates to:
  /// **'practised'**
  String get profDayDone;

  /// profDayMissed
  ///
  /// In en, this message translates to:
  /// **'no practice'**
  String get profDayMissed;

  /// profLanguages
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profLanguages;

  /// profLangProgress
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {percent}%'**
  String profLangProgress(String level, int percent);

  /// profLangEmpty
  ///
  /// In en, this message translates to:
  /// **'Pick a language on Home to start your journey.'**
  String get profLangEmpty;

  /// profBadges
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profBadges;

  /// profBadgesCount
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} unlocked'**
  String profBadgesCount(int done, int total);

  /// profViewAll
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get profViewAll;

  /// profBadgeLocked
  ///
  /// In en, this message translates to:
  /// **'{name}, locked'**
  String profBadgeLocked(String name);

  /// profShareTitle
  ///
  /// In en, this message translates to:
  /// **'Share your progress'**
  String get profShareTitle;

  /// profShareBody
  ///
  /// In en, this message translates to:
  /// **'Send a card with your streak and XP.'**
  String get profShareBody;

  /// profShare
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get profShare;

  /// profShareText
  ///
  /// In en, this message translates to:
  /// **'I\'m learning {language} on LingAfriq: {streak}-day streak and {xp} XP!'**
  String profShareText(String language, int streak, int xp);

  /// profHelpLegal
  ///
  /// In en, this message translates to:
  /// **'Help and legal'**
  String get profHelpLegal;

  /// profAboutApp
  ///
  /// In en, this message translates to:
  /// **'About LingAfriq'**
  String get profAboutApp;

  /// profSecurity
  ///
  /// In en, this message translates to:
  /// **'Account and security'**
  String get profSecurity;

  /// Teen private badge
  ///
  /// In en, this message translates to:
  /// **'Private profile'**
  String get profTeenBadge;

  /// Teen card title
  ///
  /// In en, this message translates to:
  /// **'Your profile stays private'**
  String get profTeenTitle;

  /// Teen hidden line
  ///
  /// In en, this message translates to:
  /// **'Your rank and name are hidden from leaderboards.'**
  String get profTeenHidden;

  /// Teen no DMs
  ///
  /// In en, this message translates to:
  /// **'Adults can\'t send you direct messages.'**
  String get profTeenNoDm;

  /// Teen parent consent
  ///
  /// In en, this message translates to:
  /// **'Your account is linked to a parent or guardian, who gave consent.'**
  String get profTeenParent;

  /// Close progress
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get pgClose;

  /// Streak hero label
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get pgStreakTitle;

  /// Streak count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day streak} other{{count}-day streak}}'**
  String pgStreakDays(int count);

  /// Next milestone
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =1{1 more day to your {goal}-day goal} other{{left} more days to your {goal}-day goal}}'**
  String pgNextGoal(int left, int goal);

  /// Milestone celebration
  ///
  /// In en, this message translates to:
  /// **'Milestone! {goal} days in a row'**
  String pgMilestoneHit(int goal);

  /// No streak yet
  ///
  /// In en, this message translates to:
  /// **'Practise today to light your streak.'**
  String get pgStreakStart;

  /// Error reassurance
  ///
  /// In en, this message translates to:
  /// **'Your streak and practice days are not affected.'**
  String get pgErrorSaved;

  /// Paywall title
  ///
  /// In en, this message translates to:
  /// **'LingAfriq Plus'**
  String get subTitle;

  /// Close paywall
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get subClose;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'PLUS'**
  String get subPlusBadge;

  /// Hero headline
  ///
  /// In en, this message translates to:
  /// **'Learn faster with optional extras'**
  String get subHeadline;

  /// Free promise
  ///
  /// In en, this message translates to:
  /// **'Every lesson, game and story stays free forever. Plus only adds extras.'**
  String get subFreeForever;

  /// Offline note
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Buying needs a connection, but all your lessons still work.'**
  String get subOffline;

  /// Benefits header
  ///
  /// In en, this message translates to:
  /// **'What Plus adds'**
  String get subWhatYouGet;

  /// Benefit
  ///
  /// In en, this message translates to:
  /// **'Download every unit to learn offline'**
  String get subBenefitOffline;

  /// Benefit
  ///
  /// In en, this message translates to:
  /// **'Unlimited practice chats with your tutor'**
  String get subBenefitChat;

  /// Benefit
  ///
  /// In en, this message translates to:
  /// **'Detailed speaking and tone scores'**
  String get subBenefitSpeaking;

  /// Benefit
  ///
  /// In en, this message translates to:
  /// **'No ads, ever'**
  String get subBenefitNoAds;

  /// Current plan
  ///
  /// In en, this message translates to:
  /// **'You have {plan}. Thank you for supporting African languages!'**
  String subYouHavePlus(String plan);

  /// Plans header
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get subChoosePlan;

  /// Price error
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load store prices, so these are standard prices. The store shows the final price before you pay.'**
  String get subPriceError;

  /// Plan
  ///
  /// In en, this message translates to:
  /// **'Plus Monthly'**
  String get subPlanMonthly;

  /// Plan detail
  ///
  /// In en, this message translates to:
  /// **'Billed every month. Cancel anytime.'**
  String get subPlanMonthlyDetail;

  /// Plan
  ///
  /// In en, this message translates to:
  /// **'Plus Family'**
  String get subPlanFamily;

  /// Plan detail
  ///
  /// In en, this message translates to:
  /// **'Up to 4 learners. Billed every month.'**
  String get subPlanFamilyDetail;

  /// Plan
  ///
  /// In en, this message translates to:
  /// **'Plus Lifetime'**
  String get subPlanLifetime;

  /// Plan detail
  ///
  /// In en, this message translates to:
  /// **'Pay once. No renewals.'**
  String get subPlanLifetimeDetail;

  /// Tag
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get subMostPopular;

  /// Monthly price
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String subPerMonth(String price);

  /// One-time price
  ///
  /// In en, this message translates to:
  /// **'{price} once'**
  String subOnce(String price);

  /// Timeline header
  ///
  /// In en, this message translates to:
  /// **'How your free trial works'**
  String get subHowTrialWorks;

  /// Timeline
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get subStepToday;

  /// Timeline
  ///
  /// In en, this message translates to:
  /// **'All Plus extras unlocked.'**
  String get subStepTodayBody;

  /// Timeline day
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String subStepDay(int day);

  /// Timeline
  ///
  /// In en, this message translates to:
  /// **'We remind you before the trial ends.'**
  String get subStepRemindBody;

  /// Timeline
  ///
  /// In en, this message translates to:
  /// **'You\'re charged {price} unless you cancel before.'**
  String subStepChargeBody(String price);

  /// CTA
  ///
  /// In en, this message translates to:
  /// **'Start {days}-day free trial'**
  String subStartTrial(int days);

  /// CTA
  ///
  /// In en, this message translates to:
  /// **'Get Plus Monthly'**
  String get subGetPlus;

  /// CTA
  ///
  /// In en, this message translates to:
  /// **'Get Plus Family'**
  String get subGetFamily;

  /// CTA
  ///
  /// In en, this message translates to:
  /// **'Get Plus Lifetime'**
  String get subGetLifetime;

  /// Fine print
  ///
  /// In en, this message translates to:
  /// **'Free for {days} days, then {price}/month. Cancel anytime in your store settings.'**
  String subFineTrial(int days, String price);

  /// Fine print
  ///
  /// In en, this message translates to:
  /// **'{price}/month, renews automatically. Cancel anytime in your store settings.'**
  String subFineMonthly(String price);

  /// Fine print
  ///
  /// In en, this message translates to:
  /// **'One payment of {price}. Nothing renews.'**
  String subFineOnce(String price);

  /// Free path
  ///
  /// In en, this message translates to:
  /// **'Keep learning for free'**
  String get subKeepFree;

  /// Restore
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get subRestore;

  /// Restore ok
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get subRestored;

  /// Restore none
  ///
  /// In en, this message translates to:
  /// **'No purchases found to restore'**
  String get subRestoreNone;

  /// Loading
  ///
  /// In en, this message translates to:
  /// **'Loading plans'**
  String get subLoading;

  /// Parent gate
  ///
  /// In en, this message translates to:
  /// **'Plus needs a grown-up'**
  String get subParentTitle;

  /// Parent gate
  ///
  /// In en, this message translates to:
  /// **'Everything you\'re learning stays free. Ask a parent or guardian if you\'d like Plus extras.'**
  String get subParentBody;

  /// Parent gate button
  ///
  /// In en, this message translates to:
  /// **'A grown-up is here'**
  String get subAskParent;

  /// Gate dialog
  ///
  /// In en, this message translates to:
  /// **'For grown-ups'**
  String get subGateTitle;

  /// Gate question
  ///
  /// In en, this message translates to:
  /// **'What is {a} × {b}?'**
  String subGateQuestion(int a, int b);

  /// Gate wrong
  ///
  /// In en, this message translates to:
  /// **'That\'s not right. Try again.'**
  String get subGateWrong;

  /// Gate ok
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get subGateContinue;

  /// Gate cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get subCancel;

  /// lsTitle
  ///
  /// In en, this message translates to:
  /// **'Find a language'**
  String get lsTitle;

  /// lsAsk
  ///
  /// In en, this message translates to:
  /// **'Which language do you want to explore today?'**
  String get lsAsk;

  /// lsAskChild
  ///
  /// In en, this message translates to:
  /// **'Which language shall we play with today?'**
  String get lsAskChild;

  /// lsHint
  ///
  /// In en, this message translates to:
  /// **'Search Yoruba, Swahili, Zulu…'**
  String get lsHint;

  /// lsContinue
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get lsContinue;

  /// lsAll
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get lsAll;

  /// lsSoon
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get lsSoon;

  /// lsNew
  ///
  /// In en, this message translates to:
  /// **'Start from zero'**
  String get lsNew;

  /// lsPercent
  ///
  /// In en, this message translates to:
  /// **'{p}% done'**
  String lsPercent(int p);

  /// lsNoMatch
  ///
  /// In en, this message translates to:
  /// **'No language matches “{q}”'**
  String lsNoMatch(String q);

  /// lsNoMatchBody
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or try the language\'s own name.'**
  String get lsNoMatchBody;

  /// lsClear
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get lsClear;

  /// lsEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No languages yet'**
  String get lsEmptyTitle;

  /// lsEmptyBody
  ///
  /// In en, this message translates to:
  /// **'New courses are on the way. Check back soon.'**
  String get lsEmptyBody;

  /// lsOfflineTitle
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get lsOfflineTitle;

  /// lsOfflineBody
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to see every language.'**
  String get lsOfflineBody;

  /// lsErrorTitle
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load languages'**
  String get lsErrorTitle;

  /// lsErrorBody
  ///
  /// In en, this message translates to:
  /// **'Your progress is safe. Try again in a moment.'**
  String get lsErrorBody;

  /// lsRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get lsRetry;

  /// lsBack
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get lsBack;

  /// lsLoading
  ///
  /// In en, this message translates to:
  /// **'Loading languages'**
  String get lsLoading;

  /// lbTitle
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get lbTitle;

  /// lbBack
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get lbBack;

  /// lbGlobal
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get lbGlobal;

  /// lbTribe
  ///
  /// In en, this message translates to:
  /// **'My tribe'**
  String get lbTribe;

  /// lbCountry
  ///
  /// In en, this message translates to:
  /// **'My country'**
  String get lbCountry;

  /// lbWeek
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get lbWeek;

  /// lbLeader
  ///
  /// In en, this message translates to:
  /// **'Top of the week'**
  String get lbLeader;

  /// lbColRank
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get lbColRank;

  /// lbColLearner
  ///
  /// In en, this message translates to:
  /// **'LEARNER'**
  String get lbColLearner;

  /// lbColXp
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get lbColXp;

  /// lbXp
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String lbXp(int xp);

  /// lbStreak
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String lbStreak(int days);

  /// lbUp
  ///
  /// In en, this message translates to:
  /// **'Up {n} places'**
  String lbUp(int n);

  /// lbDown
  ///
  /// In en, this message translates to:
  /// **'Down {n} places'**
  String lbDown(int n);

  /// lbRankN
  ///
  /// In en, this message translates to:
  /// **'Rank {n}'**
  String lbRankN(int n);

  /// lbYou
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get lbYou;

  /// lbYourRank
  ///
  /// In en, this message translates to:
  /// **'Your rank: #{n}'**
  String lbYourRank(int n);

  /// lbUnranked
  ///
  /// In en, this message translates to:
  /// **'Finish a lesson to join this week\'s board'**
  String get lbUnranked;

  /// lbFriendly
  ///
  /// In en, this message translates to:
  /// **'Everyone starts fresh each Monday. Practice is what counts, not speed.'**
  String get lbFriendly;

  /// lbLearner
  ///
  /// In en, this message translates to:
  /// **'Learner {n}'**
  String lbLearner(int n);

  /// lbMinorTeen
  ///
  /// In en, this message translates to:
  /// **'Your profile is private: others see you as \"Learner\", never your name.'**
  String get lbMinorTeen;

  /// lbMinorChild
  ///
  /// In en, this message translates to:
  /// **'Names are hidden to keep everyone safe. You can still see how you\'re doing!'**
  String get lbMinorChild;

  /// lbNoTribeTitle
  ///
  /// In en, this message translates to:
  /// **'Pick a tribe first'**
  String get lbNoTribeTitle;

  /// lbNoTribeBody
  ///
  /// In en, this message translates to:
  /// **'Join a tribe to see how your group is doing this week.'**
  String get lbNoTribeBody;

  /// lbPickTribe
  ///
  /// In en, this message translates to:
  /// **'Choose a tribe'**
  String get lbPickTribe;

  /// lbNoCountryTitle
  ///
  /// In en, this message translates to:
  /// **'Add your country'**
  String get lbNoCountryTitle;

  /// lbNoCountryBody
  ///
  /// In en, this message translates to:
  /// **'Set your country in your profile to see learners near you.'**
  String get lbNoCountryBody;

  /// lbEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No rankings yet this week'**
  String get lbEmptyTitle;

  /// lbEmptyBody
  ///
  /// In en, this message translates to:
  /// **'Finish a lesson and you could be first on the board.'**
  String get lbEmptyBody;

  /// lbErrorTitle
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the board'**
  String get lbErrorTitle;

  /// lbErrorBody
  ///
  /// In en, this message translates to:
  /// **'Your XP is safe. Try again in a moment.'**
  String get lbErrorBody;

  /// lbOfflineTitle
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get lbOfflineTitle;

  /// lbOfflineBody
  ///
  /// In en, this message translates to:
  /// **'Rankings update when you\'re back online. Lessons you finish offline still count.'**
  String get lbOfflineBody;

  /// lbRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get lbRetry;

  /// lbLoading
  ///
  /// In en, this message translates to:
  /// **'Loading leaderboard'**
  String get lbLoading;

  /// lbMore
  ///
  /// In en, this message translates to:
  /// **'Loading more'**
  String get lbMore;

  /// rmTitle
  ///
  /// In en, this message translates to:
  /// **'Study reminders'**
  String get rmTitle;

  /// rmBack
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get rmBack;

  /// rmPreviewApp
  ///
  /// In en, this message translates to:
  /// **'LingAfriq · now'**
  String get rmPreviewApp;

  /// rmPreviewBody
  ///
  /// In en, this message translates to:
  /// **'Ẹ kú àárọ̀! 5 minutes of Yoruba?'**
  String get rmPreviewBody;

  /// rmPreviewOff
  ///
  /// In en, this message translates to:
  /// **'Reminders are off. Turn them on to get one gentle nudge a day.'**
  String get rmPreviewOff;

  /// rmMaster
  ///
  /// In en, this message translates to:
  /// **'Daily practice nudge'**
  String get rmMaster;

  /// rmMasterSub
  ///
  /// In en, this message translates to:
  /// **'At most one a day, never at night.'**
  String get rmMasterSub;

  /// rmWhen
  ///
  /// In en, this message translates to:
  /// **'When should we remind you?'**
  String get rmWhen;

  /// rmMorning
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get rmMorning;

  /// rmLunch
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get rmLunch;

  /// rmEvening
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get rmEvening;

  /// rmCustom
  ///
  /// In en, this message translates to:
  /// **'Other time'**
  String get rmCustom;

  /// rmQuiet
  ///
  /// In en, this message translates to:
  /// **'We never send anything in quiet hours ({start}–{end}).'**
  String rmQuiet(String start, String end);

  /// rmQuietClash
  ///
  /// In en, this message translates to:
  /// **'That\'s in quiet hours, so we set it to {time}.'**
  String rmQuietClash(String time);

  /// rmTimezone
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get rmTimezone;

  /// rmUseDevice
  ///
  /// In en, this message translates to:
  /// **'Use this phone\'s'**
  String get rmUseDevice;

  /// rmAbout
  ///
  /// In en, this message translates to:
  /// **'What we remind you about'**
  String get rmAbout;

  /// rmGoal
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get rmGoal;

  /// rmGoalSub
  ///
  /// In en, this message translates to:
  /// **'A warm nudge to finish today\'s goal.'**
  String get rmGoalSub;

  /// rmRhythm
  ///
  /// In en, this message translates to:
  /// **'Practice milestones'**
  String get rmRhythm;

  /// rmRhythmSub
  ///
  /// In en, this message translates to:
  /// **'We celebrate milestones. We never guilt you.'**
  String get rmRhythmSub;

  /// rmSync
  ///
  /// In en, this message translates to:
  /// **'Saved to your account, so it comes back after reinstalling.'**
  String get rmSync;

  /// rmBlockedTitle
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get rmBlockedTitle;

  /// rmBlockedBody
  ///
  /// In en, this message translates to:
  /// **'Your phone is blocking LingAfriq. Allow notifications in Settings to get reminders.'**
  String get rmBlockedBody;

  /// rmOpenSettings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get rmOpenSettings;

  /// rmOffline
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes are saved on this phone and sync later.'**
  String get rmOffline;

  /// rmCheckError
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check notification permission.'**
  String get rmCheckError;

  /// rmRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get rmRetry;

  /// rmLoading
  ///
  /// In en, this message translates to:
  /// **'Checking notification settings'**
  String get rmLoading;

  /// rmChild
  ///
  /// In en, this message translates to:
  /// **'Reminders for young learners never arrive at night, and a grown-up can turn them off any time.'**
  String get rmChild;

  /// rmMasterA11y
  ///
  /// In en, this message translates to:
  /// **'Study reminders master switch'**
  String get rmMasterA11y;

  /// gmTitle
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gmTitle;

  /// gmBack
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get gmBack;

  /// gmWelcome
  ///
  /// In en, this message translates to:
  /// **'Welcome to your place to play.'**
  String get gmWelcome;

  /// gmWelcomeSub
  ///
  /// In en, this message translates to:
  /// **'Every game practises {language}.'**
  String gmWelcomeSub(String language);

  /// gmLanguage
  ///
  /// In en, this message translates to:
  /// **'Practice language'**
  String get gmLanguage;

  /// gmFeatured
  ///
  /// In en, this message translates to:
  /// **'Today\'s pick'**
  String get gmFeatured;

  /// gmPlay
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get gmPlay;

  /// gmCore
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get gmCore;

  /// gmCultural
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get gmCultural;

  /// gmCount
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 game} other{{count} games}}'**
  String gmCount(int count);

  /// gmCatAll
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gmCatAll;

  /// gmCatVocabulary
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get gmCatVocabulary;

  /// gmCatGrammar
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get gmCatGrammar;

  /// gmCatPronunciation
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get gmCatPronunciation;

  /// gmCatCultural
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get gmCatCultural;

  /// gmCatTraditional
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get gmCatTraditional;

  /// gmEmpty
  ///
  /// In en, this message translates to:
  /// **'No games here yet.'**
  String get gmEmpty;

  /// gmShowAll
  ///
  /// In en, this message translates to:
  /// **'Show all games'**
  String get gmShowAll;

  /// gmOffline
  ///
  /// In en, this message translates to:
  /// **'You\'re offline, so these are the games saved on this phone.'**
  String get gmOffline;

  /// gmSyncing
  ///
  /// In en, this message translates to:
  /// **'Checking for new games'**
  String get gmSyncing;

  /// gmOpening
  ///
  /// In en, this message translates to:
  /// **'Opening game…'**
  String get gmOpening;

  /// gmLoadError
  ///
  /// In en, this message translates to:
  /// **'This game could not load.'**
  String get gmLoadError;

  /// gmRule1
  ///
  /// In en, this message translates to:
  /// **'Learn and have fun with this game mode.'**
  String get gmRule1;

  /// gmRule2
  ///
  /// In en, this message translates to:
  /// **'Focus on accuracy first, then speed.'**
  String get gmRule2;

  /// gmPlayA11y
  ///
  /// In en, this message translates to:
  /// **'{name}, {category}. {description}'**
  String gmPlayA11y(String name, String category, String description);

  /// peTitle
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get peTitle;

  /// peBack
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get peBack;

  /// peAvatarEdit
  ///
  /// In en, this message translates to:
  /// **'Edit avatar'**
  String get peAvatarEdit;

  /// peAvatarHint
  ///
  /// In en, this message translates to:
  /// **'Make your avatar look like you, or not at all.'**
  String get peAvatarHint;

  /// peAbout
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get peAbout;

  /// peFirst
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get peFirst;

  /// peLast
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get peLast;

  /// peRequired
  ///
  /// In en, this message translates to:
  /// **'Please add your {field}.'**
  String peRequired(String field);

  /// peHandle
  ///
  /// In en, this message translates to:
  /// **'Handle'**
  String get peHandle;

  /// peHandleNone
  ///
  /// In en, this message translates to:
  /// **'Pick a handle so friends can find you'**
  String get peHandleNone;

  /// peHandleEdit
  ///
  /// In en, this message translates to:
  /// **'Change handle'**
  String get peHandleEdit;

  /// peCountry
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get peCountry;

  /// peCountryLocked
  ///
  /// In en, this message translates to:
  /// **'Set when you signed up. Contact support to change it.'**
  String get peCountryLocked;

  /// peEmail
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get peEmail;

  /// peSave
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get peSave;

  /// peSaving
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get peSaving;

  /// peSaved
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get peSaved;

  /// peSaveError
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save. Your changes are still here, so try again.'**
  String get peSaveError;

  /// peMinorTip
  ///
  /// In en, this message translates to:
  /// **'Tip: use a nickname for your handle, not your full name.'**
  String get peMinorTip;

  /// peDanger
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get peDanger;

  /// peDelete
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get peDelete;

  /// peDeleteSub
  ///
  /// In en, this message translates to:
  /// **'Permanently removes your progress. This can\'t be undone.'**
  String get peDeleteSub;

  /// peDeleteError
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Please try again.'**
  String get peDeleteError;

  /// peLoading
  ///
  /// In en, this message translates to:
  /// **'Loading your profile'**
  String get peLoading;
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
