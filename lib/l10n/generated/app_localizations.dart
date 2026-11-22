// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment
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
  /// **'{days, plural, other{Start {days}-day free trial}}'**
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
  /// **'{days, plural, =1{Free for 1 day, then {price}/month. Cancel anytime in your store settings.} other{Free for {days} days, then {price}/month. Cancel anytime in your store settings.}}'**
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
  /// **'{days, plural, =1{1-day streak} other{{days}-day streak}}'**
  String lbStreak(int days);

  /// lbUp
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Up 1 place} other{Up {n} places}}'**
  String lbUp(int n);

  /// lbDown
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Down 1 place} other{Down {n} places}}'**
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

  /// dgTitle
  ///
  /// In en, this message translates to:
  /// **'Daily goals'**
  String get dgTitle;

  /// dgStreak
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1-day streak} other{{n}-day streak}}'**
  String dgStreak(int n);

  /// dgStreakOn
  ///
  /// In en, this message translates to:
  /// **'Keep it going — practise today to add a day.'**
  String get dgStreakOn;

  /// dgStreakZero
  ///
  /// In en, this message translates to:
  /// **'Finish one goal today to start a streak.'**
  String get dgStreakZero;

  /// dgRing
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{{done} of 1 goal done} other{{done} of {total} goals done}}'**
  String dgRing(int done, int total);

  /// dgToday
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dgToday;

  /// dgLessons
  ///
  /// In en, this message translates to:
  /// **'Complete lessons'**
  String get dgLessons;

  /// dgQuizzes
  ///
  /// In en, this message translates to:
  /// **'Take quizzes'**
  String get dgQuizzes;

  /// dgGames
  ///
  /// In en, this message translates to:
  /// **'Play games'**
  String get dgGames;

  /// dgChat
  ///
  /// In en, this message translates to:
  /// **'Chat with Polie'**
  String get dgChat;

  /// dgWords
  ///
  /// In en, this message translates to:
  /// **'Learn words'**
  String get dgWords;

  /// dgGoal
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get dgGoal;

  /// dgCount
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String dgCount(int current, int target);

  /// dgMinutes
  ///
  /// In en, this message translates to:
  /// **'{target, plural, =1{{current} of 1 min} other{{current} of {target} min}}'**
  String dgMinutes(int current, int target);

  /// dgDone
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dgDone;

  /// dgStart
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get dgStart;

  /// dgAllDone
  ///
  /// In en, this message translates to:
  /// **'All of today\'s goals are done. See you tomorrow!'**
  String get dgAllDone;

  /// dgEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No goals yet today'**
  String get dgEmptyTitle;

  /// dgEmptyBody
  ///
  /// In en, this message translates to:
  /// **'Pull down or tap refresh to set today\'s goals.'**
  String get dgEmptyBody;

  /// dgRefresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get dgRefresh;

  /// dgSyncing
  ///
  /// In en, this message translates to:
  /// **'Syncing your progress…'**
  String get dgSyncing;

  /// dgError
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync goals. Showing progress saved on this device.'**
  String get dgError;

  /// dgRetry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dgRetry;

  /// dgPickLessons
  ///
  /// In en, this message translates to:
  /// **'Choose a language for lessons'**
  String get dgPickLessons;

  /// dgPickQuiz
  ///
  /// In en, this message translates to:
  /// **'Choose a language for the quiz'**
  String get dgPickQuiz;

  /// dgLangError
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load languages.'**
  String get dgLangError;

  /// dgGoalA11y
  ///
  /// In en, this message translates to:
  /// **'{title}, {progress}, {status}'**
  String dgGoalA11y(String title, String progress, String status);

  /// gmNameWordMatchAudio
  ///
  /// In en, this message translates to:
  /// **'Word Match Audio'**
  String get gmNameWordMatchAudio;

  /// gmDescWordMatchAudio
  ///
  /// In en, this message translates to:
  /// **'Match words with audio'**
  String get gmDescWordMatchAudio;

  /// gmNamePronunciationDuel
  ///
  /// In en, this message translates to:
  /// **'Pronunciation Duel'**
  String get gmNamePronunciationDuel;

  /// gmDescPronunciationDuel
  ///
  /// In en, this message translates to:
  /// **'Master pronunciation'**
  String get gmDescPronunciationDuel;

  /// gmNameSpeedRoundRemix
  ///
  /// In en, this message translates to:
  /// **'Speed Round'**
  String get gmNameSpeedRoundRemix;

  /// gmDescSpeedRoundRemix
  ///
  /// In en, this message translates to:
  /// **'Fast-paced vocabulary'**
  String get gmDescSpeedRoundRemix;

  /// gmNameStoryBuilder
  ///
  /// In en, this message translates to:
  /// **'Story Builder'**
  String get gmNameStoryBuilder;

  /// gmDescStoryBuilder
  ///
  /// In en, this message translates to:
  /// **'Build stories'**
  String get gmDescStoryBuilder;

  /// gmNameRoleplayAdventure
  ///
  /// In en, this message translates to:
  /// **'Roleplay Adventure'**
  String get gmNameRoleplayAdventure;

  /// gmDescRoleplayAdventure
  ///
  /// In en, this message translates to:
  /// **'Interactive conversations'**
  String get gmDescRoleplayAdventure;

  /// gmNameGrammarDetective
  ///
  /// In en, this message translates to:
  /// **'Grammar Detective'**
  String get gmNameGrammarDetective;

  /// gmDescGrammarDetective
  ///
  /// In en, this message translates to:
  /// **'Solve grammar mysteries'**
  String get gmDescGrammarDetective;

  /// gmNameListenAndSketch
  ///
  /// In en, this message translates to:
  /// **'Listen & Sketch'**
  String get gmNameListenAndSketch;

  /// gmDescListenAndSketch
  ///
  /// In en, this message translates to:
  /// **'Draw what you hear'**
  String get gmDescListenAndSketch;

  /// gmNamePictureWordAssociation
  ///
  /// In en, this message translates to:
  /// **'Picture Word Match'**
  String get gmNamePictureWordAssociation;

  /// gmDescPictureWordAssociation
  ///
  /// In en, this message translates to:
  /// **'Match words with images'**
  String get gmDescPictureWordAssociation;

  /// gmNameMemoryMap
  ///
  /// In en, this message translates to:
  /// **'Memory Map'**
  String get gmNameMemoryMap;

  /// gmDescMemoryMap
  ///
  /// In en, this message translates to:
  /// **'Memory challenge'**
  String get gmDescMemoryMap;

  /// gmNameConversationRelay
  ///
  /// In en, this message translates to:
  /// **'Conversation Relay'**
  String get gmNameConversationRelay;

  /// gmDescConversationRelay
  ///
  /// In en, this message translates to:
  /// **'Chain conversations'**
  String get gmDescConversationRelay;

  /// gmNameGrammarJam
  ///
  /// In en, this message translates to:
  /// **'Grammar Jam'**
  String get gmNameGrammarJam;

  /// gmDescGrammarJam
  ///
  /// In en, this message translates to:
  /// **'Grammar rhythm game'**
  String get gmDescGrammarJam;

  /// gmNamePronunciationKaraoke
  ///
  /// In en, this message translates to:
  /// **'Pronunciation Karaoke'**
  String get gmNamePronunciationKaraoke;

  /// gmDescPronunciationKaraoke
  ///
  /// In en, this message translates to:
  /// **'Sing and pronounce'**
  String get gmDescPronunciationKaraoke;

  /// gmNameQuizChef
  ///
  /// In en, this message translates to:
  /// **'Quiz Chef'**
  String get gmNameQuizChef;

  /// gmDescQuizChef
  ///
  /// In en, this message translates to:
  /// **'Cook up answers'**
  String get gmDescQuizChef;

  /// gmNameToneTrainer
  ///
  /// In en, this message translates to:
  /// **'Tone Trainer'**
  String get gmNameToneTrainer;

  /// gmDescToneTrainer
  ///
  /// In en, this message translates to:
  /// **'Master tonal pronunciation'**
  String get gmDescToneTrainer;

  /// gmNameScrabbleSprintArena
  ///
  /// In en, this message translates to:
  /// **'Scrabble Sprint'**
  String get gmNameScrabbleSprintArena;

  /// gmDescScrabbleSprintArena
  ///
  /// In en, this message translates to:
  /// **'Build words under pressure'**
  String get gmDescScrabbleSprintArena;

  /// gmNameProverbUnlocker
  ///
  /// In en, this message translates to:
  /// **'Proverb Unlocker'**
  String get gmNameProverbUnlocker;

  /// gmDescProverbUnlocker
  ///
  /// In en, this message translates to:
  /// **'Unlock wisdom'**
  String get gmDescProverbUnlocker;

  /// gmNameDrumRhythmShadowing
  ///
  /// In en, this message translates to:
  /// **'Drum Rhythm'**
  String get gmNameDrumRhythmShadowing;

  /// gmDescDrumRhythmShadowing
  ///
  /// In en, this message translates to:
  /// **'Follow the rhythm'**
  String get gmDescDrumRhythmShadowing;

  /// gmNameClanLineageStoryBuilder
  ///
  /// In en, this message translates to:
  /// **'Clan Story Builder'**
  String get gmNameClanLineageStoryBuilder;

  /// gmDescClanLineageStoryBuilder
  ///
  /// In en, this message translates to:
  /// **'Build clan stories'**
  String get gmDescClanLineageStoryBuilder;

  /// gmNameMarketBargainingSimulator
  ///
  /// In en, this message translates to:
  /// **'Market Bargaining'**
  String get gmNameMarketBargainingSimulator;

  /// gmDescMarketBargainingSimulator
  ///
  /// In en, this message translates to:
  /// **'Practice bargaining'**
  String get gmDescMarketBargainingSimulator;

  /// gmNameTaxiBusStopSurvival
  ///
  /// In en, this message translates to:
  /// **'Taxi Survival'**
  String get gmNameTaxiBusStopSurvival;

  /// gmDescTaxiBusStopSurvival
  ///
  /// In en, this message translates to:
  /// **'Navigate transportation'**
  String get gmDescTaxiBusStopSurvival;

  /// gmNameFoodQuest
  ///
  /// In en, this message translates to:
  /// **'Food Quest'**
  String get gmNameFoodQuest;

  /// gmDescFoodQuest
  ///
  /// In en, this message translates to:
  /// **'Explore cuisine'**
  String get gmDescFoodQuest;

  /// gmNameCallAndResponse
  ///
  /// In en, this message translates to:
  /// **'Call & Response'**
  String get gmNameCallAndResponse;

  /// gmDescCallAndResponse
  ///
  /// In en, this message translates to:
  /// **'Traditional patterns'**
  String get gmDescCallAndResponse;

  /// gmNameGreetingDiplomacyChallenge
  ///
  /// In en, this message translates to:
  /// **'Greeting Diplomacy'**
  String get gmNameGreetingDiplomacyChallenge;

  /// gmDescGreetingDiplomacyChallenge
  ///
  /// In en, this message translates to:
  /// **'Master greetings'**
  String get gmDescGreetingDiplomacyChallenge;

  /// gmNameFolktaleReconstruction
  ///
  /// In en, this message translates to:
  /// **'Folktale Builder'**
  String get gmNameFolktaleReconstruction;

  /// gmDescFolktaleReconstruction
  ///
  /// In en, this message translates to:
  /// **'Rebuild stories'**
  String get gmDescFolktaleReconstruction;

  /// gmNamePhraseSniper
  ///
  /// In en, this message translates to:
  /// **'Phrase Sniper'**
  String get gmNamePhraseSniper;

  /// gmDescPhraseSniper
  ///
  /// In en, this message translates to:
  /// **'Target phrases'**
  String get gmDescPhraseSniper;

  /// gmNameLiarLiar
  ///
  /// In en, this message translates to:
  /// **'Liar Liar'**
  String get gmNameLiarLiar;

  /// gmDescLiarLiar
  ///
  /// In en, this message translates to:
  /// **'Detect truth'**
  String get gmDescLiarLiar;

  /// gmNameVillageQuest
  ///
  /// In en, this message translates to:
  /// **'Village Quest'**
  String get gmNameVillageQuest;

  /// gmDescVillageQuest
  ///
  /// In en, this message translates to:
  /// **'Adventure quest'**
  String get gmDescVillageQuest;

  /// gmNameAccentDecodingPuzzle
  ///
  /// In en, this message translates to:
  /// **'Accent Puzzle'**
  String get gmNameAccentDecodingPuzzle;

  /// gmDescAccentDecodingPuzzle
  ///
  /// In en, this message translates to:
  /// **'Decode accents'**
  String get gmDescAccentDecodingPuzzle;

  /// gmNameFlashcardSafari
  ///
  /// In en, this message translates to:
  /// **'Flashcard Safari'**
  String get gmNameFlashcardSafari;

  /// gmDescFlashcardSafari
  ///
  /// In en, this message translates to:
  /// **'Safari vocabulary'**
  String get gmDescFlashcardSafari;

  /// gmNameRapidTongueTwisterRace
  ///
  /// In en, this message translates to:
  /// **'Tongue Twister'**
  String get gmNameRapidTongueTwisterRace;

  /// gmDescRapidTongueTwisterRace
  ///
  /// In en, this message translates to:
  /// **'Master twisters'**
  String get gmDescRapidTongueTwisterRace;

  /// gmNameEmojiTranslator
  ///
  /// In en, this message translates to:
  /// **'Emoji Translator'**
  String get gmNameEmojiTranslator;

  /// gmDescEmojiTranslator
  ///
  /// In en, this message translates to:
  /// **'Translate emojis'**
  String get gmDescEmojiTranslator;

  /// gmNameRhythmTyping
  ///
  /// In en, this message translates to:
  /// **'Rhythm Typing'**
  String get gmNameRhythmTyping;

  /// gmDescRhythmTyping
  ///
  /// In en, this message translates to:
  /// **'Type to rhythm'**
  String get gmDescRhythmTyping;

  /// gmNameEldersBlessingsChallenge
  ///
  /// In en, this message translates to:
  /// **'Elders Blessings'**
  String get gmNameEldersBlessingsChallenge;

  /// gmDescEldersBlessingsChallenge
  ///
  /// In en, this message translates to:
  /// **'Learn blessings'**
  String get gmDescEldersBlessingsChallenge;

  /// gmNameMultilingualRelayRace
  ///
  /// In en, this message translates to:
  /// **'Multilingual Relay'**
  String get gmNameMultilingualRelayRace;

  /// gmDescMultilingualRelayRace
  ///
  /// In en, this message translates to:
  /// **'Language relay'**
  String get gmDescMultilingualRelayRace;

  /// gmNameCulturalEtiquetteScenarios
  ///
  /// In en, this message translates to:
  /// **'Cultural Etiquette'**
  String get gmNameCulturalEtiquetteScenarios;

  /// gmDescCulturalEtiquetteScenarios
  ///
  /// In en, this message translates to:
  /// **'Learn etiquette'**
  String get gmDescCulturalEtiquetteScenarios;

  /// gmNameDrumToWordMatching
  ///
  /// In en, this message translates to:
  /// **'Drum Word Match'**
  String get gmNameDrumToWordMatching;

  /// gmDescDrumToWordMatching
  ///
  /// In en, this message translates to:
  /// **'Match drum patterns'**
  String get gmDescDrumToWordMatching;

  /// gmNameMarketMonopolyChallenge
  ///
  /// In en, this message translates to:
  /// **'Market Monopoly'**
  String get gmNameMarketMonopolyChallenge;

  /// gmDescMarketMonopolyChallenge
  ///
  /// In en, this message translates to:
  /// **'Strategic market negotiations'**
  String get gmDescMarketMonopolyChallenge;

  /// gmNameAyoMancala
  ///
  /// In en, this message translates to:
  /// **'Ayo (Mancala)'**
  String get gmNameAyoMancala;

  /// gmDescAyoMancala
  ///
  /// In en, this message translates to:
  /// **'Traditional board game with vocab triggers'**
  String get gmDescAyoMancala;

  /// gmNameSuweHopscotch
  ///
  /// In en, this message translates to:
  /// **'Suwe (Hopscotch)'**
  String get gmNameSuweHopscotch;

  /// gmDescSuweHopscotch
  ///
  /// In en, this message translates to:
  /// **'Stone toss and tone patterns on the grid'**
  String get gmDescSuweHopscotch;

  /// gmNameLudoLanguage
  ///
  /// In en, this message translates to:
  /// **'Language Ludo'**
  String get gmNameLudoLanguage;

  /// gmDescLudoLanguage
  ///
  /// In en, this message translates to:
  /// **'African Ludo with MCQ-gated moves'**
  String get gmDescLudoLanguage;

  /// gmNameSnakesAndLaddersCultural
  ///
  /// In en, this message translates to:
  /// **'Snakes & Ladders (Cultural)'**
  String get gmNameSnakesAndLaddersCultural;

  /// gmDescSnakesAndLaddersCultural
  ///
  /// In en, this message translates to:
  /// **'Proverb ladders and mistake-correction snakes'**
  String get gmDescSnakesAndLaddersCultural;

  /// gmNameWhotCardGame
  ///
  /// In en, this message translates to:
  /// **'Whot (Nigerian Cards)'**
  String get gmNameWhotCardGame;

  /// gmDescWhotCardGame
  ///
  /// In en, this message translates to:
  /// **'Full Whot rules with vocab per card'**
  String get gmDescWhotCardGame;

  /// gcTitle
  ///
  /// In en, this message translates to:
  /// **'Global chat'**
  String get gcTitle;

  /// gcChannelGeneral
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get gcChannelGeneral;

  /// gcChannels
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get gcChannels;

  /// gcSwitchChannel
  ///
  /// In en, this message translates to:
  /// **'Switch channel'**
  String get gcSwitchChannel;

  /// gcRefresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get gcRefresh;

  /// gcFindUser
  ///
  /// In en, this message translates to:
  /// **'Find someone'**
  String get gcFindUser;

  /// gcMore
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get gcMore;

  /// gcGuidelines
  ///
  /// In en, this message translates to:
  /// **'Community guidelines'**
  String get gcGuidelines;

  /// gcMutedBlocked
  ///
  /// In en, this message translates to:
  /// **'Muted and blocked'**
  String get gcMutedBlocked;

  /// gcPolieTitle
  ///
  /// In en, this message translates to:
  /// **'Practise privately with Polie (AI)'**
  String get gcPolieTitle;

  /// gcPolieSub
  ///
  /// In en, this message translates to:
  /// **'Your turns are not posted to channels'**
  String get gcPolieSub;

  /// gcEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get gcEmptyTitle;

  /// gcEmptyBody
  ///
  /// In en, this message translates to:
  /// **'Say hello and start the conversation.'**
  String get gcEmptyBody;

  /// gcSayHello
  ///
  /// In en, this message translates to:
  /// **'Say hello'**
  String get gcSayHello;

  /// gcHelloText
  ///
  /// In en, this message translates to:
  /// **'Hello everyone! Excited to learn together.'**
  String get gcHelloText;

  /// gcErrorTitle
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load messages'**
  String get gcErrorTitle;

  /// gcErrorBody
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get gcErrorBody;

  /// gcRetry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get gcRetry;

  /// gcOffline
  ///
  /// In en, this message translates to:
  /// **'Offline · showing saved messages'**
  String get gcOffline;

  /// gcHidden
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 message hidden from muted or blocked people} other{{n} messages hidden from muted or blocked people}}'**
  String gcHidden(int n);

  /// gcManage
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get gcManage;

  /// gcHint
  ///
  /// In en, this message translates to:
  /// **'Write a message… (@Polie for help)'**
  String get gcHint;

  /// gcSend
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get gcSend;

  /// gcSending
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get gcSending;

  /// gcYou
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get gcYou;

  /// gcNow
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get gcNow;

  /// gcMinAgo
  ///
  /// In en, this message translates to:
  /// **'{n, plural, other{{n} min}}'**
  String gcMinAgo(int n);

  /// gcHourAgo
  ///
  /// In en, this message translates to:
  /// **'{n, plural, other{{n} h}}'**
  String gcHourAgo(int n);

  /// gcFlagged
  ///
  /// In en, this message translates to:
  /// **'Hidden by moderation'**
  String get gcFlagged;

  /// gcShow
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get gcShow;

  /// gcSendFailed
  ///
  /// In en, this message translates to:
  /// **'Message not sent. Check your connection.'**
  String get gcSendFailed;

  /// gcPolieBusy
  ///
  /// In en, this message translates to:
  /// **'Too many @Polie requests. Try again in about a minute.'**
  String get gcPolieBusy;

  /// gcSignIn
  ///
  /// In en, this message translates to:
  /// **'Sign in to send messages.'**
  String get gcSignIn;

  /// gcActionsFor
  ///
  /// In en, this message translates to:
  /// **'Message from {name}'**
  String gcActionsFor(String name);

  /// gcMute
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get gcMute;

  /// gcMuteSub
  ///
  /// In en, this message translates to:
  /// **'Hide their messages on this device. They aren’t told.'**
  String get gcMuteSub;

  /// gcUnmute
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get gcUnmute;

  /// gcReport
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get gcReport;

  /// gcReportSub
  ///
  /// In en, this message translates to:
  /// **'Our moderators review every report.'**
  String get gcReportSub;

  /// gcBlock
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get gcBlock;

  /// gcBlockSub
  ///
  /// In en, this message translates to:
  /// **'Stop seeing their messages and snaps everywhere.'**
  String get gcBlockSub;

  /// gcBlockConfirm
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String gcBlockConfirm(String name);

  /// gcBlockConfirmBody
  ///
  /// In en, this message translates to:
  /// **'You won’t see their new messages or snaps. You can unblock later.'**
  String get gcBlockConfirmBody;

  /// gcCancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gcCancel;

  /// gcReasonTitle
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get gcReasonTitle;

  /// gcReasonHarassment
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get gcReasonHarassment;

  /// gcReasonSpam
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get gcReasonSpam;

  /// gcReasonHate
  ///
  /// In en, this message translates to:
  /// **'Hate speech'**
  String get gcReasonHate;

  /// gcReasonOther
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get gcReasonOther;

  /// gcReportSent
  ///
  /// In en, this message translates to:
  /// **'Report sent. Reference {ref}'**
  String gcReportSent(String ref);

  /// gcReportFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send the report. Try again.'**
  String get gcReportFailed;

  /// gcBlockedNote
  ///
  /// In en, this message translates to:
  /// **'{name} is blocked'**
  String gcBlockedNote(String name);

  /// gcBlockFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn’t block. Try again.'**
  String get gcBlockFailed;

  /// gcMutedNote
  ///
  /// In en, this message translates to:
  /// **'{name} is muted'**
  String gcMutedNote(String name);

  /// gcMutedTitle
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get gcMutedTitle;

  /// gcBlockedTitle
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get gcBlockedTitle;

  /// gcNobody
  ///
  /// In en, this message translates to:
  /// **'Nobody here'**
  String get gcNobody;

  /// gcUnblock
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get gcUnblock;

  /// gcProfileUnavailable
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable for this message.'**
  String get gcProfileUnavailable;

  /// gcLockedTeenTitle
  ///
  /// In en, this message translates to:
  /// **'Global chat opens at 18'**
  String get gcLockedTeenTitle;

  /// gcLockedTeenBody
  ///
  /// In en, this message translates to:
  /// **'To keep you safe, open chat with strangers is for adults. You can still practise with Polie and your class.'**
  String get gcLockedTeenBody;

  /// gcLockedChildTitle
  ///
  /// In en, this message translates to:
  /// **'Global chat isn’t available'**
  String get gcLockedChildTitle;

  /// gcLockedChildBody
  ///
  /// In en, this message translates to:
  /// **'Child accounts can’t use open chat. Keep learning with lessons, games and Polie.'**
  String get gcLockedChildBody;

  /// gcLockedUnknownTitle
  ///
  /// In en, this message translates to:
  /// **'We need your age first'**
  String get gcLockedUnknownTitle;

  /// gcLockedUnknownBody
  ///
  /// In en, this message translates to:
  /// **'Global chat is for adults. It will appear here once your account’s age is confirmed.'**
  String get gcLockedUnknownBody;

  /// gcPracticePolie
  ///
  /// In en, this message translates to:
  /// **'Practise with Polie'**
  String get gcPracticePolie;

  /// gcChecking
  ///
  /// In en, this message translates to:
  /// **'Checking access…'**
  String get gcChecking;

  /// gcMessagesLabel
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No messages} =1{1 message} other{{n} messages}}'**
  String gcMessagesLabel(int n);

  /// gcOpenProfile
  ///
  /// In en, this message translates to:
  /// **'Open {name}’s profile'**
  String gcOpenProfile(String name);

  /// rbReasons
  ///
  /// In en, this message translates to:
  /// **'Report reasons'**
  String get rbReasons;

  /// rbSendReport
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get rbSendReport;

  /// rbSending
  ///
  /// In en, this message translates to:
  /// **'Sending report'**
  String get rbSending;

  /// rbReceived
  ///
  /// In en, this message translates to:
  /// **'Report received. Reference {ref}'**
  String rbReceived(String ref);

  /// rbSendFailed
  ///
  /// In en, this message translates to:
  /// **'Could not send that. Try again.'**
  String get rbSendFailed;

  /// rbBlockConfirm
  ///
  /// In en, this message translates to:
  /// **'Block this person? You will not see their new messages or snaps.'**
  String get rbBlockConfirm;

  /// rbConfirmBlock
  ///
  /// In en, this message translates to:
  /// **'Confirm block'**
  String get rbConfirmBlock;

  /// rbBlockUser
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get rbBlockUser;

  /// rbBlockedNote
  ///
  /// In en, this message translates to:
  /// **'Blocked. You will not see their new messages.'**
  String get rbBlockedNote;

  /// rbBlockFailed
  ///
  /// In en, this message translates to:
  /// **'Could not block this person. Try again.'**
  String get rbBlockFailed;

  /// rbBlockedPeople
  ///
  /// In en, this message translates to:
  /// **'Blocked people'**
  String get rbBlockedPeople;

  /// rbNoBlocked
  ///
  /// In en, this message translates to:
  /// **'No blocked people'**
  String get rbNoBlocked;

  /// rbHate
  ///
  /// In en, this message translates to:
  /// **'Hate'**
  String get rbHate;

  /// rbOther
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get rbOther;

  /// gcHeroTitle
  ///
  /// In en, this message translates to:
  /// **'Welcome to #{channel}'**
  String gcHeroTitle(String channel);

  /// gcHeroBody
  ///
  /// In en, this message translates to:
  /// **'This is the start of #{channel}. Be kind: moderators review every report.'**
  String gcHeroBody(String channel);

  /// gcGreetingIn
  ///
  /// In en, this message translates to:
  /// **'Say it like a local: {greeting}'**
  String gcGreetingIn(String greeting);

  /// gcHintShort
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get gcHintShort;

  /// gcErrorServerTitle
  ///
  /// In en, this message translates to:
  /// **'Global chat didn\'t load'**
  String get gcErrorServerTitle;

  /// gcErrorServerBody
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Nothing you wrote was lost. Try again in a moment.'**
  String get gcErrorServerBody;

  /// gfamToolsTitle
  ///
  /// In en, this message translates to:
  /// **'Family tools'**
  String get gfamToolsTitle;

  /// gfamToolsApprovals
  ///
  /// In en, this message translates to:
  /// **'Group approvals'**
  String get gfamToolsApprovals;

  /// gfamToolsApprovalsSub
  ///
  /// In en, this message translates to:
  /// **'Circles and classrooms waiting for you'**
  String get gfamToolsApprovalsSub;

  /// gfamToolsGuide
  ///
  /// In en, this message translates to:
  /// **'How messaging works'**
  String get gfamToolsGuide;

  /// gfamToolsGuideSub
  ///
  /// In en, this message translates to:
  /// **'What is checked, and who can message'**
  String get gfamToolsGuideSub;

  /// gfamToolsCircles
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get gfamToolsCircles;

  /// gfamToolsCirclesSub
  ///
  /// In en, this message translates to:
  /// **'Study circles you belong to'**
  String get gfamToolsCirclesSub;

  /// gfamWhoMessages
  ///
  /// In en, this message translates to:
  /// **'Who messages learner #{id}'**
  String gfamWhoMessages(int id);

  /// gdmTitle
  ///
  /// In en, this message translates to:
  /// **'Who is messaging your learner'**
  String get gdmTitle;

  /// gdmIntro
  ///
  /// In en, this message translates to:
  /// **'You see who, when and any reports. You never see message text.'**
  String get gdmIntro;

  /// gdmEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No direct messages yet'**
  String get gdmEmptyTitle;

  /// gdmEmptyBody
  ///
  /// In en, this message translates to:
  /// **'Only teachers and members of groups you approved can message your learner.'**
  String get gdmEmptyBody;

  /// gdmError
  ///
  /// In en, this message translates to:
  /// **'We could not load messages. Try again.'**
  String get gdmError;

  /// gdmRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gdmRetry;

  /// gdmRoleTeacher
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get gdmRoleTeacher;

  /// gdmRoleClassmate
  ///
  /// In en, this message translates to:
  /// **'Classmate'**
  String get gdmRoleClassmate;

  /// gdmRoleContact
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get gdmRoleContact;

  /// gdmLastActive
  ///
  /// In en, this message translates to:
  /// **'Last message {when}'**
  String gdmLastActive(String when);

  /// gdmMessages
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message} other{{count} messages}}'**
  String gdmMessages(int count);

  /// gdmReports
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reports} =1{1 report} other{{count} reports}}'**
  String gdmReports(int count);

  /// gdmBlocked
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message stopped by safety checks} other{{count} messages stopped by safety checks}}'**
  String gdmBlocked(int count);

  /// gdmHeld
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo or voice note waiting for a moderator} other{{count} photos or voice notes waiting for a moderator}}'**
  String gdmHeld(int count);

  /// gdmStop
  ///
  /// In en, this message translates to:
  /// **'Stop messages'**
  String get gdmStop;

  /// gdmAllow
  ///
  /// In en, this message translates to:
  /// **'Allow again'**
  String get gdmAllow;

  /// gdmStopped
  ///
  /// In en, this message translates to:
  /// **'Messages stopped'**
  String get gdmStopped;

  /// gdmStopConfirmTitle
  ///
  /// In en, this message translates to:
  /// **'Stop messages from {name}?'**
  String gdmStopConfirmTitle(String name);

  /// gdmStopConfirmBody
  ///
  /// In en, this message translates to:
  /// **'They will not be able to message your learner, and your learner cannot message them. You can allow it again later.'**
  String get gdmStopConfirmBody;

  /// gdmCancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gdmCancel;

  /// gdmActionFailed
  ///
  /// In en, this message translates to:
  /// **'That did not work. Try again.'**
  String get gdmActionFailed;

  /// gdmUnknownName
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get gdmUnknownName;

  /// gccJoinButton
  ///
  /// In en, this message translates to:
  /// **'Enter class code'**
  String get gccJoinButton;

  /// gccTitle
  ///
  /// In en, this message translates to:
  /// **'Join a class'**
  String get gccTitle;

  /// gccHint
  ///
  /// In en, this message translates to:
  /// **'Ask your teacher for the class code.'**
  String get gccHint;

  /// gccLabel
  ///
  /// In en, this message translates to:
  /// **'Class code'**
  String get gccLabel;

  /// gccSubmit
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get gccSubmit;

  /// gccJoined
  ///
  /// In en, this message translates to:
  /// **'You joined the class.'**
  String get gccJoined;

  /// gccWaitingTitle
  ///
  /// In en, this message translates to:
  /// **'Waiting for your guardian'**
  String get gccWaitingTitle;

  /// gccWaitingBody
  ///
  /// In en, this message translates to:
  /// **'We asked your guardian to approve this class. You can join once they say yes.'**
  String get gccWaitingBody;

  /// gccNeedLink
  ///
  /// In en, this message translates to:
  /// **'Ask a parent or guardian to link to your account in Family hub first.'**
  String get gccNeedLink;

  /// gccNeedAge
  ///
  /// In en, this message translates to:
  /// **'Confirm your age in settings before joining a class.'**
  String get gccNeedAge;

  /// gccNotFound
  ///
  /// In en, this message translates to:
  /// **'No class has that code. Check it with your teacher.'**
  String get gccNotFound;

  /// gccAlready
  ///
  /// In en, this message translates to:
  /// **'You are already in this class.'**
  String get gccAlready;

  /// gccError
  ///
  /// In en, this message translates to:
  /// **'Could not join right now. Try again.'**
  String get gccError;

  /// gccEmpty
  ///
  /// In en, this message translates to:
  /// **'Enter the code first.'**
  String get gccEmpty;

  /// gccDone
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get gccDone;

  /// gtpTitle
  ///
  /// In en, this message translates to:
  /// **'Student requests'**
  String get gtpTitle;

  /// gtpOpen
  ///
  /// In en, this message translates to:
  /// **'Student requests'**
  String get gtpOpen;

  /// gtpWaitingSection
  ///
  /// In en, this message translates to:
  /// **'Waiting for a guardian'**
  String get gtpWaitingSection;

  /// gtpWaitingHelp
  ///
  /// In en, this message translates to:
  /// **'These students used your class code. Their guardian decides; you do not need to do anything.'**
  String get gtpWaitingHelp;

  /// gtpWaitingEmpty
  ///
  /// In en, this message translates to:
  /// **'No one is waiting.'**
  String get gtpWaitingEmpty;

  /// gtpSchoolSection
  ///
  /// In en, this message translates to:
  /// **'School accounts'**
  String get gtpSchoolSection;

  /// gtpSchoolHelp
  ///
  /// In en, this message translates to:
  /// **'Teacher messages are off until you turn them on for each student. Only you can message them, and every message is checked.'**
  String get gtpSchoolHelp;

  /// gtpSchoolEmpty
  ///
  /// In en, this message translates to:
  /// **'No school accounts in this class.'**
  String get gtpSchoolEmpty;

  /// gtpTeacherDm
  ///
  /// In en, this message translates to:
  /// **'Teacher messages'**
  String get gtpTeacherDm;

  /// gtpPendingConsent
  ///
  /// In en, this message translates to:
  /// **'School consent pending'**
  String get gtpPendingConsent;

  /// gtpStudent
  ///
  /// In en, this message translates to:
  /// **'Student #{id}'**
  String gtpStudent(int id);

  /// gtpSince
  ///
  /// In en, this message translates to:
  /// **'Asked {when}'**
  String gtpSince(String when);

  /// gtpError
  ///
  /// In en, this message translates to:
  /// **'We could not load requests. Try again.'**
  String get gtpError;

  /// gtpNotTeacher
  ///
  /// In en, this message translates to:
  /// **'Only this class\'s teacher can see requests.'**
  String get gtpNotTeacher;

  /// gccClose
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get gccClose;

  /// gccOpenFamilyHub
  ///
  /// In en, this message translates to:
  /// **'Open Family hub'**
  String get gccOpenFamilyHub;

  /// gtpEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No student requests yet'**
  String get gtpEmptyTitle;

  /// gtpEmptyBody
  ///
  /// In en, this message translates to:
  /// **'Share your class code. Students who join will show up here.'**
  String get gtpEmptyBody;

  /// gtpLocked
  ///
  /// In en, this message translates to:
  /// **'Locked until the school confirms consent'**
  String get gtpLocked;

  /// gmeTitle
  ///
  /// In en, this message translates to:
  /// **'How messages work for young learners'**
  String get gmeTitle;

  /// gmeBody
  ///
  /// In en, this message translates to:
  /// **'Messages from learners under 18 are not end-to-end encrypted so automated checks and moderators can help before harmful content is delivered.'**
  String get gmeBody;

  /// gmeModHeading
  ///
  /// In en, this message translates to:
  /// **'What moderators may review'**
  String get gmeModHeading;

  /// gmeMod1
  ///
  /// In en, this message translates to:
  /// **'Message text in chats you approved'**
  String get gmeMod1;

  /// gmeMod2
  ///
  /// In en, this message translates to:
  /// **'Safety signals from automated screening'**
  String get gmeMod2;

  /// gmeMod3
  ///
  /// In en, this message translates to:
  /// **'Reports from learners or guardians'**
  String get gmeMod3;

  /// gmeTradeoff
  ///
  /// In en, this message translates to:
  /// **'Adult encrypted chats hide content from moderation; child accounts stay on moderated messaging.'**
  String get gmeTradeoff;

  /// gmeLoadError
  ///
  /// In en, this message translates to:
  /// **'We could not load this guide right now. Pull to refresh or try again when you are online.'**
  String get gmeLoadError;

  /// gmeOffline
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing the last saved explanation.'**
  String get gmeOffline;

  /// gmeLoading
  ///
  /// In en, this message translates to:
  /// **'Loading messaging guide'**
  String get gmeLoading;

  /// gmeRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gmeRetry;

  /// gmeTileTitle
  ///
  /// In en, this message translates to:
  /// **'How learner messages stay safe'**
  String get gmeTileTitle;

  /// gmeTileSubtitle
  ///
  /// In en, this message translates to:
  /// **'Why chats are moderated and not encrypted'**
  String get gmeTileSubtitle;

  /// gcirTitle
  ///
  /// In en, this message translates to:
  /// **'Your circles'**
  String get gcirTitle;

  /// gcirLoadError
  ///
  /// In en, this message translates to:
  /// **'We could not load your circles right now.'**
  String get gcirLoadError;

  /// gcirOffline
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your circles will appear when you reconnect.'**
  String get gcirOffline;

  /// gcirRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gcirRetry;

  /// gcirEmpty
  ///
  /// In en, this message translates to:
  /// **'Start a study circle or join a language village to learn together.'**
  String get gcirEmpty;

  /// gcirEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No circles yet'**
  String get gcirEmptyTitle;

  /// gcirOpen
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} members · Open'**
  String gcirOpen(int count, int max);

  /// gcirFull
  ///
  /// In en, this message translates to:
  /// **'Full · {count} members'**
  String gcirFull(int count);

  /// gcirOpensAt
  ///
  /// In en, this message translates to:
  /// **'{count} members · Opens at {min}'**
  String gcirOpensAt(int count, int min);

  /// gcirFallbackName
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get gcirFallbackName;

  /// gapTitle
  ///
  /// In en, this message translates to:
  /// **'Group approvals'**
  String get gapTitle;

  /// gapLearnerFallback
  ///
  /// In en, this message translates to:
  /// **'Your learner'**
  String get gapLearnerFallback;

  /// gapDenyConfirmTitle
  ///
  /// In en, this message translates to:
  /// **'Deny this request?'**
  String get gapDenyConfirmTitle;

  /// gapDenyConfirmBody
  ///
  /// In en, this message translates to:
  /// **'{child} will not join {group}. They can ask again later.'**
  String gapDenyConfirmBody(String child, String group);

  /// gapCancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gapCancel;

  /// gapDeny
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get gapDeny;

  /// gapApprove
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get gapApprove;

  /// gapRevoke
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get gapRevoke;

  /// gapApprovedToast
  ///
  /// In en, this message translates to:
  /// **'Approved: {group}'**
  String gapApprovedToast(String group);

  /// gapDeniedToast
  ///
  /// In en, this message translates to:
  /// **'Denied: {group}'**
  String gapDeniedToast(String group);

  /// gapRevokedToast
  ///
  /// In en, this message translates to:
  /// **'Approval revoked: {group}'**
  String gapRevokedToast(String group);

  /// gapActionFailed
  ///
  /// In en, this message translates to:
  /// **'That did not go through. Please try again.'**
  String get gapActionFailed;

  /// gapReview
  ///
  /// In en, this message translates to:
  /// **'Needs your review'**
  String get gapReview;

  /// gapDecided
  ///
  /// In en, this message translates to:
  /// **'Decided'**
  String get gapDecided;

  /// gapLoadError
  ///
  /// In en, this message translates to:
  /// **'Approvals could not load. Check your connection and try again.'**
  String get gapLoadError;

  /// gapEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No requests right now'**
  String get gapEmptyTitle;

  /// gapEmptyBody
  ///
  /// In en, this message translates to:
  /// **'When your learner asks to join a circle or class, it will appear here for you to approve or deny.'**
  String get gapEmptyBody;

  /// gapRefresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get gapRefresh;

  /// gapOffline
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing the last list we loaded.'**
  String get gapOffline;

  /// gapLoading
  ///
  /// In en, this message translates to:
  /// **'Loading approvals'**
  String get gapLoading;

  /// gapRetry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gapRetry;

  /// gapStatusApproved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get gapStatusApproved;

  /// gapStatusExpired
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get gapStatusExpired;

  /// gapStatusRevoked
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get gapStatusRevoked;

  /// gapStatusDenied
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get gapStatusDenied;

  /// gapStatusReapprove
  ///
  /// In en, this message translates to:
  /// **'Approve again'**
  String get gapStatusReapprove;

  /// gapStatusWaiting
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get gapStatusWaiting;

  /// gapModerated
  ///
  /// In en, this message translates to:
  /// **'Messages are checked by moderators'**
  String get gapModerated;

  /// gapApprovalRequired
  ///
  /// In en, this message translates to:
  /// **'Joining needs your approval'**
  String get gapApprovalRequired;

  /// gapOpenCommunity
  ///
  /// In en, this message translates to:
  /// **'Open community'**
  String get gapOpenCommunity;

  /// gapKindCircle
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get gapKindCircle;

  /// gapKindClassroom
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get gapKindClassroom;

  /// gapWhyCircle
  ///
  /// In en, this message translates to:
  /// **'{child} wants to join the circle {group}'**
  String gapWhyCircle(String child, String group);

  /// gapWhyClass
  ///
  /// In en, this message translates to:
  /// **'{child} wants to join the class {group}'**
  String gapWhyClass(String child, String group);

  /// gapMembers
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String gapMembers(int count);

  /// gapAdults
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 adult} other{{count} adults}}'**
  String gapAdults(int count);

  /// gapExpires
  ///
  /// In en, this message translates to:
  /// **'Approval ends {date}'**
  String gapExpires(String date);

  /// gccFormatHint
  ///
  /// In en, this message translates to:
  /// **'6–8 letters or numbers, from your teacher'**
  String get gccFormatHint;

  /// gccChecking
  ///
  /// In en, this message translates to:
  /// **'Checking the code…'**
  String get gccChecking;

  /// gcirLoading
  ///
  /// In en, this message translates to:
  /// **'Loading circles'**
  String get gcirLoading;

  /// gcirJoinWithCode
  ///
  /// In en, this message translates to:
  /// **'Join with a class code'**
  String get gcirJoinWithCode;

  /// gcirExplore
  ///
  /// In en, this message translates to:
  /// **'Explore villages'**
  String get gcirExplore;

  /// gcirPillOpen
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get gcirPillOpen;

  /// gcirPillFull
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get gcirPillFull;

  /// gcirPillSoon
  ///
  /// In en, this message translates to:
  /// **'Starting soon'**
  String get gcirPillSoon;

  /// gdmLoading
  ///
  /// In en, this message translates to:
  /// **'Loading contacts'**
  String get gdmLoading;

  /// gdmTitleFor
  ///
  /// In en, this message translates to:
  /// **'Who is messaging {name}'**
  String gdmTitleFor(String name);

  /// gfamHubTitle
  ///
  /// In en, this message translates to:
  /// **'Family hub'**
  String get gfamHubTitle;

  /// gfamModeHub
  ///
  /// In en, this message translates to:
  /// **'Guardian hub'**
  String get gfamModeHub;

  /// gfamModeInvite
  ///
  /// In en, this message translates to:
  /// **'Learner invite'**
  String get gfamModeInvite;

  /// gfamStatusActive
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get gfamStatusActive;

  /// gfamStatusVerifying
  ///
  /// In en, this message translates to:
  /// **'Needs your consent'**
  String get gfamStatusVerifying;

  /// gfamStatusWithdrawn
  ///
  /// In en, this message translates to:
  /// **'Consent withdrawn'**
  String get gfamStatusWithdrawn;

  /// gfamWhoMessagesName
  ///
  /// In en, this message translates to:
  /// **'Who messages {name}'**
  String gfamWhoMessagesName(String name);

  /// gfamWhoMessagesYours
  ///
  /// In en, this message translates to:
  /// **'Who messages your learner'**
  String get gfamWhoMessagesYours;

  /// gmeSecCheckedTitle
  ///
  /// In en, this message translates to:
  /// **'Messages are checked first'**
  String get gmeSecCheckedTitle;

  /// gmeSecHeldTitle
  ///
  /// In en, this message translates to:
  /// **'Photos, voice notes and links wait for review'**
  String get gmeSecHeldTitle;

  /// gmeSecHeldBody
  ///
  /// In en, this message translates to:
  /// **'When an adult sends a photo, voice note or link to a young learner, it is held until a moderator checks it. Your learner sees it only after it is cleared.'**
  String get gmeSecHeldBody;

  /// gmeSecStopTitle
  ///
  /// In en, this message translates to:
  /// **'You can stop a contact'**
  String get gmeSecStopTitle;

  /// gmeSecStopBody
  ///
  /// In en, this message translates to:
  /// **'In Family hub, open Messages and choose Stop. That person can no longer message your learner.'**
  String get gmeSecStopBody;

  /// gmeSecTeacherTitle
  ///
  /// In en, this message translates to:
  /// **'Teachers need your approval'**
  String get gmeSecTeacherTitle;

  /// gmeSecTeacherBody
  ///
  /// In en, this message translates to:
  /// **'A teacher can message your learner only in a class you approved, or when the school has consent and the teacher turns on messages. That permission ends on its expiry date.'**
  String get gmeSecTeacherBody;

  /// gtpDmOnTitle
  ///
  /// In en, this message translates to:
  /// **'Turn on messages with {name}?'**
  String gtpDmOnTitle(String name);

  /// gtpDmOffTitle
  ///
  /// In en, this message translates to:
  /// **'Turn off messages with {name}?'**
  String gtpDmOffTitle(String name);

  /// gtpDmOnBody
  ///
  /// In en, this message translates to:
  /// **'The school\'s consent covers this. Messages stay moderated, and this lasts one year unless you turn it off.'**
  String get gtpDmOnBody;

  /// gtpDmOffBody
  ///
  /// In en, this message translates to:
  /// **'You will no longer be able to message this student directly.'**
  String get gtpDmOffBody;

  /// gtpDmOnAction
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get gtpDmOnAction;

  /// gtpDmOffAction
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get gtpDmOffAction;

  /// gtpDmUntil
  ///
  /// In en, this message translates to:
  /// **'Messages on until {date}'**
  String gtpDmUntil(String date);

  /// gtpLoading
  ///
  /// In en, this message translates to:
  /// **'Loading students'**
  String get gtpLoading;

  /// gfamModeHubLabel
  ///
  /// In en, this message translates to:
  /// **'Guardian hub, show linked learners'**
  String get gfamModeHubLabel;

  /// gfamModeInviteLabel
  ///
  /// In en, this message translates to:
  /// **'Learner invite, create a code to share'**
  String get gfamModeInviteLabel;

  /// Guardian hub (family) screen text.
  ///
  /// In en, this message translates to:
  /// **'Learner waiting for you?'**
  String get gfamInviteSectionTitle;

  /// Guardian hub (family) screen text.
  ///
  /// In en, this message translates to:
  /// **'Paste the invite code from their LingAfriq app.'**
  String get gfamAcceptInviteHint;

  /// Guardian hub (family) screen text.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get gfamInviteCodeLabel;

  /// Guardian hub (family) screen text.
  ///
  /// In en, this message translates to:
  /// **'Your name (shown to the learner)'**
  String get gfamYourNameHint;

  /// Guardian hub (family) screen text.
  ///
  /// In en, this message translates to:
  /// **'Linked learners'**
  String get gfamLinkedLearners;

  /// Guardian hub (family) screen text.
  ///
  /// In en, this message translates to:
  /// **'Link learner'**
  String get gfamLinkLearner;

  /// Guarded family screens.
  ///
  /// In en, this message translates to:
  /// **'How messaging works'**
  String get gdmEmptyAction;

  /// Class code sheet success state.
  ///
  /// In en, this message translates to:
  /// **'You joined {className}'**
  String gccJoinedNamed(String className);

  /// Class code sheet success state.
  ///
  /// In en, this message translates to:
  /// **'Your teacher can now share lessons and messages with you here.'**
  String get gccJoinedNext;

  /// Circles list row activity line.
  ///
  /// In en, this message translates to:
  /// **'Last activity {date}'**
  String gcirLastActivity(String date);

  /// gfamRegimeNdpa
  ///
  /// In en, this message translates to:
  /// **'Nigeria data protection law (NDPA 2023)'**
  String get gfamRegimeNdpa;

  /// gfamRegimeOther
  ///
  /// In en, this message translates to:
  /// **'Child privacy rules'**
  String get gfamRegimeOther;

  /// gfamMembersTitle
  ///
  /// In en, this message translates to:
  /// **'Your family'**
  String get gfamMembersTitle;

  /// gfamYou
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get gfamYou;

  /// gfamYouInitial
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get gfamYouInitial;

  /// gfamRoleGuardian
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get gfamRoleGuardian;

  /// gfamRoleLearner
  ///
  /// In en, this message translates to:
  /// **'Learner'**
  String get gfamRoleLearner;

  /// gfamNeedsYou
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 request needs you} other{{count} requests need you}}'**
  String gfamNeedsYou(int count);

  /// gfamNeedsYouAction
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get gfamNeedsYouAction;

  /// gapNotNow
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get gapNotNow;

  /// gapNotNowToast
  ///
  /// In en, this message translates to:
  /// **'Saved for later. It stays in your list.'**
  String get gapNotNowToast;

  /// gapShowAgain
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get gapShowAgain;

  /// gapApprovingAs
  ///
  /// In en, this message translates to:
  /// **'You\'re approving as {name} (Parent)'**
  String gapApprovingAs(String name);

  /// gapApprovingAsYou
  ///
  /// In en, this message translates to:
  /// **'You\'re approving as the parent on this account'**
  String get gapApprovingAsYou;

  /// gapAudit
  ///
  /// In en, this message translates to:
  /// **'{status} by you · {time}'**
  String gapAudit(String status, String time);

  /// gapAuditThisPhone
  ///
  /// In en, this message translates to:
  /// **'{status} by you · {time} · this phone'**
  String gapAuditThisPhone(String status, String time);

  /// gapPendingSync
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get gapPendingSync;

  /// gapSavedOffline
  ///
  /// In en, this message translates to:
  /// **'Saved offline. We\'ll send it when you\'re back online.'**
  String get gapSavedOffline;

  /// gdmSummary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contact} other{{count} contacts}} · {fresh} new this week'**
  String gdmSummary(int count, int fresh);

  /// gdmFilterAll
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gdmFilterAll;

  /// gdmFilterNew
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get gdmFilterNew;

  /// gdmFilterStopped
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get gdmFilterStopped;

  /// gdmFilterMedia
  ///
  /// In en, this message translates to:
  /// **'Media waiting'**
  String get gdmFilterMedia;

  /// gdmFilterEmpty
  ///
  /// In en, this message translates to:
  /// **'No contacts match this filter.'**
  String get gdmFilterEmpty;

  /// gdmStoppedToast
  ///
  /// In en, this message translates to:
  /// **'{name} can\'t message your learner now'**
  String gdmStoppedToast(String name);

  /// gdmUndo
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get gdmUndo;

  /// gccCheck
  ///
  /// In en, this message translates to:
  /// **'Check code'**
  String get gccCheck;

  /// gccPreviewTitle
  ///
  /// In en, this message translates to:
  /// **'Is this your class?'**
  String get gccPreviewTitle;

  /// gccPreviewTeacher
  ///
  /// In en, this message translates to:
  /// **'Teacher: {name}'**
  String gccPreviewTeacher(String name);

  /// gccPreviewMembers
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No learners yet} =1{1 learner} other{{count} learners}}'**
  String gccPreviewMembers(int count);

  /// gccPreviewChange
  ///
  /// In en, this message translates to:
  /// **'Use a different code'**
  String get gccPreviewChange;

  /// gtpVerified
  ///
  /// In en, this message translates to:
  /// **'Verified by school'**
  String get gtpVerified;

  /// gtpAllowUntil
  ///
  /// In en, this message translates to:
  /// **'Allow until {date}'**
  String gtpAllowUntil(String date);

  /// gtpExpiresIn
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Expires today} =1{Expires in 1 day} other{Expires in {count} days}}'**
  String gtpExpiresIn(int count);

  /// common.action.continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonActionContinue;

  /// common.action.save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonActionSave;

  /// common.action.tryAgain
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonActionTryAgain;

  /// common.action.close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonActionClose;

  /// common.action.showMore
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get commonActionShowMore;

  /// common.state.unavailable
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get commonStateUnavailable;

  /// onboarding. Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// onboarding. Select birth year
  ///
  /// In en, this message translates to:
  /// **'Select birth year'**
  String get onboardingSelectBirthYear;

  /// onboarding. Birth year, {value}
  ///
  /// In en, this message translates to:
  /// **'Birth year, {value}'**
  String onboardingBirthYearValue(String value);

  /// onboarding. Continue to lessons
  ///
  /// In en, this message translates to:
  /// **'Continue to lessons'**
  String get onboardingContinueToLessons;

  /// onboarding. We could not save that year. Try again.
  ///
  /// In en, this message translates to:
  /// **'We could not save that year. Try again.'**
  String get onboardingWeCouldNotSaveThatYear;

  /// onboarding. Choose the year you were born to continue.
  ///
  /// In en, this message translates to:
  /// **'Choose the year you were born to continue.'**
  String get onboardingChooseTheYearYouWereBorn;

  /// onboarding. Your account is ready for lessons, but chat, Village, and purchases stay paused
  ///
  /// In en, this message translates to:
  /// **'Your account is ready for lessons, but chat, Village, and purchases stay paused until a guardian approves.'**
  String get onboardingYourAccountIsReadyForLessons;

  /// onboarding. We need a guardian
  ///
  /// In en, this message translates to:
  /// **'We need a guardian'**
  String get onboardingWeNeedAGuardian;

  /// onboarding. You already entered a birth year on this device. If something looks wrong, ask a
  ///
  /// In en, this message translates to:
  /// **'You already entered a birth year on this device. If something looks wrong, ask a guardian to help from their account.'**
  String get onboardingYouAlreadyEnteredABirthYear;

  /// onboarding. We use this to keep learners safe and unlock the right features for your age. We
  ///
  /// In en, this message translates to:
  /// **'We use this to keep learners safe and unlock the right features for your age. We only ask for the year, and we store your age group, not the year itself.'**
  String get onboardingWeUseThisToKeepLearners;

  /// onboarding. What year were you born?
  ///
  /// In en, this message translates to:
  /// **'What year were you born?'**
  String get onboardingWhatYearWereYouBorn;

  /// onboarding. {pendingSyncs} pending sync{value}
  ///
  /// In en, this message translates to:
  /// **'{pendingSyncs} pending sync{value}'**
  String onboardingPendingsyncsPendingSyncValue(
    String pendingSyncs,
    String value,
  );

  /// onboarding. Could not verify availability. You can still continue.
  ///
  /// In en, this message translates to:
  /// **'Could not verify availability. You can still continue.'**
  String get onboardingCouldNotVerifyAvailabilityYouCan;

  /// onboarding. Only letters, numbers, and underscores are allowed
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and underscores are allowed'**
  String get onboardingOnlyLettersNumbersAndUnderscoresAre;

  /// onboarding. Username must be 30 characters or less
  ///
  /// In en, this message translates to:
  /// **'Username must be 30 characters or less'**
  String get onboardingUsernameMustBe30CharactersOr;

  /// onboarding. Username must be at least 3 characters
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get onboardingUsernameMustBeAtLeast3;

  /// onboarding. ✗ Username is already taken
  ///
  /// In en, this message translates to:
  /// **'✗ Username is already taken'**
  String get onboardingUsernameIsAlreadyTaken;

  /// onboarding. ✓ Username is available
  ///
  /// In en, this message translates to:
  /// **'✓ Username is available'**
  String get onboardingUsernameIsAvailable;

  /// onboarding. Checking availability...
  ///
  /// In en, this message translates to:
  /// **'Checking availability...'**
  String get onboardingCheckingAvailability;

  /// onboarding. Enter a username (3-30 characters, letters, numbers, and underscores only)
  ///
  /// In en, this message translates to:
  /// **'Enter a username (3-30 characters, letters, numbers, and underscores only)'**
  String get onboardingEnterAUsername330Characters;

  /// onboarding. Complete Onboarding
  ///
  /// In en, this message translates to:
  /// **'Complete Onboarding'**
  String get onboardingCompleteOnboarding;

  /// onboarding. Choose a unique username
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username'**
  String get onboardingChooseAUniqueUsername;

  /// onboarding. Username
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get onboardingUsername;

  /// onboarding. Change Avatar
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get onboardingChangeAvatar;

  /// onboarding. Set your username (avatar is optional)
  ///
  /// In en, this message translates to:
  /// **'Set your username (avatar is optional)'**
  String get onboardingSetYourUsernameAvatarIsOptional;

  /// onboarding. Complete Your Profile
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get onboardingCompleteYourProfile;

  /// onboarding. Enable Reminders
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get onboardingEnableReminders;

  /// onboarding. Preferred Time of Day
  ///
  /// In en, this message translates to:
  /// **'Preferred Time of Day'**
  String get onboardingPreferredTimeOfDay;

  /// onboarding. {value} minutes per day
  ///
  /// In en, this message translates to:
  /// **'{value} minutes per day'**
  String onboardingValueMinutesPerDay(String value);

  /// onboarding. {value} minutes
  ///
  /// In en, this message translates to:
  /// **'{value} minutes'**
  String onboardingValueMinutes(String value);

  /// onboarding. Daily Duration (minutes)
  ///
  /// In en, this message translates to:
  /// **'Daily Duration (minutes)'**
  String get onboardingDailyDurationMinutes;

  /// onboarding. When and how long do you want to learn?
  ///
  /// In en, this message translates to:
  /// **'When and how long do you want to learn?'**
  String get onboardingWhenAndHowLongDoYou;

  /// onboarding. Set your learning schedule
  ///
  /// In en, this message translates to:
  /// **'Set your learning schedule'**
  String get onboardingSetYourLearningSchedule;

  /// onboarding. How should Polie communicate with you?
  ///
  /// In en, this message translates to:
  /// **'How should Polie communicate with you?'**
  String get onboardingHowShouldPolieCommunicateWithYou;

  /// onboarding. What tone do you prefer?
  ///
  /// In en, this message translates to:
  /// **'What tone do you prefer?'**
  String get onboardingWhatToneDoYouPrefer;

  /// onboarding. How fast do you want to learn?
  ///
  /// In en, this message translates to:
  /// **'How fast do you want to learn?'**
  String get onboardingHowFastDoYouWantTo;

  /// onboarding. What pace do you prefer?
  ///
  /// In en, this message translates to:
  /// **'What pace do you prefer?'**
  String get onboardingWhatPaceDoYouPrefer;

  /// onboarding. Select your preferred learning style
  ///
  /// In en, this message translates to:
  /// **'Select your preferred learning style'**
  String get onboardingSelectYourPreferredLearningStyle;

  /// onboarding. How do you learn best?
  ///
  /// In en, this message translates to:
  /// **'How do you learn best?'**
  String get onboardingHowDoYouLearnBest;

  /// onboarding. Choose your main learning objective
  ///
  /// In en, this message translates to:
  /// **'Choose your main learning objective'**
  String get onboardingChooseYourMainLearningObjective;

  /// onboarding. What's your primary goal?
  ///
  /// In en, this message translates to:
  /// **'What\'s your primary goal?'**
  String get onboardingWhatSYourPrimaryGoal;

  /// onboarding. Choose your daily learning goal
  ///
  /// In en, this message translates to:
  /// **'Choose your daily learning goal'**
  String get onboardingChooseYourDailyLearningGoal;

  /// onboarding. How much time can you commit daily?
  ///
  /// In en, this message translates to:
  /// **'How much time can you commit daily?'**
  String get onboardingHowMuchTimeCanYouCommit;

  /// onboarding. Dedicated study
  ///
  /// In en, this message translates to:
  /// **'Dedicated study'**
  String get onboardingDedicatedStudy;

  /// onboarding. 20 min
  ///
  /// In en, this message translates to:
  /// **'20 min'**
  String get onboardingText20Min;

  /// onboarding. Balanced
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get onboardingBalanced;

  /// onboarding. 15 min
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get onboardingText15Min;

  /// onboarding. Light learning
  ///
  /// In en, this message translates to:
  /// **'Light learning'**
  String get onboardingLightLearning;

  /// onboarding. 10 min
  ///
  /// In en, this message translates to:
  /// **'10 min'**
  String get onboardingText10Min;

  /// onboarding. Quick practice
  ///
  /// In en, this message translates to:
  /// **'Quick practice'**
  String get onboardingQuickPractice;

  /// onboarding. 5 min
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get onboardingText5Min;

  /// onboarding. Select all that apply
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get onboardingSelectAllThatApply;

  /// onboarding. Why are you learning?
  ///
  /// In en, this message translates to:
  /// **'Why are you learning?'**
  String get onboardingWhyAreYouLearning;

  /// onboarding. This helps us personalize your experience
  ///
  /// In en, this message translates to:
  /// **'This helps us personalize your experience'**
  String get onboardingThisHelpsUsPersonalizeYourExperience;

  /// onboarding. What's your age category?
  ///
  /// In en, this message translates to:
  /// **'What\'s your age category?'**
  String get onboardingWhatSYourAgeCategory;

  /// onboarding. Select the language you want to learn
  ///
  /// In en, this message translates to:
  /// **'Select the language you want to learn'**
  String get onboardingSelectTheLanguageYouWantTo;

  /// onboarding. What language do you wish to learn first?
  ///
  /// In en, this message translates to:
  /// **'What language do you wish to learn first?'**
  String get onboardingWhatLanguageDoYouWishTo;

  /// onboarding. Xhosa
  ///
  /// In en, this message translates to:
  /// **'Xhosa'**
  String get onboardingXhosa;

  /// onboarding. Zulu
  ///
  /// In en, this message translates to:
  /// **'Zulu'**
  String get onboardingZulu;

  /// onboarding. Swahili
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get onboardingSwahili;

  /// onboarding. Nigerian Pidgin English
  ///
  /// In en, this message translates to:
  /// **'Nigerian Pidgin English'**
  String get onboardingNigerianPidginEnglish;

  /// onboarding. Igbo
  ///
  /// In en, this message translates to:
  /// **'Igbo'**
  String get onboardingIgbo;

  /// onboarding. Hausa
  ///
  /// In en, this message translates to:
  /// **'Hausa'**
  String get onboardingHausa;

  /// onboarding. Yoruba
  ///
  /// In en, this message translates to:
  /// **'Yoruba'**
  String get onboardingYoruba;

  /// onboarding. Help us personalize your learning experience
  ///
  /// In en, this message translates to:
  /// **'Help us personalize your learning experience'**
  String get onboardingHelpUsPersonalizeYourLearningExperienc;

  /// onboarding. What's your current level?
  ///
  /// In en, this message translates to:
  /// **'What\'s your current level?'**
  String get onboardingWhatSYourCurrentLevel;

  /// onboarding. I speak this language natively
  ///
  /// In en, this message translates to:
  /// **'I speak this language natively'**
  String get onboardingISpeakThisLanguageNatively;

  /// onboarding. Native
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get onboardingNative;

  /// onboarding. I'm quite fluent
  ///
  /// In en, this message translates to:
  /// **'I\'m quite fluent'**
  String get onboardingIMQuiteFluent;

  /// onboarding. Advanced
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get onboardingAdvanced;

  /// onboarding. I can have basic conversations
  ///
  /// In en, this message translates to:
  /// **'I can have basic conversations'**
  String get onboardingICanHaveBasicConversations;

  /// onboarding. Intermediate
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get onboardingIntermediate;

  /// onboarding. I know a few words
  ///
  /// In en, this message translates to:
  /// **'I know a few words'**
  String get onboardingIKnowAFewWords;

  /// onboarding. Elementary
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get onboardingElementary;

  /// onboarding. I'm just starting out
  ///
  /// In en, this message translates to:
  /// **'I\'m just starting out'**
  String get onboardingIMJustStartingOut;

  /// onboarding. Beginner
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get onboardingBeginner;

  /// onboarding. Continue to next step
  ///
  /// In en, this message translates to:
  /// **'Continue to next step'**
  String get onboardingContinueToNextStep;

  /// onboarding. Search languages...
  ///
  /// In en, this message translates to:
  /// **'Search languages...'**
  String get onboardingSearchLanguages;

  /// onboarding. Search languages
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get onboardingSearchLanguagesea93;

  /// onboarding. All Languages
  ///
  /// In en, this message translates to:
  /// **'All Languages'**
  String get onboardingAllLanguages;

  /// onboarding. Show All Languages ({value} more)
  ///
  /// In en, this message translates to:
  /// **'Show All Languages ({value} more)'**
  String onboardingShowAllLanguagesValueMore(String value);

  /// onboarding. Show all languages. {value} more languages available.
  ///
  /// In en, this message translates to:
  /// **'Show all languages. {value} more languages available.'**
  String onboardingShowAllLanguagesValueMoreLanguages(String value);

  /// onboarding. Select {value} as proficiency language. {value2}
  ///
  /// In en, this message translates to:
  /// **'Select {value} as proficiency language. {value2}'**
  String onboardingSelectValueAsProficiencyLanguageValue2(
    String value,
    String value2,
  );

  /// onboarding. Popular Languages
  ///
  /// In en, this message translates to:
  /// **'Popular Languages'**
  String get onboardingPopularLanguages;

  /// onboarding. We'll translate all in-app content to this language
  ///
  /// In en, this message translates to:
  /// **'We\'ll translate all in-app content to this language'**
  String get onboardingWeLlTranslateAllInApp;

  /// onboarding. What language do you speak?
  ///
  /// In en, this message translates to:
  /// **'What language do you speak?'**
  String get onboardingWhatLanguageDoYouSpeak;

  /// onboarding. Polish
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get onboardingPolish;

  /// onboarding. Dutch
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get onboardingDutch;

  /// onboarding. Turkish
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get onboardingTurkish;

  /// onboarding. Russian
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get onboardingRussian;

  /// onboarding. Hindi
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get onboardingHindi;

  /// onboarding. Korean
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get onboardingKorean;

  /// onboarding. Japanese
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get onboardingJapanese;

  /// onboarding. Chinese
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get onboardingChinese;

  /// onboarding. Italian
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get onboardingItalian;

  /// onboarding. German
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get onboardingGerman;

  /// onboarding. Berber
  ///
  /// In en, this message translates to:
  /// **'Berber'**
  String get onboardingBerber;

  /// onboarding. Arabic
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get onboardingArabic;

  /// onboarding. Sango
  ///
  /// In en, this message translates to:
  /// **'Sango'**
  String get onboardingSango;

  /// onboarding. Kongo
  ///
  /// In en, this message translates to:
  /// **'Kongo'**
  String get onboardingKongo;

  /// onboarding. Lingala
  ///
  /// In en, this message translates to:
  /// **'Lingala'**
  String get onboardingLingala;

  /// onboarding. Chichewa
  ///
  /// In en, this message translates to:
  /// **'Chichewa'**
  String get onboardingChichewa;

  /// onboarding. Ndebele
  ///
  /// In en, this message translates to:
  /// **'Ndebele'**
  String get onboardingNdebele;

  /// onboarding. Swati
  ///
  /// In en, this message translates to:
  /// **'Swati'**
  String get onboardingSwati;

  /// onboarding. Tsonga
  ///
  /// In en, this message translates to:
  /// **'Tsonga'**
  String get onboardingTsonga;

  /// onboarding. Venda
  ///
  /// In en, this message translates to:
  /// **'Venda'**
  String get onboardingVenda;

  /// onboarding. Setswana
  ///
  /// In en, this message translates to:
  /// **'Setswana'**
  String get onboardingSetswana;

  /// onboarding. Sesotho
  ///
  /// In en, this message translates to:
  /// **'Sesotho'**
  String get onboardingSesotho;

  /// onboarding. Afrikaans
  ///
  /// In en, this message translates to:
  /// **'Afrikaans'**
  String get onboardingAfrikaans;

  /// onboarding. Somali
  ///
  /// In en, this message translates to:
  /// **'Somali'**
  String get onboardingSomali;

  /// onboarding. Oromo
  ///
  /// In en, this message translates to:
  /// **'Oromo'**
  String get onboardingOromo;

  /// onboarding. Tigrinya
  ///
  /// In en, this message translates to:
  /// **'Tigrinya'**
  String get onboardingTigrinya;

  /// onboarding. Amharic
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get onboardingAmharic;

  /// onboarding. Kirundi
  ///
  /// In en, this message translates to:
  /// **'Kirundi'**
  String get onboardingKirundi;

  /// onboarding. Kinyarwanda
  ///
  /// In en, this message translates to:
  /// **'Kinyarwanda'**
  String get onboardingKinyarwanda;

  /// onboarding. Luganda
  ///
  /// In en, this message translates to:
  /// **'Luganda'**
  String get onboardingLuganda;

  /// onboarding. Luo
  ///
  /// In en, this message translates to:
  /// **'Luo'**
  String get onboardingLuo;

  /// onboarding. Kikuyu
  ///
  /// In en, this message translates to:
  /// **'Kikuyu'**
  String get onboardingKikuyu;

  /// onboarding. Fon
  ///
  /// In en, this message translates to:
  /// **'Fon'**
  String get onboardingFon;

  /// onboarding. Ewe
  ///
  /// In en, this message translates to:
  /// **'Ewe'**
  String get onboardingEwe;

  /// onboarding. Akan
  ///
  /// In en, this message translates to:
  /// **'Akan'**
  String get onboardingAkan;

  /// onboarding. Bambara
  ///
  /// In en, this message translates to:
  /// **'Bambara'**
  String get onboardingBambara;

  /// onboarding. Fulfulde
  ///
  /// In en, this message translates to:
  /// **'Fulfulde'**
  String get onboardingFulfulde;

  /// onboarding. Twi
  ///
  /// In en, this message translates to:
  /// **'Twi'**
  String get onboardingTwi;

  /// onboarding. Wolof
  ///
  /// In en, this message translates to:
  /// **'Wolof'**
  String get onboardingWolof;

  /// onboarding. Nigerian Pidgin
  ///
  /// In en, this message translates to:
  /// **'Nigerian Pidgin'**
  String get onboardingNigerianPidgin;

  /// onboarding. Spanish
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get onboardingSpanish;

  /// onboarding. Portuguese
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get onboardingPortuguese;

  /// onboarding. French
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get onboardingFrench;

  /// onboarding. English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get onboardingEnglish;

  /// onboarding. Take Test
  ///
  /// In en, this message translates to:
  /// **'Take Test'**
  String get onboardingTakeTest;

  /// onboarding. Skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// onboarding. Would you like to take a placement test to assess your current level in {learnin
  ///
  /// In en, this message translates to:
  /// **'Would you like to take a placement test to assess your current level in {learningLanguage}? You can skip this and take it later.'**
  String onboardingWouldYouLikeToTakeA(String learningLanguage);

  /// onboarding. Take Placement Test?
  ///
  /// In en, this message translates to:
  /// **'Take Placement Test?'**
  String get onboardingTakePlacementTest;

  /// onboarding. {progressPercent}%
  ///
  /// In en, this message translates to:
  /// **'{progressPercent}%'**
  String onboardingProgresspercent(String progressPercent);

  /// onboarding. Step {value} of {totalSteps}
  ///
  /// In en, this message translates to:
  /// **'Step {value} of {totalSteps}'**
  String onboardingStepValueOfTotalsteps(String value, String totalSteps);

  /// onboarding. Skip onboarding
  ///
  /// In en, this message translates to:
  /// **'Skip onboarding'**
  String get onboardingSkipOnboarding;

  /// onboarding. Onboarding
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboardingOnboarding;

  /// onboarding. Go back to previous step
  ///
  /// In en, this message translates to:
  /// **'Go back to previous step'**
  String get onboardingGoBackToPreviousStep;

  /// onboarding. Onboarding progress. Step {value} of {totalSteps}. {progressPercent} percent com
  ///
  /// In en, this message translates to:
  /// **'Onboarding progress. Step {value} of {totalSteps}. {progressPercent} percent complete.'**
  String onboardingOnboardingProgressStepValueOfTotalstep(
    String value,
    String totalSteps,
    String progressPercent,
  );

  /// onboarding. Skip test
  ///
  /// In en, this message translates to:
  /// **'Skip test'**
  String get onboardingSkipTest;

  /// onboarding. Question {value} of {totalQuestions}
  ///
  /// In en, this message translates to:
  /// **'Question {value} of {totalQuestions}'**
  String onboardingQuestionValueOfTotalquestions(
    String value,
    String totalQuestions,
  );

  /// onboarding. Skip for now (start as beginner)
  ///
  /// In en, this message translates to:
  /// **'Skip for now (start as beginner)'**
  String get onboardingSkipForNowStartAsBeginner;

  /// onboarding. Start Assessment
  ///
  /// In en, this message translates to:
  /// **'Start Assessment'**
  String get onboardingStartAssessment;

  /// onboarding. Answer 3 quick questions to help us personalize your learning journey.
  ///
  /// In en, this message translates to:
  /// **'Answer 3 quick questions to help us personalize your learning journey.'**
  String get onboardingAnswer3QuickQuestionsToHelp;

  /// onboarding. Let us see where you stand, traveler.
  ///
  /// In en, this message translates to:
  /// **'Let us see where you stand, traveler.'**
  String get onboardingLetUsSeeWhereYouStand;

  /// onboarding. Understand complex discussions
  ///
  /// In en, this message translates to:
  /// **'Understand complex discussions'**
  String get onboardingUnderstandComplexDiscussions;

  /// onboarding. Understand most everyday conversations
  ///
  /// In en, this message translates to:
  /// **'Understand most everyday conversations'**
  String get onboardingUnderstandMostEverydayConversations;

  /// onboarding. Understand short, simple conversations
  ///
  /// In en, this message translates to:
  /// **'Understand short, simple conversations'**
  String get onboardingUnderstandShortSimpleConversations;

  /// onboarding. Understand greetings and simple words
  ///
  /// In en, this message translates to:
  /// **'Understand greetings and simple words'**
  String get onboardingUnderstandGreetingsAndSimpleWords;

  /// onboarding. Cannot understand anything
  ///
  /// In en, this message translates to:
  /// **'Cannot understand anything'**
  String get onboardingCannotUnderstandAnything;

  /// onboarding. How confident are you in understanding spoken African languages?
  ///
  /// In en, this message translates to:
  /// **'How confident are you in understanding spoken African languages?'**
  String get onboardingHowConfidentAreYouInUnderstanding;

  /// onboarding. I can read fluently
  ///
  /// In en, this message translates to:
  /// **'I can read fluently'**
  String get onboardingICanReadFluently;

  /// onboarding. I can read sentences
  ///
  /// In en, this message translates to:
  /// **'I can read sentences'**
  String get onboardingICanReadSentences;

  /// onboarding. I can read simple words
  ///
  /// In en, this message translates to:
  /// **'I can read simple words'**
  String get onboardingICanReadSimpleWords;

  /// onboarding. I can recognize some letters/characters
  ///
  /// In en, this message translates to:
  /// **'I can recognize some letters/characters'**
  String get onboardingICanRecognizeSomeLettersCharacters;

  /// onboarding. Not at all
  ///
  /// In en, this message translates to:
  /// **'Not at all'**
  String get onboardingNotAtAll;

  /// onboarding. Can you read or write in the African language you want to learn?
  ///
  /// In en, this message translates to:
  /// **'Can you read or write in the African language you want to learn?'**
  String get onboardingCanYouReadOrWriteIn;

  /// onboarding. Advanced - speak fluently
  ///
  /// In en, this message translates to:
  /// **'Advanced - speak fluently'**
  String get onboardingAdvancedSpeakFluently;

  /// onboarding. Intermediate - can hold conversations
  ///
  /// In en, this message translates to:
  /// **'Intermediate - can hold conversations'**
  String get onboardingIntermediateCanHoldConversations;

  /// onboarding. Basic - can introduce myself
  ///
  /// In en, this message translates to:
  /// **'Basic - can introduce myself'**
  String get onboardingBasicCanIntroduceMyself;

  /// onboarding. Some exposure - know a few words
  ///
  /// In en, this message translates to:
  /// **'Some exposure - know a few words'**
  String get onboardingSomeExposureKnowAFewWords;

  /// onboarding. Complete beginner - never learned one
  ///
  /// In en, this message translates to:
  /// **'Complete beginner - never learned one'**
  String get onboardingCompleteBeginnerNeverLearnedOne;

  /// onboarding. How would you describe your familiarity with African languages?
  ///
  /// In en, this message translates to:
  /// **'How would you describe your familiarity with African languages?'**
  String get onboardingHowWouldYouDescribeYourFamiliarity;

  /// onboarding. Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// onboarding. Enter your username
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get onboardingEnterYourUsername;

  /// onboarding. A learner without a name is a drum without a rhythm!
  /// Tell us what you wish to be
  ///
  /// In en, this message translates to:
  /// **'A learner without a name is a drum without a rhythm!\nTell us what you wish to be called.'**
  String get onboardingALearnerWithoutANameIs;

  /// onboarding. Build your clan.
  ///
  /// In en, this message translates to:
  /// **'Build your clan.'**
  String get onboardingBuildYourClan;

  /// onboarding. I am the Healer.
  /// Let me make your journey smooth.
  ///
  /// In en, this message translates to:
  /// **'I am the Healer.\nLet me make your journey smooth.'**
  String get onboardingIAmTheHealerLetMe;

  /// onboarding. Gamification
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get onboardingGamification;

  /// onboarding. Tone Preference
  ///
  /// In en, this message translates to:
  /// **'Tone Preference'**
  String get onboardingTonePreference;

  /// onboarding. I am Amina the Griot.
  /// How shall I speak to you?
  ///
  /// In en, this message translates to:
  /// **'I am Amina the Griot.\nHow shall I speak to you?'**
  String get onboardingIAmAminaTheGriotHow;

  /// onboarding. Choose your path.
  ///
  /// In en, this message translates to:
  /// **'Choose your path.'**
  String get onboardingChooseYourPath;

  /// onboarding. Brain Training
  ///
  /// In en, this message translates to:
  /// **'Brain Training'**
  String get onboardingBrainTraining;

  /// onboarding. Confidence
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get onboardingConfidence;

  /// onboarding. Academic
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get onboardingAcademic;

  /// onboarding. Business
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get onboardingBusiness;

  /// onboarding. Heritage
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get onboardingHeritage;

  /// onboarding. Travel
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get onboardingTravel;

  /// onboarding. I am Zawadi, keeper of time.
  /// When shall we train your tongue?
  ///
  /// In en, this message translates to:
  /// **'I am Zawadi, keeper of time.\nWhen shall we train your tongue?'**
  String get onboardingIAmZawadiKeeperOfTime;

  /// onboarding. I am Nuru the Rhythm Master.
  /// Tap the drum that sings to your spirit.
  ///
  /// In en, this message translates to:
  /// **'I am Nuru the Rhythm Master.\nTap the drum that sings to your spirit.'**
  String get onboardingIAmNuruTheRhythmMaster;

  /// onboarding. What's your level?
  ///
  /// In en, this message translates to:
  /// **'What\'s your level?'**
  String get onboardingWhatSYourLevel;

  /// onboarding. Select Language
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get onboardingSelectLanguage;

  /// onboarding. I am Adisa, the Weaver.
  /// Choose the threads of your voice.
  ///
  /// In en, this message translates to:
  /// **'I am Adisa, the Weaver.\nChoose the threads of your voice.'**
  String get onboardingIAmAdisaTheWeaverChoose;

  /// onboarding. Tell me: who are you?
  ///
  /// In en, this message translates to:
  /// **'Tell me: who are you?'**
  String get onboardingTellMeWhoAreYou;

  /// onboarding. Welcome, traveler. I am Pa LingAfriq,
  /// keeper of the village memory.
  ///
  /// In en, this message translates to:
  /// **'Welcome, traveler. I am Pa LingAfriq,\nkeeper of the village memory.'**
  String get onboardingWelcomeTravelerIAmPaLingafriq;

  /// onboarding. Begin Journey
  ///
  /// In en, this message translates to:
  /// **'Begin Journey'**
  String get onboardingBeginJourney;

  /// onboarding. The Language Village
  /// Your journey begins here
  ///
  /// In en, this message translates to:
  /// **'The Language Village\nYour journey begins here'**
  String get onboardingTheLanguageVillageYourJourneyBegins;

  /// onboarding. Welcome to
  /// Kijiji cha Lugha
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nKijiji cha Lugha'**
  String get onboardingWelcomeToKijijiChaLugha;

  /// onboarding. Loading...
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get onboardingLoading;

  /// onboarding. Already learning? Log in
  ///
  /// In en, this message translates to:
  /// **'Already learning? Log in'**
  String get onboardingAlreadyLearningLogIn;

  /// onboarding. Get Started
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// onboarding. Choose your path and unlock new opportunities
  ///
  /// In en, this message translates to:
  /// **'Choose your path and unlock new opportunities'**
  String get onboardingChooseYourPathAndUnlockNew;

  /// onboarding. Your Language Journey
  /// Starts Here!
  ///
  /// In en, this message translates to:
  /// **'Your Language Journey\nStarts Here!'**
  String get onboardingYourLanguageJourneyStartsHere;

  /// onboarding. Prioritize how your community really speaks
  ///
  /// In en, this message translates to:
  /// **'Prioritize how your community really speaks'**
  String get onboardingPrioritizeHowYourCommunityReallySpeaks;

  /// onboarding. Local Dialect & Heritage
  ///
  /// In en, this message translates to:
  /// **'Local Dialect & Heritage'**
  String get onboardingLocalDialectHeritage;

  /// onboarding. Prepare for studies and broaden knowledge
  ///
  /// In en, this message translates to:
  /// **'Prepare for studies and broaden knowledge'**
  String get onboardingPrepareForStudiesAndBroadenKnowledge;

  /// onboarding. Excel Academically
  ///
  /// In en, this message translates to:
  /// **'Excel Academically'**
  String get onboardingExcelAcademically;

  /// onboarding. Open doors to international opportunities
  ///
  /// In en, this message translates to:
  /// **'Open doors to international opportunities'**
  String get onboardingOpenDoorsToInternationalOpportunities;

  /// onboarding. Boost Your Career
  ///
  /// In en, this message translates to:
  /// **'Boost Your Career'**
  String get onboardingBoostYourCareer;

  /// onboarding. Discover the rich heritage of African languages
  ///
  /// In en, this message translates to:
  /// **'Discover the rich heritage of African languages'**
  String get onboardingDiscoverTheRichHeritageOfAfrican;

  /// onboarding. Explore Cultures
  ///
  /// In en, this message translates to:
  /// **'Explore Cultures'**
  String get onboardingExploreCultures;

  /// onboarding. Explore 54 countries, 2000+ languages,
  /// and connect with 1+ billion voices
  ///
  /// In en, this message translates to:
  /// **'Explore 54 countries, 2000+ languages,\nand connect with 1+ billion voices'**
  String get onboardingExplore54Countries2000LanguagesAnd;

  /// onboarding. Ready for a
  /// pan-African adventure?
  ///
  /// In en, this message translates to:
  /// **'Ready for a\npan-African adventure?'**
  String get onboardingReadyForAPanAfricanAdventure;

  /// onboarding. Learn a new language,
  /// the fun way
  ///
  /// In en, this message translates to:
  /// **'Learn a new language,\nthe fun way'**
  String get onboardingLearnANewLanguageTheFun;

  /// onboarding. Learn about history, traditions, and cultural expressions
  ///
  /// In en, this message translates to:
  /// **'Learn about history, traditions, and cultural expressions'**
  String get onboardingLearnAboutHistoryTraditionsAndCultural;

  /// onboarding. Connect with culture
  ///
  /// In en, this message translates to:
  /// **'Connect with culture'**
  String get onboardingConnectWithCulture;

  /// onboarding. Stay motivated with personalized challenges and daily goals
  ///
  /// In en, this message translates to:
  /// **'Stay motivated with personalized challenges and daily goals'**
  String get onboardingStayMotivatedWithPersonalizedChallenge;

  /// onboarding. Track your progress
  ///
  /// In en, this message translates to:
  /// **'Track your progress'**
  String get onboardingTrackYourProgress;

  /// onboarding. Fun, bite-sized lessons make learning addictive and effective
  ///
  /// In en, this message translates to:
  /// **'Fun, bite-sized lessons make learning addictive and effective'**
  String get onboardingFunBiteSizedLessonsMakeLearning;

  /// onboarding. Learn languages, play games
  ///
  /// In en, this message translates to:
  /// **'Learn languages, play games'**
  String get onboardingLearnLanguagesPlayGames;

  /// onboarding. Discover the beauty of African languages
  ///
  /// In en, this message translates to:
  /// **'Discover the beauty of African languages'**
  String get onboardingDiscoverTheBeautyOfAfricanLanguages;

  /// onboarding. Your journey to fluency
  /// starts now!
  ///
  /// In en, this message translates to:
  /// **'Your journey to fluency\nstarts now!'**
  String get onboardingYourJourneyToFluencyStartsNow;

  /// onboarding. What Do We Offer Uniqely
  ///
  /// In en, this message translates to:
  /// **'What Do We Offer Uniqely'**
  String get onboardingWhatDoWeOfferUniqely;

  /// onboarding. 54 countries, 2000+ languages, 1+ billion voices. One origin.
  ///
  /// In en, this message translates to:
  /// **'54 countries, 2000+ languages, 1+ billion voices. One origin. '**
  String get onboardingText54Countries2000Languages1Billion;

  /// onboarding. {value} / {value2}
  ///
  /// In en, this message translates to:
  /// **'{value} / {value2}'**
  String onboardingValueValue2(String value, String value2);

  /// onboarding. Placement Test
  ///
  /// In en, this message translates to:
  /// **'Placement Test'**
  String get onboardingPlacementTest;

  /// onboarding. Go Back
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get onboardingGoBack;

  /// onboarding. Please try again later.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get onboardingPleaseTryAgainLater;

  /// onboarding. Placement questions are not available right now.
  ///
  /// In en, this message translates to:
  /// **'Placement questions are not available right now.'**
  String get onboardingPlacementQuestionsAreNotAvailableRight;

  /// onboarding. Loading placement test...
  ///
  /// In en, this message translates to:
  /// **'Loading placement test...'**
  String get onboardingLoadingPlacementTest;

  /// onboarding. Areas for Improvement
  ///
  /// In en, this message translates to:
  /// **'Areas for Improvement'**
  String get onboardingAreasForImprovement;

  /// onboarding. Your Proficiency Level
  ///
  /// In en, this message translates to:
  /// **'Your Proficiency Level'**
  String get onboardingYourProficiencyLevel;

  /// onboarding. Placement Test Complete!
  ///
  /// In en, this message translates to:
  /// **'Placement Test Complete!'**
  String get onboardingPlacementTestComplete;

  /// onboarding. Previous
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get onboardingPrevious;

  /// onboarding. Your Answer
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get onboardingYourAnswer;

  /// onboarding. Selected
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get onboardingSelected;

  /// onboarding. Answer option: {option}{value}
  ///
  /// In en, this message translates to:
  /// **'Answer option: {option}{value}'**
  String onboardingAnswerOptionOptionValue(String option, String value);

  /// onboarding. Question {value} of {value2}
  ///
  /// In en, this message translates to:
  /// **'Question {value} of {value2}'**
  String onboardingQuestionValueOfValue2(String value, String value2);

  /// onboarding. {value} of {value2}
  ///
  /// In en, this message translates to:
  /// **'{value} of {value2}'**
  String onboardingValueOfValue2(String value, String value2);

  /// onboarding. Progress: question {value} of {value2}
  ///
  /// In en, this message translates to:
  /// **'Progress: question {value} of {value2}'**
  String onboardingProgressQuestionValueOfValue2(String value, String value2);

  /// onboarding. Loading test...
  ///
  /// In en, this message translates to:
  /// **'Loading test...'**
  String get onboardingLoadingTest;

  /// onboarding. Try Again
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get onboardingTryAgain;

  /// onboarding. Continue Without Test
  ///
  /// In en, this message translates to:
  /// **'Continue Without Test'**
  String get onboardingContinueWithoutTest;

  /// onboarding. We couldn't connect to the server to generate your placement test. You can conti
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t connect to the server to generate your placement test. You can continue without it and take it later from your profile.'**
  String get onboardingWeCouldnTConnectToThe;

  /// onboarding. Unable to Generate Placement Test
  ///
  /// In en, this message translates to:
  /// **'Unable to Generate Placement Test'**
  String get onboardingUnableToGeneratePlacementTest;

  /// onboarding. Generating your placement test...
  ///
  /// In en, this message translates to:
  /// **'Generating your placement test...'**
  String get onboardingGeneratingYourPlacementTest;

  /// onboarding. Please answer all questions
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions'**
  String get onboardingPleaseAnswerAllQuestions;

  /// onboarding. Engage with native content
  ///
  /// In en, this message translates to:
  /// **'Engage with native content'**
  String get onboardingEngageWithNativeContent;

  /// onboarding. Focus on fluency and nuance
  ///
  /// In en, this message translates to:
  /// **'Focus on fluency and nuance'**
  String get onboardingFocusOnFluencyAndNuance;

  /// onboarding. Advanced lessons recommended
  ///
  /// In en, this message translates to:
  /// **'Advanced lessons recommended'**
  String get onboardingAdvancedLessonsRecommended;

  /// onboarding. Expand vocabulary in specific topics
  ///
  /// In en, this message translates to:
  /// **'Expand vocabulary in specific topics'**
  String get onboardingExpandVocabularyInSpecificTopics;

  /// onboarding. Practice conversation skills
  ///
  /// In en, this message translates to:
  /// **'Practice conversation skills'**
  String get onboardingPracticeConversationSkills;

  /// onboarding. Continue with intermediate content
  ///
  /// In en, this message translates to:
  /// **'Continue with intermediate content'**
  String get onboardingContinueWithIntermediateContent;

  /// onboarding. Practice pronunciation daily
  ///
  /// In en, this message translates to:
  /// **'Practice pronunciation daily'**
  String get onboardingPracticePronunciationDaily;

  /// onboarding. Focus on vocabulary building
  ///
  /// In en, this message translates to:
  /// **'Focus on vocabulary building'**
  String get onboardingFocusOnVocabularyBuilding;

  /// onboarding. Start with beginner lessons
  ///
  /// In en, this message translates to:
  /// **'Start with beginner lessons'**
  String get onboardingStartWithBeginnerLessons;

  /// onboarding. Start with the first lessons. A level waits until calibrated items are available
  ///
  /// In en, this message translates to:
  /// **'Start with the first lessons. A level waits until calibrated items are available.'**
  String get onboardingStartWithTheFirstLessonsA;

  /// onboarding. Some grammar concepts need review
  ///
  /// In en, this message translates to:
  /// **'Some grammar concepts need review'**
  String get onboardingSomeGrammarConceptsNeedReview;

  /// onboarding. Grammar fundamentals needed
  ///
  /// In en, this message translates to:
  /// **'Grammar fundamentals needed'**
  String get onboardingGrammarFundamentalsNeeded;

  /// onboarding. Need to build vocabulary
  ///
  /// In en, this message translates to:
  /// **'Need to build vocabulary'**
  String get onboardingNeedToBuildVocabulary;

  /// onboarding. Willingness to learn
  ///
  /// In en, this message translates to:
  /// **'Willingness to learn'**
  String get onboardingWillingnessToLearn;

  /// onboarding. Basic vocabulary knowledge
  ///
  /// In en, this message translates to:
  /// **'Basic vocabulary knowledge'**
  String get onboardingBasicVocabularyKnowledge;

  /// onboarding. Good understanding of basic grammar
  ///
  /// In en, this message translates to:
  /// **'Good understanding of basic grammar'**
  String get onboardingGoodUnderstandingOfBasicGrammar;

  /// onboarding. Strong vocabulary foundation
  ///
  /// In en, this message translates to:
  /// **'Strong vocabulary foundation'**
  String get onboardingStrongVocabularyFoundation;

  /// onboarding. A precise level needs more calibrated items
  ///
  /// In en, this message translates to:
  /// **'A precise level needs more calibrated items'**
  String get onboardingAPreciseLevelNeedsMoreCalibrated;

  /// onboarding. Keep learning. My parent will add it later
  ///
  /// In en, this message translates to:
  /// **'Keep learning. My parent will add it later'**
  String get onboardingKeepLearningMyParentWillAdd;

  /// onboarding. Parent's email
  ///
  /// In en, this message translates to:
  /// **'Parent\'s email'**
  String get onboardingParentSEmail;

  /// onboarding. A parent or guardian says yes before you chat or share. Add their email so they
  ///
  /// In en, this message translates to:
  /// **'A parent or guardian says yes before you chat or share. Add their email so they can approve your account.'**
  String get onboardingAParentOrGuardianSaysYes;

  /// onboarding. Ask a parent
  ///
  /// In en, this message translates to:
  /// **'Ask a parent'**
  String get onboardingAskAParent;

  /// onboarding. Your profile stays private, and adults cannot send you direct messages.
  ///
  /// In en, this message translates to:
  /// **'Your profile stays private, and adults cannot send you direct messages.'**
  String get onboardingYourProfileStaysPrivateAndAdults;

  /// onboarding. Type it instead
  ///
  /// In en, this message translates to:
  /// **'Type it instead'**
  String get onboardingTypeItInstead;

  /// onboarding. {value}
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String onboardingValue(String value);

  /// onboarding. Swipe up or down to change the year
  ///
  /// In en, this message translates to:
  /// **'Swipe up or down to change the year'**
  String get onboardingSwipeUpOrDownToChange;

  /// onboarding. Birth year
  ///
  /// In en, this message translates to:
  /// **'Birth year'**
  String get onboardingBirthYear;

  /// onboarding. Use the year wheel
  ///
  /// In en, this message translates to:
  /// **'Use the year wheel'**
  String get onboardingUseTheYearWheel;

  /// onboarding. For example {value}
  ///
  /// In en, this message translates to:
  /// **'For example {value}'**
  String onboardingForExampleValue(String value);

  /// onboarding. This helps us keep LingAfriq right for you. We only ask for the year.
  ///
  /// In en, this message translates to:
  /// **'This helps us keep LingAfriq right for you. We only ask for the year.'**
  String get onboardingThisHelpsUsKeepLingafriqRight;

  /// onboarding. {minutes} min
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String onboardingMinutesMin(String minutes);

  /// onboarding. You can change this any time in Settings.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time in Settings.'**
  String get onboardingYouCanChangeThisAnyTime;

  /// onboarding. How much time a day feels right?
  ///
  /// In en, this message translates to:
  /// **'How much time a day feels right?'**
  String get onboardingHowMuchTimeADayFeels;

  /// onboarding. For a trip or a big day soon
  ///
  /// In en, this message translates to:
  /// **'For a trip or a big day soon'**
  String get onboardingForATripOrABig;

  /// onboarding. Hold a short chat in weeks
  ///
  /// In en, this message translates to:
  /// **'Hold a short chat in weeks'**
  String get onboardingHoldAShortChatInWeeks;

  /// onboarding. A good daily start
  ///
  /// In en, this message translates to:
  /// **'A good daily start'**
  String get onboardingAGoodDailyStart;

  /// onboarding. A greeting a day
  ///
  /// In en, this message translates to:
  /// **'A greeting a day'**
  String get onboardingAGreetingADay;

  /// onboarding. Can't speak now
  ///
  /// In en, this message translates to:
  /// **'Can\'t speak now'**
  String get onboardingCanTSpeakNow;

  /// onboarding. I said it
  ///
  /// In en, this message translates to:
  /// **'I said it'**
  String get onboardingISaidIt;

  /// onboarding. Mark that you said {value}
  ///
  /// In en, this message translates to:
  /// **'Mark that you said {value}'**
  String onboardingMarkThatYouSaidValue(String value);

  /// onboarding. Say it with Polie
  ///
  /// In en, this message translates to:
  /// **'Say it with Polie'**
  String get onboardingSayItWithPolie;

  /// onboarding. Tap the greeting
  ///
  /// In en, this message translates to:
  /// **'Tap the greeting'**
  String get onboardingTapTheGreeting;

  /// onboarding. We could not play sound right now. You can still continue.
  ///
  /// In en, this message translates to:
  /// **'We could not play sound right now. You can still continue.'**
  String get onboardingWeCouldNotPlaySoundRight;

  /// onboarding. Play greeting
  ///
  /// In en, this message translates to:
  /// **'Play greeting'**
  String get onboardingPlayGreeting;

  /// onboarding. Audio unavailable
  ///
  /// In en, this message translates to:
  /// **'Audio unavailable'**
  String get onboardingAudioUnavailable;

  /// onboarding. Heard it
  ///
  /// In en, this message translates to:
  /// **'Heard it'**
  String get onboardingHeardIt;

  /// onboarding. Play greeting {value}
  ///
  /// In en, this message translates to:
  /// **'Play greeting {value}'**
  String onboardingPlayGreetingValue(String value);

  /// onboarding. Playing greeting
  ///
  /// In en, this message translates to:
  /// **'Playing greeting'**
  String get onboardingPlayingGreeting;

  /// onboarding. Greeting played
  ///
  /// In en, this message translates to:
  /// **'Greeting played'**
  String get onboardingGreetingPlayed;

  /// onboarding. Hear: {value}
  ///
  /// In en, this message translates to:
  /// **'Hear: {value}'**
  String onboardingHearValue(String value);

  /// onboarding. A 60-second taste of {value}. Hear, tap, say.
  ///
  /// In en, this message translates to:
  /// **'A 60-second taste of {value}. Hear, tap, say.'**
  String onboardingA60SecondTasteOfValue(String value);

  /// onboarding. Your first win
  ///
  /// In en, this message translates to:
  /// **'Your first win'**
  String get onboardingYourFirstWin;

  /// onboarding. Lesson done
  ///
  /// In en, this message translates to:
  /// **'Lesson done'**
  String get onboardingLessonDone;

  /// onboarding. New word
  ///
  /// In en, this message translates to:
  /// **'New word'**
  String get onboardingNewWord;

  /// onboarding. Celebrate progress, not perfection.
  ///
  /// In en, this message translates to:
  /// **'Celebrate progress, not perfection.'**
  String get onboardingCelebrateProgressNotPerfection;

  /// onboarding. You did it!
  ///
  /// In en, this message translates to:
  /// **'You did it!'**
  String get onboardingYouDidIt;

  /// onboarding. Keep going
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get onboardingKeepGoing;

  /// onboarding. Ina kwana
  ///
  /// In en, this message translates to:
  /// **'Ina kwana'**
  String get onboardingInaKwana;

  /// onboarding. {words} words in your basket
  ///
  /// In en, this message translates to:
  /// **'{words} words in your basket'**
  String onboardingWordsWordsInYourBasket(String words);

  /// onboarding. Polie is keeping your seat in the village.
  ///
  /// In en, this message translates to:
  /// **'Polie is keeping your seat in the village.'**
  String get onboardingPolieIsKeepingYourSeatIn;

  /// onboarding. Ẹ kú àbọ̀
  ///
  /// In en, this message translates to:
  /// **'Ẹ kú àbọ̀'**
  String get onboardingKB;

  /// onboarding. እንኳን ደህና መጡ
  ///
  /// In en, this message translates to:
  /// **'እንኳን ደህና መጡ'**
  String get onboardingText;

  /// onboarding. How far?
  ///
  /// In en, this message translates to:
  /// **'How far?'**
  String get onboardingHowFar;

  /// onboarding. Dalal ak jàmm
  ///
  /// In en, this message translates to:
  /// **'Dalal ak jàmm'**
  String get onboardingDalalAkJMm;

  /// onboarding. {value} · {value2}
  ///
  /// In en, this message translates to:
  /// **'{value} · {value2}'**
  String onboardingValueValue26468(String value, String value2);

  /// onboarding. Try a region, a script name, or clear the box.
  ///
  /// In en, this message translates to:
  /// **'Try a region, a script name, or clear the box.'**
  String get onboardingTryARegionAScriptName;

  /// onboarding. No languages match that search.
  ///
  /// In en, this message translates to:
  /// **'No languages match that search.'**
  String get onboardingNoLanguagesMatchThatSearch;

  /// onboarding. No languages match your search
  ///
  /// In en, this message translates to:
  /// **'No languages match your search'**
  String get onboardingNoLanguagesMatchYourSearch;

  /// onboarding. I speak
  ///
  /// In en, this message translates to:
  /// **'I speak'**
  String get onboardingISpeak;

  /// onboarding. What do you want to learn?
  ///
  /// In en, this message translates to:
  /// **'What do you want to learn?'**
  String get onboardingWhatDoYouWantToLearn;

  /// onboarding. North Africa
  ///
  /// In en, this message translates to:
  /// **'North Africa'**
  String get onboardingNorthAfrica;

  /// onboarding. ⵜⴰⵎⴰⵣⵉⵖⵜ
  ///
  /// In en, this message translates to:
  /// **'ⵜⴰⵎⴰⵣⵉⵖⵜ'**
  String get onboardingText526f;

  /// onboarding. Tamazight
  ///
  /// In en, this message translates to:
  /// **'Tamazight'**
  String get onboardingTamazight;

  /// onboarding. الدارجة
  ///
  /// In en, this message translates to:
  /// **'الدارجة'**
  String get onboardingTextd271;

  /// onboarding. Darija
  ///
  /// In en, this message translates to:
  /// **'Darija'**
  String get onboardingDarija;

  /// onboarding. Southern Africa
  ///
  /// In en, this message translates to:
  /// **'Southern Africa'**
  String get onboardingSouthernAfrica;

  /// onboarding. isiXhosa
  ///
  /// In en, this message translates to:
  /// **'isiXhosa'**
  String get onboardingIsixhosa;

  /// onboarding. isiZulu
  ///
  /// In en, this message translates to:
  /// **'isiZulu'**
  String get onboardingIsizulu;

  /// onboarding. East Africa
  ///
  /// In en, this message translates to:
  /// **'East Africa'**
  String get onboardingEastAfrica;

  /// onboarding. አማርኛ
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get onboardingText91cf;

  /// onboarding. Kiswahili
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get onboardingKiswahili;

  /// onboarding. West Africa
  ///
  /// In en, this message translates to:
  /// **'West Africa'**
  String get onboardingWestAfrica;

  /// onboarding. Naijá
  ///
  /// In en, this message translates to:
  /// **'Naijá'**
  String get onboardingNaij;

  /// onboarding. Asụsụ Igbo
  ///
  /// In en, this message translates to:
  /// **'Asụsụ Igbo'**
  String get onboardingAsSIgbo;

  /// onboarding. Èdè Yorùbá
  ///
  /// In en, this message translates to:
  /// **'Èdè Yorùbá'**
  String get onboardingDYorB;

  /// onboarding. العربية
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get onboardingText9970;

  /// onboarding. Português
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get onboardingPortuguS;

  /// onboarding. Français
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get onboardingFranAis;

  /// onboarding. Pick the style that feels most natural.
  ///
  /// In en, this message translates to:
  /// **'Pick the style that feels most natural.'**
  String get onboardingPickTheStyleThatFeelsMost;

  /// onboarding. Variety of methods
  ///
  /// In en, this message translates to:
  /// **'Variety of methods'**
  String get onboardingVarietyOfMethods;

  /// onboarding. Mixed
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get onboardingMixed;

  /// onboarding. Talk to learn
  ///
  /// In en, this message translates to:
  /// **'Talk to learn'**
  String get onboardingTalkToLearn;

  /// onboarding. Conversation
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get onboardingConversation;

  /// onboarding. Repetition & drills
  ///
  /// In en, this message translates to:
  /// **'Repetition & drills'**
  String get onboardingRepetitionDrills;

  /// onboarding. Practice
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get onboardingPractice;

  /// onboarding. Narrative learning
  ///
  /// In en, this message translates to:
  /// **'Narrative learning'**
  String get onboardingNarrativeLearning;

  /// onboarding. Stories
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get onboardingStories;

  /// onboarding. See to remember
  ///
  /// In en, this message translates to:
  /// **'See to remember'**
  String get onboardingSeeToRemember;

  /// onboarding. Visual
  ///
  /// In en, this message translates to:
  /// **'Visual'**
  String get onboardingVisual;

  /// onboarding. Learn by ear
  ///
  /// In en, this message translates to:
  /// **'Learn by ear'**
  String get onboardingLearnByEar;

  /// onboarding. Listening
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get onboardingListening;

  /// onboarding. Ẹ káàárọ̀
  ///
  /// In en, this message translates to:
  /// **'Ẹ káàárọ̀'**
  String get onboardingKR;

  /// onboarding. Na gode
  ///
  /// In en, this message translates to:
  /// **'Na gode'**
  String get onboardingNaGode;

  /// onboarding. Quick check: tap each word you recognize.
  ///
  /// In en, this message translates to:
  /// **'Quick check: tap each word you recognize.'**
  String get onboardingQuickCheckTapEachWordYou;

  /// onboarding. Not sure? Take a 1‑minute check
  ///
  /// In en, this message translates to:
  /// **'Not sure? Take a 1‑minute check'**
  String get onboardingNotSureTakeA1Minute;

  /// onboarding. How much {langName} do you know?
  ///
  /// In en, this message translates to:
  /// **'How much {langName} do you know?'**
  String onboardingHowMuchLangnameDoYouKnow(String langName);

  /// onboarding. this language
  ///
  /// In en, this message translates to:
  /// **'this language'**
  String get onboardingThisLanguage;

  /// onboarding. I can hold a conversation
  ///
  /// In en, this message translates to:
  /// **'I can hold a conversation'**
  String get onboardingICanHoldAConversation;

  /// onboarding. I can talk about various topics
  ///
  /// In en, this message translates to:
  /// **'I can talk about various topics'**
  String get onboardingICanTalkAboutVariousTopics;

  /// onboarding. I know some common words
  ///
  /// In en, this message translates to:
  /// **'I know some common words'**
  String get onboardingIKnowSomeCommonWords;

  /// onboarding. I'm new
  ///
  /// In en, this message translates to:
  /// **'I\'m new'**
  String get onboardingIMNew;

  /// onboarding. Best time
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get onboardingBestTime;

  /// onboarding. See the reminder below. Turn it on only if it helps you keep your streak. You pi
  ///
  /// In en, this message translates to:
  /// **'See the reminder below. Turn it on only if it helps you keep your streak. You pick the time.'**
  String get onboardingSeeTheReminderBelowTurnIt;

  /// onboarding. A soft nudge when it matters
  ///
  /// In en, this message translates to:
  /// **'A soft nudge when it matters'**
  String get onboardingASoftNudgeWhenItMatters;

  /// onboarding. Not now
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotNow;

  /// onboarding. Turn on reminders
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get onboardingTurnOnReminders;

  /// onboarding. {dailyMinutes} minutes
  ///
  /// In en, this message translates to:
  /// **'{dailyMinutes} minutes'**
  String onboardingDailyminutesMinutes(String dailyMinutes);

  /// onboarding. 5 minutes
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get onboardingText5Minutes;

  /// onboarding. 8–10 PM
  ///
  /// In en, this message translates to:
  /// **'8–10 PM'**
  String get onboardingText810Pm;

  /// onboarding. Night
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get onboardingNight;

  /// onboarding. 5–7 PM
  ///
  /// In en, this message translates to:
  /// **'5–7 PM'**
  String get onboardingText57Pm;

  /// onboarding. Sunset
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get onboardingSunset;

  /// onboarding. 12–2 PM
  ///
  /// In en, this message translates to:
  /// **'12–2 PM'**
  String get onboardingText122Pm;

  /// onboarding. Midday
  ///
  /// In en, this message translates to:
  /// **'Midday'**
  String get onboardingMidday;

  /// onboarding. 6–9 AM
  ///
  /// In en, this message translates to:
  /// **'6–9 AM'**
  String get onboardingText69Am;

  /// onboarding. Sunrise
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get onboardingSunrise;

  /// onboarding. Preview: how you appear in the village, {shown}
  ///
  /// In en, this message translates to:
  /// **'Preview: how you appear in the village, {shown}'**
  String onboardingPreviewHowYouAppearInThe(String shown);

  /// onboarding. Your name
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingYourName;

  /// onboarding. We couldn't check that just now, but you can still continue
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check that just now, but you can still continue'**
  String get onboardingWeCouldnTCheckThatJust;

  /// onboarding. Only letters, numbers, and underscores, please
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and underscores, please'**
  String get onboardingOnlyLettersNumbersAndUnderscoresPlease;

  /// onboarding. Keep it to 30 characters or fewer
  ///
  /// In en, this message translates to:
  /// **'Keep it to 30 characters or fewer'**
  String get onboardingKeepItTo30CharactersOr;

  /// onboarding. Needs at least 3 characters
  ///
  /// In en, this message translates to:
  /// **'Needs at least 3 characters'**
  String get onboardingNeedsAtLeast3Characters;

  /// onboarding. Someone's already using that one, try another
  ///
  /// In en, this message translates to:
  /// **'Someone\'s already using that one, try another'**
  String get onboardingSomeoneSAlreadyUsingThatOne;

  /// onboarding. That name is yours
  ///
  /// In en, this message translates to:
  /// **'That name is yours'**
  String get onboardingThatNameIsYours;

  /// onboarding. Checking if that name is free…
  ///
  /// In en, this message translates to:
  /// **'Checking if that name is free…'**
  String get onboardingCheckingIfThatNameIsFree;

  /// onboarding. Use 3 to 30 letters, numbers, or underscores
  ///
  /// In en, this message translates to:
  /// **'Use 3 to 30 letters, numbers, or underscores'**
  String get onboardingUse3To30LettersNumbers;

  /// onboarding. Use the name {idea}
  ///
  /// In en, this message translates to:
  /// **'Use the name {idea}'**
  String onboardingUseTheNameIdea(String idea);

  /// onboarding. Ideas from your language
  ///
  /// In en, this message translates to:
  /// **'Ideas from your language'**
  String get onboardingIdeasFromYourLanguage;

  /// onboarding. Add a photo (optional)
  ///
  /// In en, this message translates to:
  /// **'Add a photo (optional)'**
  String get onboardingAddAPhotoOptional;

  /// onboarding. Add a profile photo, optional
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo, optional'**
  String get onboardingAddAProfilePhotoOptional;

  /// onboarding. A learner without a name is a drum without a rhythm.
  ///
  /// In en, this message translates to:
  /// **'A learner without a name is a drum without a rhythm.'**
  String get onboardingALearnerWithoutANameIs56f4;

  /// onboarding. Pick a name
  ///
  /// In en, this message translates to:
  /// **'Pick a name'**
  String get onboardingPickAName;

  /// onboarding. Skip for now
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkipForNow;

  /// onboarding. Complete setup
  ///
  /// In en, this message translates to:
  /// **'Complete setup'**
  String get onboardingCompleteSetup;

  /// onboarding. Pick all that fit. Your first lessons follow your answer.
  ///
  /// In en, this message translates to:
  /// **'Pick all that fit. Your first lessons follow your answer.'**
  String get onboardingPickAllThatFitYourFirst;

  /// onboarding. Why are you learning {languageName}?
  ///
  /// In en, this message translates to:
  /// **'Why are you learning {languageName}?'**
  String onboardingWhyAreYouLearningLanguagename(String languageName);

  /// onboarding. Colleagues, clients and community
  ///
  /// In en, this message translates to:
  /// **'Colleagues, clients and community'**
  String get onboardingColleaguesClientsAndCommunity;

  /// onboarding. Markets, directions and small talk
  ///
  /// In en, this message translates to:
  /// **'Markets, directions and small talk'**
  String get onboardingMarketsDirectionsAndSmallTalk;

  /// onboarding. Proverbs, names, music and stories
  ///
  /// In en, this message translates to:
  /// **'Proverbs, names, music and stories'**
  String get onboardingProverbsNamesMusicAndStories;

  /// onboarding. Heritage and culture
  ///
  /// In en, this message translates to:
  /// **'Heritage and culture'**
  String get onboardingHeritageAndCulture;

  /// onboarding. Greet elders and keep up at gatherings
  ///
  /// In en, this message translates to:
  /// **'Greet elders and keep up at gatherings'**
  String get onboardingGreetEldersAndKeepUpAt;

  /// onboarding. Talk to family
  ///
  /// In en, this message translates to:
  /// **'Talk to family'**
  String get onboardingTalkToFamily;

  /// onboarding. Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get onboardingRetry;

  /// onboarding. You're offline. Your answers are saved on this phone. Connect, then try again.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your answers are saved on this phone. Connect, then try again.'**
  String get onboardingYouReOfflineYourAnswersAre;

  /// onboarding. Couldn't reach sign-in
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach sign-in'**
  String get onboardingCouldnTReachSignIn;

  /// onboarding. Error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get onboardingError;

  /// onboarding. Saving your progress…
  ///
  /// In en, this message translates to:
  /// **'Saving your progress…'**
  String get onboardingSavingYourProgress;

  /// onboarding. I already have an account
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get onboardingIAlreadyHaveAnAccount;

  /// onboarding. Sign up with email
  ///
  /// In en, this message translates to:
  /// **'Sign up with email'**
  String get onboardingSignUpWithEmail;

  /// onboarding. Continue with Apple
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get onboardingContinueWithApple;

  /// onboarding. Continue with Google
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get onboardingContinueWithGoogle;

  /// onboarding. You finished your first lesson and learned {words}. An account keeps your progre
  ///
  /// In en, this message translates to:
  /// **'You finished your first lesson and learned {words}. An account keeps your progress safe if you change phones.'**
  String onboardingYouFinishedYourFirstLessonAnd(String words);

  /// onboarding. Save your progress?
  ///
  /// In en, this message translates to:
  /// **'Save your progress?'**
  String get onboardingSaveYourProgress;

  /// onboarding. Later. My answers stay on this phone
  ///
  /// In en, this message translates to:
  /// **'Later. My answers stay on this phone'**
  String get onboardingLaterMyAnswersStayOnThis;

  /// onboarding. {wordsLearned} words
  ///
  /// In en, this message translates to:
  /// **'{wordsLearned} words'**
  String onboardingWordslearnedWords(String wordsLearned);

  /// onboarding. You're offline. Keep going: your answers are saved on this phone and sync when y
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Keep going: your answers are saved on this phone and sync when you reconnect.'**
  String get onboardingYouReOfflineKeepGoingYour;

  /// onboarding. Double tap to choose
  ///
  /// In en, this message translates to:
  /// **'Double tap to choose'**
  String get onboardingDoubleTapToChoose;

  /// onboarding. Saving…
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get onboardingSaving;

  /// onboarding. How much game feel?
  ///
  /// In en, this message translates to:
  /// **'How much game feel?'**
  String get onboardingHowMuchGameFeel;

  /// onboarding. Pick the voice that feels like a good study buddy.
  ///
  /// In en, this message translates to:
  /// **'Pick the voice that feels like a good study buddy.'**
  String get onboardingPickTheVoiceThatFeelsLike;

  /// onboarding. How should Polie sound?
  ///
  /// In en, this message translates to:
  /// **'How should Polie sound?'**
  String get onboardingHowShouldPolieSound;

  /// onboarding. Just learning
  ///
  /// In en, this message translates to:
  /// **'Just learning'**
  String get onboardingJustLearning;

  /// onboarding. Minimal
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get onboardingMinimal;

  /// onboarding. Progress tracking
  ///
  /// In en, this message translates to:
  /// **'Progress tracking'**
  String get onboardingProgressTracking;

  /// onboarding. Moderate
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get onboardingModerate;

  /// onboarding. XP, badges, streaks
  ///
  /// In en, this message translates to:
  /// **'XP, badges, streaks'**
  String get onboardingXpBadgesStreaks;

  /// onboarding. Full
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get onboardingFull;

  /// onboarding. Warm & casual
  ///
  /// In en, this message translates to:
  /// **'Warm & casual'**
  String get onboardingWarmCasual;

  /// onboarding. Friendly
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get onboardingFriendly;

  /// onboarding. Direct & efficient
  ///
  /// In en, this message translates to:
  /// **'Direct & efficient'**
  String get onboardingDirectEfficient;

  /// onboarding. Focused
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get onboardingFocused;

  /// onboarding. Supportive
  ///
  /// In en, this message translates to:
  /// **'Supportive'**
  String get onboardingSupportive;

  /// onboarding. Encouraging
  ///
  /// In en, this message translates to:
  /// **'Encouraging'**
  String get onboardingEncouraging;

  /// onboarding. Fun & light
  ///
  /// In en, this message translates to:
  /// **'Fun & light'**
  String get onboardingFunLight;

  /// onboarding. Playful
  ///
  /// In en, this message translates to:
  /// **'Playful'**
  String get onboardingPlayful;

  /// onboarding. Get started
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted90e4;

  /// onboarding. Works offline · about 2 MB per unit
  ///
  /// In en, this message translates to:
  /// **'Works offline · about 2 MB per unit'**
  String get onboardingWorksOfflineAbout2MbPer;

  /// onboarding. Works offline, about 2 megabytes per unit
  ///
  /// In en, this message translates to:
  /// **'Works offline, about 2 megabytes per unit'**
  String get onboardingWorksOfflineAbout2MegabytesPer;

  /// onboarding. Short lessons with Polie. Hear, tap, and say real phrases.
  ///
  /// In en, this message translates to:
  /// **'Short lessons with Polie. Hear, tap, and say real phrases.'**
  String get onboardingShortLessonsWithPolieHearTap;

  /// onboarding. The language village that gets you speaking.
  ///
  /// In en, this message translates to:
  /// **'The language village that gets you speaking.'**
  String get onboardingTheLanguageVillageThatGetsYou;

  /// onboarding. LingAfriq
  ///
  /// In en, this message translates to:
  /// **'LingAfriq'**
  String get onboardingLingafriq;

  /// onboarding. Welcome to
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get onboardingWelcomeTo;

  /// onboarding. Ẹ kú àbọ̀ · Sannu · Nnọọ · Karibu · Akwaaba
  ///
  /// In en, this message translates to:
  /// **'Ẹ kú àbọ̀ · Sannu · Nnọọ · Karibu · Akwaaba'**
  String get onboardingKBSannuNnKaribuAkwaaba;

  /// onboarding. Polie greets you: welcome, in Yoruba, Hausa, Igbo, Swahili and Twi.
  ///
  /// In en, this message translates to:
  /// **'Polie greets you: welcome, in Yoruba, Hausa, Igbo, Swahili and Twi.'**
  String get onboardingPolieGreetsYouWelcomeInYoruba;

  /// onboarding. LingAfriq. Speak African languages with confidence. Learn with Polie. Works offl
  ///
  /// In en, this message translates to:
  /// **'LingAfriq. Speak African languages with confidence. Learn with Polie. Works offline.'**
  String get onboardingLingafriqSpeakAfricanLanguagesWithConf;

  /// onboarding. Step {value} of {total}
  ///
  /// In en, this message translates to:
  /// **'Step {value} of {total}'**
  String onboardingStepValueOfTotal(String value, String total);

  /// onboarding. Onboarding progress
  ///
  /// In en, this message translates to:
  /// **'Onboarding progress'**
  String get onboardingOnboardingProgress;

  /// onboarding. Go back to the previous step
  ///
  /// In en, this message translates to:
  /// **'Go back to the previous step'**
  String get onboardingGoBackToThePreviousStep;

  /// onboarding. Take the test
  ///
  /// In en, this message translates to:
  /// **'Take the test'**
  String get onboardingTakeTheTest;

  /// onboarding. Maybe later
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get onboardingMaybeLater;

  /// onboarding. We'll ask a few short questions to find your starting level in {learningLanguage
  ///
  /// In en, this message translates to:
  /// **'We\'ll ask a few short questions to find your starting level in {learningLanguage}. You can always take it later from your profile.'**
  String onboardingWeLlAskAFewShort(String learningLanguage);

  /// onboarding. Take a quick placement test?
  ///
  /// In en, this message translates to:
  /// **'Take a quick placement test?'**
  String get onboardingTakeAQuickPlacementTest;

  /// onboarding. You're offline right now, but we've saved your answers and will sync them the mo
  ///
  /// In en, this message translates to:
  /// **'You\'re offline right now, but we\'ve saved your answers and will sync them the moment you reconnect.'**
  String get onboardingYouReOfflineRightNowBut;

  /// onboarding. Ẹ kú àárọ̀! 5 minutes of Yoruba?
  ///
  /// In en, this message translates to:
  /// **'Ẹ kú àárọ̀! 5 minutes of Yoruba?'**
  String get onboardingKR5MinutesOfYoruba;

  /// onboarding. Báwo, Hello
  ///
  /// In en, this message translates to:
  /// **'Báwo, Hello'**
  String get onboardingBWoHello;

  /// onboarding. Báwo ni
  ///
  /// In en, this message translates to:
  /// **'Báwo ni'**
  String get onboardingBWoNi;

  /// onboarding. Sawubona! 5 minutes of Zulu?
  ///
  /// In en, this message translates to:
  /// **'Sawubona! 5 minutes of Zulu?'**
  String get onboardingSawubona5MinutesOfZulu;

  /// onboarding. Sawubona, Hello
  ///
  /// In en, this message translates to:
  /// **'Sawubona, Hello'**
  String get onboardingSawubonaHello;

  /// onboarding. ሰላም! 5 minutes of Amharic?
  ///
  /// In en, this message translates to:
  /// **'ሰላም! 5 minutes of Amharic?'**
  String get onboardingText5MinutesOfAmharic;

  /// onboarding. ሰላም, Hello
  ///
  /// In en, this message translates to:
  /// **'ሰላም, Hello'**
  String get onboardingHello;

  /// onboarding. Habari! 5 minutes of Swahili?
  ///
  /// In en, this message translates to:
  /// **'Habari! 5 minutes of Swahili?'**
  String get onboardingHabari5MinutesOfSwahili;

  /// onboarding. Habari, Hello
  ///
  /// In en, this message translates to:
  /// **'Habari, Hello'**
  String get onboardingHabariHello;

  /// onboarding. Ndewo! 5 minutes of Igbo?
  ///
  /// In en, this message translates to:
  /// **'Ndewo! 5 minutes of Igbo?'**
  String get onboardingNdewo5MinutesOfIgbo;

  /// onboarding. Ndewo, Hello
  ///
  /// In en, this message translates to:
  /// **'Ndewo, Hello'**
  String get onboardingNdewoHello;

  /// onboarding. Sannu! 5 minutes of Hausa?
  ///
  /// In en, this message translates to:
  /// **'Sannu! 5 minutes of Hausa?'**
  String get onboardingSannu5MinutesOfHausa;

  /// onboarding. Sannu, Hello
  ///
  /// In en, this message translates to:
  /// **'Sannu, Hello'**
  String get onboardingSannuHello;

  /// onboarding. The ancestors smile upon your dedication.
  ///
  /// In en, this message translates to:
  /// **'The ancestors smile upon your dedication.'**
  String get onboardingTheAncestorsSmileUponYourDedication;

  /// onboarding. May your journey be filled with discovery.
  ///
  /// In en, this message translates to:
  /// **'May your journey be filled with discovery.'**
  String get onboardingMayYourJourneyBeFilledWith;

  /// onboarding. Village Elder
  ///
  /// In en, this message translates to:
  /// **'Village Elder'**
  String get onboardingVillageElder;

  /// onboarding. Pa LingAfriq
  ///
  /// In en, this message translates to:
  /// **'Pa LingAfriq'**
  String get onboardingPaLingafriq;

  /// onboarding. Choose wisely — it will be known across the village.
  ///
  /// In en, this message translates to:
  /// **'Choose wisely — it will be known across the village.'**
  String get onboardingChooseWiselyItWillBeKnown;

  /// onboarding. Every villager must have a name.
  ///
  /// In en, this message translates to:
  /// **'Every villager must have a name.'**
  String get onboardingEveryVillagerMustHaveAName;

  /// onboarding. Now it is time for your naming ceremony.
  ///
  /// In en, this message translates to:
  /// **'Now it is time for your naming ceremony.'**
  String get onboardingNowItIsTimeForYour;

  /// onboarding. How does your spirit best receive knowledge?
  ///
  /// In en, this message translates to:
  /// **'How does your spirit best receive knowledge?'**
  String get onboardingHowDoesYourSpiritBestReceive;

  /// onboarding. Each soul dances differently to the rhythm of words.
  ///
  /// In en, this message translates to:
  /// **'Each soul dances differently to the rhythm of words.'**
  String get onboardingEachSoulDancesDifferentlyToThe;

  /// onboarding. Language is music, traveler!
  ///
  /// In en, this message translates to:
  /// **'Language is music, traveler!'**
  String get onboardingLanguageIsMusicTraveler;

  /// onboarding. The Rhythm Master
  ///
  /// In en, this message translates to:
  /// **'The Rhythm Master'**
  String get onboardingTheRhythmMaster;

  /// onboarding. For in every word lies the wisdom of generations.
  ///
  /// In en, this message translates to:
  /// **'For in every word lies the wisdom of generations.'**
  String get onboardingForInEveryWordLiesThe;

  /// onboarding. Let me tell you the story of our languages...
  ///
  /// In en, this message translates to:
  /// **'Let me tell you the story of our languages...'**
  String get onboardingLetMeTellYouTheStory;

  /// onboarding. Ah, a new student! I am Amara, the griot.
  ///
  /// In en, this message translates to:
  /// **'Ah, a new student! I am Amara, the griot.'**
  String get onboardingAhANewStudentIAm;

  /// onboarding. The Griot
  ///
  /// In en, this message translates to:
  /// **'The Griot'**
  String get onboardingTheGriot;

  /// onboarding. How much time can you dedicate each day?
  ///
  /// In en, this message translates to:
  /// **'How much time can you dedicate each day?'**
  String get onboardingHowMuchTimeCanYouDedicate;

  /// onboarding. Consistency is the heartbeat of learning.
  ///
  /// In en, this message translates to:
  /// **'Consistency is the heartbeat of learning.'**
  String get onboardingConsistencyIsTheHeartbeatOfLearning;

  /// onboarding. I am Kofi, keeper of time and rhythm.
  ///
  /// In en, this message translates to:
  /// **'I am Kofi, keeper of time and rhythm.'**
  String get onboardingIAmKofiKeeperOfTime;

  /// onboarding. The Timekeeper
  ///
  /// In en, this message translates to:
  /// **'The Timekeeper'**
  String get onboardingTheTimekeeper;

  /// onboarding. What brings you to learn this beautiful language?
  ///
  /// In en, this message translates to:
  /// **'What brings you to learn this beautiful language?'**
  String get onboardingWhatBringsYouToLearnThis;

  /// onboarding. Every great journey needs a destination.
  ///
  /// In en, this message translates to:
  /// **'Every great journey needs a destination.'**
  String get onboardingEveryGreatJourneyNeedsADestination;

  /// onboarding. Greetings, traveler! I am Zuri, your pathfinder.
  ///
  /// In en, this message translates to:
  /// **'Greetings, traveler! I am Zuri, your pathfinder.'**
  String get onboardingGreetingsTravelerIAmZuriYour;

  /// onboarding. The Pathfinder
  ///
  /// In en, this message translates to:
  /// **'The Pathfinder'**
  String get onboardingThePathfinder;

  /// onboarding. Which thread shall we weave into your story?
  ///
  /// In en, this message translates to:
  /// **'Which thread shall we weave into your story?'**
  String get onboardingWhichThreadShallWeWeaveInto;

  /// onboarding. Each language is a thread in the tapestry of Africa.
  ///
  /// In en, this message translates to:
  /// **'Each language is a thread in the tapestry of Africa.'**
  String get onboardingEachLanguageIsAThreadIn;

  /// onboarding. I am Adisa, weaver of words and keeper of tongues.
  ///
  /// In en, this message translates to:
  /// **'I am Adisa, weaver of words and keeper of tongues.'**
  String get onboardingIAmAdisaWeaverOfWords;

  /// onboarding. The Weaver
  ///
  /// In en, this message translates to:
  /// **'The Weaver'**
  String get onboardingTheWeaver;

  /// onboarding. Your journey to connect with your roots begins here.
  ///
  /// In en, this message translates to:
  /// **'Your journey to connect with your roots begins here.'**
  String get onboardingYourJourneyToConnectWithYour;

  /// onboarding. I am Pa LingAfriq, guardian of our ancestral tongues.
  ///
  /// In en, this message translates to:
  /// **'I am Pa LingAfriq, guardian of our ancestral tongues.'**
  String get onboardingIAmPaLingafriqGuardianOf;

  /// onboarding. Welcome, young one, to our village of languages.
  ///
  /// In en, this message translates to:
  /// **'Welcome, young one, to our village of languages.'**
  String get onboardingWelcomeYoungOneToOurVillage;

  /// shell. Logout
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get shellLogout;

  /// shell. Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get shellCancel;

  /// shell. Are you sure you want to logout?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get shellAreYouSureYouWantTo;

  /// shell. Switch between light and dark theme
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark theme'**
  String get shellSwitchBetweenLightAndDarkTheme;

  /// shell. Dark Mode
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get shellDarkMode;

  /// shell. Friend Quests
  ///
  /// In en, this message translates to:
  /// **'Friend Quests'**
  String get shellFriendQuests;

  /// shell. Social Hub
  ///
  /// In en, this message translates to:
  /// **'Social Hub'**
  String get shellSocialHub;

  /// shell. Micro-mentor reports
  ///
  /// In en, this message translates to:
  /// **'Micro-mentor reports'**
  String get shellMicroMentorReports;

  /// shell. Persona Missions
  ///
  /// In en, this message translates to:
  /// **'Persona Missions'**
  String get shellPersonaMissions;

  /// shell. Historical Personas
  ///
  /// In en, this message translates to:
  /// **'Historical Personas'**
  String get shellHistoricalPersonas;

  /// shell. My Tribes
  ///
  /// In en, this message translates to:
  /// **'My Tribes'**
  String get shellMyTribes;

  /// shell. Language Villages
  ///
  /// In en, this message translates to:
  /// **'Language Villages'**
  String get shellLanguageVillages;

  /// shell. Private Chat
  ///
  /// In en, this message translates to:
  /// **'Private Chat'**
  String get shellPrivateChat;

  /// shell. Community Feed
  ///
  /// In en, this message translates to:
  /// **'Community Feed'**
  String get shellCommunityFeed;

  /// shell. Global Chat
  ///
  /// In en, this message translates to:
  /// **'Global Chat'**
  String get shellGlobalChat;

  /// shell. Create Content
  ///
  /// In en, this message translates to:
  /// **'Create Content'**
  String get shellCreateContent;

  /// shell. Live translate
  ///
  /// In en, this message translates to:
  /// **'Live translate'**
  String get shellLiveTranslate;

  /// shell. Point & Say
  ///
  /// In en, this message translates to:
  /// **'Point & Say'**
  String get shellPointSay;

  /// shell. Import Media
  ///
  /// In en, this message translates to:
  /// **'Import Media'**
  String get shellImportMedia;

  /// shell. Cultural Magazine
  ///
  /// In en, this message translates to:
  /// **'Cultural Magazine'**
  String get shellCulturalMagazine;

  /// shell. Cultural Hub
  ///
  /// In en, this message translates to:
  /// **'Cultural Hub'**
  String get shellCulturalHub;

  /// shell. Add words in Vocabulary Builder to start flashcard review.
  ///
  /// In en, this message translates to:
  /// **'Add words in Vocabulary Builder to start flashcard review.'**
  String get shellAddWordsInVocabularyBuilderTo;

  /// shell. Please select a language first
  ///
  /// In en, this message translates to:
  /// **'Please select a language first'**
  String get shellPleaseSelectALanguageFirst;

  /// shell. Flashcard Review
  ///
  /// In en, this message translates to:
  /// **'Flashcard Review'**
  String get shellFlashcardReview;

  /// shell. Writing Practice
  ///
  /// In en, this message translates to:
  /// **'Writing Practice'**
  String get shellWritingPractice;

  /// shell. Listening Practice
  ///
  /// In en, this message translates to:
  /// **'Listening Practice'**
  String get shellListeningPractice;

  /// shell. Conversation Scenarios
  ///
  /// In en, this message translates to:
  /// **'Conversation Scenarios'**
  String get shellConversationScenarios;

  /// shell. Vocabulary Builder
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Builder'**
  String get shellVocabularyBuilder;

  /// shell. Learning Path
  ///
  /// In en, this message translates to:
  /// **'Learning Path'**
  String get shellLearningPath;

  /// shell. Grammar Hub
  ///
  /// In en, this message translates to:
  /// **'Grammar Hub'**
  String get shellGrammarHub;

  /// shell. AI Chat
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get shellAiChat;

  /// shell. Tutor Mode
  ///
  /// In en, this message translates to:
  /// **'Tutor Mode'**
  String get shellTutorMode;

  /// shell. Native content review
  ///
  /// In en, this message translates to:
  /// **'Native content review'**
  String get shellNativeContentReview;

  /// shell. Authentic Path (A1–C1)
  ///
  /// In en, this message translates to:
  /// **'Authentic Path (A1–C1)'**
  String get shellAuthenticPathA1C1;

  /// shell. Toggle Dark Mode
  ///
  /// In en, this message translates to:
  /// **'Toggle Dark Mode'**
  String get shellToggleDarkMode;

  /// shell. Dark mode {value}
  ///
  /// In en, this message translates to:
  /// **'Dark mode {value}'**
  String shellDarkModeValue(String value);

  /// shell. {title} section
  ///
  /// In en, this message translates to:
  /// **'{title} section'**
  String shellTitleSection(String title);

  /// shell. Toggle theme
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get shellToggleTheme;

  /// shell. Dark mode
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get shellDarkMode9cf8;

  /// shell. Practice Rooms
  ///
  /// In en, this message translates to:
  /// **'Practice Rooms'**
  String get shellPracticeRooms;

  /// shell. Live Classroom
  ///
  /// In en, this message translates to:
  /// **'Live Classroom'**
  String get shellLiveClassroom;

  /// shell. Dialect preference
  ///
  /// In en, this message translates to:
  /// **'Dialect preference'**
  String get shellDialectPreference;

  /// shell. Heritage milestones
  ///
  /// In en, this message translates to:
  /// **'Heritage milestones'**
  String get shellHeritageMilestones;

  /// shell. Living Dictionary
  ///
  /// In en, this message translates to:
  /// **'Living Dictionary'**
  String get shellLivingDictionary;

  /// shell. Tone & Rhythm
  ///
  /// In en, this message translates to:
  /// **'Tone & Rhythm'**
  String get shellToneRhythm;

  /// shell. Phrase DNA
  ///
  /// In en, this message translates to:
  /// **'Phrase DNA'**
  String get shellPhraseDna;

  /// shell. Polie Tutor
  ///
  /// In en, this message translates to:
  /// **'Polie Tutor'**
  String get shellPolieTutor;

  /// shell. Email: {value}
  ///
  /// In en, this message translates to:
  /// **'Email: {value}'**
  String shellEmailValue(String value);

  /// shell. Username: {value}
  ///
  /// In en, this message translates to:
  /// **'Username: {value}'**
  String shellUsernameValue(String value);

  /// shell. User avatar
  ///
  /// In en, this message translates to:
  /// **'User avatar'**
  String get shellUserAvatar;

  /// shell. Lessons completed: {value} • Points earned: {value2}
  ///
  /// In en, this message translates to:
  /// **'Lessons completed: {value} • Points earned: {value2}'**
  String shellLessonsCompletedValuePointsEarnedValue2(
    String value,
    String value2,
  );

  /// shell. Loading Courses ...
  ///
  /// In en, this message translates to:
  /// **'Loading Courses ...'**
  String get shellLoadingCourses;

  /// shell. Start a course to see your progress
  ///
  /// In en, this message translates to:
  /// **'Start a course to see your progress'**
  String get shellStartACourseToSeeYour;

  /// shell. No Course started yet
  ///
  /// In en, this message translates to:
  /// **'No Course started yet'**
  String get shellNoCourseStartedYet;

  /// shell. Hi {value}
  ///
  /// In en, this message translates to:
  /// **'Hi {value}'**
  String shellHiValue(String value);

  /// shell. Your Courses!
  ///
  /// In en, this message translates to:
  /// **'Your Courses!'**
  String get shellYourCourses;

  /// shell. {value}%
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String shellValue(String value);

  /// shell. Progress
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get shellProgress;

  /// shell. Progress {value}%
  ///
  /// In en, this message translates to:
  /// **'Progress {value}%'**
  String shellProgressValue(String value);

  /// shell. Lessons completed: {value} • Points: {value2}
  ///
  /// In en, this message translates to:
  /// **'Lessons completed: {value} • Points: {value2}'**
  String shellLessonsCompletedValuePointsValue2(String value, String value2);

  /// shell. {value}, {value2}% complete. Tap to open.
  ///
  /// In en, this message translates to:
  /// **'{value}, {value2}% complete. Tap to open.'**
  String shellValueValue2CompleteTapToOpen(String value, String value2);

  /// shell. Loading Courses...
  ///
  /// In en, this message translates to:
  /// **'Loading Courses...'**
  String get shellLoadingCourses7098;

  /// shell. No languages available
  ///
  /// In en, this message translates to:
  /// **'No languages available'**
  String get shellNoLanguagesAvailable;

  /// shell. Your Progress
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get shellYourProgress;

  /// shell. Menu
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get shellMenu;

  /// shell. Open menu
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get shellOpenMenu;

  /// shell. Your Courses
  ///
  /// In en, this message translates to:
  /// **'Your Courses'**
  String get shellYourCourses9648;

  /// shell. Nanga def
  ///
  /// In en, this message translates to:
  /// **'Nanga def'**
  String get shellNangaDef;

  /// shell. How far
  ///
  /// In en, this message translates to:
  /// **'How far'**
  String get shellHowFar;

  /// shell. Asụsụ Igbo
  ///
  /// In en, this message translates to:
  /// **'Asụsụ Igbo'**
  String get shellAsSIgbo;

  /// shell. Harshen Hausa
  ///
  /// In en, this message translates to:
  /// **'Harshen Hausa'**
  String get shellHarshenHausa;

  /// shell. Ẹ káàbọ̀
  ///
  /// In en, this message translates to:
  /// **'Ẹ káàbọ̀'**
  String get shellKB;

  /// shell. {value}. Tap to open.
  ///
  /// In en, this message translates to:
  /// **'{value}. Tap to open.'**
  String shellValueTapToOpen(String value);

  /// shell. {label}: {value}
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String shellLabelValue(String label, String value);

  /// shell. {title}. {subtitle}
  ///
  /// In en, this message translates to:
  /// **'{title}. {subtitle}'**
  String shellTitleSubtitle(String title, String subtitle);

  /// shell. View dashboard
  ///
  /// In en, this message translates to:
  /// **'View dashboard'**
  String get shellViewDashboard;

  /// shell. Conversation with Polie
  ///
  /// In en, this message translates to:
  /// **'Conversation with Polie'**
  String get shellConversationWithPolie;

  /// shell. Polie modes & skills
  ///
  /// In en, this message translates to:
  /// **'Polie modes & skills'**
  String get shellPolieModesSkills;

  /// shell. AI Tutor
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get shellAiTutor;

  /// shell. Quick Actions
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get shellQuickActions;

  /// shell. {value} languages
  ///
  /// In en, this message translates to:
  /// **'{value} languages'**
  String shellValueLanguages(String value);

  /// shell. {value} badges
  ///
  /// In en, this message translates to:
  /// **'{value} badges'**
  String shellValueBadges(String value);

  /// shell. {value} day streak
  ///
  /// In en, this message translates to:
  /// **'{value} day streak'**
  String shellValueDayStreak(String value);

  /// shell. {value} XP to next level
  ///
  /// In en, this message translates to:
  /// **'{value} XP to next level'**
  String shellValueXpToNextLevel(String value);

  /// shell. XP {value}
  ///
  /// In en, this message translates to:
  /// **'XP {value}'**
  String shellXpValue(String value);

  /// shell. Level
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get shellLevel;

  /// shell. {value}
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String shellValue75ce(String value);

  /// shell. Level {value}. XP {value2}. {value3} XP to next level. {value4} day streak. {val
  ///
  /// In en, this message translates to:
  /// **'Level {value}. XP {value2}. {value3} XP to next level. {value4} day streak. {value5} badges. {value6} languages.'**
  String shellLevelValueXpValue2Value3Xp(
    String value,
    String value2,
    String value3,
    String value4,
    String value5,
    String value6,
  );

  /// shell. {title}{value}
  ///
  /// In en, this message translates to:
  /// **'{title}{value}'**
  String shellTitleValue(String title, String value);

  /// shell. Loading Languages ...
  ///
  /// In en, this message translates to:
  /// **'Loading Languages ...'**
  String get shellLoadingLanguages;

  /// shell. Search languages
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get shellSearchLanguages;

  /// shell. Explore More
  ///
  /// In en, this message translates to:
  /// **'Explore More'**
  String get shellExploreMore;

  /// shell. Featured Languages
  ///
  /// In en, this message translates to:
  /// **'Featured Languages'**
  String get shellFeaturedLanguages;

  /// shell. Ẹ Káàbọ
  ///
  /// In en, this message translates to:
  /// **'Ẹ Káàbọ'**
  String get shellKBd95e;

  /// shell. Wehcome o
  ///
  /// In en, this message translates to:
  /// **'Wehcome o'**
  String get shellWehcomeO;

  /// shell. Sannu da zuwa
  ///
  /// In en, this message translates to:
  /// **'Sannu da zuwa'**
  String get shellSannuDaZuwa;

  /// shell. {percent}%
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String shellPercent(String percent);

  /// shell. Ẹ Káàbọ̀
  ///
  /// In en, this message translates to:
  /// **'Ẹ Káàbọ̀'**
  String get shellKBf733;

  /// shell. Welcome o
  ///
  /// In en, this message translates to:
  /// **'Welcome o'**
  String get shellWelcomeO;

  /// shell. connection timed out
  ///
  /// In en, this message translates to:
  /// **'connection timed out'**
  String get shellConnectionTimedOut;

  /// shell. connection refused
  ///
  /// In en, this message translates to:
  /// **'connection refused'**
  String get shellConnectionRefused;

  /// shell. failed host lookup
  ///
  /// In en, this message translates to:
  /// **'failed host lookup'**
  String get shellFailedHostLookup;

  /// shell. network is unreachable
  ///
  /// In en, this message translates to:
  /// **'network is unreachable'**
  String get shellNetworkIsUnreachable;

  /// shell. no internet
  ///
  /// In en, this message translates to:
  /// **'no internet'**
  String get shellNoInternet;

  /// shell. Authentic Path
  ///
  /// In en, this message translates to:
  /// **'Authentic Path'**
  String get shellAuthenticPath;

  /// shell. Take Quiz
  ///
  /// In en, this message translates to:
  /// **'Take Quiz'**
  String get shellTakeQuiz;

  /// shell. Back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get shellBack;

  /// shell. Pick where you want to learn
  ///
  /// In en, this message translates to:
  /// **'Pick where you want to learn'**
  String get shellPickWhereYouWantToLearn;

  /// shell. Start learning
  ///
  /// In en, this message translates to:
  /// **'Start learning'**
  String get shellStartLearning;

  /// shell. {value} pts
  ///
  /// In en, this message translates to:
  /// **'{value} pts'**
  String shellValuePts(String value);

  /// shell. Try a different search term
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get shellTryADifferentSearchTerm;

  /// shell. No languages found
  ///
  /// In en, this message translates to:
  /// **'No languages found'**
  String get shellNoLanguagesFound;

  /// shell. Clear search
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get shellClearSearch;

  /// shell. Search languages...
  ///
  /// In en, this message translates to:
  /// **'Search languages...'**
  String get shellSearchLanguages2580;

  /// shell. {value}
  ///
  /// In en, this message translates to:
  /// **'{value} '**
  String shellValuea1d1(String value);

  /// shell. Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get shellRetry;

  /// shell. Failed to load quizzes. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Failed to load quizzes. Please try again.'**
  String get shellFailedToLoadQuizzesPleaseTry;

  /// shell. Connection timed out
  ///
  /// In en, this message translates to:
  /// **'Connection timed out'**
  String get shellConnectionTimedOut52c8;

  /// shell. We're working to add random quizzes for {value}!
  ///
  /// In en, this message translates to:
  /// **'We\'re working to add random quizzes for {value}!'**
  String shellWeReWorkingToAddRandom(String value);

  /// shell. Loading quizzes for {value}...
  ///
  /// In en, this message translates to:
  /// **'Loading quizzes for {value}...'**
  String shellLoadingQuizzesForValue(String value);

  /// shell. Choose a quiz type
  ///
  /// In en, this message translates to:
  /// **'Choose a quiz type'**
  String get shellChooseAQuizType;

  /// shell. App Policy
  ///
  /// In en, this message translates to:
  /// **'App Policy'**
  String get shellAppPolicy;

  /// shell. Change Password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get shellChangePassword;

  /// shell. Password Changed
  ///
  /// In en, this message translates to:
  /// **'Password Changed'**
  String get shellPasswordChanged;

  /// shell. Confirm your new password
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get shellConfirmYourNewPassword;

  /// shell. Confirm Password
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get shellConfirmPassword;

  /// shell. Enter new password
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get shellEnterNewPassword;

  /// shell. New Password
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get shellNewPassword;

  /// shell. Enter your current password
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get shellEnterYourCurrentPassword;

  /// shell. Current Password
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get shellCurrentPassword;

  /// shell. Delete Now
  ///
  /// In en, this message translates to:
  /// **'Delete Now'**
  String get shellDeleteNow;

  /// shell. Enter Current Password
  ///
  /// In en, this message translates to:
  /// **'Enter Current Password'**
  String get shellEnterCurrentPassword;

  /// shell. Confirmation
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get shellConfirmation;

  /// shell. Yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get shellYes;

  /// shell. No
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get shellNo;

  /// shell. Are you sure you want to DELETE account?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to DELETE account?'**
  String get shellAreYouSureYouWantToecc5;

  /// shell. Account Deleted
  ///
  /// In en, this message translates to:
  /// **'Account Deleted'**
  String get shellAccountDeleted;

  /// shell. This action is permanent
  ///
  /// In en, this message translates to:
  /// **'This action is permanent'**
  String get shellThisActionIsPermanent;

  /// shell. Delete your account
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get shellDeleteYourAccount;

  /// shell. Read how your data is protected
  ///
  /// In en, this message translates to:
  /// **'Read how your data is protected'**
  String get shellReadHowYourDataIsProtected;

  /// shell. Privacy & User Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy & User Policy'**
  String get shellPrivacyUserPolicy;

  /// shell. Learn about the LingAfriq mission
  ///
  /// In en, this message translates to:
  /// **'Learn about the LingAfriq mission'**
  String get shellLearnAboutTheLingafriqMission;

  /// shell. Who are we?
  ///
  /// In en, this message translates to:
  /// **'Who are we?'**
  String get shellWhoAreWe;

  /// shell. Help us improve LingAfriq
  ///
  /// In en, this message translates to:
  /// **'Help us improve LingAfriq'**
  String get shellHelpUsImproveLingafriq;

  /// shell. Give us Feedback
  ///
  /// In en, this message translates to:
  /// **'Give us Feedback'**
  String get shellGiveUsFeedback;

  /// shell. Update your credentials securely
  ///
  /// In en, this message translates to:
  /// **'Update your credentials securely'**
  String get shellUpdateYourCredentialsSecurely;

  /// shell. #{value}
  ///
  /// In en, this message translates to:
  /// **'#{value}'**
  String shellValue12bd(String value);

  /// shell. Global rank: {value}
  ///
  /// In en, this message translates to:
  /// **'Global rank: {value}'**
  String shellGlobalRankValue(String value);

  /// shell. Global Ranking
  ///
  /// In en, this message translates to:
  /// **'Global Ranking'**
  String get shellGlobalRanking;

  /// shell. Streak {value}
  ///
  /// In en, this message translates to:
  /// **'Streak {value}'**
  String shellStreakValue(String value);

  /// shell. {value} XP
  ///
  /// In en, this message translates to:
  /// **'{value} XP'**
  String shellValueXp(String value);

  /// shell. Achievement progress: {unlockedBadges} out of {totalBadges} badges unlocked
  ///
  /// In en, this message translates to:
  /// **'Achievement progress: {unlockedBadges} out of {totalBadges} badges unlocked'**
  String shellAchievementProgressUnlockedbadgesOutOfTotal(
    String unlockedBadges,
    String totalBadges,
  );

  /// shell. {unlockedBadges}/{totalBadges}
  ///
  /// In en, this message translates to:
  /// **'{unlockedBadges}/{totalBadges}'**
  String shellUnlockedbadgesTotalbadges(
    String unlockedBadges,
    String totalBadges,
  );

  /// shell. Achievements
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get shellAchievements;

  /// shell. Level {value}
  ///
  /// In en, this message translates to:
  /// **'Level {value}'**
  String shellLevelValue(String value);

  /// shell. Profile: {value}, {value2}, Level {value3}, Streak {value4}
  ///
  /// In en, this message translates to:
  /// **'Profile: {value}, {value2}, Level {value3}, Streak {value4}'**
  String shellProfileValueValue2LevelValue3Streak(
    String value,
    String value2,
    String value3,
    String value4,
  );

  /// shell. Profile avatar. Tap to edit profile
  ///
  /// In en, this message translates to:
  /// **'Profile avatar. Tap to edit profile'**
  String get shellProfileAvatarTapToEditProfile;

  /// shell. Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get shellProfile;

  /// shell. Submit
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get shellSubmit;

  /// shell. Feedback Form on Mobile App
  ///
  /// In en, this message translates to:
  /// **'Feedback Form on Mobile App'**
  String get shellFeedbackFormOnMobileApp;

  /// shell. Language Country:
  /// {country}
  ///
  ///
  ///
  /// In en, this message translates to:
  /// **'Language Country:\n{country}\n\n'**
  String shellLanguageCountryCountry(String country);

  /// shell. Would you like to suggest a language? If yes, enter language below:
  /// {suggestion}
  ///
  /// In en, this message translates to:
  /// **'Would you like to suggest a language? If yes, enter language below:\n{suggestion}\n\n'**
  String shellWouldYouLikeToSuggestA(String suggestion);

  /// shell. What would you like us to know:
  /// {reason}
  ///
  ///
  ///
  /// In en, this message translates to:
  /// **'What would you like us to know:\n{reason}\n\n'**
  String shellWhatWouldYouLikeUsTo(String reason);

  /// shell. Please fill in some fields
  ///
  /// In en, this message translates to:
  /// **'Please fill in some fields'**
  String get shellPleaseFillInSomeFields;

  /// shell. Language Country
  ///
  /// In en, this message translates to:
  /// **'Language Country'**
  String get shellLanguageCountry;

  /// shell. Write your suggestion here
  ///
  /// In en, this message translates to:
  /// **'Write your suggestion here'**
  String get shellWriteYourSuggestionHere;

  /// shell. Would you like to suggest a language? If yes, enter language below
  ///
  /// In en, this message translates to:
  /// **'Would you like to suggest a language? If yes, enter language below'**
  String get shellWouldYouLikeToSuggestAb06a;

  /// shell. Please explain What would you like us to know?
  ///
  /// In en, this message translates to:
  /// **'Please explain What would you like us to know?'**
  String get shellPleaseExplainWhatWouldYouLike;

  /// shell. What would you like us to know?
  ///
  /// In en, this message translates to:
  /// **'What would you like us to know?'**
  String get shellWhatWouldYouLikeUsTo0de8;

  /// shell. Start a course to see your country ranking
  ///
  /// In en, this message translates to:
  /// **'Start a course to see your country ranking'**
  String get shellStartACourseToSeeYoure3fc;

  /// shell. No points earned yet
  ///
  /// In en, this message translates to:
  /// **'No points earned yet'**
  String get shellNoPointsEarnedYet;

  /// shell. {space}{text}{space2}
  ///
  /// In en, this message translates to:
  /// **'{space}{text}{space2}'**
  String shellSpaceTextSpace2(String space, String text, String space2);

  /// shell. Loading Leaderboard...
  ///
  /// In en, this message translates to:
  /// **'Loading Leaderboard...'**
  String get shellLoadingLeaderboard;

  /// shell. Country
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get shellCountry;

  /// shell. Global
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get shellGlobal;

  /// shell. Leaderboard view: {value}. Switch between Global and Country.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard view: {value}. Switch between Global and Country.'**
  String shellLeaderboardViewValueSwitchBetweenGlobal(String value);

  /// shell. Leaderboard
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get shellLeaderboard;

  /// shell. Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile tab'**
  String get shellProfileTab;

  /// shell. Social
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get shellSocial;

  /// shell. Social tab
  ///
  /// In en, this message translates to:
  /// **'Social tab'**
  String get shellSocialTab;

  /// shell. AI
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get shellAi;

  /// shell. AI Tutor tab
  ///
  /// In en, this message translates to:
  /// **'AI Tutor tab'**
  String get shellAiTutorTab;

  /// shell. Courses
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get shellCourses;

  /// shell. Courses tab
  ///
  /// In en, this message translates to:
  /// **'Courses tab'**
  String get shellCoursesTab;

  /// shell. Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get shellHome;

  /// shell. Home tab
  ///
  /// In en, this message translates to:
  /// **'Home tab'**
  String get shellHomeTab;

  /// shell. Back to learning
  ///
  /// In en, this message translates to:
  /// **'Back to learning'**
  String get shellBackToLearning;

  /// shell. Back to learning home
  ///
  /// In en, this message translates to:
  /// **'Back to learning home'**
  String get shellBackToLearningHome;

  /// shell. Not available yet
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get shellNotAvailableYet;

  /// shell. Private messages, calls, snaps, and the public feed unlock when you are 18 and y
  ///
  /// In en, this message translates to:
  /// **'Private messages, calls, snaps, and the public feed unlock when you are 18 and your age is verified. Until then, keep going on lessons, games, and Polie.'**
  String get shellPrivateMessagesCallsSnapsAndThe;

  /// shell. Learning comes first
  ///
  /// In en, this message translates to:
  /// **'Learning comes first'**
  String get shellLearningComesFirst;

  /// onboarding. Words in the first-win basket
  ///
  /// In en, this message translates to:
  /// **'{words, plural, =1{1 word in your basket} other{{words} words in your basket}}'**
  String onboardingWordsInYourBasket(int words);

  /// onboarding. not selected
  ///
  /// In en, this message translates to:
  /// **'not selected'**
  String get onboardingNotSelected;

  /// onboarding. Add Avatar (Optional)
  ///
  /// In en, this message translates to:
  /// **'Add Avatar (Optional)'**
  String get onboardingAddAvatarOptional;

  /// onboarding. Level not precise yet
  ///
  /// In en, this message translates to:
  /// **'Level not precise yet'**
  String get onboardingLevelNotPreciseYet;

  /// onboarding. , selected
  ///
  /// In en, this message translates to:
  /// **', selected'**
  String get onboardingSelectedd7a1;

  /// onboarding. Use a year between 1900 and {nowYear}.
  ///
  /// In en, this message translates to:
  /// **'Use a year between 1900 and {nowYear}.'**
  String onboardingUseAYearBetween1900And(String nowYear);

  /// onboarding. Nice, you said it
  ///
  /// In en, this message translates to:
  /// **'Nice, you said it'**
  String get onboardingNiceYouSaidIt;

  /// onboarding. You marked the phrase as said
  ///
  /// In en, this message translates to:
  /// **'You marked the phrase as said'**
  String get onboardingYouMarkedThePhraseAsSaid;

  /// onboarding. Finish lesson
  ///
  /// In en, this message translates to:
  /// **'Finish lesson'**
  String get onboardingFinishLesson;

  /// onboarding. 1 word
  ///
  /// In en, this message translates to:
  /// **'1 word'**
  String get onboardingText1Word;

  /// shell. , {username}
  ///
  /// In en, this message translates to:
  /// **', {username}'**
  String shellUsername(String username);

  /// shell.tab.today tab label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get shellTabToday;

  /// shell.tab.learn tab label
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get shellTabLearn;

  /// shell.tab.speak tab label
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get shellTabSpeak;

  /// shell.tab.play tab label
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get shellTabPlay;

  /// shell.tab.village tab label
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get shellTabVillage;

  /// shell. Me control
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get shellMe;

  /// shell. Search control
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get shellSearch;

  /// shell. Lens control
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get shellLens;

  /// button that opens a section in the current tab
  ///
  /// In en, this message translates to:
  /// **'Open {tab}'**
  String shellOpenSection(String tab);

  /// shell. A tab section is open
  ///
  /// In en, this message translates to:
  /// **'{tab} is open'**
  String shellSectionOpen(String tab);

  /// shell. A line in a tab list
  ///
  /// In en, this message translates to:
  /// **'Line {index} in {tab}'**
  String shellSectionLine(int index, String tab);

  /// shell. What happened when a link misses
  ///
  /// In en, this message translates to:
  /// **'This link did not open.'**
  String get shellLinkMissedWhat;

  /// shell. Why a link missed
  ///
  /// In en, this message translates to:
  /// **'Nothing in the app matches {link}.'**
  String shellLinkMissedWhy(String link);

  /// shell. Why a link missed, with the parser detail
  ///
  /// In en, this message translates to:
  /// **'Nothing in the app matches {link}. {detail}'**
  String shellLinkMissedWhyWithDetail(String link, String detail);

  /// shell. What to do after a missed link
  ///
  /// In en, this message translates to:
  /// **'Go back to Today.'**
  String get shellLinkMissedNext;

  /// button that leaves a missed link
  ///
  /// In en, this message translates to:
  /// **'Go to Today'**
  String get shellLinkMissedAction;

  /// shell. A link had no text
  ///
  /// In en, this message translates to:
  /// **'The link was empty.'**
  String get shellLinkWasEmpty;

  /// shell. What happened while offline
  ///
  /// In en, this message translates to:
  /// **'The phone has no network.'**
  String get shellOfflineWhat;

  /// shell. Why the shell is offline
  ///
  /// In en, this message translates to:
  /// **'These tabs are not saved offline.'**
  String get shellOfflineWhy;

  /// shell. What to do while offline
  ///
  /// In en, this message translates to:
  /// **'Connect, then try again.'**
  String get shellOfflineNext;

  /// hub.h_learn. Path and lessons
  ///
  /// In en, this message translates to:
  /// **'Path and lessons'**
  String get hubLearnPathAndLessons;

  /// hub.h_learn. Lesson Recap
  ///
  /// In en, this message translates to:
  /// **'Lesson Recap'**
  String get hubLearnLessonRecap;

  /// hub.h_learn. Words and Review
  ///
  /// In en, this message translates to:
  /// **'Words and Review'**
  String get hubLearnWordsAndReview;

  /// hub.h_learn. Review Rush
  ///
  /// In en, this message translates to:
  /// **'Review Rush'**
  String get hubLearnReviewRush;

  /// hub.h_learn. Grammar
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get hubLearnGrammar;

  /// hub.h_learn. Phrase DNA
  ///
  /// In en, this message translates to:
  /// **'Phrase DNA'**
  String get hubLearnPhraseDna;

  /// hub.h_learn. Listening
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get hubLearnListening;

  /// hub.h_learn. Writing
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get hubLearnWriting;

  /// hub.h_learn. Tone Gym
  ///
  /// In en, this message translates to:
  /// **'Tone Gym'**
  String get hubLearnToneGym;

  /// hub.h_learn. Culture shelf
  ///
  /// In en, this message translates to:
  /// **'Culture shelf'**
  String get hubLearnCultureShelf;

  /// hub.h_learn. Magazine
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get hubLearnMagazine;

  /// hub.h_learn. Heritage
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get hubLearnHeritage;

  /// hub.h_learn. History
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get hubLearnHistory;

  /// hub.h_learn. Mannerisms
  ///
  /// In en, this message translates to:
  /// **'Mannerisms'**
  String get hubLearnMannerisms;

  /// hub.h_learn. Cultural Hub
  ///
  /// In en, this message translates to:
  /// **'Cultural Hub'**
  String get hubLearnCulturalHub;

  /// hub.h_learn. Passport
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get hubLearnPassport;

  /// hub.h_learn. Downloads
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get hubLearnDownloads;

  /// hub.h_learn. Back to Learn
  ///
  /// In en, this message translates to:
  /// **'Back to Learn'**
  String get hubLearnBack;

  /// hub.h_learn. What happened when a destination is not built
  ///
  /// In en, this message translates to:
  /// **'This part is not built yet.'**
  String get hubLearnNotAvailableWhat;

  /// hub.h_learn. Why a destination shows nothing
  ///
  /// In en, this message translates to:
  /// **'There is nothing to show.'**
  String get hubLearnNotAvailableWhy;

  /// hub.h_learn. What to do when a destination is not built
  ///
  /// In en, this message translates to:
  /// **'Go back to Learn.'**
  String get hubLearnNotAvailableNext;

  /// hub.h_learn. Empty hub title
  ///
  /// In en, this message translates to:
  /// **'Nothing is here yet'**
  String get hubLearnEmptyTitle;

  /// hub.h_learn. What happened when the hub is empty
  ///
  /// In en, this message translates to:
  /// **'Learn has no lessons yet.'**
  String get hubLearnEmptyWhat;

  /// hub.h_learn. Why the hub is empty
  ///
  /// In en, this message translates to:
  /// **'No units came back.'**
  String get hubLearnEmptyWhy;

  /// hub.h_learn. Next step when the hub is empty
  ///
  /// In en, this message translates to:
  /// **'Open Path and start the first lesson.'**
  String get hubLearnEmptyNext;

  /// hub.h_learn. Button that opens Path
  ///
  /// In en, this message translates to:
  /// **'Open Path'**
  String get hubLearnOpenPath;

  /// hub.h_learn. Empty path title
  ///
  /// In en, this message translates to:
  /// **'This path has no lessons'**
  String get hubLearnPathEmptyTitle;

  /// hub.h_learn. What happened when Path has no units
  ///
  /// In en, this message translates to:
  /// **'No units are on this path.'**
  String get hubLearnPathEmptyWhat;

  /// hub.h_learn. Why Path has no units
  ///
  /// In en, this message translates to:
  /// **'No units came back to group.'**
  String get hubLearnPathEmptyWhy;

  /// hub.h_learn. Next step when Path has no units
  ///
  /// In en, this message translates to:
  /// **'Try again later.'**
  String get hubLearnPathEmptyNext;

  /// hub.h_learn. Empty grammar title
  ///
  /// In en, this message translates to:
  /// **'No pattern yet'**
  String get hubLearnGrammarEmptyTitle;

  /// hub.h_learn. What happened when Grammar has no pattern
  ///
  /// In en, this message translates to:
  /// **'Grammar has no pattern yet.'**
  String get hubLearnGrammarEmptyWhat;

  /// hub.h_learn. Why Grammar has no pattern
  ///
  /// In en, this message translates to:
  /// **'No drill came back.'**
  String get hubLearnGrammarEmptyWhy;

  /// hub.h_learn. Next step when Grammar has no pattern
  ///
  /// In en, this message translates to:
  /// **'Open Path and start a lesson.'**
  String get hubLearnGrammarEmptyNext;

  /// hub.h_learn. CEFR band heading
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String hubLearnLevel(String level);

  /// hub.h_learn. Heading when a unit has no CEFR band
  ///
  /// In en, this message translates to:
  /// **'Level not set'**
  String get hubLearnLevelNotSet;

  /// hub.h_learn. What happened when Learn fails
  ///
  /// In en, this message translates to:
  /// **'Learn did not open.'**
  String get hubLearnErrorWhat;

  /// hub.h_learn. Why Learn failed
  ///
  /// In en, this message translates to:
  /// **'The lesson list did not come back.'**
  String get hubLearnErrorWhy;

  /// hub.h_learn. What to do when Learn fails
  ///
  /// In en, this message translates to:
  /// **'Try again.'**
  String get hubLearnErrorNext;

  /// hub.h_learn. Why Learn is offline
  ///
  /// In en, this message translates to:
  /// **'This path is not saved on the phone.'**
  String get hubLearnOfflineWhy;

  /// hub.h_learn. What to do when Learn is offline
  ///
  /// In en, this message translates to:
  /// **'Connect, then try again.'**
  String get hubLearnOfflineNext;
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
