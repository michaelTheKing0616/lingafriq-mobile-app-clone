// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'Bienvenue sur LingAfriq';

  @override
  String get continueButton => 'Continuer';

  @override
  String get startLearning => 'Commencer a Apprendre';

  @override
  String get loading => 'Chargement...';

  @override
  String get errorOccurred => 'Une erreur est produite';

  @override
  String get tryAgain => 'Reessayer';

  @override
  String get home => 'Accueil';

  @override
  String get learn => 'Apprendre';

  @override
  String get games => 'Jeux';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Parametres';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Selectionner la Langue';

  @override
  String get lessons => 'Lecons';

  @override
  String get quizzes => 'Quiz';

  @override
  String get takeQuiz => 'Faire un Quiz';

  @override
  String get takeLesson => 'Suivre une Lecon';

  @override
  String get dailyStreak => 'Serie Quotidienne';

  @override
  String daysStreak(int count) {
    return '$count jours';
  }

  @override
  String xpEarned(int count) {
    return '$count XP';
  }

  @override
  String get level => 'Niveau';

  @override
  String get beginner => 'Debutant';

  @override
  String get intermediate => 'Intermediaire';

  @override
  String get advanced => 'Avance';

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get skip => 'Passer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get done => 'Termine';

  @override
  String get submit => 'Soumettre';

  @override
  String get logout => 'Déconnexion';

  @override
  String get login => 'Connexion';

  @override
  String get signup => 'Inscrire';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublie?';

  @override
  String get noAccount => 'Vous navez pas de compte?';

  @override
  String get haveAccount => 'Vous avez deja un compte?';

  @override
  String get congratulations => 'Felicitations!';

  @override
  String get lessonComplete => 'Leçon terminée !';

  @override
  String get quizComplete => 'Quiz Termine!';

  @override
  String get accuracy => 'Precision';

  @override
  String get score => 'Score';

  @override
  String get aiTutor => 'Tuteur IA';

  @override
  String get cultureMagazine => 'Magazine Culturel';

  @override
  String get tribes => 'Tribus';

  @override
  String get leaderboard => 'Classement';

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
      'Généré par IA : les réponses et la voix proviennent d\'un tuteur IA et peuvent être erronées.';

  @override
  String get aiDisclosureShort => 'Contenu généré par IA';

  @override
  String get aiDisclosureMoreHint => 'Découvrir comment l\'IA est utilisée ici';

  @override
  String get aiDisclosureSheetTitle => 'À propos de l\'IA dans LingAfriq';

  @override
  String get aiDisclosureSheetBody =>
      'Polie, les tuteurs et les personnages IA ne sont pas des personnes. Leurs textes et leurs voix sont générés par IA. Ils peuvent se tromper : vérifiez les informations importantes. Évitez de partager des informations privées.';

  @override
  String get aiDisclosureGotIt => 'Compris';

  @override
  String get voiceRetentionTitle => 'Enregistrements sur cet appareil';

  @override
  String get voiceRetentionBody =>
      'Votre voix n\'est enregistrée que pendant l\'entraînement, pour noter la prononciation et transcrire la parole. Les enregistrements sur ce téléphone sont supprimés automatiquement.';

  @override
  String get voiceRetentionSelectLabel => 'Supprimer automatiquement';

  @override
  String get voiceRetentionImmediate => 'Juste après l\'évaluation';

  @override
  String get voiceRetention24h => 'Après 24 heures';

  @override
  String get voiceRetention7d => 'Après 7 jours';

  @override
  String get voiceRetention30d => 'Après 30 jours';

  @override
  String get voiceRetentionDeleteNow => 'Supprimer mes enregistrements';

  @override
  String get voiceRetentionConfirmTitle =>
      'Supprimer les enregistrements de cet appareil ?';

  @override
  String get voiceRetentionConfirmBody =>
      'Les enregistrements d\'entraînement de ce téléphone seront supprimés. Action irréversible. Les enregistrements sauvegardés dans votre compte ne sont pas concernés.';

  @override
  String get voiceRetentionConfirmDelete => 'Supprimer';

  @override
  String voiceRetentionDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements supprimés de cet appareil.',
      one: '1 enregistrement supprimé de cet appareil.',
      zero: 'Aucun enregistrement à supprimer.',
    );
    return '$_temp0';
  }

  @override
  String get paywallTermsTitle => 'Conditions de l\'abonnement';

  @override
  String get paywallRowPrice => 'Prix';

  @override
  String get paywallRowRenews => 'Renouvellement';

  @override
  String get paywallRowTrial => 'Essai gratuit';

  @override
  String get paywallRowCancel => 'Résiliation';

  @override
  String paywallPriceValue(String premium, String family, String lifetime) {
    return 'Plus mensuel $premium/mois\nPlus Famille $family/mois\nPlus à vie $lifetime, paiement unique';
  }

  @override
  String paywallChargedTo(String store) {
    return 'Débité sur votre compte $store.';
  }

  @override
  String get paywallRenewsAuto =>
      'Plus mensuel et Plus Famille se renouvellent automatiquement au même prix jusqu\'à résiliation. Plus à vie ne se renouvelle pas.';

  @override
  String paywallRenewsOn(String date) {
    return 'Votre forfait se renouvelle le $date.';
  }

  @override
  String paywallTrialOffered(int days, String price) {
    return 'Essai gratuit de Plus mensuel pendant $days jours, puis $price/mois sauf résiliation au moins 24 h avant la fin.';
  }

  @override
  String get paywallTrialGeneric =>
      'Si un essai est proposé, le prix du forfait est facturé à la fin, sauf résiliation au moins 24 h avant.';

  @override
  String get paywallCancelApple =>
      'À tout moment dans Réglages › votre nom › Abonnements. L\'accès reste actif jusqu\'à la fin de la période payée.';

  @override
  String get paywallCancelGoogle =>
      'À tout moment dans Google Play › Paiements et abonnements › Abonnements. L\'accès reste actif jusqu\'à la fin de la période payée.';

  @override
  String get paywallFreeStays =>
      'Les fonctions gratuites restent disponibles sans abonnement ou après résiliation.';

  @override
  String get paywallManage => 'Gérer l\'abonnement';

  @override
  String get paywallTerms => 'Conditions d\'utilisation';

  @override
  String get paywallPrivacy => 'Politique de confidentialité';

  @override
  String get reportReasonHarassment => 'Harcèlement ou intimidation';

  @override
  String get reportReasonSpam => 'Spam ou arnaque';

  @override
  String get reportReasonHate => 'Discours haineux';

  @override
  String get reportReasonCopyright => 'Atteinte au droit d\'auteur';

  @override
  String get reportReasonCopyrightHint =>
      'Quelqu\'un a publié votre œuvre sans autorisation';

  @override
  String get reportReasonOther => 'Autre chose';

  @override
  String get settingsCopyright => 'Droit d\'auteur et retrait';

  @override
  String get cpTitle => 'Droit d\'auteur et retrait';

  @override
  String get cpIntro =>
      'Si un contenu sur LingAfriq utilise votre œuvre sans autorisation, signalez-le. Chaque notification est examinée par une personne.';

  @override
  String get cpHowTitle => 'Comment ça marche';

  @override
  String get cpStep1 =>
      'Vous envoyez une notification avec les informations ci-dessous.';

  @override
  String get cpStep2 =>
      'Nous retirons ou masquons rapidement le contenu et prévenons la personne qui l\'a publié.';

  @override
  String get cpStep3 =>
      'La personne peut envoyer une contre-notification en cas d\'erreur. Sauf action en justice, le contenu peut revenir après 10 à 14 jours ouvrés.';

  @override
  String get cpRepeatTitle => 'Récidivistes';

  @override
  String get cpRepeatBody =>
      'Les comptes ayant 3 notifications confirmées sont fermés. Les notifications ou contre-notifications mensongères peuvent engager votre responsabilité.';

  @override
  String get cpAgentTitle => 'Agent désigné pour le droit d\'auteur';

  @override
  String get cpAgentPending =>
      'Enregistrement de l\'agent en cours. En attendant, utilisez ce formulaire.';

  @override
  String get cpKindNotice => 'Signaler';

  @override
  String get cpKindCounter => 'Contre-notification';

  @override
  String get cpFormTitle => 'Votre notification';

  @override
  String get cpFieldTarget => 'Identifiant ou lien du contenu sur LingAfriq';

  @override
  String get cpFieldWork => 'Décrivez votre œuvre originale';

  @override
  String get cpFieldWorkCounter => 'Décrivez le contenu retiré';

  @override
  String get cpFieldWorkHelp =>
      'Par exemple : titre, lieu de première publication et lien.';

  @override
  String get cpFieldName => 'Nom légal complet';

  @override
  String get cpFieldEmail => 'E-mail pour notre réponse';

  @override
  String get cpFieldSignature => 'Signature : saisissez votre nom complet';

  @override
  String get cpStatementsTitle => 'Déclarations';

  @override
  String get cpStmtGoodFaith =>
      'Je crois de bonne foi que cette utilisation n\'est autorisée ni par le titulaire, ni par son agent, ni par la loi.';

  @override
  String get cpStmtAccurate =>
      'Cette notification est exacte et, sous peine de parjure, je suis le titulaire ou autorisé à agir en son nom.';

  @override
  String get cpStmtMistake =>
      'Sous peine de parjure, je crois que le contenu a été retiré par erreur ou mauvaise identification.';

  @override
  String get cpStmtJurisdiction =>
      'J\'accepte la compétence du tribunal compétent et la signification par le plaignant.';

  @override
  String get cpRequired => 'Obligatoire';

  @override
  String get cpEmailInvalid => 'Saisissez un e-mail valide';

  @override
  String get cpWorkTooShort => 'Ajoutez un peu plus de détails';

  @override
  String get cpStatementsMissing =>
      'Cochez les deux déclarations pour continuer';

  @override
  String get cpSend => 'Envoyer la notification';

  @override
  String get cpSending => 'Envoi…';

  @override
  String get cpErrorTitle => 'Impossible d\'envoyer votre notification';

  @override
  String get cpErrorBody =>
      'Vérifiez votre connexion et réessayez. Votre saisie est conservée.';

  @override
  String get cpRetry => 'Réessayer';

  @override
  String get cpSuccessTitle => 'Notification reçue';

  @override
  String cpSuccessBody(String reference) {
    return 'Une personne l\'examinera et vous écrira. Conservez cette référence : $reference';
  }

  @override
  String get cpDone => 'Terminé';

  @override
  String get reportReasonTitle => 'Pourquoi signalez-vous ce contenu ?';

  @override
  String get settingsSecAppearance => 'Apparence';

  @override
  String get settingsSecNotifications => 'Notifications';

  @override
  String get settingsSecAudio => 'Audio';

  @override
  String get settingsSecSecurity => 'Sécurité';

  @override
  String get settingsSecAccount => 'Compte';

  @override
  String get settingsSecLearning => 'Apprentissage';

  @override
  String get settingsSecOffline => 'Hors ligne et synchronisation';

  @override
  String get settingsSecAbout => 'À propos';

  @override
  String get settingsDarkMode => 'Mode sombre';

  @override
  String get settingsDarkModeSub => 'Basculer entre thème clair et sombre';

  @override
  String get settingsPush => 'Notifications push';

  @override
  String get settingsPushSub => 'Recevoir des notifications push';

  @override
  String get settingsDailyReminders => 'Rappels quotidiens';

  @override
  String get settingsDailyRemindersSub =>
      'Un rappel pour pratiquer chaque jour';

  @override
  String get settingsSoundEffects => 'Effets sonores';

  @override
  String get settingsSoundEffectsSub =>
      'Jouer des effets sonores pendant les leçons';

  @override
  String get settingsVoiceStyles => 'Styles de voix du tuteur';

  @override
  String get settingsVoiceStylesSub =>
      'Voix synthétiques non identifiantes (facultatif)';

  @override
  String get settingsAppLanguage => 'Langue de l\'application';

  @override
  String get settingsBiometric => 'Connexion biométrique';

  @override
  String get settingsBiometricSub =>
      'Utilisez la biométrie pour vous connecter rapidement';

  @override
  String get settingsEncryptCache => 'Chiffrer les données en cache';

  @override
  String get settingsEncryptCacheSub =>
      'Chiffrer les données sensibles stockées sur cet appareil';

  @override
  String get settingsEditProfile => 'Modifier le profil';

  @override
  String get settingsEditProfileSub =>
      'Mettre à jour vos informations personnelles';

  @override
  String get settingsChangePassword => 'Changer le mot de passe';

  @override
  String get settingsChangePasswordSub =>
      'Mettre à jour le mot de passe du compte';

  @override
  String get settingsPrivacy => 'Paramètres de confidentialité';

  @override
  String get settingsPrivacySub => 'Gérer vos préférences de confidentialité';

  @override
  String get settingsMentorReports => 'Signalements des micro-mentors';

  @override
  String get settingsMentorReportsSub => 'Examiner les signalements (équipe)';

  @override
  String get settingsGoals => 'Objectifs d\'apprentissage';

  @override
  String get settingsGoalsSub => 'Définir vos objectifs quotidiens';

  @override
  String get settingsStudyReminders => 'Rappels d\'étude';

  @override
  String get settingsStudyRemindersSub => 'Choisir quand recevoir un rappel';

  @override
  String get settingsSync => 'Paramètres de synchronisation';

  @override
  String get settingsSyncSub => 'Choisir ce qui est synchronisé';

  @override
  String get settingsCache => 'Gestion du cache';

  @override
  String get settingsCacheSub => 'Voir et gérer les données en cache';

  @override
  String get settingsDownloads => 'Téléchargements';

  @override
  String get settingsDownloadsSub => 'Taille des unités, Wi-Fi et suppression';

  @override
  String get settingsAppVersion => 'Version de l\'application';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsHelp => 'Aide et assistance';

  @override
  String get settingsLogoutConfirm => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get settingsFeaturesGuide => 'Guide des fonctionnalités';

  @override
  String get settingsGamesTour => 'Fonctionnement des jeux';

  @override
  String get lowBandwidthTitle => 'Faible bande passante';

  @override
  String get lowBandwidthAutoOn =>
      'Activé car l\'économiseur de données est activé';

  @override
  String get lowBandwidthManualOn =>
      'Activé jusqu\'à ce que vous le désactiviez';

  @override
  String get lowBandwidthOff => 'Désactivé';

  @override
  String get lessonExit => 'Quitter la leçon';

  @override
  String get lessonQuitTitle => 'Quitter cette leçon ?';

  @override
  String get lessonQuitBody =>
      'Tu t\'en sors bien. Encore quelques minutes et cette leçon est finie.';

  @override
  String get lessonKeepLearning => 'Continuer à apprendre';

  @override
  String get lessonEndSession => 'Arrêter la leçon';

  @override
  String get lessonPreparing => 'Préparation de ta leçon';

  @override
  String get lessonLoadFailedTitle => 'On réessaie';

  @override
  String get lessonRetry => 'Réessayer';

  @override
  String lessonProgressLabel(int current, int total, int percent) {
    return 'Progression de la leçon. Section $current sur $total. $percent pour cent terminé.';
  }

  @override
  String lessonSectionLabel(int current, int total) {
    return 'Section $current sur $total';
  }

  @override
  String get lessonContinueNext => 'Passer à la section suivante';

  @override
  String pointsCount(int count) {
    return '$count points';
  }

  @override
  String lessonQuitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count sections',
      one: 'Plus qu\'une section',
    );
    return '$_temp0';
  }

  @override
  String get homeSearchLanguagesLabel => 'Rechercher des langues';

  @override
  String get homeSearchLanguagesAction => 'Rechercher des langues';

  @override
  String get homeOpenMenu => 'Ouvrir le menu';

  @override
  String get homeMenu => 'Menu';

  @override
  String get homeFeaturedLanguages => 'Langues à la une';

  @override
  String get homeNoLanguagesTitle => 'Pas encore de langues';

  @override
  String get homeNoLanguagesBody =>
      'Nous ajoutons encore des langues pour ta région. Fais une recherche pour voir ce qui est disponible, ou reviens bientôt.';

  @override
  String homeComingSoonSnack(String name) {
    return '$name arrive bientôt. On peaufine les derniers détails.';
  }

  @override
  String get homeOfflineTitle => 'Tu es hors ligne';

  @override
  String get homeOfflineBody =>
      'Vérifie ta connexion. Nous rechargerons tes langues dès ton retour en ligne.';

  @override
  String get homeTryAgain => 'Réessayer';

  @override
  String get homeLoadingLanguages => 'Chargement de tes langues...';

  @override
  String get homeComingSoon => 'Bientôt disponible';

  @override
  String homePercentComplete(int percent) {
    return '$percent % terminé';
  }

  @override
  String get homeStartLearning => 'Commencer';

  @override
  String homeCardLocked(String name) {
    return 'Carte de langue $name, bientôt disponible, pas encore accessible';
  }

  @override
  String homeCardProgress(String name, int percent) {
    return 'Carte de langue $name, $percent % terminé';
  }

  @override
  String homeCardStart(String name) {
    return 'Carte de langue $name, commencer';
  }

  @override
  String homeFlag(String name) {
    return 'Image $name';
  }

  @override
  String get homeGuardianTitle => 'En attente d\'un tuteur';

  @override
  String get homeGuardianBody =>
      'Les leçons sont ouvertes. Le chat, le Village et les achats restent en pause jusqu\'à l\'accord d\'un tuteur.';

  @override
  String get homeGuardianLabel =>
      'En attente d\'un tuteur. Les leçons sont ouvertes, mais le chat, le Village et les achats restent en pause jusqu\'à son accord.';

  @override
  String homeWelcomeBack(String name) {
    return 'Bon retour, $name';
  }

  @override
  String get homeLearner => 'Apprenant';

  @override
  String get homeStreakNone =>
      'Choisis une langue et lance ta série aujourd\'hui.';

  @override
  String get homeStreakOne =>
      'Premier jour : garde ta série en vie aujourd\'hui.';

  @override
  String homeStreakMany(int count) {
    return 'Tu es sur une série de $count jours, continue !';
  }

  @override
  String homeStreakBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String homeStreakSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count jours',
      one: 'Série de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get homeDailyGoals => 'Objectifs du jour';

  @override
  String homeGoalRing(int percent) {
    return 'Objectif du jour : $percent %';
  }

  @override
  String get homeGoalCaption => 'aujourd\'hui';

  @override
  String homeWordOfDay(String word, String language) {
    return 'Mot du jour : $word, « bienvenue » en $language';
  }

  @override
  String get homeLangHausa => 'haoussa';

  @override
  String get homeLangPidgin => 'pidgin';

  @override
  String get homeLangSwahili => 'swahili';

  @override
  String get homeLangYoruba => 'yoruba';

  @override
  String get homeLangZulu => 'zoulou';

  @override
  String get homeLangIgbo => 'igbo';

  @override
  String homeContinueTitle(String name) {
    return 'Continuer : $name';
  }

  @override
  String homeContinueLabel(String name, int percent) {
    return 'Continuer : $name, $percent % terminé';
  }

  @override
  String get homeErrorTitle => 'Impossible de charger tes langues';

  @override
  String get homeErrorBody =>
      'Le problème vient de nous. Ta progression est sauvegardée : réessaie dans un instant.';

  @override
  String get homeKidsTitle => 'Mode enfant activé';

  @override
  String get homeKidsBody =>
      'Toutes les leçons sont ouvertes. Le chat, le Village et les achats sont désactivés.';

  @override
  String get homeKidsLabel =>
      'Mode enfant activé. Toutes les leçons sont ouvertes. Le chat, le Village et les achats sont désactivés.';

  @override
  String get lessonNewPhrase => 'Nouvelle expression';

  @override
  String get lessonExampleLabel => 'Exemple';

  @override
  String get lessonListen => 'Écouter';

  @override
  String get lessonListenSlowly => 'Écouter lentement';

  @override
  String get lessonTutorialAudio => 'Audio de la leçon';

  @override
  String get lessonTutorialVideo => 'Vidéo de la leçon';

  @override
  String lessonQuestionOf(int current, int total) {
    return 'Question $current sur $total';
  }

  @override
  String lessonQuestionProgress(int current, int total, int percent) {
    return 'Question $current sur $total. $percent pour cent terminé.';
  }

  @override
  String get lessonPrevious => 'Précédent';

  @override
  String get lessonPreviousQuestion => 'Question précédente';

  @override
  String get lessonCheck => 'Vérifier';

  @override
  String get lessonCheckAnswer => 'Vérifier la réponse';

  @override
  String get lessonNext => 'Suivant';

  @override
  String get lessonNextQuestion => 'Question suivante';

  @override
  String get lessonFinish => 'Terminer';

  @override
  String get lessonFinishQuiz => 'Terminer le quiz';

  @override
  String get lessonPickFirst =>
      'Choisis d\'abord une réponse, puis on vérifie ensemble.';

  @override
  String get lessonCorrectTitle => 'Bravo !';

  @override
  String get lessonCorrectBody => 'C\'est juste. Continue comme ça.';

  @override
  String get lessonIncorrectTitle => 'Pas tout à fait';

  @override
  String lessonCorrectAnswer(String answer) {
    return 'Bonne réponse : $answer';
  }

  @override
  String lessonOptionLabel(String letter, String text) {
    return 'Réponse $letter : $text.';
  }

  @override
  String get lessonOptionSelected => 'Sélectionnée';

  @override
  String lessonQuestionLabel(String question) {
    return 'Question. $question';
  }

  @override
  String lessonHintLabel(String hint) {
    return 'Indice : $hint';
  }

  @override
  String get lessonFunFact => 'Le saviez-vous ?';

  @override
  String get lessonNotReadyTitle => 'Cette partie n\'est pas encore prête';

  @override
  String get lessonNotReadyBody =>
      'Nous préparons encore ces questions. Reviens dans un instant.';

  @override
  String get lessonLoadFailedBody =>
      'Vérifie ta connexion et réessaie. Ta progression est sauvegardée.';

  @override
  String lessonAvatarLabel(String points) {
    return 'Ton profil, $points';
  }

  @override
  String get lcMsgGreat => 'Ta confiance à l\'oral grandit vraiment.';

  @override
  String get lcMsgGood => 'Cette leçon t\'a fait avancer. Bravo.';

  @override
  String get lcMsgSteady => 'Chaque séance renforce ta mémoire. Continue.';

  @override
  String get lcMsgReview =>
      'Une petite révision la prochaine fois va tout ancrer.';

  @override
  String get lcMsgNoQuiz =>
      'Tu as découvert de nouvelles phrases. Elles reviendront dans ton prochain quiz.';

  @override
  String get lcStatXp => 'XP gagnés';

  @override
  String get lcStatAccuracy => 'Précision';

  @override
  String get lcStatTime => 'Temps';

  @override
  String get lcNoQuizValue => 'Sans quiz';

  @override
  String lcPercent(int value) {
    return '$value %';
  }

  @override
  String lcTimeMinSec(int m, int s) {
    return '$m min $s s';
  }

  @override
  String lcTimeSec(int s) {
    return '$s s';
  }

  @override
  String lcBestRun(int count) {
    return 'Meilleure série : $count d\'affilée';
  }

  @override
  String lcComboBonus(int xp) {
    return 'Bonus combo +$xp XP';
  }

  @override
  String get lcContinue => 'Continuer';

  @override
  String get lcShare => 'Partager';

  @override
  String get lcContinueA11y => 'Passer à la leçon suivante';

  @override
  String get lcShareA11y => 'Partager ton résultat';

  @override
  String get lcOffline =>
      'Tu es hors ligne. Ta progression est enregistrée sur ce téléphone ; le partage reviendra à la reconnexion.';

  @override
  String lcSummaryA11y(int xp, String accuracy, String time) {
    return 'Leçon terminée. $xp XP gagnés. Précision $accuracy. Temps $time.';
  }

  @override
  String get lcHeroA11y => 'Amara et Kofi applaudissent';

  @override
  String get profOverview => 'Aperçu';

  @override
  String get profAccount => 'Compte';

  @override
  String get profWallet => 'Portefeuille';

  @override
  String profStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get profStreakLabel => 'Série de jours';

  @override
  String get profStreakZero => 'Commence aujourd\'hui';

  @override
  String profXpValue(int count) {
    return '$count XP';
  }

  @override
  String get profXpLabel => 'XP au total';

  @override
  String profRankValue(int rank) {
    return 'n° $rank';
  }

  @override
  String get profRankLabel => 'Classement mondial';

  @override
  String get profRankNone => 'Pas encore classé';

  @override
  String get profLevelLabel => 'Niveau';

  @override
  String get profLevelNone => 'Débutant';

  @override
  String get profPrivateValue => 'Privé';

  @override
  String get profPrivateHint =>
      'Ton profil est privé : ton classement reste caché aux autres.';

  @override
  String profLearning(String language) {
    return 'Apprend le $language';
  }

  @override
  String get profEdit => 'Modifier le profil';

  @override
  String get profChangePassword => 'Changer le mot de passe';

  @override
  String get profFeedback => 'Donne-nous ton avis';

  @override
  String get profAbout => 'Qui sommes-nous';

  @override
  String get profPolicy => 'Confidentialité et conditions';

  @override
  String get profDelete => 'Supprimer ton compte';

  @override
  String get profDeleted => 'Compte supprimé';

  @override
  String get profLoading => 'Chargement de ton profil…';

  @override
  String get profErrorTitle => 'Impossible de charger ton profil';

  @override
  String get profErrorBody =>
      'Vérifie ta connexion et réessaie. Rien de ce que tu as appris n\'est perdu.';

  @override
  String get profRetry => 'Réessayer';

  @override
  String get profOffline => 'Tu es hors ligne. Voici ton profil enregistré.';

  @override
  String get profNgwenya => 'Ngwenya';

  @override
  String get profCowries => 'Cauris';

  @override
  String get profBeads => 'Perles';

  @override
  String get profOpenLeaderboard => 'Ouvrir le classement';

  @override
  String get pgTitle => 'Ta progression';

  @override
  String get pgThisWeek => 'Cette semaine';

  @override
  String pgMinutes(int count) {
    return '$count min';
  }

  @override
  String pgVsUp(int count) {
    return '$count min de plus que la semaine dernière';
  }

  @override
  String pgVsDown(int count) {
    return '$count min de moins que la semaine dernière';
  }

  @override
  String get pgVsSame => 'Comme la semaine dernière';

  @override
  String get pgWordsLearned => 'Mots appris';

  @override
  String get pgKnownWords => 'Mots connus';

  @override
  String get pgListening => 'Écoute';

  @override
  String get pgSpeaking => 'Expression orale';

  @override
  String pgHours(String value) {
    return '$value h';
  }

  @override
  String get pgDaily => 'Minutes par jour';

  @override
  String get pgCalendar => '4 dernières semaines';

  @override
  String pgActiveDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours actifs',
      one: '1 jour actif',
      zero: 'Aucun jour actif pour l\'instant',
    );
    return '$_temp0';
  }

  @override
  String get pgActivities => 'Temps par activité';

  @override
  String get pgActLessons => 'Leçons';

  @override
  String get pgActQuizzes => 'Quiz';

  @override
  String get pgActGames => 'Jeux';

  @override
  String get pgActChat => 'Conversation';

  @override
  String get pgActStories => 'Histoires';

  @override
  String get pgActReading => 'Lecture';

  @override
  String get pgActWriting => 'Écriture';

  @override
  String get pgActOther => 'Autres exercices';

  @override
  String get pgOfflineCount => 'Les jours hors ligne comptent aussi.';

  @override
  String get pgOffline =>
      'Tu es hors ligne. Voici la progression enregistrée sur cet appareil.';

  @override
  String get pgEmptyTitle => 'Ta progression commence ici';

  @override
  String get pgEmptyBody =>
      'Termine une leçon : tes minutes, tes mots et tes jours actifs s\'afficheront ici.';

  @override
  String get pgLoading => 'Chargement de ta progression…';

  @override
  String get pgErrorTitle => 'Impossible de charger ta progression';

  @override
  String get pgErrorBody =>
      'Ta progression est en sécurité sur cet appareil. Réessaie dans un instant.';

  @override
  String get pgRetry => 'Réessayer';

  @override
  String get pgPrivate => 'Ta progression est privée. Toi seul peux la voir.';

  @override
  String pgDayA11y(String day, int count) {
    return '$day : $count minutes';
  }

  @override
  String pgCalA11y(String summary) {
    return 'Calendrier d\'activité : $summary';
  }

  @override
  String get pgOverviewTitle => 'Totaux';

  @override
  String get profTitle => 'Profil';

  @override
  String get profClose => 'Fermer';

  @override
  String get profThisWeek => 'Cette semaine';

  @override
  String get profSeeProgress => 'Voir toute la progression';

  @override
  String profDayA11y(String day, String status) {
    return '$day : $status';
  }

  @override
  String get profDayDone => 'pratiqué';

  @override
  String get profDayMissed => 'pas de pratique';

  @override
  String get profLanguages => 'Langues';

  @override
  String profLangProgress(String level, int percent) {
    return 'Niveau $level · $percent %';
  }

  @override
  String get profLangEmpty =>
      'Choisis une langue sur l\'accueil pour commencer.';

  @override
  String get profBadges => 'Succès';

  @override
  String profBadgesCount(int done, int total) {
    return '$done sur $total débloqués';
  }

  @override
  String get profViewAll => 'Tout voir';

  @override
  String profBadgeLocked(String name) {
    return '$name, verrouillé';
  }

  @override
  String get profShareTitle => 'Partage ta progression';

  @override
  String get profShareBody => 'Envoie une carte avec ta série et tes XP.';

  @override
  String get profShare => 'Partager';

  @override
  String profShareText(String language, int streak, int xp) {
    return 'J\'apprends le $language sur LingAfriq : $streak jours de série et $xp XP !';
  }

  @override
  String get profHelpLegal => 'Aide et mentions légales';

  @override
  String get profAboutApp => 'À propos de LingAfriq';

  @override
  String get profSecurity => 'Compte et sécurité';

  @override
  String get profTeenBadge => 'Profil privé';

  @override
  String get profTeenTitle => 'Ton profil reste privé';

  @override
  String get profTeenHidden =>
      'Ton classement et ton nom sont masqués des classements.';

  @override
  String get profTeenNoDm =>
      'Les adultes ne peuvent pas t\'envoyer de messages privés.';

  @override
  String get profTeenParent =>
      'Ton compte est lié à un parent ou tuteur qui a donné son accord.';

  @override
  String get pgClose => 'Fermer';

  @override
  String get pgStreakTitle => 'Série actuelle';

  @override
  String pgStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours de série',
      one: '1 jour de série',
      zero: '0 jour de série',
    );
    return '$_temp0';
  }

  @override
  String pgNextGoal(int left, int goal) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'Plus que $left jours avant ton objectif de $goal jours',
      one: 'Plus qu\'1 jour avant ton objectif de $goal jours',
    );
    return '$_temp0';
  }

  @override
  String pgMilestoneHit(int goal) {
    return 'Palier atteint ! $goal jours d\'affilée';
  }

  @override
  String get pgStreakStart =>
      'Entraîne-toi aujourd\'hui pour allumer ta série.';

  @override
  String get pgErrorSaved =>
      'Ta série et tes jours d\'entraînement ne sont pas affectés.';

  @override
  String get subTitle => 'LingAfriq Plus';

  @override
  String get subClose => 'Fermer';

  @override
  String get subPlusBadge => 'PLUS';

  @override
  String get subHeadline => 'Apprends plus vite avec des bonus en option';

  @override
  String get subFreeForever =>
      'Chaque leçon, jeu et histoire reste gratuit pour toujours. Plus ajoute seulement des bonus.';

  @override
  String get subOffline =>
      'Tu es hors ligne. L\'achat nécessite une connexion, mais toutes tes leçons fonctionnent.';

  @override
  String get subWhatYouGet => 'Ce que Plus ajoute';

  @override
  String get subBenefitOffline =>
      'Télécharge chaque unité pour apprendre hors ligne';

  @override
  String get subBenefitChat =>
      'Conversations d\'entraînement illimitées avec ton tuteur';

  @override
  String get subBenefitSpeaking =>
      'Scores détaillés de prononciation et de tons';

  @override
  String get subBenefitNoAds => 'Aucune publicité';

  @override
  String subYouHavePlus(String plan) {
    return 'Tu as $plan. Merci de soutenir les langues africaines !';
  }

  @override
  String get subChoosePlan => 'Choisis une formule';

  @override
  String get subPriceError =>
      'Impossible de charger les prix du store : voici les prix standard. Le store affiche le prix final avant paiement.';

  @override
  String get subPlanMonthly => 'Plus mensuel';

  @override
  String get subPlanMonthlyDetail =>
      'Facturé chaque mois. Résiliable à tout moment.';

  @override
  String get subPlanFamily => 'Plus Famille';

  @override
  String get subPlanFamilyDetail =>
      'Jusqu\'à 4 apprenants. Facturé chaque mois.';

  @override
  String get subPlanLifetime => 'Plus à vie';

  @override
  String get subPlanLifetimeDetail => 'Un seul paiement. Sans renouvellement.';

  @override
  String get subMostPopular => 'La plus choisie';

  @override
  String subPerMonth(String price) {
    return '$price / mois';
  }

  @override
  String subOnce(String price) {
    return '$price une fois';
  }

  @override
  String get subHowTrialWorks => 'Comment fonctionne ton essai gratuit';

  @override
  String get subStepToday => 'Aujourd\'hui';

  @override
  String get subStepTodayBody => 'Tous les bonus Plus débloqués.';

  @override
  String subStepDay(int day) {
    return 'Jour $day';
  }

  @override
  String get subStepRemindBody => 'On te prévient avant la fin de l\'essai.';

  @override
  String subStepChargeBody(String price) {
    return 'Tu es débité de $price sauf si tu résilies avant.';
  }

  @override
  String subStartTrial(int days) {
    return 'Commencer l\'essai gratuit de $days jours';
  }

  @override
  String get subGetPlus => 'Prendre Plus mensuel';

  @override
  String get subGetFamily => 'Prendre Plus Famille';

  @override
  String get subGetLifetime => 'Prendre Plus à vie';

  @override
  String subFineTrial(int days, String price) {
    return 'Gratuit $days jours, puis $price/mois. Résiliable à tout moment dans les réglages du store.';
  }

  @override
  String subFineMonthly(String price) {
    return '$price/mois, renouvellement automatique. Résiliable à tout moment dans les réglages du store.';
  }

  @override
  String subFineOnce(String price) {
    return 'Un paiement unique de $price. Aucun renouvellement.';
  }

  @override
  String get subKeepFree => 'Continuer gratuitement';

  @override
  String get subRestore => 'Restaurer les achats';

  @override
  String get subRestored => 'Achats restaurés';

  @override
  String get subRestoreNone => 'Aucun achat à restaurer';

  @override
  String get subLoading => 'Chargement des formules';

  @override
  String get subParentTitle => 'Plus nécessite un adulte';

  @override
  String get subParentBody =>
      'Tout ce que tu apprends reste gratuit. Demande à un parent ou tuteur si tu veux les bonus Plus.';

  @override
  String get subAskParent => 'Un adulte est là';

  @override
  String get subGateTitle => 'Pour les adultes';

  @override
  String subGateQuestion(int a, int b) {
    return 'Combien font $a × $b ?';
  }

  @override
  String get subGateWrong => 'Ce n\'est pas ça. Réessaie.';

  @override
  String get subGateContinue => 'Continuer';

  @override
  String get subCancel => 'Annuler';

  @override
  String get lsTitle => 'Trouver une langue';

  @override
  String get lsAsk => 'Quelle langue veux-tu explorer aujourd\'hui ?';

  @override
  String get lsAskChild => 'Avec quelle langue on joue aujourd\'hui ?';

  @override
  String get lsHint => 'Chercher yoruba, swahili, zoulou…';

  @override
  String get lsContinue => 'Continuer';

  @override
  String get lsAll => 'Toutes les langues';

  @override
  String get lsSoon => 'Bientôt';

  @override
  String get lsNew => 'Commencer de zéro';

  @override
  String lsPercent(int p) {
    return '$p % fait';
  }

  @override
  String lsNoMatch(String q) {
    return 'Aucune langue ne correspond à « $q »';
  }

  @override
  String get lsNoMatchBody =>
      'Vérifie l\'orthographe ou essaie le nom de la langue dans cette langue.';

  @override
  String get lsClear => 'Effacer la recherche';

  @override
  String get lsEmptyTitle => 'Pas encore de langues';

  @override
  String get lsEmptyBody => 'De nouveaux cours arrivent. Reviens bientôt.';

  @override
  String get lsOfflineTitle => 'Tu es hors ligne';

  @override
  String get lsOfflineBody =>
      'Connecte-toi à Internet pour voir toutes les langues.';

  @override
  String get lsErrorTitle => 'Impossible de charger les langues';

  @override
  String get lsErrorBody =>
      'Ta progression est en sécurité. Réessaie dans un instant.';

  @override
  String get lsRetry => 'Réessayer';

  @override
  String get lsBack => 'Retour';

  @override
  String get lsLoading => 'Chargement des langues';
}
