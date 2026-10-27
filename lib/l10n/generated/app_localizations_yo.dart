// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Ẹ káàbọ̀ sí LingAfriq';

  @override
  String get continueButton => 'Tẹ̀síwájú';

  @override
  String get startLearning => 'Bẹ̀rẹ̀ ẹ̀kọ́';

  @override
  String get loading => 'Ó ń gbé wọlé...';

  @override
  String get errorOccurred => 'Àṣìṣe kan ṣẹlẹ̀';

  @override
  String get tryAgain => 'Gbìyànjú lẹ́ẹ̀kansi';

  @override
  String get home => 'Ilé';

  @override
  String get learn => 'Kọ́';

  @override
  String get games => 'Eré';

  @override
  String get profile => 'Àkọsílẹ̀';

  @override
  String get settings => 'Ètò';

  @override
  String get language => 'Èdè';

  @override
  String get selectLanguage => 'Yan èdè';

  @override
  String get lessons => 'Ẹ̀kọ́';

  @override
  String get quizzes => 'Ìdánwò';

  @override
  String get takeQuiz => 'Ṣe ìdánwò';

  @override
  String get takeLesson => 'Kọ́ ẹ̀kọ́';

  @override
  String get dailyStreak => 'Ìtẹ̀síwájú ojoojúmọ́';

  @override
  String daysStreak(int count) {
    return 'Ọjọ́ $count';
  }

  @override
  String xpEarned(int count) {
    return 'XP $count';
  }

  @override
  String get level => 'Ìpele';

  @override
  String get beginner => 'Alábẹ̀ẹ̀rẹ̀';

  @override
  String get intermediate => 'Ààrin';

  @override
  String get advanced => 'Agbára';

  @override
  String get correct => 'Ó tọ́!';

  @override
  String get incorrect => 'Kò tọ́';

  @override
  String get next => 'Tókàn';

  @override
  String get back => 'Padà';

  @override
  String get skip => 'Fò';

  @override
  String get cancel => 'Fagílé';

  @override
  String get save => 'Fípamọ́';

  @override
  String get done => 'Parí';

  @override
  String get submit => 'Fiwé';

  @override
  String get logout => 'Jáde';

  @override
  String get login => 'Wọlé';

  @override
  String get signup => 'Forúkọsílẹ̀';

  @override
  String get email => 'Ímeèlì';

  @override
  String get password => 'Ọ̀rọ̀ àṣínà';

  @override
  String get forgotPassword => 'Ṣe o gbàgbé ọ̀rọ̀ àṣínà?';

  @override
  String get noAccount => 'O ní àkọọ́lẹ̀?';

  @override
  String get haveAccount => 'Ṣé o ní àkọọ́lẹ̀ tẹ́lẹ̀?';

  @override
  String get congratulations => 'Kú oríire!';

  @override
  String get lessonComplete => 'Ẹ̀kọ́ parí!';

  @override
  String get quizComplete => 'Ìdánwò parí!';

  @override
  String get accuracy => 'Ìtọ́ọ̀tọ́';

  @override
  String get score => 'Àmì';

  @override
  String get aiTutor => 'Olùkọ́ AI';

  @override
  String get cultureMagazine => 'Ìwé àṣà';

  @override
  String get tribes => 'Ẹ̀yà';

  @override
  String get leaderboard => 'Àtòjọ́ àsájú';

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

  @override
  String get polieTutorSavedCards => 'Saved cards';

  @override
  String get polieTutorSaveCard => 'Save';

  @override
  String get polieTutorRemoveSavedCard => 'Remove';

  @override
  String get polieTutorNoSavedCardsYet => 'No saved cards yet.';

  @override
  String get liveTranslateTitle => 'Live translate';

  @override
  String get liveTranslateEndSession => 'End session';

  @override
  String liveTranslateStatus(Object status) {
    return 'Status: $status';
  }

  @override
  String get liveTranslateSource => 'Source';

  @override
  String get liveTranslateTranslation => 'Translation';

  @override
  String get liveTranslateSourceLanguageLabel =>
      'Source language (e.g. english)';

  @override
  String get liveTranslateTargetLanguageLabel =>
      'Target language (e.g. yoruba)';

  @override
  String get liveTranslateStartSession => 'Start session';

  @override
  String get liveTranslateStarting => 'Starting…';

  @override
  String get liveTranslateReconnect => 'Reconnect';

  @override
  String get liveTranslateListen => 'Listen';

  @override
  String get liveTranslateStopListening => 'Stop listening';

  @override
  String get liveTranslateInterruptBargeIn => 'Interrupt / barge-in';

  @override
  String get liveTranslatePlaceholderDash => '…';

  @override
  String get liveTranslateSpeechUnavailable =>
      'Speech input did not start. This phone cannot run live speech here. Type your phrase or use another device.';

  @override
  String get liveTranslateMicPermissionRequired =>
      'The mic is blocked. LingAfriq needs the mic to hear you. Open Settings and allow the mic.';

  @override
  String get liveTranslateInvalidSession =>
      'Could not start live translate. The server sent an invalid session. Tap Reconnect and try again.';

  @override
  String get liveTranslateStartSessionFirst =>
      'Listening is not active yet. You have not started a session. Tap Start session, then speak.';

  @override
  String get liveTranslateConnectionLost =>
      'Connection lost. Your network cut out. Tap reconnect to try again.';

  @override
  String liveTranslateSocketError(Object error) {
    return 'Could not connect for live translate. The socket failed: $error. Check your network and tap Reconnect.';
  }

  @override
  String get liveTranslateSessionFailed =>
      'Could not start a live translate session. The server rejected the request. Wait a moment and try again.';

  @override
  String liveTranslateCouldNotPlayAudio(Object error) {
    return 'Could not play the translation audio. Playback failed: $error. Tap Hear it again or check your volume.';
  }

  @override
  String get liveTranslateSessionError =>
      'Live translate hit a session error. Something went wrong on the connection. Leave the session and start again.';

  @override
  String get liveTranslateDefaultAudioMime => 'audio/wav';

  @override
  String get gameWordMatchConnectMeaningTitle => 'Connect the Meaning';

  @override
  String get gameWordMatchConnectMeaningSubtitle =>
      'Tap a word to hear its voice, then match it to its anchor.';

  @override
  String get gameWordMatchEnglishLabel => 'English';

  @override
  String get content_coming_soon => 'Coming Soon';

  @override
  String get content_not_available_yet => 'This content is not available yet.';

  @override
  String get content_coming_soon_badge => 'Soon';

  @override
  String get pron_practice_mode => 'Practice mode';

  @override
  String get pron_scoring_soon => 'Scoring coming soon';

  @override
  String get pron_unavailable =>
      'We could not score your speech. The scorer is temporarily unavailable. Try again in a moment; no score is shown.';

  @override
  String get contentPublishAction => 'Publish';

  @override
  String get contentPublishDone => 'Published';

  @override
  String get persona_ai_disclosure =>
      'This is an AI recreation based on sources.';

  @override
  String get personaBadgeAiRecreation => 'AI recreation';

  @override
  String personaOpeningHowBuilt(String personaName, String sourceSummary) {
    return 'This recreates $personaName from $sourceSummary. Speech and scenes are AI-generated, not a recording of the historical person.';
  }

  @override
  String get personaVoiceSynthesised => 'Synthesised voice';

  @override
  String get persona_error_retry =>
      'Couldn\'t reach the persona. The network or server timed out. Retry when you\'re ready.';

  @override
  String get personaChipSource => 'Source';

  @override
  String get personaChipInferred => 'Inferred';

  @override
  String get personaChipLegend => 'Legend';

  @override
  String get personaChipLoading => 'Checking sources';

  @override
  String get personaChipNoSource => 'Source unavailable';

  @override
  String get personaChipSourceSemantics =>
      'Documented claim. Source available. Double tap to open the cited card.';

  @override
  String get personaChipInferredSemantics =>
      'Inferred claim. Drawn from context, not a direct citation.';

  @override
  String get personaChipLegendSemantics =>
      'Legend claim. Traditional or oral tradition, not a single document.';

  @override
  String get personaChipNoSourceSemantics =>
      'Documented claim, but the cited source is not available yet.';

  @override
  String get persona_dialogue_welcome =>
      'Eh, welcome back, friend. The path waits for you today.';

  @override
  String get labelBetaCopy =>
      'AI-assisted, machine-checked. Spotted a problem? Tell us.';

  @override
  String get labelNative => 'Native-verified';

  @override
  String get labelExpert => 'Expert-reviewed';

  @override
  String get audioSynthetic => 'Synthetic voice';
}
