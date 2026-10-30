// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Bienvenido a LingAfriq';

  @override
  String get continueButton => 'Continuar';

  @override
  String get startLearning => 'Comenzar a Aprender';

  @override
  String get loading => 'Cargando...';

  @override
  String get errorOccurred => 'Ocurrió un error';

  @override
  String get tryAgain => 'Intentar de Nuevo';

  @override
  String get home => 'Inicio';

  @override
  String get learn => 'Aprender';

  @override
  String get games => 'Juegos';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get lessons => 'Lecciones';

  @override
  String get quizzes => 'Cuestionarios';

  @override
  String get takeQuiz => 'Hacer un Cuestionario';

  @override
  String get takeLesson => 'Tomar una Lección';

  @override
  String get dailyStreak => 'Racha Diaria';

  @override
  String daysStreak(int count) {
    return '$count días';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Nivel';

  @override
  String get beginner => 'Principiante';

  @override
  String get intermediate => 'Intermedio';

  @override
  String get advanced => 'Avanzado';

  @override
  String get correct => '¡Correcto!';

  @override
  String get incorrect => 'Incorrecto';

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Atrás';

  @override
  String get skip => 'Saltar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get done => 'Hecho';

  @override
  String get submit => 'Enviar';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get signup => 'Registrarse';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu Contraseña?';

  @override
  String get noAccount => '¿No tienes una cuenta?';

  @override
  String get haveAccount => '¿Ya tienes una cuenta?';

  @override
  String get congratulations => '¡Felicidades!';

  @override
  String get lessonComplete => '¡Lección Completada!';

  @override
  String get quizComplete => '¡Cuestionario Completado!';

  @override
  String get accuracy => 'Precisión';

  @override
  String get score => 'Puntuación';

  @override
  String get aiTutor => 'Tutor de IA';

  @override
  String get cultureMagazine => 'Revista Cultural';

  @override
  String get tribes => 'Tribus';

  @override
  String get leaderboard => 'Clasificación';

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
    return 'Plus Monthly $premium/month\nPlus Family $family/month\nPlus Lifetime $lifetime, paid once';
  }

  @override
  String paywallChargedTo(String store) {
    return 'Charged to your $store account.';
  }

  @override
  String get paywallRenewsAuto =>
      'Plus Monthly and Plus Family renew automatically at the same price until you cancel. Plus Lifetime does not renew.';

  @override
  String paywallRenewsOn(String date) {
    return 'Your plan renews on $date.';
  }

  @override
  String paywallTrialOffered(int days, String price) {
    return '$days-day free trial of Plus Monthly, then $price/month unless you cancel at least 24 hours before it ends.';
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

  @override
  String get reportReasonTitle => 'Why are you reporting this?';

  @override
  String get settingsSecAppearance => 'Appearance';

  @override
  String get settingsSecNotifications => 'Notifications';

  @override
  String get settingsSecAudio => 'Audio';

  @override
  String get settingsSecSecurity => 'Security';

  @override
  String get settingsSecAccount => 'Account';

  @override
  String get settingsSecLearning => 'Learning';

  @override
  String get settingsSecOffline => 'Offline & Sync';

  @override
  String get settingsSecAbout => 'About';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsDarkModeSub => 'Switch between light and dark theme';

  @override
  String get settingsPush => 'Push notifications';

  @override
  String get settingsPushSub => 'Receive push notifications';

  @override
  String get settingsDailyReminders => 'Daily reminders';

  @override
  String get settingsDailyRemindersSub => 'Get reminded to practise daily';

  @override
  String get settingsSoundEffects => 'Sound effects';

  @override
  String get settingsSoundEffectsSub => 'Play sound effects during lessons';

  @override
  String get settingsVoiceStyles => 'Tutor voice styles';

  @override
  String get settingsVoiceStylesSub =>
      'Synthetic, non-identifying voices (opt-in)';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsBiometric => 'Biometric sign-in';

  @override
  String get settingsBiometricSub => 'Use biometrics to sign in quickly';

  @override
  String get settingsEncryptCache => 'Encrypt cached data';

  @override
  String get settingsEncryptCacheSub =>
      'Encrypt sensitive data stored on this device';

  @override
  String get settingsEditProfile => 'Edit profile';

  @override
  String get settingsEditProfileSub => 'Update your personal information';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsChangePasswordSub => 'Update your account password';

  @override
  String get settingsPrivacy => 'Privacy settings';

  @override
  String get settingsPrivacySub => 'Manage your privacy preferences';

  @override
  String get settingsMentorReports => 'Micro-mentor reports';

  @override
  String get settingsMentorReportsSub => 'Review safety reports (staff)';

  @override
  String get settingsGoals => 'Learning goals';

  @override
  String get settingsGoalsSub => 'Set your daily learning goals';

  @override
  String get settingsStudyReminders => 'Study reminders';

  @override
  String get settingsStudyRemindersSub => 'Choose when to be reminded';

  @override
  String get settingsSync => 'Sync settings';

  @override
  String get settingsSyncSub => 'Choose what to sync';

  @override
  String get settingsCache => 'Cache management';

  @override
  String get settingsCacheSub => 'View and manage cached data';

  @override
  String get settingsDownloads => 'Downloads';

  @override
  String get settingsDownloadsSub => 'Unit size, Wi-Fi and delete';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsHelp => 'Help & Support';

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get settingsFeaturesGuide => 'Features guide';

  @override
  String get settingsGamesTour => 'How games work';

  @override
  String get lowBandwidthTitle => 'Low bandwidth';

  @override
  String get lowBandwidthAutoOn => 'On because Data Saver is on';

  @override
  String get lowBandwidthManualOn => 'On until you turn it off';

  @override
  String get lowBandwidthOff => 'Off';

  @override
  String get lessonExit => 'Exit lesson';

  @override
  String get lessonQuitTitle => 'Leave this lesson?';

  @override
  String get lessonQuitBody =>
      'You\'re doing well. A few more minutes finishes this lesson.';

  @override
  String get lessonKeepLearning => 'Keep learning';

  @override
  String get lessonEndSession => 'End lesson';

  @override
  String get lessonPreparing => 'Preparing your lesson';

  @override
  String get lessonLoadFailedTitle => 'Let\'s try that again';

  @override
  String get lessonRetry => 'Retry';

  @override
  String lessonProgressLabel(int current, int total, int percent) {
    return 'Lesson progress. Section $current of $total. $percent percent complete.';
  }

  @override
  String lessonSectionLabel(int current, int total) {
    return 'Section $current of $total';
  }

  @override
  String get lessonContinueNext => 'Continue to next section';

  @override
  String pointsCount(int count) {
    return '$count Points';
  }

  @override
  String lessonQuitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sections left',
      one: '1 section left',
    );
    return '$_temp0';
  }

  @override
  String get homeSearchLanguagesLabel => 'Search languages';

  @override
  String get homeSearchLanguagesAction => 'Search Languages';

  @override
  String get homeOpenMenu => 'Open menu';

  @override
  String get homeMenu => 'Menu';

  @override
  String get homeFeaturedLanguages => 'Featured Languages';

  @override
  String get homeNoLanguagesTitle => 'No languages yet';

  @override
  String get homeNoLanguagesBody =>
      'We\'re still adding languages for your region. Search to see what\'s available, or check back soon.';

  @override
  String homeComingSoonSnack(String name) {
    return '$name is coming soon. We\'re putting the finishing touches on it.';
  }

  @override
  String get homeOfflineTitle => 'You\'re offline';

  @override
  String get homeOfflineBody =>
      'Check your connection. We\'ll reload your languages as soon as you\'re back online.';

  @override
  String get homeTryAgain => 'Try Again';

  @override
  String get homeLoadingLanguages => 'Loading your languages...';

  @override
  String get homeComingSoon => 'Coming soon';

  @override
  String homePercentComplete(int percent) {
    return '$percent% Complete';
  }

  @override
  String get homeStartLearning => 'Start Learning';

  @override
  String homeCardLocked(String name) {
    return '$name language card, coming soon, not available yet';
  }

  @override
  String homeCardProgress(String name, int percent) {
    return '$name language card, $percent% complete';
  }

  @override
  String homeCardStart(String name) {
    return '$name language card, start learning';
  }

  @override
  String homeFlag(String name) {
    return '$name picture';
  }

  @override
  String get homeGuardianTitle => 'Waiting for a guardian';

  @override
  String get homeGuardianBody =>
      'Lessons are open. Chat, Village, and purchases stay paused until a guardian approves.';

  @override
  String get homeGuardianLabel =>
      'Waiting for a guardian. Lessons are open, but chat, Village, and purchases stay paused until a guardian approves.';

  @override
  String homeWelcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get homeLearner => 'Learner';

  @override
  String get homeStreakNone => 'Pick a language and start your streak today.';

  @override
  String get homeStreakOne =>
      'You\'re one day in, keep your streak alive today.';

  @override
  String homeStreakMany(int count) {
    return 'You\'re on a $count-day streak, keep it going!';
  }

  @override
  String homeStreakBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String homeStreakSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get homeDailyGoals => 'Daily goals';

  @override
  String homeGoalRing(int percent) {
    return 'Today\'s goal progress: $percent%';
  }

  @override
  String get homeGoalCaption => 'today';

  @override
  String homeWordOfDay(String word, String language) {
    return 'Today\'s word: $word, “welcome” in $language';
  }

  @override
  String get homeLangHausa => 'Hausa';

  @override
  String get homeLangPidgin => 'Pidgin';

  @override
  String get homeLangSwahili => 'Swahili';

  @override
  String get homeLangYoruba => 'Yorùbá';

  @override
  String get homeLangZulu => 'Zulu';

  @override
  String get homeLangIgbo => 'Igbo';

  @override
  String homeContinueTitle(String name) {
    return 'Continue $name';
  }

  @override
  String homeContinueLabel(String name, int percent) {
    return 'Continue $name, $percent% complete';
  }

  @override
  String get homeErrorTitle => 'We couldn\'t load your languages';

  @override
  String get homeErrorBody =>
      'That one\'s on us. Your progress is safe, so try again in a moment.';

  @override
  String get homeKidsTitle => 'Kids mode is on';

  @override
  String get homeKidsBody =>
      'Every lesson is open. Chat, Village and purchases are switched off.';

  @override
  String get homeKidsLabel =>
      'Kids mode is on. Every lesson is open. Chat, Village and purchases are switched off.';

  @override
  String get lessonNewPhrase => 'New phrase';

  @override
  String get lessonExampleLabel => 'Example';

  @override
  String get lessonListen => 'Listen';

  @override
  String get lessonListenSlowly => 'Listen slowly';

  @override
  String get lessonTutorialAudio => 'Tutorial audio';

  @override
  String get lessonTutorialVideo => 'Tutorial video';

  @override
  String lessonQuestionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String lessonQuestionProgress(int current, int total, int percent) {
    return 'Question $current of $total. $percent percent complete.';
  }

  @override
  String get lessonPrevious => 'Previous';

  @override
  String get lessonPreviousQuestion => 'Previous question';

  @override
  String get lessonCheck => 'Check';

  @override
  String get lessonCheckAnswer => 'Check answer';

  @override
  String get lessonNext => 'Next';

  @override
  String get lessonNextQuestion => 'Next question';

  @override
  String get lessonFinish => 'Finish';

  @override
  String get lessonFinishQuiz => 'Finish quiz';

  @override
  String get lessonPickFirst =>
      'Pick an answer first, then we\'ll check it together.';

  @override
  String get lessonCorrectTitle => 'Nice work!';

  @override
  String get lessonCorrectBody => 'That\'s right. Keep the streak going.';

  @override
  String get lessonIncorrectTitle => 'Not quite';

  @override
  String lessonCorrectAnswer(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String lessonOptionLabel(String letter, String text) {
    return 'Answer option $letter: $text.';
  }

  @override
  String get lessonOptionSelected => 'Selected';

  @override
  String lessonQuestionLabel(String question) {
    return 'Question. $question';
  }

  @override
  String lessonHintLabel(String hint) {
    return 'Hint: $hint';
  }

  @override
  String get lessonFunFact => 'Fun fact';

  @override
  String get lessonNotReadyTitle => 'This part isn\'t ready yet';

  @override
  String get lessonNotReadyBody =>
      'We\'re still preparing these questions. Please check back in a moment.';

  @override
  String get lessonLoadFailedBody =>
      'Check your connection and try again. Your progress is saved.';

  @override
  String lessonAvatarLabel(String points) {
    return 'Your profile, $points';
  }

  @override
  String get lcMsgGreat => 'You\'re building real conversational confidence.';

  @override
  String get lcMsgGood => 'That lesson moved you forward. Well done.';

  @override
  String get lcMsgSteady => 'Every session strengthens memory. Keep going.';

  @override
  String get lcMsgReview => 'A short review next time will lock these in.';

  @override
  String get lcMsgNoQuiz =>
      'You met new phrases today. They\'ll come back in your next quiz.';

  @override
  String get lcStatXp => 'XP earned';

  @override
  String get lcStatAccuracy => 'Accuracy';

  @override
  String get lcStatTime => 'Time';

  @override
  String get lcNoQuizValue => 'Not quizzed';

  @override
  String lcPercent(int value) {
    return '$value%';
  }

  @override
  String lcTimeMinSec(int m, int s) {
    return '${m}m ${s}s';
  }

  @override
  String lcTimeSec(int s) {
    return '${s}s';
  }

  @override
  String lcBestRun(int count) {
    return 'Best run: $count in a row';
  }

  @override
  String lcComboBonus(int xp) {
    return 'Combo bonus +$xp XP';
  }

  @override
  String get lcContinue => 'Continue';

  @override
  String get lcShare => 'Share';

  @override
  String get lcContinueA11y => 'Continue to next lesson';

  @override
  String get lcShareA11y => 'Share your result';

  @override
  String get lcOffline =>
      'You\'re offline. Your progress is saved on this phone, and sharing will be back when you reconnect.';

  @override
  String lcSummaryA11y(int xp, String accuracy, String time) {
    return 'Lesson complete. $xp XP earned. Accuracy $accuracy. Time $time.';
  }

  @override
  String get lcHeroA11y => 'Amara and Kofi cheering';

  @override
  String get profOverview => 'Overview';

  @override
  String get profAccount => 'Account';

  @override
  String get profWallet => 'Wallet';

  @override
  String profStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get profStreakLabel => 'Day streak';

  @override
  String get profStreakZero => 'Start today';

  @override
  String profXpValue(int count) {
    return '$count XP';
  }

  @override
  String get profXpLabel => 'Total XP';

  @override
  String profRankValue(int rank) {
    return '#$rank';
  }

  @override
  String get profRankLabel => 'Global rank';

  @override
  String get profRankNone => 'Not ranked yet';

  @override
  String get profLevelLabel => 'Level';

  @override
  String get profLevelNone => 'Just starting';

  @override
  String get profPrivateValue => 'Private';

  @override
  String get profPrivateHint =>
      'Your profile is private, so your rank stays hidden from others.';

  @override
  String profLearning(String language) {
    return 'Learning $language';
  }

  @override
  String get profEdit => 'Edit profile';

  @override
  String get profChangePassword => 'Change password';

  @override
  String get profFeedback => 'Give us feedback';

  @override
  String get profAbout => 'Who we are';

  @override
  String get profPolicy => 'Privacy and user policy';

  @override
  String get profDelete => 'Delete your account';

  @override
  String get profDeleted => 'Account deleted';

  @override
  String get profLoading => 'Loading your profile…';

  @override
  String get profErrorTitle => 'We couldn\'t load your profile';

  @override
  String get profErrorBody =>
      'Check your connection and try again. Nothing you\'ve learned is lost.';

  @override
  String get profRetry => 'Try again';

  @override
  String get profOffline => 'You\'re offline. Showing your saved profile.';

  @override
  String get profNgwenya => 'Ngwenya';

  @override
  String get profCowries => 'Cowries';

  @override
  String get profBeads => 'Beads';

  @override
  String get profOpenLeaderboard => 'Open the leaderboard';

  @override
  String get pgTitle => 'Your progress';

  @override
  String get pgThisWeek => 'This week';

  @override
  String pgMinutes(int count) {
    return '$count min';
  }

  @override
  String pgVsUp(int count) {
    return '$count min more than last week';
  }

  @override
  String pgVsDown(int count) {
    return '$count min less than last week';
  }

  @override
  String get pgVsSame => 'Same as last week';

  @override
  String get pgWordsLearned => 'Words learned';

  @override
  String get pgKnownWords => 'Words you know';

  @override
  String get pgListening => 'Listening';

  @override
  String get pgSpeaking => 'Speaking';

  @override
  String pgHours(String value) {
    return '$value h';
  }

  @override
  String get pgDaily => 'Minutes per day';

  @override
  String get pgCalendar => 'Last 4 weeks';

  @override
  String pgActiveDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active days',
      one: '1 active day',
      zero: 'No active days yet',
    );
    return '$_temp0';
  }

  @override
  String get pgActivities => 'Time by activity';

  @override
  String get pgActLessons => 'Lessons';

  @override
  String get pgActQuizzes => 'Quizzes';

  @override
  String get pgActGames => 'Games';

  @override
  String get pgActChat => 'Chat practice';

  @override
  String get pgActStories => 'Stories';

  @override
  String get pgActReading => 'Reading';

  @override
  String get pgActWriting => 'Writing';

  @override
  String get pgActOther => 'Other practice';

  @override
  String get pgOfflineCount => 'Offline days count too.';

  @override
  String get pgOffline =>
      'You\'re offline. Showing progress saved on this device.';

  @override
  String get pgEmptyTitle => 'Your progress starts here';

  @override
  String get pgEmptyBody =>
      'Finish a lesson and your minutes, words and active days will appear here.';

  @override
  String get pgLoading => 'Loading your progress…';

  @override
  String get pgErrorTitle => 'We couldn\'t load your progress';

  @override
  String get pgErrorBody =>
      'Your progress is safe on this device. Try again in a moment.';

  @override
  String get pgRetry => 'Try again';

  @override
  String get pgPrivate => 'Your progress is private. Only you can see it.';

  @override
  String pgDayA11y(String day, int count) {
    return '$day: $count minutes';
  }

  @override
  String pgCalA11y(String summary) {
    return 'Activity calendar: $summary';
  }

  @override
  String get pgOverviewTitle => 'Totals';

  @override
  String get profTitle => 'Profile';

  @override
  String get profClose => 'Close';

  @override
  String get profThisWeek => 'This week';

  @override
  String get profSeeProgress => 'See all progress';

  @override
  String profDayA11y(String day, String status) {
    return '$day: $status';
  }

  @override
  String get profDayDone => 'practised';

  @override
  String get profDayMissed => 'no practice';

  @override
  String get profLanguages => 'Languages';

  @override
  String profLangProgress(String level, int percent) {
    return 'Level $level · $percent%';
  }

  @override
  String get profLangEmpty => 'Pick a language on Home to start your journey.';

  @override
  String get profBadges => 'Achievements';

  @override
  String profBadgesCount(int done, int total) {
    return '$done of $total unlocked';
  }

  @override
  String get profViewAll => 'View all';

  @override
  String profBadgeLocked(String name) {
    return '$name, locked';
  }

  @override
  String get profShareTitle => 'Share your progress';

  @override
  String get profShareBody => 'Send a card with your streak and XP.';

  @override
  String get profShare => 'Share';

  @override
  String profShareText(String language, int streak, int xp) {
    return 'I\'m learning $language on LingAfriq: $streak-day streak and $xp XP!';
  }

  @override
  String get profHelpLegal => 'Help and legal';

  @override
  String get profAboutApp => 'About LingAfriq';

  @override
  String get profSecurity => 'Account and security';

  @override
  String get profTeenBadge => 'Private profile';

  @override
  String get profTeenTitle => 'Your profile stays private';

  @override
  String get profTeenHidden =>
      'Your rank and name are hidden from leaderboards.';

  @override
  String get profTeenNoDm => 'Adults can\'t send you direct messages.';

  @override
  String get profTeenParent =>
      'Your account is linked to a parent or guardian, who gave consent.';

  @override
  String get pgClose => 'Close';

  @override
  String get pgStreakTitle => 'Current streak';

  @override
  String pgStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String pgNextGoal(int left, int goal) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left more days to your $goal-day goal',
      one: '1 more day to your $goal-day goal',
    );
    return '$_temp0';
  }

  @override
  String pgMilestoneHit(int goal) {
    return 'Milestone! $goal days in a row';
  }

  @override
  String get pgStreakStart => 'Practise today to light your streak.';

  @override
  String get pgErrorSaved => 'Your streak and practice days are not affected.';

  @override
  String get subTitle => 'LingAfriq Plus';

  @override
  String get subClose => 'Close';

  @override
  String get subPlusBadge => 'PLUS';

  @override
  String get subHeadline => 'Learn faster with optional extras';

  @override
  String get subFreeForever =>
      'Every lesson, game and story stays free forever. Plus only adds extras.';

  @override
  String get subOffline =>
      'You\'re offline. Buying needs a connection, but all your lessons still work.';

  @override
  String get subWhatYouGet => 'What Plus adds';

  @override
  String get subBenefitOffline => 'Download every unit to learn offline';

  @override
  String get subBenefitChat => 'Unlimited practice chats with your tutor';

  @override
  String get subBenefitSpeaking => 'Detailed speaking and tone scores';

  @override
  String get subBenefitNoAds => 'No ads, ever';

  @override
  String subYouHavePlus(String plan) {
    return 'You have $plan. Thank you for supporting African languages!';
  }

  @override
  String get subChoosePlan => 'Choose a plan';

  @override
  String get subPriceError =>
      'We couldn\'t load store prices, so these are standard prices. The store shows the final price before you pay.';

  @override
  String get subPlanMonthly => 'Plus Monthly';

  @override
  String get subPlanMonthlyDetail => 'Billed every month. Cancel anytime.';

  @override
  String get subPlanFamily => 'Plus Family';

  @override
  String get subPlanFamilyDetail => 'Up to 4 learners. Billed every month.';

  @override
  String get subPlanLifetime => 'Plus Lifetime';

  @override
  String get subPlanLifetimeDetail => 'Pay once. No renewals.';

  @override
  String get subMostPopular => 'Most popular';

  @override
  String subPerMonth(String price) {
    return '$price / month';
  }

  @override
  String subOnce(String price) {
    return '$price once';
  }

  @override
  String get subHowTrialWorks => 'How your free trial works';

  @override
  String get subStepToday => 'Today';

  @override
  String get subStepTodayBody => 'All Plus extras unlocked.';

  @override
  String subStepDay(int day) {
    return 'Day $day';
  }

  @override
  String get subStepRemindBody => 'We remind you before the trial ends.';

  @override
  String subStepChargeBody(String price) {
    return 'You\'re charged $price unless you cancel before.';
  }

  @override
  String subStartTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Start $days-day free trial',
    );
    return '$_temp0';
  }

  @override
  String get subGetPlus => 'Get Plus Monthly';

  @override
  String get subGetFamily => 'Get Plus Family';

  @override
  String get subGetLifetime => 'Get Plus Lifetime';

  @override
  String subFineTrial(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Free for $days days, then $price/month. Cancel anytime in your store settings.',
      one:
          'Free for 1 day, then $price/month. Cancel anytime in your store settings.',
    );
    return '$_temp0';
  }

  @override
  String subFineMonthly(String price) {
    return '$price/month, renews automatically. Cancel anytime in your store settings.';
  }

  @override
  String subFineOnce(String price) {
    return 'One payment of $price. Nothing renews.';
  }

  @override
  String get subKeepFree => 'Keep learning for free';

  @override
  String get subRestore => 'Restore purchases';

  @override
  String get subRestored => 'Purchases restored';

  @override
  String get subRestoreNone => 'No purchases found to restore';

  @override
  String get subLoading => 'Loading plans';

  @override
  String get subParentTitle => 'Plus needs a grown-up';

  @override
  String get subParentBody =>
      'Everything you\'re learning stays free. Ask a parent or guardian if you\'d like Plus extras.';

  @override
  String get subAskParent => 'A grown-up is here';

  @override
  String get subGateTitle => 'For grown-ups';

  @override
  String subGateQuestion(int a, int b) {
    return 'What is $a × $b?';
  }

  @override
  String get subGateWrong => 'That\'s not right. Try again.';

  @override
  String get subGateContinue => 'Continue';

  @override
  String get subCancel => 'Cancel';

  @override
  String get lsTitle => 'Find a language';

  @override
  String get lsAsk => 'Which language do you want to explore today?';

  @override
  String get lsAskChild => 'Which language shall we play with today?';

  @override
  String get lsHint => 'Search Yoruba, Swahili, Zulu…';

  @override
  String get lsContinue => 'Continue learning';

  @override
  String get lsAll => 'All languages';

  @override
  String get lsSoon => 'Coming soon';

  @override
  String get lsNew => 'Start from zero';

  @override
  String lsPercent(int p) {
    return '$p% done';
  }

  @override
  String lsNoMatch(String q) {
    return 'No language matches “$q”';
  }

  @override
  String get lsNoMatchBody =>
      'Check the spelling, or try the language\'s own name.';

  @override
  String get lsClear => 'Clear search';

  @override
  String get lsEmptyTitle => 'No languages yet';

  @override
  String get lsEmptyBody => 'New courses are on the way. Check back soon.';

  @override
  String get lsOfflineTitle => 'You\'re offline';

  @override
  String get lsOfflineBody => 'Connect to the internet to see every language.';

  @override
  String get lsErrorTitle => 'We couldn\'t load languages';

  @override
  String get lsErrorBody => 'Your progress is safe. Try again in a moment.';

  @override
  String get lsRetry => 'Try again';

  @override
  String get lsBack => 'Back';

  @override
  String get lsLoading => 'Loading languages';

  @override
  String get lbTitle => 'Leaderboard';

  @override
  String get lbBack => 'Back';

  @override
  String get lbGlobal => 'Global';

  @override
  String get lbTribe => 'My tribe';

  @override
  String get lbCountry => 'My country';

  @override
  String get lbWeek => 'This week';

  @override
  String get lbLeader => 'Top of the week';

  @override
  String get lbColRank => 'RANK';

  @override
  String get lbColLearner => 'LEARNER';

  @override
  String get lbColXp => 'XP';

  @override
  String lbXp(int xp) {
    return '$xp XP';
  }

  @override
  String lbStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String lbUp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Up $n places',
      one: 'Up 1 place',
    );
    return '$_temp0';
  }

  @override
  String lbDown(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Down $n places',
      one: 'Down 1 place',
    );
    return '$_temp0';
  }

  @override
  String lbRankN(int n) {
    return 'Rank $n';
  }

  @override
  String get lbYou => 'You';

  @override
  String lbYourRank(int n) {
    return 'Your rank: #$n';
  }

  @override
  String get lbUnranked => 'Finish a lesson to join this week\'s board';

  @override
  String get lbFriendly =>
      'Everyone starts fresh each Monday. Practice is what counts, not speed.';

  @override
  String lbLearner(int n) {
    return 'Learner $n';
  }

  @override
  String get lbMinorTeen =>
      'Your profile is private: others see you as \"Learner\", never your name.';

  @override
  String get lbMinorChild =>
      'Names are hidden to keep everyone safe. You can still see how you\'re doing!';

  @override
  String get lbNoTribeTitle => 'Pick a tribe first';

  @override
  String get lbNoTribeBody =>
      'Join a tribe to see how your group is doing this week.';

  @override
  String get lbPickTribe => 'Choose a tribe';

  @override
  String get lbNoCountryTitle => 'Add your country';

  @override
  String get lbNoCountryBody =>
      'Set your country in your profile to see learners near you.';

  @override
  String get lbEmptyTitle => 'No rankings yet this week';

  @override
  String get lbEmptyBody =>
      'Finish a lesson and you could be first on the board.';

  @override
  String get lbErrorTitle => 'We couldn\'t load the board';

  @override
  String get lbErrorBody => 'Your XP is safe. Try again in a moment.';

  @override
  String get lbOfflineTitle => 'You\'re offline';

  @override
  String get lbOfflineBody =>
      'Rankings update when you\'re back online. Lessons you finish offline still count.';

  @override
  String get lbRetry => 'Try again';

  @override
  String get lbLoading => 'Loading leaderboard';

  @override
  String get lbMore => 'Loading more';

  @override
  String get rmTitle => 'Study reminders';

  @override
  String get rmBack => 'Back';

  @override
  String get rmPreviewApp => 'LingAfriq · now';

  @override
  String get rmPreviewBody => 'Ẹ kú àárọ̀! 5 minutes of Yoruba?';

  @override
  String get rmPreviewOff =>
      'Reminders are off. Turn them on to get one gentle nudge a day.';

  @override
  String get rmMaster => 'Daily practice nudge';

  @override
  String get rmMasterSub => 'At most one a day, never at night.';

  @override
  String get rmWhen => 'When should we remind you?';

  @override
  String get rmMorning => 'Morning';

  @override
  String get rmLunch => 'Lunch';

  @override
  String get rmEvening => 'Evening';

  @override
  String get rmCustom => 'Other time';

  @override
  String rmQuiet(String start, String end) {
    return 'We never send anything in quiet hours ($start–$end).';
  }

  @override
  String rmQuietClash(String time) {
    return 'That\'s in quiet hours, so we set it to $time.';
  }

  @override
  String get rmTimezone => 'Timezone';

  @override
  String get rmUseDevice => 'Use this phone\'s';

  @override
  String get rmAbout => 'What we remind you about';

  @override
  String get rmGoal => 'Daily goal';

  @override
  String get rmGoalSub => 'A warm nudge to finish today\'s goal.';

  @override
  String get rmRhythm => 'Practice milestones';

  @override
  String get rmRhythmSub => 'We celebrate milestones. We never guilt you.';

  @override
  String get rmSync =>
      'Saved to your account, so it comes back after reinstalling.';

  @override
  String get rmBlockedTitle => 'Notifications are blocked';

  @override
  String get rmBlockedBody =>
      'Your phone is blocking LingAfriq. Allow notifications in Settings to get reminders.';

  @override
  String get rmOpenSettings => 'Open Settings';

  @override
  String get rmOffline =>
      'You\'re offline. Changes are saved on this phone and sync later.';

  @override
  String get rmCheckError => 'We couldn\'t check notification permission.';

  @override
  String get rmRetry => 'Try again';

  @override
  String get rmLoading => 'Checking notification settings';

  @override
  String get rmChild =>
      'Reminders for young learners never arrive at night, and a grown-up can turn them off any time.';

  @override
  String get rmMasterA11y => 'Study reminders master switch';

  @override
  String get gmTitle => 'Games';

  @override
  String get gmBack => 'Back';

  @override
  String get gmWelcome => 'Welcome to your place to play.';

  @override
  String gmWelcomeSub(String language) {
    return 'Every game practises $language.';
  }

  @override
  String get gmLanguage => 'Practice language';

  @override
  String get gmFeatured => 'Today\'s pick';

  @override
  String get gmPlay => 'Play';

  @override
  String get gmCore => 'Core';

  @override
  String get gmCultural => 'Cultural';

  @override
  String gmCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
    );
    return '$_temp0';
  }

  @override
  String get gmCatAll => 'All';

  @override
  String get gmCatVocabulary => 'Vocabulary';

  @override
  String get gmCatGrammar => 'Grammar';

  @override
  String get gmCatPronunciation => 'Pronunciation';

  @override
  String get gmCatCultural => 'Culture';

  @override
  String get gmCatTraditional => 'Traditional';

  @override
  String get gmEmpty => 'No games here yet.';

  @override
  String get gmShowAll => 'Show all games';

  @override
  String get gmOffline =>
      'You\'re offline, so these are the games saved on this phone.';

  @override
  String get gmSyncing => 'Checking for new games';

  @override
  String get gmOpening => 'Opening game…';

  @override
  String get gmLoadError => 'This game could not load.';

  @override
  String get gmRule1 => 'Learn and have fun with this game mode.';

  @override
  String get gmRule2 => 'Focus on accuracy first, then speed.';

  @override
  String gmPlayA11y(String name, String category, String description) {
    return '$name, $category. $description';
  }

  @override
  String get peTitle => 'Edit profile';

  @override
  String get peBack => 'Back';

  @override
  String get peAvatarEdit => 'Edit avatar';

  @override
  String get peAvatarHint => 'Make your avatar look like you, or not at all.';

  @override
  String get peAbout => 'About you';

  @override
  String get peFirst => 'First name';

  @override
  String get peLast => 'Last name';

  @override
  String peRequired(String field) {
    return 'Please add your $field.';
  }

  @override
  String get peHandle => 'Handle';

  @override
  String get peHandleNone => 'Pick a handle so friends can find you';

  @override
  String get peHandleEdit => 'Change handle';

  @override
  String get peCountry => 'Country';

  @override
  String get peCountryLocked =>
      'Set when you signed up. Contact support to change it.';

  @override
  String get peEmail => 'Email';

  @override
  String get peSave => 'Save changes';

  @override
  String get peSaving => 'Saving…';

  @override
  String get peSaved => 'Profile saved';

  @override
  String get peSaveError =>
      'We couldn\'t save. Your changes are still here, so try again.';

  @override
  String get peMinorTip =>
      'Tip: use a nickname for your handle, not your full name.';

  @override
  String get peDanger => 'Account';

  @override
  String get peDelete => 'Delete account';

  @override
  String get peDeleteSub =>
      'Permanently removes your progress. This can\'t be undone.';

  @override
  String get peDeleteError =>
      'We couldn\'t delete your account. Please try again.';

  @override
  String get peLoading => 'Loading your profile';

  @override
  String get dgTitle => 'Daily goals';

  @override
  String dgStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get dgStreakOn => 'Keep it going — practise today to add a day.';

  @override
  String get dgStreakZero => 'Finish one goal today to start a streak.';

  @override
  String dgRing(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done of $total goals done',
      one: '$done of 1 goal done',
    );
    return '$_temp0';
  }

  @override
  String get dgToday => 'Today';

  @override
  String get dgLessons => 'Complete lessons';

  @override
  String get dgQuizzes => 'Take quizzes';

  @override
  String get dgGames => 'Play games';

  @override
  String get dgChat => 'Chat with Polie';

  @override
  String get dgWords => 'Learn words';

  @override
  String get dgGoal => 'Goal';

  @override
  String dgCount(int current, int target) {
    return '$current of $target';
  }

  @override
  String dgMinutes(int current, int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: '$current of $target min',
      one: '$current of 1 min',
    );
    return '$_temp0';
  }

  @override
  String get dgDone => 'Done';

  @override
  String get dgStart => 'Start';

  @override
  String get dgAllDone => 'All of today\'s goals are done. See you tomorrow!';

  @override
  String get dgEmptyTitle => 'No goals yet today';

  @override
  String get dgEmptyBody => 'Pull down or tap refresh to set today\'s goals.';

  @override
  String get dgRefresh => 'Refresh';

  @override
  String get dgSyncing => 'Syncing your progress…';

  @override
  String get dgError =>
      'Couldn\'t sync goals. Showing progress saved on this device.';

  @override
  String get dgRetry => 'Retry';

  @override
  String get dgPickLessons => 'Choose a language for lessons';

  @override
  String get dgPickQuiz => 'Choose a language for the quiz';

  @override
  String get dgLangError => 'Couldn\'t load languages.';

  @override
  String dgGoalA11y(String title, String progress, String status) {
    return '$title, $progress, $status';
  }

  @override
  String get gmNameWordMatchAudio => 'Word Match Audio';

  @override
  String get gmDescWordMatchAudio => 'Match words with audio';

  @override
  String get gmNamePronunciationDuel => 'Pronunciation Duel';

  @override
  String get gmDescPronunciationDuel => 'Master pronunciation';

  @override
  String get gmNameSpeedRoundRemix => 'Speed Round';

  @override
  String get gmDescSpeedRoundRemix => 'Fast-paced vocabulary';

  @override
  String get gmNameStoryBuilder => 'Story Builder';

  @override
  String get gmDescStoryBuilder => 'Build stories';

  @override
  String get gmNameRoleplayAdventure => 'Roleplay Adventure';

  @override
  String get gmDescRoleplayAdventure => 'Interactive conversations';

  @override
  String get gmNameGrammarDetective => 'Grammar Detective';

  @override
  String get gmDescGrammarDetective => 'Solve grammar mysteries';

  @override
  String get gmNameListenAndSketch => 'Listen & Sketch';

  @override
  String get gmDescListenAndSketch => 'Draw what you hear';

  @override
  String get gmNamePictureWordAssociation => 'Picture Word Match';

  @override
  String get gmDescPictureWordAssociation => 'Match words with images';

  @override
  String get gmNameMemoryMap => 'Memory Map';

  @override
  String get gmDescMemoryMap => 'Memory challenge';

  @override
  String get gmNameConversationRelay => 'Conversation Relay';

  @override
  String get gmDescConversationRelay => 'Chain conversations';

  @override
  String get gmNameGrammarJam => 'Grammar Jam';

  @override
  String get gmDescGrammarJam => 'Grammar rhythm game';

  @override
  String get gmNamePronunciationKaraoke => 'Pronunciation Karaoke';

  @override
  String get gmDescPronunciationKaraoke => 'Sing and pronounce';

  @override
  String get gmNameQuizChef => 'Quiz Chef';

  @override
  String get gmDescQuizChef => 'Cook up answers';

  @override
  String get gmNameToneTrainer => 'Tone Trainer';

  @override
  String get gmDescToneTrainer => 'Master tonal pronunciation';

  @override
  String get gmNameScrabbleSprintArena => 'Scrabble Sprint';

  @override
  String get gmDescScrabbleSprintArena => 'Build words under pressure';

  @override
  String get gmNameProverbUnlocker => 'Proverb Unlocker';

  @override
  String get gmDescProverbUnlocker => 'Unlock wisdom';

  @override
  String get gmNameDrumRhythmShadowing => 'Drum Rhythm';

  @override
  String get gmDescDrumRhythmShadowing => 'Follow the rhythm';

  @override
  String get gmNameClanLineageStoryBuilder => 'Clan Story Builder';

  @override
  String get gmDescClanLineageStoryBuilder => 'Build clan stories';

  @override
  String get gmNameMarketBargainingSimulator => 'Market Bargaining';

  @override
  String get gmDescMarketBargainingSimulator => 'Practice bargaining';

  @override
  String get gmNameTaxiBusStopSurvival => 'Taxi Survival';

  @override
  String get gmDescTaxiBusStopSurvival => 'Navigate transportation';

  @override
  String get gmNameFoodQuest => 'Food Quest';

  @override
  String get gmDescFoodQuest => 'Explore cuisine';

  @override
  String get gmNameCallAndResponse => 'Call & Response';

  @override
  String get gmDescCallAndResponse => 'Traditional patterns';

  @override
  String get gmNameGreetingDiplomacyChallenge => 'Greeting Diplomacy';

  @override
  String get gmDescGreetingDiplomacyChallenge => 'Master greetings';

  @override
  String get gmNameFolktaleReconstruction => 'Folktale Builder';

  @override
  String get gmDescFolktaleReconstruction => 'Rebuild stories';

  @override
  String get gmNamePhraseSniper => 'Phrase Sniper';

  @override
  String get gmDescPhraseSniper => 'Target phrases';

  @override
  String get gmNameLiarLiar => 'Liar Liar';

  @override
  String get gmDescLiarLiar => 'Detect truth';

  @override
  String get gmNameVillageQuest => 'Village Quest';

  @override
  String get gmDescVillageQuest => 'Adventure quest';

  @override
  String get gmNameAccentDecodingPuzzle => 'Accent Puzzle';

  @override
  String get gmDescAccentDecodingPuzzle => 'Decode accents';

  @override
  String get gmNameFlashcardSafari => 'Flashcard Safari';

  @override
  String get gmDescFlashcardSafari => 'Safari vocabulary';

  @override
  String get gmNameRapidTongueTwisterRace => 'Tongue Twister';

  @override
  String get gmDescRapidTongueTwisterRace => 'Master twisters';

  @override
  String get gmNameEmojiTranslator => 'Emoji Translator';

  @override
  String get gmDescEmojiTranslator => 'Translate emojis';

  @override
  String get gmNameRhythmTyping => 'Rhythm Typing';

  @override
  String get gmDescRhythmTyping => 'Type to rhythm';

  @override
  String get gmNameEldersBlessingsChallenge => 'Elders Blessings';

  @override
  String get gmDescEldersBlessingsChallenge => 'Learn blessings';

  @override
  String get gmNameMultilingualRelayRace => 'Multilingual Relay';

  @override
  String get gmDescMultilingualRelayRace => 'Language relay';

  @override
  String get gmNameCulturalEtiquetteScenarios => 'Cultural Etiquette';

  @override
  String get gmDescCulturalEtiquetteScenarios => 'Learn etiquette';

  @override
  String get gmNameDrumToWordMatching => 'Drum Word Match';

  @override
  String get gmDescDrumToWordMatching => 'Match drum patterns';

  @override
  String get gmNameMarketMonopolyChallenge => 'Market Monopoly';

  @override
  String get gmDescMarketMonopolyChallenge => 'Strategic market negotiations';

  @override
  String get gmNameAyoMancala => 'Ayo (Mancala)';

  @override
  String get gmDescAyoMancala => 'Traditional board game with vocab triggers';

  @override
  String get gmNameSuweHopscotch => 'Suwe (Hopscotch)';

  @override
  String get gmDescSuweHopscotch => 'Stone toss and tone patterns on the grid';

  @override
  String get gmNameLudoLanguage => 'Language Ludo';

  @override
  String get gmDescLudoLanguage => 'African Ludo with MCQ-gated moves';

  @override
  String get gmNameSnakesAndLaddersCultural => 'Snakes & Ladders (Cultural)';

  @override
  String get gmDescSnakesAndLaddersCultural =>
      'Proverb ladders and mistake-correction snakes';

  @override
  String get gmNameWhotCardGame => 'Whot (Nigerian Cards)';

  @override
  String get gmDescWhotCardGame => 'Full Whot rules with vocab per card';

  @override
  String get gcTitle => 'Global chat';

  @override
  String get gcChannelGeneral => 'General';

  @override
  String get gcChannels => 'Channels';

  @override
  String get gcSwitchChannel => 'Switch channel';

  @override
  String get gcRefresh => 'Refresh';

  @override
  String get gcFindUser => 'Find someone';

  @override
  String get gcMore => 'More';

  @override
  String get gcGuidelines => 'Community guidelines';

  @override
  String get gcMutedBlocked => 'Muted and blocked';

  @override
  String get gcPolieTitle => 'Practise privately with Polie (AI)';

  @override
  String get gcPolieSub => 'Your turns are not posted to channels';

  @override
  String get gcEmptyTitle => 'No messages yet';

  @override
  String get gcEmptyBody => 'Say hello and start the conversation.';

  @override
  String get gcSayHello => 'Say hello';

  @override
  String get gcHelloText => 'Hello everyone! Excited to learn together.';

  @override
  String get gcErrorTitle => 'Couldn’t load messages';

  @override
  String get gcErrorBody => 'Check your connection and try again.';

  @override
  String get gcRetry => 'Retry';

  @override
  String get gcOffline => 'Offline · showing saved messages';

  @override
  String gcHidden(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n messages hidden from muted or blocked people',
      one: '1 message hidden from muted or blocked people',
    );
    return '$_temp0';
  }

  @override
  String get gcManage => 'Manage';

  @override
  String get gcHint => 'Write a message… (@Polie for help)';

  @override
  String get gcSend => 'Send';

  @override
  String get gcSending => 'Sending…';

  @override
  String get gcYou => 'You';

  @override
  String get gcNow => 'now';

  @override
  String gcMinAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n min',
    );
    return '$_temp0';
  }

  @override
  String gcHourAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n h');
    return '$_temp0';
  }

  @override
  String get gcFlagged => 'Hidden by moderation';

  @override
  String get gcShow => 'Show';

  @override
  String get gcSendFailed => 'Message not sent. Check your connection.';

  @override
  String get gcPolieBusy =>
      'Too many @Polie requests. Try again in about a minute.';

  @override
  String get gcSignIn => 'Sign in to send messages.';

  @override
  String gcActionsFor(String name) {
    return 'Message from $name';
  }

  @override
  String get gcMute => 'Mute';

  @override
  String get gcMuteSub =>
      'Hide their messages on this device. They aren’t told.';

  @override
  String get gcUnmute => 'Unmute';

  @override
  String get gcReport => 'Report';

  @override
  String get gcReportSub => 'Our moderators review every report.';

  @override
  String get gcBlock => 'Block';

  @override
  String get gcBlockSub => 'Stop seeing their messages and snaps everywhere.';

  @override
  String gcBlockConfirm(String name) {
    return 'Block $name?';
  }

  @override
  String get gcBlockConfirmBody =>
      'You won’t see their new messages or snaps. You can unblock later.';

  @override
  String get gcCancel => 'Cancel';

  @override
  String get gcReasonTitle => 'Why are you reporting this?';

  @override
  String get gcReasonHarassment => 'Harassment';

  @override
  String get gcReasonSpam => 'Spam';

  @override
  String get gcReasonHate => 'Hate speech';

  @override
  String get gcReasonOther => 'Something else';

  @override
  String gcReportSent(String ref) {
    return 'Report sent. Reference $ref';
  }

  @override
  String get gcReportFailed => 'Couldn’t send the report. Try again.';

  @override
  String gcBlockedNote(String name) {
    return '$name is blocked';
  }

  @override
  String get gcBlockFailed => 'Couldn’t block. Try again.';

  @override
  String gcMutedNote(String name) {
    return '$name is muted';
  }

  @override
  String get gcMutedTitle => 'Muted';

  @override
  String get gcBlockedTitle => 'Blocked';

  @override
  String get gcNobody => 'Nobody here';

  @override
  String get gcUnblock => 'Unblock';

  @override
  String get gcProfileUnavailable => 'Profile unavailable for this message.';

  @override
  String get gcLockedTeenTitle => 'Global chat opens at 18';

  @override
  String get gcLockedTeenBody =>
      'To keep you safe, open chat with strangers is for adults. You can still practise with Polie and your class.';

  @override
  String get gcLockedChildTitle => 'Global chat isn’t available';

  @override
  String get gcLockedChildBody =>
      'Child accounts can’t use open chat. Keep learning with lessons, games and Polie.';

  @override
  String get gcLockedUnknownTitle => 'We need your age first';

  @override
  String get gcLockedUnknownBody =>
      'Global chat is for adults. It will appear here once your account’s age is confirmed.';

  @override
  String get gcPracticePolie => 'Practise with Polie';

  @override
  String get gcChecking => 'Checking access…';

  @override
  String gcMessagesLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n messages',
      one: '1 message',
      zero: 'No messages',
    );
    return '$_temp0';
  }

  @override
  String gcOpenProfile(String name) {
    return 'Open $name’s profile';
  }

  @override
  String get rbReasons => 'Report reasons';

  @override
  String get rbSendReport => 'Send report';

  @override
  String get rbSending => 'Sending report';

  @override
  String rbReceived(String ref) {
    return 'Report received. Reference $ref';
  }

  @override
  String get rbSendFailed => 'Could not send that. Try again.';

  @override
  String get rbBlockConfirm =>
      'Block this person? You will not see their new messages or snaps.';

  @override
  String get rbConfirmBlock => 'Confirm block';

  @override
  String get rbBlockUser => 'Block user';

  @override
  String get rbBlockedNote => 'Blocked. You will not see their new messages.';

  @override
  String get rbBlockFailed => 'Could not block this person. Try again.';

  @override
  String get rbBlockedPeople => 'Blocked people';

  @override
  String get rbNoBlocked => 'No blocked people';

  @override
  String get rbHate => 'Hate';

  @override
  String get rbOther => 'Other';

  @override
  String gcHeroTitle(String channel) {
    return 'Welcome to #$channel';
  }

  @override
  String gcHeroBody(String channel) {
    return 'This is the start of #$channel. Be kind: moderators review every report.';
  }

  @override
  String gcGreetingIn(String greeting) {
    return 'Say it like a local: $greeting';
  }

  @override
  String get gcHintShort => 'Message';

  @override
  String get gcErrorServerTitle => 'Global chat didn\'t load';

  @override
  String get gcErrorServerBody =>
      'Something went wrong on our side. Nothing you wrote was lost. Try again in a moment.';

  @override
  String get gfamToolsTitle => 'Family tools';

  @override
  String get gfamToolsApprovals => 'Group approvals';

  @override
  String get gfamToolsApprovalsSub => 'Circles and classrooms waiting for you';

  @override
  String get gfamToolsGuide => 'How messaging works';

  @override
  String get gfamToolsGuideSub => 'What is checked, and who can message';

  @override
  String get gfamToolsCircles => 'Circles';

  @override
  String get gfamToolsCirclesSub => 'Study circles you belong to';

  @override
  String gfamWhoMessages(int id) {
    return 'Who messages learner #$id';
  }

  @override
  String get gdmTitle => 'Who is messaging your learner';

  @override
  String get gdmIntro =>
      'You see who, when and any reports. You never see message text.';

  @override
  String get gdmEmptyTitle => 'No direct messages yet';

  @override
  String get gdmEmptyBody =>
      'Only teachers and members of groups you approved can message your learner.';

  @override
  String get gdmError => 'We could not load messages. Try again.';

  @override
  String get gdmRetry => 'Try again';

  @override
  String get gdmRoleTeacher => 'Teacher';

  @override
  String get gdmRoleClassmate => 'Classmate';

  @override
  String get gdmRoleContact => 'Contact';

  @override
  String gdmLastActive(String when) {
    return 'Last message $when';
  }

  @override
  String gdmMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String gdmReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
      zero: 'No reports',
    );
    return '$_temp0';
  }

  @override
  String gdmBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages stopped by safety checks',
      one: '1 message stopped by safety checks',
    );
    return '$_temp0';
  }

  @override
  String get gdmStop => 'Stop messages';

  @override
  String get gdmAllow => 'Allow again';

  @override
  String get gdmStopped => 'Messages stopped';

  @override
  String gdmStopConfirmTitle(String name) {
    return 'Stop messages from $name?';
  }

  @override
  String get gdmStopConfirmBody =>
      'They will not be able to message your learner, and your learner cannot message them. You can allow it again later.';

  @override
  String get gdmCancel => 'Cancel';

  @override
  String get gdmActionFailed => 'That did not work. Try again.';

  @override
  String get gdmUnknownName => 'Unknown user';

  @override
  String get gccJoinButton => 'Enter class code';

  @override
  String get gccTitle => 'Join a class';

  @override
  String get gccHint => 'Ask your teacher for the class code.';

  @override
  String get gccLabel => 'Class code';

  @override
  String get gccSubmit => 'Join';

  @override
  String get gccJoined => 'You joined the class.';

  @override
  String get gccWaitingTitle => 'Waiting for your guardian';

  @override
  String get gccWaitingBody =>
      'We asked your guardian to approve this class. You can join once they say yes.';

  @override
  String get gccNeedLink =>
      'Ask a parent or guardian to link to your account in Family hub first.';

  @override
  String get gccNeedAge =>
      'Confirm your age in settings before joining a class.';

  @override
  String get gccNotFound =>
      'No class has that code. Check it with your teacher.';

  @override
  String get gccAlready => 'You are already in this class.';

  @override
  String get gccError => 'Could not join right now. Try again.';

  @override
  String get gccEmpty => 'Enter the code first.';

  @override
  String get gccDone => 'Done';

  @override
  String get gtpTitle => 'Student requests';

  @override
  String get gtpOpen => 'Student requests';

  @override
  String get gtpWaitingSection => 'Waiting for a guardian';

  @override
  String get gtpWaitingHelp =>
      'These students used your class code. Their guardian decides; you do not need to do anything.';

  @override
  String get gtpWaitingEmpty => 'No one is waiting.';

  @override
  String get gtpSchoolSection => 'School accounts';

  @override
  String get gtpSchoolHelp =>
      'Teacher messages are off until you turn them on for each student. Only you can message them, and every message is checked.';

  @override
  String get gtpSchoolEmpty => 'No school accounts in this class.';

  @override
  String get gtpTeacherDm => 'Teacher messages';

  @override
  String get gtpPendingConsent => 'School consent pending';

  @override
  String gtpStudent(int id) {
    return 'Student #$id';
  }

  @override
  String gtpSince(String when) {
    return 'Asked $when';
  }

  @override
  String get gtpError => 'We could not load requests. Try again.';

  @override
  String get gtpNotTeacher => 'Only this class\'s teacher can see requests.';
}
