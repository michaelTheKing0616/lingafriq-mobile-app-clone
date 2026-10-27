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
