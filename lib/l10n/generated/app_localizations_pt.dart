// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Bem-vindo ao LingAfriq';

  @override
  String get continueButton => 'Continuar';

  @override
  String get startLearning => 'Começar a Aprender';

  @override
  String get loading => 'Carregando...';

  @override
  String get errorOccurred => 'Ocorreu um erro';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get home => 'Início';

  @override
  String get learn => 'Aprender';

  @override
  String get games => 'Jogos';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get lessons => 'Lições';

  @override
  String get quizzes => 'Questionários';

  @override
  String get takeQuiz => 'Fazer um Questionário';

  @override
  String get takeLesson => 'Fazer uma Lição';

  @override
  String get dailyStreak => 'Sequência Diária';

  @override
  String daysStreak(int count) {
    return '$count dias';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Nível';

  @override
  String get beginner => 'Iniciante';

  @override
  String get intermediate => 'Intermediário';

  @override
  String get advanced => 'Avançado';

  @override
  String get correct => 'Correto!';

  @override
  String get incorrect => 'Incorreto';

  @override
  String get next => 'Próximo';

  @override
  String get back => 'Voltar';

  @override
  String get skip => 'Pular';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get done => 'Concluído';

  @override
  String get submit => 'Enviar';

  @override
  String get logout => 'Sair';

  @override
  String get login => 'Entrar';

  @override
  String get signup => 'Cadastrar';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get forgotPassword => 'Esqueceu a Senha?';

  @override
  String get noAccount => 'Não tem uma conta?';

  @override
  String get haveAccount => 'Já tem uma conta?';

  @override
  String get congratulations => 'Parabéns!';

  @override
  String get lessonComplete => 'Lição Concluída!';

  @override
  String get quizComplete => 'Questionário Concluído!';

  @override
  String get accuracy => 'Precisão';

  @override
  String get score => 'Pontuação';

  @override
  String get aiTutor => 'Tutor de IA';

  @override
  String get cultureMagazine => 'Revista Cultural';

  @override
  String get tribes => 'Tribos';

  @override
  String get leaderboard => 'Classificação';

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
}
