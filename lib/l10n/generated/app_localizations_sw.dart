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
  String get gamekitFeedbackTitle => 'Your answer';

  @override
  String get gamekitFeedbackInstructions => 'Tap an answer when you are ready.';

  @override
  String get gamekitFeedbackCorrect => 'Nice one!';

  @override
  String get gamekitFeedbackWrong => 'Not quite — try the next one.';

  @override
  String get gamekitFeedbackPending => 'Checking your answer…';

  @override
  String get gamekitFeedbackWhyWrong => 'Why was I wrong?';

  @override
  String get gamekitFeedbackPracticeLabel => 'Practice mode';

  @override
  String get gamekitPracticeModeTitle => 'Practice round';

  @override
  String get gamekitPracticeModeInstructions =>
      'Listen, repeat, and compare. Nothing here is scored.';

  @override
  String get gamekitPracticeModeWhyWrong => 'Tips';

  @override
  String get gamekitPracticeModePracticeLabel => 'Practice, not scored';

  @override
  String get gamekitPracticeModeError =>
      'Audio is not ready yet. You can still read the phrase.';

  @override
  String get gamesGreetingGauntletTitle => 'Greeting Gauntlet';

  @override
  String get gamesGreetingGauntletInstructions =>
      'Read the scene, pick the greeting and gesture that fit — before the timer runs out.';

  @override
  String get gamesGreetingGauntletWhyWrong =>
      'Listen to why that greeting or gesture did not match the moment.';

  @override
  String get gamesGreetingGauntletPracticeLabel =>
      'Practice — cultural rounds do not affect rank until scoring is verified.';

  @override
  String get gamesGreetingGauntletError =>
      'We could not load greeting scenarios for this language yet. Try again when you are online.';

  @override
  String get gamesGameMasteryResultsTitle => 'Round complete';

  @override
  String get gamesGameMasteryResultsInstructions =>
      'Here is how this round touched your skills in the learner model.';

  @override
  String get gamesGameMasteryResultsSkillsHeading => 'Skills this round';

  @override
  String get gamesGameMasteryResultsNoChange => 'No change';

  @override
  String get gamesGameMasteryResultsImproved => 'Improved';

  @override
  String get gamesGameMasteryResultsDeclined => 'Needs practice';

  @override
  String get gamesGameMasteryResultsPracticeLabel => 'Practice, not scored';

  @override
  String get gamesGameMasteryResultsError =>
      'Skill details are still syncing. Your practice was saved.';

  @override
  String get gamesGameMasteryResultsDone => 'Back to Play';

  @override
  String get gamesMasteryMapTitle => 'Mastery map';

  @override
  String get gamesMasteryMapInstructions =>
      'See which arcade games moved each skill in your learner model.';

  @override
  String get gamesMasteryMapGamesHeading => 'Games that moved this skill';

  @override
  String get gamesMasteryMapNotMeasured => 'Not measured';

  @override
  String get gamesMasteryMapUnsure => 'Unsure';

  @override
  String get gamesMasteryMapPracticeLabel => 'Practice, not scored';

  @override
  String get gamesMasteryMapError =>
      'We could not load your mastery map. Finish a scored arcade round and try again.';

  @override
  String get gamekitFeedbackError => 'We could not score that turn. Try again.';

  @override
  String gamekitFeedbackStreak(int count) {
    return '$count in a row!';
  }

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
    return 'AI version of $personaName from $sourceSummary.';
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
      'Documented claim. Source card ready. Double tap to open it.';

  @override
  String get personaChipInferredSemantics =>
      'Inferred claim. Drawn from context, not a direct citation.';

  @override
  String get personaChipLegendSemantics =>
      'Legend claim. Oral tradition, not one document.';

  @override
  String get personaChipNoSourceSemantics =>
      'Documented claim. Source card is not ready yet.';

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

  @override
  String avatarSemanticsExpression(String name, String expression) {
    return '$name looks $expression';
  }

  @override
  String avatarSemanticsExpressionActivity(
    String name,
    String expression,
    String activity,
  ) {
    return '$name looks $expression and is $activity';
  }

  @override
  String get avatarEditorTitle => 'Your avatar';

  @override
  String get avatarEditorLoadError =>
      'We could not load avatar styles. Try again shortly.';

  @override
  String get avatarEditorSkinTone => 'Skin tone';

  @override
  String get avatarEditorSlotHair => 'Hair';

  @override
  String get avatarEditorSlotHeadwear => 'Headwear';

  @override
  String get avatarEditorSlotTop => 'Top';

  @override
  String get avatarEditorSlotBottom => 'Bottom';

  @override
  String get avatarEditorSlotAccessory => 'Accessory';

  @override
  String get avatarEditorSlotProp => 'Prop';

  @override
  String avatarItemLocked(String reason) {
    return 'Locked — $reason';
  }

  @override
  String get avatarItemLockedTitle => 'This look is still locked';

  @override
  String avatarItemNote(String note) {
    return '$note';
  }

  @override
  String get avatarItemLockedReasonGreetings =>
      'Finish the Greetings & respect can-do to unlock this headwear.';

  @override
  String get avatarItemLockedReasonTone =>
      'Pass a tone checkpoint to unlock this prop.';

  @override
  String get avatarItemLockedReasonCulturalReview =>
      'This garment unlocks after our cultural review gate clears.';

  @override
  String get avatarItemLockedReasonIsicholo =>
      'Isicholo needs cultural context — unlock with guided quest content.';

  @override
  String get avatarItemLockedReasonMastery =>
      'Earn this look through a mastery milestone, not the shop.';

  @override
  String get avatarItemLockedReasonStreamPack =>
      'Extra styles unlock when you complete a chapter can-do.';

  @override
  String get gamesArcadeHeadlinersTitle => 'Headliners';

  @override
  String get gamesArcadeHeadlinersInstructions =>
      'Tap a flagship to play — more are on the way.';

  @override
  String get gamesArcadeHeadlinersFeatured => 'Featured';

  @override
  String get gamesArcadeHeadlinersComingSoon => 'Coming soon';

  @override
  String get gamesArcadeHeadlinersError =>
      'This game is not ready yet. Try another headliner.';

  @override
  String get gamesArcadeHeadlinersWhyWrong =>
      'We will add a short tip here after you play.';

  @override
  String get duetStart => 'Start duet';

  @override
  String get duetBlocked => 'Duet unavailable';

  @override
  String get stitchLabel => 'Native correction';

  @override
  String get aiDisclosureLabel =>
      'AI-generated: replies and voice come from an AI tutor and can be wrong.';

  @override
  String get aiDisclosureShort => 'AI-generated content';

  @override
  String get aiDisclosureMoreHint => 'Learn how AI is used here';

  @override
  String get aiDisclosureSheetTitle => 'About AI in LingAfriq';

  @override
  String get aiDisclosureSheetBody =>
      'Polie, the tutors and AI personas are not people. Their text and voices are generated by AI. They can be wrong, so check important facts. Avoid sharing private information in chats.';

  @override
  String get aiDisclosureGotIt => 'Got it';

  @override
  String get voiceRetentionTitle => 'Recordings on this device';

  @override
  String get voiceRetentionBody =>
      'Your voice is recorded only while you practise, to score pronunciation and turn speech into text. Recordings saved on this phone are deleted automatically.';

  @override
  String get voiceRetentionSelectLabel => 'Delete recordings automatically';

  @override
  String get voiceRetentionImmediate => 'Right after scoring';

  @override
  String get voiceRetention24h => 'After 24 hours';

  @override
  String get voiceRetention7d => 'After 7 days';

  @override
  String get voiceRetention30d => 'After 30 days';

  @override
  String get voiceRetentionDeleteNow => 'Delete my recordings now';

  @override
  String get voiceRetentionConfirmTitle => 'Delete recordings on this device?';

  @override
  String get voiceRetentionConfirmBody =>
      'Practice recordings saved on this phone will be removed. This can\'t be undone. Recordings you chose to save to your account are not affected.';

  @override
  String get voiceRetentionConfirmDelete => 'Delete';

  @override
  String voiceRetentionDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings deleted from this device.',
      one: '1 recording deleted from this device.',
      zero: 'No recordings to delete.',
    );
    return '$_temp0';
  }

  @override
  String get paywallTermsTitle => 'Subscription terms';

  @override
  String get paywallRowPrice => 'Price';

  @override
  String get paywallRowRenews => 'Renews';

  @override
  String get paywallRowTrial => 'Free trial';

  @override
  String get paywallRowCancel => 'Cancel';

  @override
  String paywallPriceValue(String premium, String family, String lifetime) {
    return 'Premium $premium/month\nFamily $family/month\nLifetime $lifetime, paid once';
  }

  @override
  String paywallChargedTo(String store) {
    return 'Charged to your $store account.';
  }

  @override
  String get paywallRenewsAuto =>
      'Monthly plans renew automatically at the same price until you cancel. Lifetime does not renew.';

  @override
  String paywallRenewsOn(String date) {
    return 'Your plan renews on $date.';
  }

  @override
  String paywallTrialOffered(int days, String price) {
    return '$days-day free trial, then $price/month unless you cancel at least 24 hours before it ends.';
  }

  @override
  String get paywallTrialGeneric =>
      'If a trial is offered, you pay the plan price when it ends unless you cancel at least 24 hours before.';

  @override
  String get paywallCancelApple =>
      'Any time in Settings › your name › Subscriptions. You keep access until the paid period ends.';

  @override
  String get paywallCancelGoogle =>
      'Any time in Google Play › Payments & subscriptions › Subscriptions. You keep access until the paid period ends.';

  @override
  String get paywallFreeStays =>
      'Free features stay available if you don\'t subscribe or you cancel.';

  @override
  String get paywallManage => 'Manage subscription';

  @override
  String get paywallTerms => 'Terms of Service';

  @override
  String get paywallPrivacy => 'Privacy Policy';

  @override
  String get reportReasonHarassment => 'Harassment or bullying';

  @override
  String get reportReasonSpam => 'Spam or scam';

  @override
  String get reportReasonHate => 'Hate speech';

  @override
  String get reportReasonCopyright => 'Copyright infringement';

  @override
  String get reportReasonCopyrightHint =>
      'Someone posted your work without permission';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get settingsCopyright => 'Copyright & takedown';

  @override
  String get cpTitle => 'Copyright & takedown';

  @override
  String get cpIntro =>
      'If something on LingAfriq uses your work without permission, tell us. A person reviews every notice.';

  @override
  String get cpHowTitle => 'How it works';

  @override
  String get cpStep1 => 'You send a notice with the details below.';

  @override
  String get cpStep2 =>
      'We remove or hide the content quickly and tell the uploader.';

  @override
  String get cpStep3 =>
      'The uploader can send a counter-notice if it was a mistake. Unless you start a court case, the content may return after 10–14 business days.';

  @override
  String get cpRepeatTitle => 'Repeat infringers';

  @override
  String get cpRepeatBody =>
      'Accounts with 3 upheld copyright notices are closed. False notices or counter-notices can have legal consequences.';

  @override
  String get cpAgentTitle => 'Designated copyright agent';

  @override
  String get cpAgentPending =>
      'Agent registration in progress. Until then, use this form.';

  @override
  String get cpKindNotice => 'Report copyright';

  @override
  String get cpKindCounter => 'Counter-notice';

  @override
  String get cpFormTitle => 'Your notice';

  @override
  String get cpFieldTarget => 'Content ID or link on LingAfriq';

  @override
  String get cpFieldWork => 'Describe your original work';

  @override
  String get cpFieldWorkCounter => 'Describe the removed content';

  @override
  String get cpFieldWorkHelp =>
      'For example: title, where it was first published, and a link.';

  @override
  String get cpFieldName => 'Full legal name';

  @override
  String get cpFieldEmail => 'Email for our reply';

  @override
  String get cpFieldSignature => 'Signature: type your full name';

  @override
  String get cpStatementsTitle => 'Statements';

  @override
  String get cpStmtGoodFaith =>
      'I believe in good faith this use is not authorised by the owner, its agent or the law.';

  @override
  String get cpStmtAccurate =>
      'This notice is accurate and, under penalty of perjury, I am the owner or authorised to act for the owner.';

  @override
  String get cpStmtMistake =>
      'Under penalty of perjury, I believe the content was removed by mistake or misidentification.';

  @override
  String get cpStmtJurisdiction =>
      'I consent to the jurisdiction of the appropriate court and accept service from the claimant.';

  @override
  String get cpRequired => 'Required';

  @override
  String get cpEmailInvalid => 'Enter a valid email';

  @override
  String get cpWorkTooShort => 'Add a little more detail';

  @override
  String get cpStatementsMissing => 'Tick both statements to continue';

  @override
  String get cpSend => 'Send notice';

  @override
  String get cpSending => 'Sending…';

  @override
  String get cpErrorTitle => 'We couldn\'t send your notice';

  @override
  String get cpErrorBody =>
      'Check your connection and try again. Nothing you typed was lost.';

  @override
  String get cpRetry => 'Try again';

  @override
  String get cpSuccessTitle => 'Notice received';

  @override
  String cpSuccessBody(String reference) {
    return 'A person will review it and email you. Keep this reference: $reference';
  }

  @override
  String get cpDone => 'Done';
}
