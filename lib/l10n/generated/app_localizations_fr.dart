// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

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
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Commencer l\'essai gratuit de $days jours',
      one: 'Commencer l\'essai gratuit de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get subGetPlus => 'Prendre Plus mensuel';

  @override
  String get subGetFamily => 'Prendre Plus Famille';

  @override
  String get subGetLifetime => 'Prendre Plus à vie';

  @override
  String subFineTrial(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Gratuit $days jours, puis $price/mois. Résiliable à tout moment dans les réglages du store.',
      one:
          'Gratuit 1 jour, puis $price/mois. Résiliable à tout moment dans les réglages du store.',
    );
    return '$_temp0';
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

  @override
  String get lbTitle => 'Classement';

  @override
  String get lbBack => 'Retour';

  @override
  String get lbGlobal => 'Mondial';

  @override
  String get lbTribe => 'Ma tribu';

  @override
  String get lbCountry => 'Mon pays';

  @override
  String get lbWeek => 'Cette semaine';

  @override
  String get lbLeader => 'En tête cette semaine';

  @override
  String get lbColRank => 'RANG';

  @override
  String get lbColLearner => 'APPRENANT';

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
      other: 'Série de $days jours',
      one: 'Série de 1 jour',
      zero: 'Série de 0 jour',
    );
    return '$_temp0';
  }

  @override
  String lbUp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Gagne $n places',
      one: 'Gagne 1 place',
    );
    return '$_temp0';
  }

  @override
  String lbDown(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Perd $n places',
      one: 'Perd 1 place',
    );
    return '$_temp0';
  }

  @override
  String lbRankN(int n) {
    return 'Rang $n';
  }

  @override
  String get lbYou => 'Toi';

  @override
  String lbYourRank(int n) {
    return 'Ton rang : n° $n';
  }

  @override
  String get lbUnranked =>
      'Termine une leçon pour rejoindre le classement de la semaine';

  @override
  String get lbFriendly =>
      'Tout le monde repart à zéro chaque lundi. C\'est la pratique qui compte, pas la vitesse.';

  @override
  String lbLearner(int n) {
    return 'Apprenant $n';
  }

  @override
  String get lbMinorTeen =>
      'Ton profil est privé : les autres te voient comme « Apprenant », jamais ton nom.';

  @override
  String get lbMinorChild =>
      'Les noms sont cachés pour la sécurité de tous. Tu vois quand même tes progrès !';

  @override
  String get lbNoTribeTitle => 'Choisis d\'abord une tribu';

  @override
  String get lbNoTribeBody =>
      'Rejoins une tribu pour voir comment ton groupe s\'en sort cette semaine.';

  @override
  String get lbPickTribe => 'Choisir une tribu';

  @override
  String get lbNoCountryTitle => 'Ajoute ton pays';

  @override
  String get lbNoCountryBody =>
      'Indique ton pays dans ton profil pour voir les apprenants près de toi.';

  @override
  String get lbEmptyTitle => 'Pas encore de classement cette semaine';

  @override
  String get lbEmptyBody => 'Termine une leçon et tu pourrais être premier.';

  @override
  String get lbErrorTitle => 'Impossible de charger le classement';

  @override
  String get lbErrorBody =>
      'Tes XP sont en sécurité. Réessaie dans un instant.';

  @override
  String get lbOfflineTitle => 'Tu es hors ligne';

  @override
  String get lbOfflineBody =>
      'Le classement se met à jour une fois en ligne. Les leçons faites hors ligne comptent.';

  @override
  String get lbRetry => 'Réessayer';

  @override
  String get lbLoading => 'Chargement du classement';

  @override
  String get lbMore => 'Chargement';

  @override
  String get rmTitle => 'Rappels d\'étude';

  @override
  String get rmBack => 'Retour';

  @override
  String get rmPreviewApp => 'LingAfriq · maintenant';

  @override
  String get rmPreviewBody => 'Ẹ kú àárọ̀ ! 5 minutes de yoruba ?';

  @override
  String get rmPreviewOff =>
      'Les rappels sont coupés. Active-les pour un petit rappel par jour.';

  @override
  String get rmMaster => 'Rappel quotidien';

  @override
  String get rmMasterSub => 'Un par jour maximum, jamais la nuit.';

  @override
  String get rmWhen => 'Quand te le rappeler ?';

  @override
  String get rmMorning => 'Matin';

  @override
  String get rmLunch => 'Midi';

  @override
  String get rmEvening => 'Soir';

  @override
  String get rmCustom => 'Autre heure';

  @override
  String rmQuiet(String start, String end) {
    return 'Rien n\'est envoyé pendant les heures calmes ($start–$end).';
  }

  @override
  String rmQuietClash(String time) {
    return 'C\'est pendant les heures calmes, donc on l\'a réglé sur $time.';
  }

  @override
  String get rmTimezone => 'Fuseau horaire';

  @override
  String get rmUseDevice => 'Celui du téléphone';

  @override
  String get rmAbout => 'Ce qu\'on te rappelle';

  @override
  String get rmGoal => 'Objectif du jour';

  @override
  String get rmGoalSub =>
      'Un petit coup de pouce pour finir l\'objectif du jour.';

  @override
  String get rmRhythm => 'Étapes de pratique';

  @override
  String get rmRhythmSub => 'On fête tes étapes. Jamais de culpabilisation.';

  @override
  String get rmSync => 'Enregistré sur ton compte, même après réinstallation.';

  @override
  String get rmBlockedTitle => 'Notifications bloquées';

  @override
  String get rmBlockedBody =>
      'Ton téléphone bloque LingAfriq. Autorise les notifications dans Réglages.';

  @override
  String get rmOpenSettings => 'Ouvrir Réglages';

  @override
  String get rmOffline =>
      'Hors ligne. Les changements sont gardés sur ce téléphone et synchronisés plus tard.';

  @override
  String get rmCheckError =>
      'Impossible de vérifier l\'autorisation des notifications.';

  @override
  String get rmRetry => 'Réessayer';

  @override
  String get rmLoading => 'Vérification des notifications';

  @override
  String get rmChild =>
      'Les rappels des jeunes n\'arrivent jamais la nuit, et un adulte peut les couper à tout moment.';

  @override
  String get rmMasterA11y => 'Interrupteur principal des rappels d\'étude';

  @override
  String get gmTitle => 'Jeux';

  @override
  String get gmBack => 'Retour';

  @override
  String get gmWelcome => 'Bienvenue dans ton espace de jeu.';

  @override
  String gmWelcomeSub(String language) {
    return 'Chaque jeu fait pratiquer le $language.';
  }

  @override
  String get gmLanguage => 'Langue pratiquée';

  @override
  String get gmFeatured => 'Le choix du jour';

  @override
  String get gmPlay => 'Jouer';

  @override
  String get gmCore => 'Essentiels';

  @override
  String get gmCultural => 'Culturels';

  @override
  String gmCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jeux',
      one: '1 jeu',
    );
    return '$_temp0';
  }

  @override
  String get gmCatAll => 'Tous';

  @override
  String get gmCatVocabulary => 'Vocabulaire';

  @override
  String get gmCatGrammar => 'Grammaire';

  @override
  String get gmCatPronunciation => 'Prononciation';

  @override
  String get gmCatCultural => 'Culture';

  @override
  String get gmCatTraditional => 'Traditionnels';

  @override
  String get gmEmpty => 'Pas encore de jeux ici.';

  @override
  String get gmShowAll => 'Voir tous les jeux';

  @override
  String get gmOffline =>
      'Hors ligne : voici les jeux enregistrés sur ce téléphone.';

  @override
  String get gmSyncing => 'Recherche de nouveaux jeux';

  @override
  String get gmOpening => 'Ouverture du jeu…';

  @override
  String get gmLoadError => 'Ce jeu n\'a pas pu se charger.';

  @override
  String get gmRule1 => 'Apprends en t\'amusant avec ce mode de jeu.';

  @override
  String get gmRule2 => 'Vise la précision d\'abord, puis la vitesse.';

  @override
  String gmPlayA11y(String name, String category, String description) {
    return '$name, $category. $description';
  }

  @override
  String get peTitle => 'Modifier le profil';

  @override
  String get peBack => 'Retour';

  @override
  String get peAvatarEdit => 'Modifier l\'avatar';

  @override
  String get peAvatarHint => 'Fais un avatar qui te ressemble, ou pas du tout.';

  @override
  String get peAbout => 'À propos de toi';

  @override
  String get peFirst => 'Prénom';

  @override
  String get peLast => 'Nom';

  @override
  String peRequired(String field) {
    return 'Merci d\'indiquer ton $field.';
  }

  @override
  String get peHandle => 'Pseudo';

  @override
  String get peHandleNone => 'Choisis un pseudo pour que tes amis te trouvent';

  @override
  String get peHandleEdit => 'Changer de pseudo';

  @override
  String get peCountry => 'Pays';

  @override
  String get peCountryLocked =>
      'Défini à l\'inscription. Contacte le support pour le changer.';

  @override
  String get peEmail => 'E-mail';

  @override
  String get peSave => 'Enregistrer';

  @override
  String get peSaving => 'Enregistrement…';

  @override
  String get peSaved => 'Profil enregistré';

  @override
  String get peSaveError =>
      'Échec de l\'enregistrement. Tes changements sont conservés : réessaie.';

  @override
  String get peMinorTip =>
      'Astuce : choisis un surnom comme pseudo, pas ton nom complet.';

  @override
  String get peDanger => 'Compte';

  @override
  String get peDelete => 'Supprimer le compte';

  @override
  String get peDeleteSub =>
      'Supprime définitivement ta progression. Irréversible.';

  @override
  String get peDeleteError => 'Impossible de supprimer ton compte. Réessaie.';

  @override
  String get peLoading => 'Chargement du profil';

  @override
  String get dgTitle => 'Objectifs du jour';

  @override
  String dgStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Série de $n jours',
      one: 'Série de 1 jour',
      zero: 'Série de 0 jour',
    );
    return '$_temp0';
  }

  @override
  String get dgStreakOn =>
      'Continuez — pratiquez aujourd\'hui pour ajouter un jour.';

  @override
  String get dgStreakZero =>
      'Terminez un objectif aujourd\'hui pour lancer une série.';

  @override
  String dgRing(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done objectifs atteints sur $total',
      one: '$done objectif atteint sur $total',
    );
    return '$_temp0';
  }

  @override
  String get dgToday => 'Aujourd\'hui';

  @override
  String get dgLessons => 'Terminer des leçons';

  @override
  String get dgQuizzes => 'Faire des quiz';

  @override
  String get dgGames => 'Jouer à des jeux';

  @override
  String get dgChat => 'Discuter avec Polie';

  @override
  String get dgWords => 'Apprendre des mots';

  @override
  String get dgGoal => 'Objectif';

  @override
  String dgCount(int current, int target) {
    return '$current sur $target';
  }

  @override
  String dgMinutes(int current, int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: '$current sur $target min',
    );
    return '$_temp0';
  }

  @override
  String get dgDone => 'Fait';

  @override
  String get dgStart => 'Commencer';

  @override
  String get dgAllDone =>
      'Tous les objectifs du jour sont atteints. À demain !';

  @override
  String get dgEmptyTitle => 'Pas encore d\'objectifs aujourd\'hui';

  @override
  String get dgEmptyBody =>
      'Tirez vers le bas ou touchez Actualiser pour définir les objectifs.';

  @override
  String get dgRefresh => 'Actualiser';

  @override
  String get dgSyncing => 'Synchronisation de votre progression…';

  @override
  String get dgError =>
      'Synchronisation impossible. Progression enregistrée sur cet appareil affichée.';

  @override
  String get dgRetry => 'Réessayer';

  @override
  String get dgPickLessons => 'Choisissez une langue pour les leçons';

  @override
  String get dgPickQuiz => 'Choisissez une langue pour le quiz';

  @override
  String get dgLangError => 'Impossible de charger les langues.';

  @override
  String dgGoalA11y(String title, String progress, String status) {
    return '$title, $progress, $status';
  }

  @override
  String get gmNameWordMatchAudio => 'Mots à l\'écoute';

  @override
  String get gmDescWordMatchAudio => 'Associe les mots à l\'audio';

  @override
  String get gmNamePronunciationDuel => 'Duel de prononciation';

  @override
  String get gmDescPronunciationDuel => 'Maîtrise la prononciation';

  @override
  String get gmNameSpeedRoundRemix => 'Course éclair';

  @override
  String get gmDescSpeedRoundRemix => 'Vocabulaire à toute vitesse';

  @override
  String get gmNameStoryBuilder => 'Atelier d\'histoires';

  @override
  String get gmDescStoryBuilder => 'Construis des histoires';

  @override
  String get gmNameRoleplayAdventure => 'Aventure jeu de rôle';

  @override
  String get gmDescRoleplayAdventure => 'Conversations interactives';

  @override
  String get gmNameGrammarDetective => 'Détective de grammaire';

  @override
  String get gmDescGrammarDetective => 'Résous des énigmes de grammaire';

  @override
  String get gmNameListenAndSketch => 'Écoute et dessine';

  @override
  String get gmDescListenAndSketch => 'Dessine ce que tu entends';

  @override
  String get gmNamePictureWordAssociation => 'Mots en images';

  @override
  String get gmDescPictureWordAssociation => 'Associe les mots aux images';

  @override
  String get gmNameMemoryMap => 'Carte mémoire';

  @override
  String get gmDescMemoryMap => 'Défi de mémoire';

  @override
  String get gmNameConversationRelay => 'Relais de conversation';

  @override
  String get gmDescConversationRelay => 'Enchaîne les conversations';

  @override
  String get gmNameGrammarJam => 'Jam de grammaire';

  @override
  String get gmDescGrammarJam => 'Jeu de rythme grammatical';

  @override
  String get gmNamePronunciationKaraoke => 'Karaoké de prononciation';

  @override
  String get gmDescPronunciationKaraoke => 'Chante et prononce';

  @override
  String get gmNameQuizChef => 'Chef du quiz';

  @override
  String get gmDescQuizChef => 'Cuisine tes réponses';

  @override
  String get gmNameToneTrainer => 'Entraîneur de tons';

  @override
  String get gmDescToneTrainer => 'Maîtrise les tons';

  @override
  String get gmNameScrabbleSprintArena => 'Sprint de mots';

  @override
  String get gmDescScrabbleSprintArena => 'Forme des mots sous pression';

  @override
  String get gmNameProverbUnlocker => 'Proverbes à débloquer';

  @override
  String get gmDescProverbUnlocker => 'Débloque la sagesse';

  @override
  String get gmNameDrumRhythmShadowing => 'Rythme du tambour';

  @override
  String get gmDescDrumRhythmShadowing => 'Suis le rythme';

  @override
  String get gmNameClanLineageStoryBuilder => 'Histoires de clan';

  @override
  String get gmDescClanLineageStoryBuilder => 'Raconte l\'histoire du clan';

  @override
  String get gmNameMarketBargainingSimulator => 'Marchandage au marché';

  @override
  String get gmDescMarketBargainingSimulator => 'Entraîne-toi à marchander';

  @override
  String get gmNameTaxiBusStopSurvival => 'Survie en taxi';

  @override
  String get gmDescTaxiBusStopSurvival => 'Déplace-toi en ville';

  @override
  String get gmNameFoodQuest => 'Quête culinaire';

  @override
  String get gmDescFoodQuest => 'Explore la cuisine';

  @override
  String get gmNameCallAndResponse => 'Appel et réponse';

  @override
  String get gmDescCallAndResponse => 'Formes traditionnelles';

  @override
  String get gmNameGreetingDiplomacyChallenge => 'Diplomatie des salutations';

  @override
  String get gmDescGreetingDiplomacyChallenge => 'Maîtrise les salutations';

  @override
  String get gmNameFolktaleReconstruction => 'Contes à reconstruire';

  @override
  String get gmDescFolktaleReconstruction => 'Reconstitue les histoires';

  @override
  String get gmNamePhraseSniper => 'Tireur de phrases';

  @override
  String get gmDescPhraseSniper => 'Vise les bonnes phrases';

  @override
  String get gmNameLiarLiar => 'Menteur, menteur';

  @override
  String get gmDescLiarLiar => 'Démêle le vrai du faux';

  @override
  String get gmNameVillageQuest => 'Quête du village';

  @override
  String get gmDescVillageQuest => 'Aventure au village';

  @override
  String get gmNameAccentDecodingPuzzle => 'Énigme des accents';

  @override
  String get gmDescAccentDecodingPuzzle => 'Décode les accents';

  @override
  String get gmNameFlashcardSafari => 'Safari de cartes';

  @override
  String get gmDescFlashcardSafari => 'Vocabulaire en safari';

  @override
  String get gmNameRapidTongueTwisterRace => 'Virelangues';

  @override
  String get gmDescRapidTongueTwisterRace => 'Maîtrise les virelangues';

  @override
  String get gmNameEmojiTranslator => 'Traducteur d\'emoji';

  @override
  String get gmDescEmojiTranslator => 'Traduis les emoji';

  @override
  String get gmNameRhythmTyping => 'Frappe en rythme';

  @override
  String get gmDescRhythmTyping => 'Tape en rythme';

  @override
  String get gmNameEldersBlessingsChallenge => 'Bénédictions des aînés';

  @override
  String get gmDescEldersBlessingsChallenge => 'Apprends les bénédictions';

  @override
  String get gmNameMultilingualRelayRace => 'Relais multilingue';

  @override
  String get gmDescMultilingualRelayRace => 'Relais des langues';

  @override
  String get gmNameCulturalEtiquetteScenarios => 'Savoir-vivre culturel';

  @override
  String get gmDescCulturalEtiquetteScenarios => 'Apprends les usages';

  @override
  String get gmNameDrumToWordMatching => 'Tambour et mots';

  @override
  String get gmDescDrumToWordMatching => 'Associe les rythmes du tambour';

  @override
  String get gmNameMarketMonopolyChallenge => 'Monopoly du marché';

  @override
  String get gmDescMarketMonopolyChallenge =>
      'Négociations stratégiques au marché';

  @override
  String get gmNameAyoMancala => 'Ayo (mancala)';

  @override
  String get gmDescAyoMancala =>
      'Jeu de plateau traditionnel avec du vocabulaire';

  @override
  String get gmNameSuweHopscotch => 'Suwe (marelle)';

  @override
  String get gmDescSuweHopscotch =>
      'Lance la pierre et suis les tons sur la grille';

  @override
  String get gmNameLudoLanguage => 'Ludo des langues';

  @override
  String get gmDescLudoLanguage => 'Ludo africain, chaque coup après un QCM';

  @override
  String get gmNameSnakesAndLaddersCultural => 'Serpents et échelles (culture)';

  @override
  String get gmDescSnakesAndLaddersCultural =>
      'Échelles de proverbes, serpents de corrections';

  @override
  String get gmNameWhotCardGame => 'Whot (cartes nigérianes)';

  @override
  String get gmDescWhotCardGame => 'Règles complètes du Whot, un mot par carte';

  @override
  String get gcTitle => 'Chat mondial';

  @override
  String get gcChannelGeneral => 'Général';

  @override
  String get gcChannels => 'Salons';

  @override
  String get gcSwitchChannel => 'Changer de salon';

  @override
  String get gcRefresh => 'Actualiser';

  @override
  String get gcFindUser => 'Trouver quelqu’un';

  @override
  String get gcMore => 'Plus';

  @override
  String get gcGuidelines => 'Règles de la communauté';

  @override
  String get gcMutedBlocked => 'Masqués et bloqués';

  @override
  String get gcPolieTitle => 'Pratiquer en privé avec Polie (IA)';

  @override
  String get gcPolieSub => 'Vos messages ne sont pas publiés dans les salons';

  @override
  String get gcEmptyTitle => 'Aucun message pour l’instant';

  @override
  String get gcEmptyBody => 'Dites bonjour pour lancer la conversation.';

  @override
  String get gcSayHello => 'Dire bonjour';

  @override
  String get gcHelloText => 'Bonjour à tous ! Ravi d’apprendre ensemble.';

  @override
  String get gcErrorTitle => 'Impossible de charger les messages';

  @override
  String get gcErrorBody => 'Vérifiez votre connexion et réessayez.';

  @override
  String get gcRetry => 'Réessayer';

  @override
  String get gcOffline => 'Hors ligne · messages enregistrés';

  @override
  String gcHidden(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n messages masqués (personnes masquées ou bloquées)',
      one: '$n message masqué (personnes masquées ou bloquées)',
    );
    return '$_temp0';
  }

  @override
  String get gcManage => 'Gérer';

  @override
  String get gcHint => 'Écrire un message… (@Polie pour de l’aide)';

  @override
  String get gcSend => 'Envoyer';

  @override
  String get gcSending => 'Envoi…';

  @override
  String get gcYou => 'Vous';

  @override
  String get gcNow => 'à l’instant';

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
  String get gcFlagged => 'Masqué par la modération';

  @override
  String get gcShow => 'Afficher';

  @override
  String get gcSendFailed => 'Message non envoyé. Vérifiez votre connexion.';

  @override
  String get gcPolieBusy =>
      'Trop de demandes à @Polie. Réessayez dans une minute environ.';

  @override
  String get gcSignIn => 'Connectez-vous pour envoyer des messages.';

  @override
  String gcActionsFor(String name) {
    return 'Message de $name';
  }

  @override
  String get gcMute => 'Masquer';

  @override
  String get gcMuteSub =>
      'Ne plus voir ses messages sur cet appareil. La personne n’est pas prévenue.';

  @override
  String get gcUnmute => 'Réafficher';

  @override
  String get gcReport => 'Signaler';

  @override
  String get gcReportSub => 'Nos modérateurs examinent chaque signalement.';

  @override
  String get gcBlock => 'Bloquer';

  @override
  String get gcBlockSub => 'Ne plus voir ses messages et snaps nulle part.';

  @override
  String gcBlockConfirm(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get gcBlockConfirmBody =>
      'Vous ne verrez plus ses nouveaux messages ni ses snaps. Vous pourrez débloquer plus tard.';

  @override
  String get gcCancel => 'Annuler';

  @override
  String get gcReasonTitle => 'Pourquoi signalez-vous ce message ?';

  @override
  String get gcReasonHarassment => 'Harcèlement';

  @override
  String get gcReasonSpam => 'Spam';

  @override
  String get gcReasonHate => 'Discours haineux';

  @override
  String get gcReasonOther => 'Autre chose';

  @override
  String gcReportSent(String ref) {
    return 'Signalement envoyé. Référence $ref';
  }

  @override
  String get gcReportFailed =>
      'Impossible d’envoyer le signalement. Réessayez.';

  @override
  String gcBlockedNote(String name) {
    return '$name est bloqué·e';
  }

  @override
  String get gcBlockFailed => 'Blocage impossible. Réessayez.';

  @override
  String gcMutedNote(String name) {
    return '$name est masqué·e';
  }

  @override
  String get gcMutedTitle => 'Masqués';

  @override
  String get gcBlockedTitle => 'Bloqués';

  @override
  String get gcNobody => 'Personne';

  @override
  String get gcUnblock => 'Débloquer';

  @override
  String get gcProfileUnavailable => 'Profil indisponible pour ce message.';

  @override
  String get gcLockedTeenTitle => 'Le chat mondial ouvre à 18 ans';

  @override
  String get gcLockedTeenBody =>
      'Pour votre sécurité, le chat ouvert avec des inconnus est réservé aux adultes. Vous pouvez toujours pratiquer avec Polie et votre classe.';

  @override
  String get gcLockedChildTitle => 'Le chat mondial n’est pas disponible';

  @override
  String get gcLockedChildBody =>
      'Les comptes enfants n’ont pas accès au chat ouvert. Continuez avec les leçons, les jeux et Polie.';

  @override
  String get gcLockedUnknownTitle => 'Nous devons d’abord connaître votre âge';

  @override
  String get gcLockedUnknownBody =>
      'Le chat mondial est réservé aux adultes. Il apparaîtra ici dès que l’âge de votre compte sera confirmé.';

  @override
  String get gcPracticePolie => 'Pratiquer avec Polie';

  @override
  String get gcChecking => 'Vérification de l’accès…';

  @override
  String gcMessagesLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n messages',
      one: '$n message',
      zero: 'Aucun message',
    );
    return '$_temp0';
  }

  @override
  String gcOpenProfile(String name) {
    return 'Ouvrir le profil de $name';
  }

  @override
  String get rbReasons => 'Motifs du signalement';

  @override
  String get rbSendReport => 'Envoyer le signalement';

  @override
  String get rbSending => 'Envoi du signalement';

  @override
  String rbReceived(String ref) {
    return 'Signalement reçu. Référence $ref';
  }

  @override
  String get rbSendFailed => 'Échec de l’envoi. Réessayez.';

  @override
  String get rbBlockConfirm =>
      'Bloquer cette personne ? Vous ne verrez plus ses nouveaux messages ni ses snaps.';

  @override
  String get rbConfirmBlock => 'Confirmer le blocage';

  @override
  String get rbBlockUser => 'Bloquer l’utilisateur';

  @override
  String get rbBlockedNote =>
      'Bloqué. Vous ne verrez plus ses nouveaux messages.';

  @override
  String get rbBlockFailed =>
      'Impossible de bloquer cette personne. Réessayez.';

  @override
  String get rbBlockedPeople => 'Personnes bloquées';

  @override
  String get rbNoBlocked => 'Aucune personne bloquée';

  @override
  String get rbHate => 'Haine';

  @override
  String get rbOther => 'Autre';

  @override
  String gcHeroTitle(String channel) {
    return 'Bienvenue sur #$channel';
  }

  @override
  String gcHeroBody(String channel) {
    return 'Voici le début de #$channel. Soyez bienveillant : les modérateurs examinent chaque signalement.';
  }

  @override
  String gcGreetingIn(String greeting) {
    return 'Dites-le comme sur place : $greeting';
  }

  @override
  String get gcHintShort => 'Message';

  @override
  String get gcErrorServerTitle => 'Le chat mondial ne s\'est pas chargé';

  @override
  String get gcErrorServerBody =>
      'Un problème est survenu de notre côté. Rien de ce que vous avez écrit n\'est perdu. Réessayez dans un instant.';

  @override
  String get gfamToolsTitle => 'Outils famille';

  @override
  String get gfamToolsApprovals => 'Approbations de groupes';

  @override
  String get gfamToolsApprovalsSub => 'Cercles et classes en attente';

  @override
  String get gfamToolsGuide => 'Comment fonctionnent les messages';

  @override
  String get gfamToolsGuideSub => 'Ce qui est vérifié et qui peut écrire';

  @override
  String get gfamToolsCircles => 'Cercles';

  @override
  String get gfamToolsCirclesSub => 'Vos cercles d’étude';

  @override
  String gfamWhoMessages(int id) {
    return 'Qui écrit à l’apprenant n°$id';
  }

  @override
  String get gdmTitle => 'Qui écrit à votre apprenant';

  @override
  String get gdmIntro =>
      'Vous voyez qui, quand et les signalements. Jamais le texte des messages.';

  @override
  String get gdmEmptyTitle => 'Aucun message privé pour l’instant';

  @override
  String get gdmEmptyBody =>
      'Seuls les enseignants et les membres des groupes approuvés peuvent écrire à votre apprenant.';

  @override
  String get gdmError => 'Impossible de charger les messages. Réessayez.';

  @override
  String get gdmRetry => 'Réessayer';

  @override
  String get gdmRoleTeacher => 'Enseignant';

  @override
  String get gdmRoleClassmate => 'Camarade';

  @override
  String get gdmRoleContact => 'Contact';

  @override
  String gdmLastActive(String when) {
    return 'Dernier message $when';
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
      other: '$count signalements',
      one: '1 signalement',
      zero: 'Aucun signalement',
    );
    return '$_temp0';
  }

  @override
  String gdmBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages bloqués par les contrôles',
      one: '1 message bloqué par les contrôles',
    );
    return '$_temp0';
  }

  @override
  String gdmHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos ou messages vocaux en attente de modération',
      one: '1 photo ou message vocal en attente de modération',
    );
    return '$_temp0';
  }

  @override
  String get gdmStop => 'Bloquer les messages';

  @override
  String get gdmAllow => 'Autoriser à nouveau';

  @override
  String get gdmStopped => 'Messages bloqués';

  @override
  String gdmStopConfirmTitle(String name) {
    return 'Bloquer les messages de $name ?';
  }

  @override
  String get gdmStopConfirmBody =>
      'Cette personne ne pourra plus écrire à votre apprenant, et inversement. Vous pourrez réautoriser plus tard.';

  @override
  String get gdmCancel => 'Annuler';

  @override
  String get gdmActionFailed => 'Échec. Réessayez.';

  @override
  String get gdmUnknownName => 'Utilisateur inconnu';

  @override
  String get gccJoinButton => 'Saisir un code de classe';

  @override
  String get gccTitle => 'Rejoindre une classe';

  @override
  String get gccHint => 'Demandez le code à votre enseignant.';

  @override
  String get gccLabel => 'Code de classe';

  @override
  String get gccSubmit => 'Rejoindre';

  @override
  String get gccJoined => 'Vous avez rejoint la classe.';

  @override
  String get gccWaitingTitle => 'En attente de votre tuteur';

  @override
  String get gccWaitingBody =>
      'Nous avons demandé à votre tuteur d’approuver cette classe. Vous pourrez la rejoindre après son accord.';

  @override
  String get gccNeedLink =>
      'Demandez d’abord à un parent ou tuteur de se lier à votre compte dans l’espace Famille.';

  @override
  String get gccNeedAge =>
      'Confirmez votre âge dans les paramètres avant de rejoindre une classe.';

  @override
  String get gccNotFound =>
      'Aucune classe avec ce code. Vérifiez avec votre enseignant.';

  @override
  String get gccAlready => 'Vous êtes déjà dans cette classe.';

  @override
  String get gccError => 'Impossible de rejoindre pour le moment. Réessayez.';

  @override
  String get gccEmpty => 'Saisissez d’abord le code.';

  @override
  String get gccDone => 'Terminé';

  @override
  String get gtpTitle => 'Demandes des élèves';

  @override
  String get gtpOpen => 'Demandes des élèves';

  @override
  String get gtpWaitingSection => 'En attente d’un tuteur';

  @override
  String get gtpWaitingHelp =>
      'Ces élèves ont utilisé votre code. Leur tuteur décide ; vous n’avez rien à faire.';

  @override
  String get gtpWaitingEmpty => 'Personne n’attend.';

  @override
  String get gtpSchoolSection => 'Comptes scolaires';

  @override
  String get gtpSchoolHelp =>
      'Les messages de l’enseignant sont désactivés jusqu’à activation pour chaque élève. Vous seul pouvez leur écrire, et chaque message est vérifié.';

  @override
  String get gtpSchoolEmpty => 'Aucun compte scolaire dans cette classe.';

  @override
  String get gtpTeacherDm => 'Messages de l’enseignant';

  @override
  String get gtpPendingConsent => 'Consentement de l’école en attente';

  @override
  String gtpStudent(int id) {
    return 'Élève n°$id';
  }

  @override
  String gtpSince(String when) {
    return 'Demandé $when';
  }

  @override
  String get gtpError => 'Impossible de charger les demandes. Réessayez.';

  @override
  String get gtpNotTeacher =>
      'Seul l’enseignant de cette classe peut voir les demandes.';

  @override
  String get gccClose => 'Fermer';

  @override
  String get gccOpenFamilyHub => 'Ouvrir l’espace Famille';

  @override
  String get gtpEmptyTitle => 'Aucune demande d’élève pour l’instant';

  @override
  String get gtpEmptyBody =>
      'Partagez le code de la classe. Les élèves qui rejoignent apparaîtront ici.';

  @override
  String get gtpLocked =>
      'Bloqué jusqu’à la confirmation du consentement par l’école';

  @override
  String get gmeTitle =>
      'Comment fonctionnent les messages des jeunes apprenants';

  @override
  String get gmeBody =>
      'Les messages des apprenants de moins de 18 ans ne sont pas chiffrés de bout en bout, afin que les contrôles automatiques et les modérateurs puissent intervenir avant qu’un contenu nuisible soit livré.';

  @override
  String get gmeModHeading => 'Ce que les modérateurs peuvent examiner';

  @override
  String get gmeMod1 =>
      'Le texte des messages dans les discussions que vous avez approuvées';

  @override
  String get gmeMod2 => 'Les signaux de sécurité du filtrage automatique';

  @override
  String get gmeMod3 => 'Les signalements des apprenants ou des tuteurs';

  @override
  String get gmeTradeoff =>
      'Les discussions chiffrées entre adultes échappent à la modération ; les comptes enfants restent sur une messagerie modérée.';

  @override
  String get gmeLoadError =>
      'Impossible de charger ce guide pour le moment. Tirez pour actualiser ou réessayez une fois en ligne.';

  @override
  String get gmeOffline =>
      'Vous êtes hors ligne. Voici la dernière explication enregistrée.';

  @override
  String get gmeLoading => 'Chargement du guide de messagerie';

  @override
  String get gmeRetry => 'Réessayer';

  @override
  String get gmeTileTitle => 'Comment les messages des apprenants restent sûrs';

  @override
  String get gmeTileSubtitle =>
      'Pourquoi les discussions sont modérées et non chiffrées';

  @override
  String get gcirTitle => 'Vos cercles';

  @override
  String get gcirLoadError =>
      'Impossible de charger vos cercles pour le moment.';

  @override
  String get gcirOffline =>
      'Vous êtes hors ligne. Vos cercles apparaîtront à la reconnexion.';

  @override
  String get gcirRetry => 'Réessayer';

  @override
  String get gcirEmpty =>
      'Créez un cercle d’étude ou rejoignez un village linguistique pour apprendre ensemble.';

  @override
  String get gcirEmptyTitle => 'Aucun cercle pour l’instant';

  @override
  String gcirOpen(int count, int max) {
    return '$count membres sur $max · Ouvert';
  }

  @override
  String gcirFull(int count) {
    return 'Complet · $count membres';
  }

  @override
  String gcirOpensAt(int count, int min) {
    return '$count membres · Ouverture à $min';
  }

  @override
  String get gcirFallbackName => 'Cercle';

  @override
  String get gapTitle => 'Approbations de groupe';

  @override
  String get gapLearnerFallback => 'Votre apprenant';

  @override
  String get gapDenyConfirmTitle => 'Refuser cette demande ?';

  @override
  String gapDenyConfirmBody(String child, String group) {
    return '$child ne rejoindra pas $group. Une nouvelle demande reste possible plus tard.';
  }

  @override
  String get gapCancel => 'Annuler';

  @override
  String get gapDeny => 'Refuser';

  @override
  String get gapApprove => 'Approuver';

  @override
  String get gapRevoke => 'Révoquer';

  @override
  String gapApprovedToast(String group) {
    return 'Approuvé : $group';
  }

  @override
  String gapDeniedToast(String group) {
    return 'Refusé : $group';
  }

  @override
  String gapRevokedToast(String group) {
    return 'Approbation révoquée : $group';
  }

  @override
  String get gapActionFailed => 'Cela n\'a pas abouti. Veuillez réessayer.';

  @override
  String get gapReview => 'À examiner';

  @override
  String get gapDecided => 'Décidé';

  @override
  String get gapLoadError =>
      'Impossible de charger les approbations. Vérifiez votre connexion et réessayez.';

  @override
  String get gapEmptyTitle => 'Aucune demande pour l\'instant';

  @override
  String get gapEmptyBody =>
      'Quand votre apprenant demande à rejoindre un cercle ou une classe, la demande apparaît ici.';

  @override
  String get gapRefresh => 'Actualiser';

  @override
  String get gapOffline =>
      'Vous êtes hors ligne. Dernière liste chargée affichée.';

  @override
  String get gapLoading => 'Chargement des approbations';

  @override
  String get gapRetry => 'Réessayer';

  @override
  String get gapStatusApproved => 'Approuvé';

  @override
  String get gapStatusExpired => 'Expiré';

  @override
  String get gapStatusRevoked => 'Révoqué';

  @override
  String get gapStatusDenied => 'Refusé';

  @override
  String get gapStatusReapprove => 'À réapprouver';

  @override
  String get gapStatusWaiting => 'En attente de vous';

  @override
  String get gapModerated => 'Messages vérifiés par des modérateurs';

  @override
  String get gapApprovalRequired => 'Votre accord est requis pour rejoindre';

  @override
  String get gapOpenCommunity => 'Communauté ouverte';

  @override
  String get gapKindCircle => 'Cercle';

  @override
  String get gapKindClassroom => 'Classe';

  @override
  String gapWhyCircle(String child, String group) {
    return '$child veut rejoindre le cercle $group';
  }

  @override
  String gapWhyClass(String child, String group) {
    return '$child veut rejoindre la classe $group';
  }

  @override
  String gapMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String gapAdults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adultes',
      one: '1 adulte',
    );
    return '$_temp0';
  }

  @override
  String gapExpires(String date) {
    return 'L\'approbation prend fin le $date';
  }

  @override
  String get gccFormatHint =>
      '6 à 8 lettres ou chiffres, donnés par votre enseignant';

  @override
  String get gccChecking => 'Vérification du code…';

  @override
  String get gcirLoading => 'Chargement des cercles';

  @override
  String get gcirJoinWithCode => 'Rejoindre avec un code de classe';

  @override
  String get gcirExplore => 'Explorer les villages';

  @override
  String get gcirPillOpen => 'Ouvert';

  @override
  String get gcirPillFull => 'Complet';

  @override
  String get gcirPillSoon => 'Bientôt';

  @override
  String get gdmLoading => 'Chargement des contacts';

  @override
  String gdmTitleFor(String name) {
    return 'Qui écrit à $name';
  }

  @override
  String get gfamHubTitle => 'Espace famille';

  @override
  String get gfamModeHub => 'Espace tuteur';

  @override
  String get gfamModeInvite => 'Invitation de l\'apprenant';

  @override
  String get gfamStatusActive => 'Approuvé';

  @override
  String get gfamStatusVerifying => 'Votre consentement est requis';

  @override
  String get gfamStatusWithdrawn => 'Consentement retiré';

  @override
  String gfamWhoMessagesName(String name) {
    return 'Qui écrit à $name';
  }

  @override
  String get gfamWhoMessagesYours => 'Qui écrit à votre apprenant';

  @override
  String get gmeSecCheckedTitle => 'Les messages sont vérifiés en premier';

  @override
  String get gmeSecHeldTitle =>
      'Photos, notes vocales et liens attendent une vérification';

  @override
  String get gmeSecHeldBody =>
      'Quand un adulte envoie une photo, une note vocale ou un lien à un jeune apprenant, l\'envoi est retenu jusqu\'à sa vérification par un modérateur.';

  @override
  String get gmeSecStopTitle => 'Vous pouvez bloquer un contact';

  @override
  String get gmeSecStopBody =>
      'Dans l\'espace famille, ouvrez Messages et choisissez Arrêter. Cette personne ne pourra plus écrire à votre apprenant.';

  @override
  String get gmeSecTeacherTitle => 'Les enseignants ont besoin de votre accord';

  @override
  String get gmeSecTeacherBody =>
      'Un enseignant ne peut écrire à votre apprenant que dans une classe que vous avez approuvée, ou si l\'école a le consentement et que l\'enseignant active les messages. Cette autorisation prend fin à sa date d\'expiration.';

  @override
  String gtpDmOnTitle(String name) {
    return 'Activer les messages avec $name ?';
  }

  @override
  String gtpDmOffTitle(String name) {
    return 'Désactiver les messages avec $name ?';
  }

  @override
  String get gtpDmOnBody =>
      'Le consentement de l\'école couvre cela. Les messages restent modérés, pendant un an sauf si vous désactivez.';

  @override
  String get gtpDmOffBody =>
      'Vous ne pourrez plus écrire directement à cet élève.';

  @override
  String get gtpDmOnAction => 'Activer';

  @override
  String get gtpDmOffAction => 'Désactiver';

  @override
  String gtpDmUntil(String date) {
    return 'Messages actifs jusqu\'au $date';
  }

  @override
  String get gtpLoading => 'Chargement des élèves';

  @override
  String get gfamModeHubLabel => 'Espace tuteur, afficher les apprenants liés';

  @override
  String get gfamModeInviteLabel =>
      'Invitation de l\'apprenant, créer un code à partager';

  @override
  String get gfamInviteSectionTitle => 'Un apprenant vous attend ?';

  @override
  String get gfamAcceptInviteHint =>
      'Collez le code d\'invitation de son appli LingAfriq.';

  @override
  String get gfamInviteCodeLabel => 'Code d\'invitation';

  @override
  String get gfamYourNameHint => 'Votre nom (visible par l\'apprenant)';

  @override
  String get gfamLinkedLearners => 'Apprenants liés';

  @override
  String get gfamLinkLearner => 'Lier l\'apprenant';

  @override
  String get gdmEmptyAction => 'Comment fonctionnent les messages';

  @override
  String gccJoinedNamed(String className) {
    return 'Vous avez rejoint $className';
  }

  @override
  String get gccJoinedNext =>
      'Votre enseignant peut maintenant partager des leçons et des messages avec vous ici.';

  @override
  String gcirLastActivity(String date) {
    return 'Dernière activité $date';
  }

  @override
  String get gfamRegimeNdpa =>
      'Loi nigériane sur la protection des données (NDPA 2023)';

  @override
  String get gfamRegimeOther => 'Règles de confidentialité pour enfants';

  @override
  String get gfamMembersTitle => 'Votre famille';

  @override
  String get gfamYou => 'Vous';

  @override
  String get gfamYouInitial => 'V';

  @override
  String get gfamRoleGuardian => 'Responsable';

  @override
  String get gfamRoleLearner => 'Apprenant';

  @override
  String gfamNeedsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count demandes vous attendent',
      one: '1 demande vous attend',
    );
    return '$_temp0';
  }

  @override
  String get gfamNeedsYouAction => 'Examiner';

  @override
  String get gapNotNow => 'Plus tard';

  @override
  String get gapNotNowToast =>
      'Gardé pour plus tard. La demande reste dans votre liste.';

  @override
  String get gapShowAgain => 'Afficher';

  @override
  String gapApprovingAs(String name) {
    return 'Vous approuvez en tant que $name (parent)';
  }

  @override
  String get gapApprovingAsYou =>
      'Vous approuvez en tant que parent de ce compte';

  @override
  String gapAudit(String status, String time) {
    return '$status par vous · $time';
  }

  @override
  String gapAuditThisPhone(String status, String time) {
    return '$status par vous · $time · ce téléphone';
  }

  @override
  String get gapPendingSync => 'En attente de synchronisation';

  @override
  String get gapSavedOffline =>
      'Enregistré hors ligne. Envoi dès votre retour en ligne.';

  @override
  String gdmSummary(int count, int fresh) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '1 contact',
    );
    return '$_temp0 · $fresh nouveaux cette semaine';
  }

  @override
  String get gdmFilterAll => 'Tous';

  @override
  String get gdmFilterNew => 'Nouveau';

  @override
  String get gdmFilterStopped => 'Arrêtés';

  @override
  String get gdmFilterMedia => 'Médias en attente';

  @override
  String get gdmFilterEmpty => 'Aucun contact ne correspond à ce filtre.';

  @override
  String gdmStoppedToast(String name) {
    return '$name ne peut plus écrire à votre apprenant';
  }

  @override
  String get gdmUndo => 'Annuler';

  @override
  String get gccCheck => 'Vérifier le code';

  @override
  String get gccPreviewTitle => 'Est-ce votre classe ?';

  @override
  String gccPreviewTeacher(String name) {
    return 'Enseignant : $name';
  }

  @override
  String gccPreviewMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apprenants',
      one: '1 apprenant',
      zero: 'Aucun apprenant pour l’instant',
    );
    return '$_temp0';
  }

  @override
  String get gccPreviewChange => 'Utiliser un autre code';

  @override
  String get gtpVerified => 'Vérifié par l’école';

  @override
  String gtpAllowUntil(String date) {
    return 'Autorisé jusqu’au $date';
  }

  @override
  String gtpExpiresIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expire dans $count jours',
      one: 'Expire dans 1 jour',
      zero: 'Expire aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String get commonActionContinue => 'Continue';

  @override
  String get commonActionSave => 'Save';

  @override
  String get commonActionTryAgain => 'Try again';

  @override
  String get commonActionClose => 'Close';

  @override
  String get commonActionShowMore => 'Show more';

  @override
  String get commonStateUnavailable => 'Unavailable';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingSelectBirthYear => 'Select birth year';

  @override
  String onboardingBirthYearValue(String value) {
    return 'Birth year, $value';
  }

  @override
  String get onboardingContinueToLessons => 'Continue to lessons';

  @override
  String get onboardingWeCouldNotSaveThatYear =>
      'We could not save that year. Try again.';

  @override
  String get onboardingChooseTheYearYouWereBorn =>
      'Choose the year you were born to continue.';

  @override
  String get onboardingYourAccountIsReadyForLessons =>
      'Your account is ready for lessons, but chat, Village, and purchases stay paused until a guardian approves.';

  @override
  String get onboardingWeNeedAGuardian => 'We need a guardian';

  @override
  String get onboardingYouAlreadyEnteredABirthYear =>
      'You already entered a birth year on this device. If something looks wrong, ask a guardian to help from their account.';

  @override
  String get onboardingWeUseThisToKeepLearners =>
      'We use this to keep learners safe and unlock the right features for your age. We only ask for the year, and we store your age group, not the year itself.';

  @override
  String get onboardingWhatYearWereYouBorn => 'What year were you born?';

  @override
  String onboardingPendingsyncsPendingSyncValue(
    String pendingSyncs,
    String value,
  ) {
    return '$pendingSyncs pending sync$value';
  }

  @override
  String get onboardingCouldNotVerifyAvailabilityYouCan =>
      'Could not verify availability. You can still continue.';

  @override
  String get onboardingOnlyLettersNumbersAndUnderscoresAre =>
      'Only letters, numbers, and underscores are allowed';

  @override
  String get onboardingUsernameMustBe30CharactersOr =>
      'Username must be 30 characters or less';

  @override
  String get onboardingUsernameMustBeAtLeast3 =>
      'Username must be at least 3 characters';

  @override
  String get onboardingUsernameIsAlreadyTaken => '✗ Username is already taken';

  @override
  String get onboardingUsernameIsAvailable => '✓ Username is available';

  @override
  String get onboardingCheckingAvailability => 'Checking availability...';

  @override
  String get onboardingEnterAUsername330Characters =>
      'Enter a username (3-30 characters, letters, numbers, and underscores only)';

  @override
  String get onboardingCompleteOnboarding => 'Complete Onboarding';

  @override
  String get onboardingChooseAUniqueUsername => 'Choose a unique username';

  @override
  String get onboardingUsername => 'Username';

  @override
  String get onboardingChangeAvatar => 'Change Avatar';

  @override
  String get onboardingSetYourUsernameAvatarIsOptional =>
      'Set your username (avatar is optional)';

  @override
  String get onboardingCompleteYourProfile => 'Complete Your Profile';

  @override
  String get onboardingEnableReminders => 'Enable Reminders';

  @override
  String get onboardingPreferredTimeOfDay => 'Preferred Time of Day';

  @override
  String onboardingValueMinutesPerDay(String value) {
    return '$value minutes per day';
  }

  @override
  String onboardingValueMinutes(String value) {
    return '$value minutes';
  }

  @override
  String get onboardingDailyDurationMinutes => 'Daily Duration (minutes)';

  @override
  String get onboardingWhenAndHowLongDoYou =>
      'When and how long do you want to learn?';

  @override
  String get onboardingSetYourLearningSchedule => 'Set your learning schedule';

  @override
  String get onboardingHowShouldPolieCommunicateWithYou =>
      'How should Polie communicate with you?';

  @override
  String get onboardingWhatToneDoYouPrefer => 'What tone do you prefer?';

  @override
  String get onboardingHowFastDoYouWantTo => 'How fast do you want to learn?';

  @override
  String get onboardingWhatPaceDoYouPrefer => 'What pace do you prefer?';

  @override
  String get onboardingSelectYourPreferredLearningStyle =>
      'Select your preferred learning style';

  @override
  String get onboardingHowDoYouLearnBest => 'How do you learn best?';

  @override
  String get onboardingChooseYourMainLearningObjective =>
      'Choose your main learning objective';

  @override
  String get onboardingWhatSYourPrimaryGoal => 'What\'s your primary goal?';

  @override
  String get onboardingChooseYourDailyLearningGoal =>
      'Choose your daily learning goal';

  @override
  String get onboardingHowMuchTimeCanYouCommit =>
      'How much time can you commit daily?';

  @override
  String get onboardingDedicatedStudy => 'Dedicated study';

  @override
  String get onboardingText20Min => '20 min';

  @override
  String get onboardingBalanced => 'Balanced';

  @override
  String get onboardingText15Min => '15 min';

  @override
  String get onboardingLightLearning => 'Light learning';

  @override
  String get onboardingText10Min => '10 min';

  @override
  String get onboardingQuickPractice => 'Quick practice';

  @override
  String get onboardingText5Min => '5 min';

  @override
  String get onboardingSelectAllThatApply => 'Select all that apply';

  @override
  String get onboardingWhyAreYouLearning => 'Why are you learning?';

  @override
  String get onboardingThisHelpsUsPersonalizeYourExperience =>
      'This helps us personalize your experience';

  @override
  String get onboardingWhatSYourAgeCategory => 'What\'s your age category?';

  @override
  String get onboardingSelectTheLanguageYouWantTo =>
      'Select the language you want to learn';

  @override
  String get onboardingWhatLanguageDoYouWishTo =>
      'What language do you wish to learn first?';

  @override
  String get onboardingXhosa => 'Xhosa';

  @override
  String get onboardingZulu => 'Zulu';

  @override
  String get onboardingSwahili => 'Swahili';

  @override
  String get onboardingNigerianPidginEnglish => 'Nigerian Pidgin English';

  @override
  String get onboardingIgbo => 'Igbo';

  @override
  String get onboardingHausa => 'Hausa';

  @override
  String get onboardingYoruba => 'Yoruba';

  @override
  String get onboardingHelpUsPersonalizeYourLearningExperienc =>
      'Help us personalize your learning experience';

  @override
  String get onboardingWhatSYourCurrentLevel => 'What\'s your current level?';

  @override
  String get onboardingISpeakThisLanguageNatively =>
      'I speak this language natively';

  @override
  String get onboardingNative => 'Native';

  @override
  String get onboardingIMQuiteFluent => 'I\'m quite fluent';

  @override
  String get onboardingAdvanced => 'Advanced';

  @override
  String get onboardingICanHaveBasicConversations =>
      'I can have basic conversations';

  @override
  String get onboardingIntermediate => 'Intermediate';

  @override
  String get onboardingIKnowAFewWords => 'I know a few words';

  @override
  String get onboardingElementary => 'Elementary';

  @override
  String get onboardingIMJustStartingOut => 'I\'m just starting out';

  @override
  String get onboardingBeginner => 'Beginner';

  @override
  String get onboardingContinueToNextStep => 'Continue to next step';

  @override
  String get onboardingSearchLanguages => 'Search languages...';

  @override
  String get onboardingSearchLanguagesea93 => 'Search languages';

  @override
  String get onboardingAllLanguages => 'All Languages';

  @override
  String onboardingShowAllLanguagesValueMore(String value) {
    return 'Show All Languages ($value more)';
  }

  @override
  String onboardingShowAllLanguagesValueMoreLanguages(String value) {
    return 'Show all languages. $value more languages available.';
  }

  @override
  String onboardingSelectValueAsProficiencyLanguageValue2(
    String value,
    String value2,
  ) {
    return 'Select $value as proficiency language. $value2';
  }

  @override
  String get onboardingPopularLanguages => 'Popular Languages';

  @override
  String get onboardingWeLlTranslateAllInApp =>
      'We\'ll translate all in-app content to this language';

  @override
  String get onboardingWhatLanguageDoYouSpeak => 'What language do you speak?';

  @override
  String get onboardingPolish => 'Polish';

  @override
  String get onboardingDutch => 'Dutch';

  @override
  String get onboardingTurkish => 'Turkish';

  @override
  String get onboardingRussian => 'Russian';

  @override
  String get onboardingHindi => 'Hindi';

  @override
  String get onboardingKorean => 'Korean';

  @override
  String get onboardingJapanese => 'Japanese';

  @override
  String get onboardingChinese => 'Chinese';

  @override
  String get onboardingItalian => 'Italian';

  @override
  String get onboardingGerman => 'German';

  @override
  String get onboardingBerber => 'Berber';

  @override
  String get onboardingArabic => 'Arabic';

  @override
  String get onboardingSango => 'Sango';

  @override
  String get onboardingKongo => 'Kongo';

  @override
  String get onboardingLingala => 'Lingala';

  @override
  String get onboardingChichewa => 'Chichewa';

  @override
  String get onboardingNdebele => 'Ndebele';

  @override
  String get onboardingSwati => 'Swati';

  @override
  String get onboardingTsonga => 'Tsonga';

  @override
  String get onboardingVenda => 'Venda';

  @override
  String get onboardingSetswana => 'Setswana';

  @override
  String get onboardingSesotho => 'Sesotho';

  @override
  String get onboardingAfrikaans => 'Afrikaans';

  @override
  String get onboardingSomali => 'Somali';

  @override
  String get onboardingOromo => 'Oromo';

  @override
  String get onboardingTigrinya => 'Tigrinya';

  @override
  String get onboardingAmharic => 'Amharic';

  @override
  String get onboardingKirundi => 'Kirundi';

  @override
  String get onboardingKinyarwanda => 'Kinyarwanda';

  @override
  String get onboardingLuganda => 'Luganda';

  @override
  String get onboardingLuo => 'Luo';

  @override
  String get onboardingKikuyu => 'Kikuyu';

  @override
  String get onboardingFon => 'Fon';

  @override
  String get onboardingEwe => 'Ewe';

  @override
  String get onboardingAkan => 'Akan';

  @override
  String get onboardingBambara => 'Bambara';

  @override
  String get onboardingFulfulde => 'Fulfulde';

  @override
  String get onboardingTwi => 'Twi';

  @override
  String get onboardingWolof => 'Wolof';

  @override
  String get onboardingNigerianPidgin => 'Nigerian Pidgin';

  @override
  String get onboardingSpanish => 'Spanish';

  @override
  String get onboardingPortuguese => 'Portuguese';

  @override
  String get onboardingFrench => 'French';

  @override
  String get onboardingEnglish => 'English';

  @override
  String get onboardingTakeTest => 'Take Test';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String onboardingWouldYouLikeToTakeA(String learningLanguage) {
    return 'Would you like to take a placement test to assess your current level in $learningLanguage? You can skip this and take it later.';
  }

  @override
  String get onboardingTakePlacementTest => 'Take Placement Test?';

  @override
  String onboardingProgresspercent(String progressPercent) {
    return '$progressPercent%';
  }

  @override
  String onboardingStepValueOfTotalsteps(String value, String totalSteps) {
    return 'Step $value of $totalSteps';
  }

  @override
  String get onboardingSkipOnboarding => 'Skip onboarding';

  @override
  String get onboardingOnboarding => 'Onboarding';

  @override
  String get onboardingGoBackToPreviousStep => 'Go back to previous step';

  @override
  String onboardingOnboardingProgressStepValueOfTotalstep(
    String value,
    String totalSteps,
    String progressPercent,
  ) {
    return 'Onboarding progress. Step $value of $totalSteps. $progressPercent percent complete.';
  }

  @override
  String get onboardingSkipTest => 'Skip test';

  @override
  String onboardingQuestionValueOfTotalquestions(
    String value,
    String totalQuestions,
  ) {
    return 'Question $value of $totalQuestions';
  }

  @override
  String get onboardingSkipForNowStartAsBeginner =>
      'Skip for now (start as beginner)';

  @override
  String get onboardingStartAssessment => 'Start Assessment';

  @override
  String get onboardingAnswer3QuickQuestionsToHelp =>
      'Answer 3 quick questions to help us personalize your learning journey.';

  @override
  String get onboardingLetUsSeeWhereYouStand =>
      'Let us see where you stand, traveler.';

  @override
  String get onboardingUnderstandComplexDiscussions =>
      'Understand complex discussions';

  @override
  String get onboardingUnderstandMostEverydayConversations =>
      'Understand most everyday conversations';

  @override
  String get onboardingUnderstandShortSimpleConversations =>
      'Understand short, simple conversations';

  @override
  String get onboardingUnderstandGreetingsAndSimpleWords =>
      'Understand greetings and simple words';

  @override
  String get onboardingCannotUnderstandAnything => 'Cannot understand anything';

  @override
  String get onboardingHowConfidentAreYouInUnderstanding =>
      'How confident are you in understanding spoken African languages?';

  @override
  String get onboardingICanReadFluently => 'I can read fluently';

  @override
  String get onboardingICanReadSentences => 'I can read sentences';

  @override
  String get onboardingICanReadSimpleWords => 'I can read simple words';

  @override
  String get onboardingICanRecognizeSomeLettersCharacters =>
      'I can recognize some letters/characters';

  @override
  String get onboardingNotAtAll => 'Not at all';

  @override
  String get onboardingCanYouReadOrWriteIn =>
      'Can you read or write in the African language you want to learn?';

  @override
  String get onboardingAdvancedSpeakFluently => 'Advanced - speak fluently';

  @override
  String get onboardingIntermediateCanHoldConversations =>
      'Intermediate - can hold conversations';

  @override
  String get onboardingBasicCanIntroduceMyself =>
      'Basic - can introduce myself';

  @override
  String get onboardingSomeExposureKnowAFewWords =>
      'Some exposure - know a few words';

  @override
  String get onboardingCompleteBeginnerNeverLearnedOne =>
      'Complete beginner - never learned one';

  @override
  String get onboardingHowWouldYouDescribeYourFamiliarity =>
      'How would you describe your familiarity with African languages?';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingEnterYourUsername => 'Enter your username';

  @override
  String get onboardingALearnerWithoutANameIs =>
      'A learner without a name is a drum without a rhythm!\nTell us what you wish to be called.';

  @override
  String get onboardingBuildYourClan => 'Build your clan.';

  @override
  String get onboardingIAmTheHealerLetMe =>
      'I am the Healer.\nLet me make your journey smooth.';

  @override
  String get onboardingGamification => 'Gamification';

  @override
  String get onboardingTonePreference => 'Tone Preference';

  @override
  String get onboardingIAmAminaTheGriotHow =>
      'I am Amina the Griot.\nHow shall I speak to you?';

  @override
  String get onboardingChooseYourPath => 'Choose your path.';

  @override
  String get onboardingBrainTraining => 'Brain Training';

  @override
  String get onboardingConfidence => 'Confidence';

  @override
  String get onboardingAcademic => 'Academic';

  @override
  String get onboardingBusiness => 'Business';

  @override
  String get onboardingHeritage => 'Heritage';

  @override
  String get onboardingTravel => 'Travel';

  @override
  String get onboardingIAmZawadiKeeperOfTime =>
      'I am Zawadi, keeper of time.\nWhen shall we train your tongue?';

  @override
  String get onboardingIAmNuruTheRhythmMaster =>
      'I am Nuru the Rhythm Master.\nTap the drum that sings to your spirit.';

  @override
  String get onboardingWhatSYourLevel => 'What\'s your level?';

  @override
  String get onboardingSelectLanguage => 'Select Language';

  @override
  String get onboardingIAmAdisaTheWeaverChoose =>
      'I am Adisa, the Weaver.\nChoose the threads of your voice.';

  @override
  String get onboardingTellMeWhoAreYou => 'Tell me: who are you?';

  @override
  String get onboardingWelcomeTravelerIAmPaLingafriq =>
      'Welcome, traveler. I am Pa LingAfriq,\nkeeper of the village memory.';

  @override
  String get onboardingBeginJourney => 'Begin Journey';

  @override
  String get onboardingTheLanguageVillageYourJourneyBegins =>
      'The Language Village\nYour journey begins here';

  @override
  String get onboardingWelcomeToKijijiChaLugha =>
      'Welcome to\nKijiji cha Lugha';

  @override
  String get onboardingLoading => 'Loading...';

  @override
  String get onboardingAlreadyLearningLogIn => 'Already learning? Log in';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingChooseYourPathAndUnlockNew =>
      'Choose your path and unlock new opportunities';

  @override
  String get onboardingYourLanguageJourneyStartsHere =>
      'Your Language Journey\nStarts Here!';

  @override
  String get onboardingPrioritizeHowYourCommunityReallySpeaks =>
      'Prioritize how your community really speaks';

  @override
  String get onboardingLocalDialectHeritage => 'Local Dialect & Heritage';

  @override
  String get onboardingPrepareForStudiesAndBroadenKnowledge =>
      'Prepare for studies and broaden knowledge';

  @override
  String get onboardingExcelAcademically => 'Excel Academically';

  @override
  String get onboardingOpenDoorsToInternationalOpportunities =>
      'Open doors to international opportunities';

  @override
  String get onboardingBoostYourCareer => 'Boost Your Career';

  @override
  String get onboardingDiscoverTheRichHeritageOfAfrican =>
      'Discover the rich heritage of African languages';

  @override
  String get onboardingExploreCultures => 'Explore Cultures';

  @override
  String get onboardingExplore54Countries2000LanguagesAnd =>
      'Explore 54 countries, 2000+ languages,\nand connect with 1+ billion voices';

  @override
  String get onboardingReadyForAPanAfricanAdventure =>
      'Ready for a\npan-African adventure?';

  @override
  String get onboardingLearnANewLanguageTheFun =>
      'Learn a new language,\nthe fun way';

  @override
  String get onboardingLearnAboutHistoryTraditionsAndCultural =>
      'Learn about history, traditions, and cultural expressions';

  @override
  String get onboardingConnectWithCulture => 'Connect with culture';

  @override
  String get onboardingStayMotivatedWithPersonalizedChallenge =>
      'Stay motivated with personalized challenges and daily goals';

  @override
  String get onboardingTrackYourProgress => 'Track your progress';

  @override
  String get onboardingFunBiteSizedLessonsMakeLearning =>
      'Fun, bite-sized lessons make learning addictive and effective';

  @override
  String get onboardingLearnLanguagesPlayGames => 'Learn languages, play games';

  @override
  String get onboardingDiscoverTheBeautyOfAfricanLanguages =>
      'Discover the beauty of African languages';

  @override
  String get onboardingYourJourneyToFluencyStartsNow =>
      'Your journey to fluency\nstarts now!';

  @override
  String get onboardingWhatDoWeOfferUniqely => 'What Do We Offer Uniqely';

  @override
  String get onboardingText54Countries2000Languages1Billion =>
      '54 countries, 2000+ languages, 1+ billion voices. One origin. ';

  @override
  String onboardingValueValue2(String value, String value2) {
    return '$value / $value2';
  }

  @override
  String get onboardingPlacementTest => 'Placement Test';

  @override
  String get onboardingGoBack => 'Go Back';

  @override
  String get onboardingPleaseTryAgainLater => 'Please try again later.';

  @override
  String get onboardingPlacementQuestionsAreNotAvailableRight =>
      'Placement questions are not available right now.';

  @override
  String get onboardingLoadingPlacementTest => 'Loading placement test...';

  @override
  String get onboardingAreasForImprovement => 'Areas for Improvement';

  @override
  String get onboardingYourProficiencyLevel => 'Your Proficiency Level';

  @override
  String get onboardingPlacementTestComplete => 'Placement Test Complete!';

  @override
  String get onboardingPrevious => 'Previous';

  @override
  String get onboardingYourAnswer => 'Your Answer';

  @override
  String get onboardingSelected => 'Selected';

  @override
  String onboardingAnswerOptionOptionValue(String option, String value) {
    return 'Answer option: $option$value';
  }

  @override
  String onboardingQuestionValueOfValue2(String value, String value2) {
    return 'Question $value of $value2';
  }

  @override
  String onboardingValueOfValue2(String value, String value2) {
    return '$value of $value2';
  }

  @override
  String onboardingProgressQuestionValueOfValue2(String value, String value2) {
    return 'Progress: question $value of $value2';
  }

  @override
  String get onboardingLoadingTest => 'Loading test...';

  @override
  String get onboardingTryAgain => 'Try Again';

  @override
  String get onboardingContinueWithoutTest => 'Continue Without Test';

  @override
  String get onboardingWeCouldnTConnectToThe =>
      'We couldn\'t connect to the server to generate your placement test. You can continue without it and take it later from your profile.';

  @override
  String get onboardingUnableToGeneratePlacementTest =>
      'Unable to Generate Placement Test';

  @override
  String get onboardingGeneratingYourPlacementTest =>
      'Generating your placement test...';

  @override
  String get onboardingPleaseAnswerAllQuestions =>
      'Please answer all questions';

  @override
  String get onboardingEngageWithNativeContent => 'Engage with native content';

  @override
  String get onboardingFocusOnFluencyAndNuance => 'Focus on fluency and nuance';

  @override
  String get onboardingAdvancedLessonsRecommended =>
      'Advanced lessons recommended';

  @override
  String get onboardingExpandVocabularyInSpecificTopics =>
      'Expand vocabulary in specific topics';

  @override
  String get onboardingPracticeConversationSkills =>
      'Practice conversation skills';

  @override
  String get onboardingContinueWithIntermediateContent =>
      'Continue with intermediate content';

  @override
  String get onboardingPracticePronunciationDaily =>
      'Practice pronunciation daily';

  @override
  String get onboardingFocusOnVocabularyBuilding =>
      'Focus on vocabulary building';

  @override
  String get onboardingStartWithBeginnerLessons =>
      'Start with beginner lessons';

  @override
  String get onboardingStartWithTheFirstLessonsA =>
      'Start with the first lessons. A level waits until calibrated items are available.';

  @override
  String get onboardingSomeGrammarConceptsNeedReview =>
      'Some grammar concepts need review';

  @override
  String get onboardingGrammarFundamentalsNeeded =>
      'Grammar fundamentals needed';

  @override
  String get onboardingNeedToBuildVocabulary => 'Need to build vocabulary';

  @override
  String get onboardingWillingnessToLearn => 'Willingness to learn';

  @override
  String get onboardingBasicVocabularyKnowledge => 'Basic vocabulary knowledge';

  @override
  String get onboardingGoodUnderstandingOfBasicGrammar =>
      'Good understanding of basic grammar';

  @override
  String get onboardingStrongVocabularyFoundation =>
      'Strong vocabulary foundation';

  @override
  String get onboardingAPreciseLevelNeedsMoreCalibrated =>
      'A precise level needs more calibrated items';

  @override
  String get onboardingKeepLearningMyParentWillAdd =>
      'Keep learning. My parent will add it later';

  @override
  String get onboardingParentSEmail => 'Parent\'s email';

  @override
  String get onboardingAParentOrGuardianSaysYes =>
      'A parent or guardian says yes before you chat or share. Add their email so they can approve your account.';

  @override
  String get onboardingAskAParent => 'Ask a parent';

  @override
  String get onboardingYourProfileStaysPrivateAndAdults =>
      'Your profile stays private, and adults cannot send you direct messages.';

  @override
  String get onboardingTypeItInstead => 'Type it instead';

  @override
  String onboardingValue(String value) {
    return '$value';
  }

  @override
  String get onboardingSwipeUpOrDownToChange =>
      'Swipe up or down to change the year';

  @override
  String get onboardingBirthYear => 'Birth year';

  @override
  String get onboardingUseTheYearWheel => 'Use the year wheel';

  @override
  String onboardingForExampleValue(String value) {
    return 'For example $value';
  }

  @override
  String get onboardingThisHelpsUsKeepLingafriqRight =>
      'This helps us keep LingAfriq right for you. We only ask for the year.';

  @override
  String onboardingMinutesMin(String minutes) {
    return '$minutes min';
  }

  @override
  String get onboardingYouCanChangeThisAnyTime =>
      'You can change this any time in Settings.';

  @override
  String get onboardingHowMuchTimeADayFeels =>
      'How much time a day feels right?';

  @override
  String get onboardingForATripOrABig => 'For a trip or a big day soon';

  @override
  String get onboardingHoldAShortChatInWeeks => 'Hold a short chat in weeks';

  @override
  String get onboardingAGoodDailyStart => 'A good daily start';

  @override
  String get onboardingAGreetingADay => 'A greeting a day';

  @override
  String get onboardingCanTSpeakNow => 'Can\'t speak now';

  @override
  String get onboardingISaidIt => 'I said it';

  @override
  String onboardingMarkThatYouSaidValue(String value) {
    return 'Mark that you said $value';
  }

  @override
  String get onboardingSayItWithPolie => 'Say it with Polie';

  @override
  String get onboardingTapTheGreeting => 'Tap the greeting';

  @override
  String get onboardingWeCouldNotPlaySoundRight =>
      'We could not play sound right now. You can still continue.';

  @override
  String get onboardingPlayGreeting => 'Play greeting';

  @override
  String get onboardingAudioUnavailable => 'Audio unavailable';

  @override
  String get onboardingHeardIt => 'Heard it';

  @override
  String onboardingPlayGreetingValue(String value) {
    return 'Play greeting $value';
  }

  @override
  String get onboardingPlayingGreeting => 'Playing greeting';

  @override
  String get onboardingGreetingPlayed => 'Greeting played';

  @override
  String onboardingHearValue(String value) {
    return 'Hear: $value';
  }

  @override
  String onboardingA60SecondTasteOfValue(String value) {
    return 'A 60-second taste of $value. Hear, tap, say.';
  }

  @override
  String get onboardingYourFirstWin => 'Your first win';

  @override
  String get onboardingLessonDone => 'Lesson done';

  @override
  String get onboardingNewWord => 'New word';

  @override
  String get onboardingCelebrateProgressNotPerfection =>
      'Celebrate progress, not perfection.';

  @override
  String get onboardingYouDidIt => 'You did it!';

  @override
  String get onboardingKeepGoing => 'Keep going';

  @override
  String get onboardingInaKwana => 'Ina kwana';

  @override
  String onboardingWordsWordsInYourBasket(String words) {
    return '$words words in your basket';
  }

  @override
  String get onboardingPolieIsKeepingYourSeatIn =>
      'Polie is keeping your seat in the village.';

  @override
  String get onboardingKB => 'Ẹ kú àbọ̀';

  @override
  String get onboardingText => 'እንኳን ደህና መጡ';

  @override
  String get onboardingHowFar => 'How far?';

  @override
  String get onboardingDalalAkJMm => 'Dalal ak jàmm';

  @override
  String onboardingValueValue26468(String value, String value2) {
    return '$value · $value2';
  }

  @override
  String get onboardingTryARegionAScriptName =>
      'Try a region, a script name, or clear the box.';

  @override
  String get onboardingNoLanguagesMatchThatSearch =>
      'No languages match that search.';

  @override
  String get onboardingNoLanguagesMatchYourSearch =>
      'No languages match your search';

  @override
  String get onboardingISpeak => 'I speak';

  @override
  String get onboardingWhatDoYouWantToLearn => 'What do you want to learn?';

  @override
  String get onboardingNorthAfrica => 'North Africa';

  @override
  String get onboardingText526f => 'ⵜⴰⵎⴰⵣⵉⵖⵜ';

  @override
  String get onboardingTamazight => 'Tamazight';

  @override
  String get onboardingTextd271 => 'الدارجة';

  @override
  String get onboardingDarija => 'Darija';

  @override
  String get onboardingSouthernAfrica => 'Southern Africa';

  @override
  String get onboardingIsixhosa => 'isiXhosa';

  @override
  String get onboardingIsizulu => 'isiZulu';

  @override
  String get onboardingEastAfrica => 'East Africa';

  @override
  String get onboardingText91cf => 'አማርኛ';

  @override
  String get onboardingKiswahili => 'Kiswahili';

  @override
  String get onboardingWestAfrica => 'West Africa';

  @override
  String get onboardingNaij => 'Naijá';

  @override
  String get onboardingAsSIgbo => 'Asụsụ Igbo';

  @override
  String get onboardingDYorB => 'Èdè Yorùbá';

  @override
  String get onboardingText9970 => 'العربية';

  @override
  String get onboardingPortuguS => 'Português';

  @override
  String get onboardingFranAis => 'Français';

  @override
  String get onboardingPickTheStyleThatFeelsMost =>
      'Pick the style that feels most natural.';

  @override
  String get onboardingVarietyOfMethods => 'Variety of methods';

  @override
  String get onboardingMixed => 'Mixed';

  @override
  String get onboardingTalkToLearn => 'Talk to learn';

  @override
  String get onboardingConversation => 'Conversation';

  @override
  String get onboardingRepetitionDrills => 'Repetition & drills';

  @override
  String get onboardingPractice => 'Practice';

  @override
  String get onboardingNarrativeLearning => 'Narrative learning';

  @override
  String get onboardingStories => 'Stories';

  @override
  String get onboardingSeeToRemember => 'See to remember';

  @override
  String get onboardingVisual => 'Visual';

  @override
  String get onboardingLearnByEar => 'Learn by ear';

  @override
  String get onboardingListening => 'Listening';

  @override
  String get onboardingKR => 'Ẹ káàárọ̀';

  @override
  String get onboardingNaGode => 'Na gode';

  @override
  String get onboardingQuickCheckTapEachWordYou =>
      'Quick check: tap each word you recognize.';

  @override
  String get onboardingNotSureTakeA1Minute => 'Not sure? Take a 1‑minute check';

  @override
  String onboardingHowMuchLangnameDoYouKnow(String langName) {
    return 'How much $langName do you know?';
  }

  @override
  String get onboardingThisLanguage => 'this language';

  @override
  String get onboardingICanHoldAConversation => 'I can hold a conversation';

  @override
  String get onboardingICanTalkAboutVariousTopics =>
      'I can talk about various topics';

  @override
  String get onboardingIKnowSomeCommonWords => 'I know some common words';

  @override
  String get onboardingIMNew => 'I\'m new';

  @override
  String get onboardingBestTime => 'Best time';

  @override
  String get onboardingSeeTheReminderBelowTurnIt =>
      'See the reminder below. Turn it on only if it helps you keep your streak. You pick the time.';

  @override
  String get onboardingASoftNudgeWhenItMatters =>
      'A soft nudge when it matters';

  @override
  String get onboardingNotNow => 'Not now';

  @override
  String get onboardingTurnOnReminders => 'Turn on reminders';

  @override
  String onboardingDailyminutesMinutes(String dailyMinutes) {
    return '$dailyMinutes minutes';
  }

  @override
  String get onboardingText5Minutes => '5 minutes';

  @override
  String get onboardingText810Pm => '8–10 PM';

  @override
  String get onboardingNight => 'Night';

  @override
  String get onboardingText57Pm => '5–7 PM';

  @override
  String get onboardingSunset => 'Sunset';

  @override
  String get onboardingText122Pm => '12–2 PM';

  @override
  String get onboardingMidday => 'Midday';

  @override
  String get onboardingText69Am => '6–9 AM';

  @override
  String get onboardingSunrise => 'Sunrise';

  @override
  String onboardingPreviewHowYouAppearInThe(String shown) {
    return 'Preview: how you appear in the village, $shown';
  }

  @override
  String get onboardingYourName => 'Your name';

  @override
  String get onboardingWeCouldnTCheckThatJust =>
      'We couldn\'t check that just now, but you can still continue';

  @override
  String get onboardingOnlyLettersNumbersAndUnderscoresPlease =>
      'Only letters, numbers, and underscores, please';

  @override
  String get onboardingKeepItTo30CharactersOr =>
      'Keep it to 30 characters or fewer';

  @override
  String get onboardingNeedsAtLeast3Characters => 'Needs at least 3 characters';

  @override
  String get onboardingSomeoneSAlreadyUsingThatOne =>
      'Someone\'s already using that one, try another';

  @override
  String get onboardingThatNameIsYours => 'That name is yours';

  @override
  String get onboardingCheckingIfThatNameIsFree =>
      'Checking if that name is free…';

  @override
  String get onboardingUse3To30LettersNumbers =>
      'Use 3 to 30 letters, numbers, or underscores';

  @override
  String onboardingUseTheNameIdea(String idea) {
    return 'Use the name $idea';
  }

  @override
  String get onboardingIdeasFromYourLanguage => 'Ideas from your language';

  @override
  String get onboardingAddAPhotoOptional => 'Add a photo (optional)';

  @override
  String get onboardingAddAProfilePhotoOptional =>
      'Add a profile photo, optional';

  @override
  String get onboardingALearnerWithoutANameIs56f4 =>
      'A learner without a name is a drum without a rhythm.';

  @override
  String get onboardingPickAName => 'Pick a name';

  @override
  String get onboardingSkipForNow => 'Skip for now';

  @override
  String get onboardingCompleteSetup => 'Complete setup';

  @override
  String get onboardingPickAllThatFitYourFirst =>
      'Pick all that fit. Your first lessons follow your answer.';

  @override
  String onboardingWhyAreYouLearningLanguagename(String languageName) {
    return 'Why are you learning $languageName?';
  }

  @override
  String get onboardingColleaguesClientsAndCommunity =>
      'Colleagues, clients and community';

  @override
  String get onboardingMarketsDirectionsAndSmallTalk =>
      'Markets, directions and small talk';

  @override
  String get onboardingProverbsNamesMusicAndStories =>
      'Proverbs, names, music and stories';

  @override
  String get onboardingHeritageAndCulture => 'Heritage and culture';

  @override
  String get onboardingGreetEldersAndKeepUpAt =>
      'Greet elders and keep up at gatherings';

  @override
  String get onboardingTalkToFamily => 'Talk to family';

  @override
  String get onboardingRetry => 'Retry';

  @override
  String get onboardingYouReOfflineYourAnswersAre =>
      'You\'re offline. Your answers are saved on this phone. Connect, then try again.';

  @override
  String get onboardingCouldnTReachSignIn => 'Couldn\'t reach sign-in';

  @override
  String get onboardingError => 'Error';

  @override
  String get onboardingSavingYourProgress => 'Saving your progress…';

  @override
  String get onboardingIAlreadyHaveAnAccount => 'I already have an account';

  @override
  String get onboardingSignUpWithEmail => 'Sign up with email';

  @override
  String get onboardingContinueWithApple => 'Continue with Apple';

  @override
  String get onboardingContinueWithGoogle => 'Continue with Google';

  @override
  String onboardingYouFinishedYourFirstLessonAnd(String words) {
    return 'You finished your first lesson and learned $words. An account keeps your progress safe if you change phones.';
  }

  @override
  String get onboardingSaveYourProgress => 'Save your progress?';

  @override
  String get onboardingLaterMyAnswersStayOnThis =>
      'Later. My answers stay on this phone';

  @override
  String onboardingWordslearnedWords(String wordsLearned) {
    return '$wordsLearned words';
  }

  @override
  String get onboardingYouReOfflineKeepGoingYour =>
      'You\'re offline. Keep going: your answers are saved on this phone and sync when you reconnect.';

  @override
  String get onboardingDoubleTapToChoose => 'Double tap to choose';

  @override
  String get onboardingSaving => 'Saving…';

  @override
  String get onboardingHowMuchGameFeel => 'How much game feel?';

  @override
  String get onboardingPickTheVoiceThatFeelsLike =>
      'Pick the voice that feels like a good study buddy.';

  @override
  String get onboardingHowShouldPolieSound => 'How should Polie sound?';

  @override
  String get onboardingJustLearning => 'Just learning';

  @override
  String get onboardingMinimal => 'Minimal';

  @override
  String get onboardingProgressTracking => 'Progress tracking';

  @override
  String get onboardingModerate => 'Moderate';

  @override
  String get onboardingXpBadgesStreaks => 'XP, badges, streaks';

  @override
  String get onboardingFull => 'Full';

  @override
  String get onboardingWarmCasual => 'Warm & casual';

  @override
  String get onboardingFriendly => 'Friendly';

  @override
  String get onboardingDirectEfficient => 'Direct & efficient';

  @override
  String get onboardingFocused => 'Focused';

  @override
  String get onboardingSupportive => 'Supportive';

  @override
  String get onboardingEncouraging => 'Encouraging';

  @override
  String get onboardingFunLight => 'Fun & light';

  @override
  String get onboardingPlayful => 'Playful';

  @override
  String get onboardingGetStarted90e4 => 'Get started';

  @override
  String get onboardingWorksOfflineAbout2MbPer =>
      'Works offline · about 2 MB per unit';

  @override
  String get onboardingWorksOfflineAbout2MegabytesPer =>
      'Works offline, about 2 megabytes per unit';

  @override
  String get onboardingShortLessonsWithPolieHearTap =>
      'Short lessons with Polie. Hear, tap, and say real phrases.';

  @override
  String get onboardingTheLanguageVillageThatGetsYou =>
      'The language village that gets you speaking.';

  @override
  String get onboardingLingafriq => 'LingAfriq';

  @override
  String get onboardingWelcomeTo => 'Welcome to';

  @override
  String get onboardingKBSannuNnKaribuAkwaaba =>
      'Ẹ kú àbọ̀ · Sannu · Nnọọ · Karibu · Akwaaba';

  @override
  String get onboardingPolieGreetsYouWelcomeInYoruba =>
      'Polie greets you: welcome, in Yoruba, Hausa, Igbo, Swahili and Twi.';

  @override
  String get onboardingLingafriqSpeakAfricanLanguagesWithConf =>
      'LingAfriq. Speak African languages with confidence. Learn with Polie. Works offline.';

  @override
  String onboardingStepValueOfTotal(String value, String total) {
    return 'Step $value of $total';
  }

  @override
  String get onboardingOnboardingProgress => 'Onboarding progress';

  @override
  String get onboardingGoBackToThePreviousStep =>
      'Go back to the previous step';

  @override
  String get onboardingTakeTheTest => 'Take the test';

  @override
  String get onboardingMaybeLater => 'Maybe later';

  @override
  String onboardingWeLlAskAFewShort(String learningLanguage) {
    return 'We\'ll ask a few short questions to find your starting level in $learningLanguage. You can always take it later from your profile.';
  }

  @override
  String get onboardingTakeAQuickPlacementTest =>
      'Take a quick placement test?';

  @override
  String get onboardingYouReOfflineRightNowBut =>
      'You\'re offline right now, but we\'ve saved your answers and will sync them the moment you reconnect.';

  @override
  String get onboardingKR5MinutesOfYoruba => 'Ẹ kú àárọ̀! 5 minutes of Yoruba?';

  @override
  String get onboardingBWoHello => 'Báwo, Hello';

  @override
  String get onboardingBWoNi => 'Báwo ni';

  @override
  String get onboardingSawubona5MinutesOfZulu => 'Sawubona! 5 minutes of Zulu?';

  @override
  String get onboardingSawubonaHello => 'Sawubona, Hello';

  @override
  String get onboardingText5MinutesOfAmharic => 'ሰላም! 5 minutes of Amharic?';

  @override
  String get onboardingHello => 'ሰላም, Hello';

  @override
  String get onboardingHabari5MinutesOfSwahili =>
      'Habari! 5 minutes of Swahili?';

  @override
  String get onboardingHabariHello => 'Habari, Hello';

  @override
  String get onboardingNdewo5MinutesOfIgbo => 'Ndewo! 5 minutes of Igbo?';

  @override
  String get onboardingNdewoHello => 'Ndewo, Hello';

  @override
  String get onboardingSannu5MinutesOfHausa => 'Sannu! 5 minutes of Hausa?';

  @override
  String get onboardingSannuHello => 'Sannu, Hello';

  @override
  String get onboardingTheAncestorsSmileUponYourDedication =>
      'The ancestors smile upon your dedication.';

  @override
  String get onboardingMayYourJourneyBeFilledWith =>
      'May your journey be filled with discovery.';

  @override
  String get onboardingVillageElder => 'Village Elder';

  @override
  String get onboardingPaLingafriq => 'Pa LingAfriq';

  @override
  String get onboardingChooseWiselyItWillBeKnown =>
      'Choose wisely — it will be known across the village.';

  @override
  String get onboardingEveryVillagerMustHaveAName =>
      'Every villager must have a name.';

  @override
  String get onboardingNowItIsTimeForYour =>
      'Now it is time for your naming ceremony.';

  @override
  String get onboardingHowDoesYourSpiritBestReceive =>
      'How does your spirit best receive knowledge?';

  @override
  String get onboardingEachSoulDancesDifferentlyToThe =>
      'Each soul dances differently to the rhythm of words.';

  @override
  String get onboardingLanguageIsMusicTraveler =>
      'Language is music, traveler!';

  @override
  String get onboardingTheRhythmMaster => 'The Rhythm Master';

  @override
  String get onboardingForInEveryWordLiesThe =>
      'For in every word lies the wisdom of generations.';

  @override
  String get onboardingLetMeTellYouTheStory =>
      'Let me tell you the story of our languages...';

  @override
  String get onboardingAhANewStudentIAm =>
      'Ah, a new student! I am Amara, the griot.';

  @override
  String get onboardingTheGriot => 'The Griot';

  @override
  String get onboardingHowMuchTimeCanYouDedicate =>
      'How much time can you dedicate each day?';

  @override
  String get onboardingConsistencyIsTheHeartbeatOfLearning =>
      'Consistency is the heartbeat of learning.';

  @override
  String get onboardingIAmKofiKeeperOfTime =>
      'I am Kofi, keeper of time and rhythm.';

  @override
  String get onboardingTheTimekeeper => 'The Timekeeper';

  @override
  String get onboardingWhatBringsYouToLearnThis =>
      'What brings you to learn this beautiful language?';

  @override
  String get onboardingEveryGreatJourneyNeedsADestination =>
      'Every great journey needs a destination.';

  @override
  String get onboardingGreetingsTravelerIAmZuriYour =>
      'Greetings, traveler! I am Zuri, your pathfinder.';

  @override
  String get onboardingThePathfinder => 'The Pathfinder';

  @override
  String get onboardingWhichThreadShallWeWeaveInto =>
      'Which thread shall we weave into your story?';

  @override
  String get onboardingEachLanguageIsAThreadIn =>
      'Each language is a thread in the tapestry of Africa.';

  @override
  String get onboardingIAmAdisaWeaverOfWords =>
      'I am Adisa, weaver of words and keeper of tongues.';

  @override
  String get onboardingTheWeaver => 'The Weaver';

  @override
  String get onboardingYourJourneyToConnectWithYour =>
      'Your journey to connect with your roots begins here.';

  @override
  String get onboardingIAmPaLingafriqGuardianOf =>
      'I am Pa LingAfriq, guardian of our ancestral tongues.';

  @override
  String get onboardingWelcomeYoungOneToOurVillage =>
      'Welcome, young one, to our village of languages.';

  @override
  String get shellLogout => 'Logout';

  @override
  String get shellCancel => 'Cancel';

  @override
  String get shellAreYouSureYouWantTo => 'Are you sure you want to logout?';

  @override
  String get shellSwitchBetweenLightAndDarkTheme =>
      'Switch between light and dark theme';

  @override
  String get shellDarkMode => 'Dark Mode';

  @override
  String get shellFriendQuests => 'Friend Quests';

  @override
  String get shellSocialHub => 'Social Hub';

  @override
  String get shellMicroMentorReports => 'Micro-mentor reports';

  @override
  String get shellPersonaMissions => 'Persona Missions';

  @override
  String get shellHistoricalPersonas => 'Historical Personas';

  @override
  String get shellMyTribes => 'My Tribes';

  @override
  String get shellLanguageVillages => 'Language Villages';

  @override
  String get shellPrivateChat => 'Private Chat';

  @override
  String get shellCommunityFeed => 'Community Feed';

  @override
  String get shellGlobalChat => 'Global Chat';

  @override
  String get shellCreateContent => 'Create Content';

  @override
  String get shellLiveTranslate => 'Live translate';

  @override
  String get shellPointSay => 'Point & Say';

  @override
  String get shellImportMedia => 'Import Media';

  @override
  String get shellCulturalMagazine => 'Cultural Magazine';

  @override
  String get shellCulturalHub => 'Cultural Hub';

  @override
  String get shellAddWordsInVocabularyBuilderTo =>
      'Add words in Vocabulary Builder to start flashcard review.';

  @override
  String get shellPleaseSelectALanguageFirst =>
      'Please select a language first';

  @override
  String get shellFlashcardReview => 'Flashcard Review';

  @override
  String get shellWritingPractice => 'Writing Practice';

  @override
  String get shellListeningPractice => 'Listening Practice';

  @override
  String get shellConversationScenarios => 'Conversation Scenarios';

  @override
  String get shellVocabularyBuilder => 'Vocabulary Builder';

  @override
  String get shellLearningPath => 'Learning Path';

  @override
  String get shellGrammarHub => 'Grammar Hub';

  @override
  String get shellAiChat => 'AI Chat';

  @override
  String get shellTutorMode => 'Tutor Mode';

  @override
  String get shellNativeContentReview => 'Native content review';

  @override
  String get shellAuthenticPathA1C1 => 'Authentic Path (A1–C1)';

  @override
  String get shellToggleDarkMode => 'Toggle Dark Mode';

  @override
  String shellDarkModeValue(String value) {
    return 'Dark mode $value';
  }

  @override
  String shellTitleSection(String title) {
    return '$title section';
  }

  @override
  String get shellToggleTheme => 'Toggle theme';

  @override
  String get shellDarkMode9cf8 => 'Dark mode';

  @override
  String get shellPracticeRooms => 'Practice Rooms';

  @override
  String get shellLiveClassroom => 'Live Classroom';

  @override
  String get shellDialectPreference => 'Dialect preference';

  @override
  String get shellHeritageMilestones => 'Heritage milestones';

  @override
  String get shellLivingDictionary => 'Living Dictionary';

  @override
  String get shellToneRhythm => 'Tone & Rhythm';

  @override
  String get shellPhraseDna => 'Phrase DNA';

  @override
  String get shellPolieTutor => 'Polie Tutor';

  @override
  String shellEmailValue(String value) {
    return 'Email: $value';
  }

  @override
  String shellUsernameValue(String value) {
    return 'Username: $value';
  }

  @override
  String get shellUserAvatar => 'User avatar';

  @override
  String shellLessonsCompletedValuePointsEarnedValue2(
    String value,
    String value2,
  ) {
    return 'Lessons completed: $value • Points earned: $value2';
  }

  @override
  String get shellLoadingCourses => 'Loading Courses ...';

  @override
  String get shellStartACourseToSeeYour =>
      'Start a course to see your progress';

  @override
  String get shellNoCourseStartedYet => 'No Course started yet';

  @override
  String shellHiValue(String value) {
    return 'Hi $value';
  }

  @override
  String get shellYourCourses => 'Your Courses!';

  @override
  String shellValue(String value) {
    return '$value%';
  }

  @override
  String get shellProgress => 'Progress';

  @override
  String shellProgressValue(String value) {
    return 'Progress $value%';
  }

  @override
  String shellLessonsCompletedValuePointsValue2(String value, String value2) {
    return 'Lessons completed: $value • Points: $value2';
  }

  @override
  String shellValueValue2CompleteTapToOpen(String value, String value2) {
    return '$value, $value2% complete. Tap to open.';
  }

  @override
  String get shellLoadingCourses7098 => 'Loading Courses...';

  @override
  String get shellNoLanguagesAvailable => 'No languages available';

  @override
  String get shellYourProgress => 'Your Progress';

  @override
  String get shellMenu => 'Menu';

  @override
  String get shellOpenMenu => 'Open menu';

  @override
  String get shellYourCourses9648 => 'Your Courses';

  @override
  String get shellNangaDef => 'Nanga def';

  @override
  String get shellHowFar => 'How far';

  @override
  String get shellAsSIgbo => 'Asụsụ Igbo';

  @override
  String get shellHarshenHausa => 'Harshen Hausa';

  @override
  String get shellKB => 'Ẹ káàbọ̀';

  @override
  String shellValueTapToOpen(String value) {
    return '$value. Tap to open.';
  }

  @override
  String shellLabelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String shellTitleSubtitle(String title, String subtitle) {
    return '$title. $subtitle';
  }

  @override
  String get shellViewDashboard => 'View dashboard';

  @override
  String get shellConversationWithPolie => 'Conversation with Polie';

  @override
  String get shellPolieModesSkills => 'Polie modes & skills';

  @override
  String get shellAiTutor => 'AI Tutor';

  @override
  String get shellQuickActions => 'Quick Actions';

  @override
  String shellValueLanguages(String value) {
    return '$value languages';
  }

  @override
  String shellValueBadges(String value) {
    return '$value badges';
  }

  @override
  String shellValueDayStreak(String value) {
    return '$value day streak';
  }

  @override
  String shellValueXpToNextLevel(String value) {
    return '$value XP to next level';
  }

  @override
  String shellXpValue(String value) {
    return 'XP $value';
  }

  @override
  String get shellLevel => 'Level';

  @override
  String shellValue75ce(String value) {
    return '$value';
  }

  @override
  String shellLevelValueXpValue2Value3Xp(
    String value,
    String value2,
    String value3,
    String value4,
    String value5,
    String value6,
  ) {
    return 'Level $value. XP $value2. $value3 XP to next level. $value4 day streak. $value5 badges. $value6 languages.';
  }

  @override
  String shellTitleValue(String title, String value) {
    return '$title$value';
  }

  @override
  String get shellLoadingLanguages => 'Loading Languages ...';

  @override
  String get shellSearchLanguages => 'Search languages';

  @override
  String get shellExploreMore => 'Explore More';

  @override
  String get shellFeaturedLanguages => 'Featured Languages';

  @override
  String get shellKBd95e => 'Ẹ Káàbọ';

  @override
  String get shellWehcomeO => 'Wehcome o';

  @override
  String get shellSannuDaZuwa => 'Sannu da zuwa';

  @override
  String shellPercent(String percent) {
    return '$percent%';
  }

  @override
  String get shellKBf733 => 'Ẹ Káàbọ̀';

  @override
  String get shellWelcomeO => 'Welcome o';

  @override
  String get shellConnectionTimedOut => 'connection timed out';

  @override
  String get shellConnectionRefused => 'connection refused';

  @override
  String get shellFailedHostLookup => 'failed host lookup';

  @override
  String get shellNetworkIsUnreachable => 'network is unreachable';

  @override
  String get shellNoInternet => 'no internet';

  @override
  String get shellAuthenticPath => 'Authentic Path';

  @override
  String get shellTakeQuiz => 'Take Quiz';

  @override
  String get shellBack => 'Back';

  @override
  String get shellPickWhereYouWantToLearn => 'Pick where you want to learn';

  @override
  String get shellStartLearning => 'Start learning';

  @override
  String shellValuePts(String value) {
    return '$value pts';
  }

  @override
  String get shellTryADifferentSearchTerm => 'Try a different search term';

  @override
  String get shellNoLanguagesFound => 'No languages found';

  @override
  String get shellClearSearch => 'Clear search';

  @override
  String get shellSearchLanguages2580 => 'Search languages...';

  @override
  String shellValuea1d1(String value) {
    return '$value ';
  }

  @override
  String get shellRetry => 'Retry';

  @override
  String get shellFailedToLoadQuizzesPleaseTry =>
      'Failed to load quizzes. Please try again.';

  @override
  String get shellConnectionTimedOut52c8 => 'Connection timed out';

  @override
  String shellWeReWorkingToAddRandom(String value) {
    return 'We\'re working to add random quizzes for $value!';
  }

  @override
  String shellLoadingQuizzesForValue(String value) {
    return 'Loading quizzes for $value...';
  }

  @override
  String get shellChooseAQuizType => 'Choose a quiz type';

  @override
  String get shellAppPolicy => 'App Policy';

  @override
  String get shellChangePassword => 'Change Password';

  @override
  String get shellPasswordChanged => 'Password Changed';

  @override
  String get shellConfirmYourNewPassword => 'Confirm your new password';

  @override
  String get shellConfirmPassword => 'Confirm Password';

  @override
  String get shellEnterNewPassword => 'Enter new password';

  @override
  String get shellNewPassword => 'New Password';

  @override
  String get shellEnterYourCurrentPassword => 'Enter your current password';

  @override
  String get shellCurrentPassword => 'Current Password';

  @override
  String get shellDeleteNow => 'Delete Now';

  @override
  String get shellEnterCurrentPassword => 'Enter Current Password';

  @override
  String get shellConfirmation => 'Confirmation';

  @override
  String get shellYes => 'Yes';

  @override
  String get shellNo => 'No';

  @override
  String get shellAreYouSureYouWantToecc5 =>
      'Are you sure you want to DELETE account?';

  @override
  String get shellAccountDeleted => 'Account Deleted';

  @override
  String get shellThisActionIsPermanent => 'This action is permanent';

  @override
  String get shellDeleteYourAccount => 'Delete your account';

  @override
  String get shellReadHowYourDataIsProtected =>
      'Read how your data is protected';

  @override
  String get shellPrivacyUserPolicy => 'Privacy & User Policy';

  @override
  String get shellLearnAboutTheLingafriqMission =>
      'Learn about the LingAfriq mission';

  @override
  String get shellWhoAreWe => 'Who are we?';

  @override
  String get shellHelpUsImproveLingafriq => 'Help us improve LingAfriq';

  @override
  String get shellGiveUsFeedback => 'Give us Feedback';

  @override
  String get shellUpdateYourCredentialsSecurely =>
      'Update your credentials securely';

  @override
  String shellValue12bd(String value) {
    return '#$value';
  }

  @override
  String shellGlobalRankValue(String value) {
    return 'Global rank: $value';
  }

  @override
  String get shellGlobalRanking => 'Global Ranking';

  @override
  String shellStreakValue(String value) {
    return 'Streak $value';
  }

  @override
  String shellValueXp(String value) {
    return '$value XP';
  }

  @override
  String shellAchievementProgressUnlockedbadgesOutOfTotal(
    String unlockedBadges,
    String totalBadges,
  ) {
    return 'Achievement progress: $unlockedBadges out of $totalBadges badges unlocked';
  }

  @override
  String shellUnlockedbadgesTotalbadges(
    String unlockedBadges,
    String totalBadges,
  ) {
    return '$unlockedBadges/$totalBadges';
  }

  @override
  String get shellAchievements => 'Achievements';

  @override
  String shellLevelValue(String value) {
    return 'Level $value';
  }

  @override
  String shellProfileValueValue2LevelValue3Streak(
    String value,
    String value2,
    String value3,
    String value4,
  ) {
    return 'Profile: $value, $value2, Level $value3, Streak $value4';
  }

  @override
  String get shellProfileAvatarTapToEditProfile =>
      'Profile avatar. Tap to edit profile';

  @override
  String get shellProfile => 'Profile';

  @override
  String get shellSubmit => 'Submit';

  @override
  String get shellFeedbackFormOnMobileApp => 'Feedback Form on Mobile App';

  @override
  String shellLanguageCountryCountry(String country) {
    return 'Language Country:\n$country\n\n';
  }

  @override
  String shellWouldYouLikeToSuggestA(String suggestion) {
    return 'Would you like to suggest a language? If yes, enter language below:\n$suggestion\n\n';
  }

  @override
  String shellWhatWouldYouLikeUsTo(String reason) {
    return 'What would you like us to know:\n$reason\n\n';
  }

  @override
  String get shellPleaseFillInSomeFields => 'Please fill in some fields';

  @override
  String get shellLanguageCountry => 'Language Country';

  @override
  String get shellWriteYourSuggestionHere => 'Write your suggestion here';

  @override
  String get shellWouldYouLikeToSuggestAb06a =>
      'Would you like to suggest a language? If yes, enter language below';

  @override
  String get shellPleaseExplainWhatWouldYouLike =>
      'Please explain What would you like us to know?';

  @override
  String get shellWhatWouldYouLikeUsTo0de8 => 'What would you like us to know?';

  @override
  String get shellStartACourseToSeeYoure3fc =>
      'Start a course to see your country ranking';

  @override
  String get shellNoPointsEarnedYet => 'No points earned yet';

  @override
  String shellSpaceTextSpace2(String space, String text, String space2) {
    return '$space$text$space2';
  }

  @override
  String get shellLoadingLeaderboard => 'Loading Leaderboard...';

  @override
  String get shellCountry => 'Country';

  @override
  String get shellGlobal => 'Global';

  @override
  String shellLeaderboardViewValueSwitchBetweenGlobal(String value) {
    return 'Leaderboard view: $value. Switch between Global and Country.';
  }

  @override
  String get shellLeaderboard => 'Leaderboard';

  @override
  String get shellProfileTab => 'Profile tab';

  @override
  String get shellSocial => 'Social';

  @override
  String get shellSocialTab => 'Social tab';

  @override
  String get shellAi => 'AI';

  @override
  String get shellAiTutorTab => 'AI Tutor tab';

  @override
  String get shellCourses => 'Courses';

  @override
  String get shellCoursesTab => 'Courses tab';

  @override
  String get shellHome => 'Home';

  @override
  String get shellHomeTab => 'Home tab';

  @override
  String get shellBackToLearning => 'Back to learning';

  @override
  String get shellBackToLearningHome => 'Back to learning home';

  @override
  String get shellNotAvailableYet => 'Not available yet';

  @override
  String get shellPrivateMessagesCallsSnapsAndThe =>
      'Private messages, calls, snaps, and the public feed unlock when you are 18 and your age is verified. Until then, keep going on lessons, games, and Polie.';

  @override
  String get shellLearningComesFirst => 'Learning comes first';

  @override
  String onboardingWordsInYourBasket(int words) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words words in your basket',
      one: '1 word in your basket',
    );
    return '$_temp0';
  }

  @override
  String get onboardingNotSelected => 'not selected';

  @override
  String get onboardingAddAvatarOptional => 'Add Avatar (Optional)';

  @override
  String get onboardingLevelNotPreciseYet => 'Level not precise yet';

  @override
  String get onboardingSelectedd7a1 => ', selected';

  @override
  String onboardingUseAYearBetween1900And(String nowYear) {
    return 'Use a year between 1900 and $nowYear.';
  }

  @override
  String get onboardingNiceYouSaidIt => 'Nice, you said it';

  @override
  String get onboardingYouMarkedThePhraseAsSaid =>
      'You marked the phrase as said';

  @override
  String get onboardingFinishLesson => 'Finish lesson';

  @override
  String get onboardingText1Word => '1 word';

  @override
  String shellUsername(String username) {
    return ', $username';
  }

  @override
  String get shellTabToday => 'Today';

  @override
  String get shellTabLearn => 'Learn';

  @override
  String get shellTabSpeak => 'Speak';

  @override
  String get shellTabPlay => 'Play';

  @override
  String get shellTabVillage => 'Village';

  @override
  String get shellMe => 'Me';

  @override
  String get shellSearch => 'Search';

  @override
  String get shellLens => 'Lens';

  @override
  String shellOpenSection(String tab) {
    return 'Open $tab';
  }

  @override
  String shellSectionOpen(String tab) {
    return '$tab is open';
  }

  @override
  String shellSectionLine(int index, String tab) {
    return 'Line $index in $tab';
  }

  @override
  String get shellLinkMissedWhat => 'This link did not open.';

  @override
  String shellLinkMissedWhy(String link) {
    return 'Nothing in the app matches $link.';
  }

  @override
  String shellLinkMissedWhyWithDetail(String link, String detail) {
    return 'Nothing in the app matches $link. $detail';
  }

  @override
  String get shellLinkMissedNext => 'Go back to Today.';

  @override
  String get shellLinkMissedAction => 'Go to Today';

  @override
  String get shellLinkWasEmpty => 'The link was empty.';

  @override
  String get shellOfflineWhat => 'The phone has no network.';

  @override
  String get shellOfflineWhy => 'These tabs are not saved offline.';

  @override
  String get shellOfflineNext => 'Connect, then try again.';

  @override
  String get searchFieldLabel => 'Search words, features, and content';

  @override
  String get searchWords => 'Words';

  @override
  String get searchFeatures => 'Features';

  @override
  String get searchContent => 'Content';

  @override
  String get searchIdleWhat => 'Search is ready.';

  @override
  String get searchIdleWhy => 'The box is empty.';

  @override
  String get searchIdleNext => 'Type a word or a feature name.';

  @override
  String get searchEmptyTitle => 'No match';

  @override
  String searchEmptyWhat(String query) {
    return 'Nothing matches $query.';
  }

  @override
  String get searchEmptyWhy =>
      'That name is not in words, features, or content on this phone.';

  @override
  String get searchEmptyNext => 'Open the directory to see every feature.';

  @override
  String get searchEmptyAction => 'Open the directory';

  @override
  String get searchOfflineLabel =>
      'Offline. Showing results saved on this phone.';

  @override
  String searchUnlockWhat(String feature) {
    return '$feature is not open yet.';
  }

  @override
  String searchUnlockWhy(String stage) {
    return 'It unlocks at $stage.';
  }

  @override
  String get searchUnlockNext => 'Read this preview, then go back.';

  @override
  String get searchPreviewLabel => 'Preview';

  @override
  String get searchBack => 'Back';

  @override
  String searchOpenWord(String word) {
    return 'Open Word Card for $word';
  }

  @override
  String searchOpenFeature(String feature) {
    return 'Open $feature';
  }

  @override
  String searchOpenContent(String title) {
    return 'Open $title';
  }

  @override
  String get hubTodayTitle => 'Today';

  @override
  String get hubTodayLead => 'One plan for today.';

  @override
  String get hubTodayDailyPlan => 'Daily plan';

  @override
  String get hubTodayDailyChallenges => 'Daily Challenges';

  @override
  String get hubTodayQuests => 'Quests';

  @override
  String get hubTodayEvents => 'Events and Festivals';

  @override
  String get hubTodayStreaks => 'Streaks';

  @override
  String get hubTodayBack => 'Back to Today';

  @override
  String hubTodayMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String hubTodayMinutesAbout(int minutes) {
    return 'About $minutes minutes';
  }

  @override
  String get hubTodayDueReviews => 'Due reviews';

  @override
  String get hubTodayNextLesson => 'Next lesson';

  @override
  String get hubTodayStart => 'Start';

  @override
  String hubTodayStartPlan(int minutes) {
    return 'Start the $minutes minute plan';
  }

  @override
  String get hubTodayEmptyTitle => 'No plan yet';

  @override
  String get hubTodayEmptyWhat => 'Today has nothing queued.';

  @override
  String get hubTodayEmptyWhy =>
      'There is no review due, and no lesson is chosen.';

  @override
  String get hubTodayEmptyNext => 'Open Path and start the first lesson.';

  @override
  String get hubTodayOpenPath => 'Open Path';

  @override
  String get hubTodayNotBuiltWhat => 'This part is not available yet.';

  @override
  String get hubTodayNotBuiltWhy => 'It is not built yet.';

  @override
  String get hubTodayNotBuiltNext => 'Go back to Today.';

  @override
  String get hubTodayProviderWhat => 'The daily plan is not available.';

  @override
  String get hubTodayProviderWhy => 'The plan provider is not here.';

  @override
  String get hubTodayProviderNext => 'Come back when the plan is ready.';

  @override
  String get hubTodayRangeWhat => 'This plan cannot be shown.';

  @override
  String get hubTodayRangeWhy =>
      'A shown plan is 10 to 15 minutes and lists due reviews and the next lesson.';

  @override
  String get hubTodayRangeNext => 'Come back when the plan is ready.';

  @override
  String get hubTodayErrorWhat => 'The plan did not open.';

  @override
  String get hubTodayErrorWhy => 'The lesson list did not come back.';

  @override
  String get hubTodayErrorNext => 'Try again.';

  @override
  String get hubTodayOfflineWhat => 'The phone has no network.';

  @override
  String get hubTodayOfflineWhy => 'This plan is not saved on the phone.';

  @override
  String get hubTodayOfflineNext => 'Connect, then try again.';

  @override
  String get hubLearnPathAndLessons => 'Path and lessons';

  @override
  String get hubLearnLessonRecap => 'Lesson Recap';

  @override
  String get hubLearnWordsAndReview => 'Words and Review';

  @override
  String get hubLearnReviewRush => 'Review Rush';

  @override
  String get hubLearnGrammar => 'Grammar';

  @override
  String get hubLearnPhraseDna => 'Phrase DNA';

  @override
  String get hubLearnListening => 'Listening';

  @override
  String get hubLearnWriting => 'Writing';

  @override
  String get hubLearnToneGym => 'Tone Gym';

  @override
  String get hubLearnCultureShelf => 'Culture shelf';

  @override
  String get hubLearnMagazine => 'Magazine';

  @override
  String get hubLearnHeritage => 'Heritage';

  @override
  String get hubLearnHistory => 'History';

  @override
  String get hubLearnMannerisms => 'Mannerisms';

  @override
  String get hubLearnCulturalHub => 'Cultural Hub';

  @override
  String get hubLearnPassport => 'Passport';

  @override
  String get hubLearnDownloads => 'Downloads';

  @override
  String get hubLearnBack => 'Back to Learn';

  @override
  String get hubLearnNotAvailableWhat => 'This part is not built yet.';

  @override
  String get hubLearnNotAvailableWhy => 'There is nothing to show.';

  @override
  String get hubLearnNotAvailableNext => 'Go back to Learn.';

  @override
  String get hubLearnEmptyTitle => 'Nothing is here yet';

  @override
  String get hubLearnEmptyWhat => 'Learn has no lessons yet.';

  @override
  String get hubLearnEmptyWhy => 'No units came back.';

  @override
  String get hubLearnEmptyNext => 'Open Path and start the first lesson.';

  @override
  String get hubLearnOpenPath => 'Open Path';

  @override
  String get hubLearnPathEmptyTitle => 'This path has no lessons';

  @override
  String get hubLearnPathEmptyWhat => 'No units are on this path.';

  @override
  String get hubLearnPathEmptyWhy => 'No units came back to group.';

  @override
  String get hubLearnPathEmptyNext => 'Try again later.';

  @override
  String get hubLearnGrammarEmptyTitle => 'No pattern yet';

  @override
  String get hubLearnGrammarEmptyWhat => 'Grammar has no pattern yet.';

  @override
  String get hubLearnGrammarEmptyWhy => 'No drill came back.';

  @override
  String get hubLearnGrammarEmptyNext => 'Open Path and start a lesson.';

  @override
  String hubLearnLevel(String level) {
    return 'Level $level';
  }

  @override
  String get hubLearnLevelNotSet => 'Level not set';

  @override
  String get hubLearnErrorWhat => 'Learn did not open.';

  @override
  String get hubLearnErrorWhy => 'The lesson list did not come back.';

  @override
  String get hubLearnErrorNext => 'Try again.';

  @override
  String get hubLearnOfflineWhy => 'This path is not saved on the phone.';

  @override
  String get hubLearnOfflineNext => 'Connect, then try again.';

  @override
  String get hubHSpeakTitle => 'Speak';

  @override
  String get hubHSpeakPolie => 'Polie';

  @override
  String get hubHSpeakScenarios => 'Scenarios';

  @override
  String get hubHSpeakPersonas => 'Personas and Missions';

  @override
  String get hubHSpeakShadowing => 'Shadowing';

  @override
  String get hubHSpeakCodeSwitch => 'Code-Switch and Respect';

  @override
  String get hubHSpeakMissions => 'Speak Missions';

  @override
  String get hubHSpeakCoach => 'Coach insights';

  @override
  String get hubHSpeakBack => 'Back to Speak';

  @override
  String get hubHSpeakNotAvailableTitle => 'Not available yet';

  @override
  String hubHSpeakNotAvailableWhat(String name) {
    return '$name is not available yet.';
  }

  @override
  String get hubHSpeakNotAvailableWhy => 'This screen is not built yet.';

  @override
  String get hubHSpeakNotAvailableNext => 'Go back to Speak.';

  @override
  String get hubHSpeakEmptyWhat => 'Speak has nothing to open yet.';

  @override
  String get hubHSpeakEmptyWhy => 'No speaking place is listed.';

  @override
  String get hubHSpeakEmptyNext => 'Open Polie and hold to talk.';

  @override
  String get hubHSpeakOpenPolie => 'Open Polie';

  @override
  String get hubHSpeakErrorWhat => 'Speak did not open.';

  @override
  String get hubHSpeakErrorWhy => 'The list did not come back.';

  @override
  String get hubHSpeakErrorNext => 'Try again.';

  @override
  String get hubHSpeakOfflineWhy => 'Speak is not saved on the phone.';

  @override
  String get hubHSpeakTalk => 'Talk with Polie.';

  @override
  String get hubHSpeakModeChat => 'Chat';

  @override
  String get hubHSpeakModeExplain => 'Explain';

  @override
  String get hubHSpeakModeCorrect => 'Correct me';

  @override
  String get hubHSpeakModeRoleplay => 'Roleplay';

  @override
  String get hubHSpeakModeStory => 'Story';

  @override
  String get hubHSpeakModeTranslate => 'Translate';

  @override
  String get hubHSpeakOn => 'On';

  @override
  String hubHSpeakModeOn(String mode) {
    return '$mode, on';
  }

  @override
  String get hubHSpeakNoReply => 'No reply yet';

  @override
  String get hubHSpeakPolieEmptyWhat => 'Polie has not spoken.';

  @override
  String get hubHSpeakPolieEmptyWhy => 'You have not held to talk.';

  @override
  String get hubHSpeakPolieEmptyNext => 'Hold to talk when you are ready.';

  @override
  String get hubHSpeakHoldToTalk => 'Hold to talk';

  @override
  String get hubHSpeakPolieErrorWhat => 'The voice screen did not load.';

  @override
  String get hubHSpeakPolieErrorWhy => 'The tutor screen did not come back.';

  @override
  String get hubHSpeakPolieOfflineWhy => 'Polie needs the network to answer.';

  @override
  String get hubHPlayTitle => 'Play';

  @override
  String get hubHPlaySubtitle => 'Games sit on skill shelves.';

  @override
  String get hubHPlayShelfTone => 'Tone & Sound';

  @override
  String get hubHPlayShelfWords => 'Words';

  @override
  String get hubHPlayShelfGrammar => 'Grammar';

  @override
  String get hubHPlayShelfSpeaking => 'Speaking';

  @override
  String get hubHPlayShelfCulture => 'Culture';

  @override
  String get hubHPlayShelfTraditional => 'Traditional';

  @override
  String get hubHPlayShelfMultiplayer => 'Multiplayer';

  @override
  String get hubHPlayToneForge => 'Tone Forge';

  @override
  String get hubHPlayGameGames => 'Games';

  @override
  String get hubHPlayGameChallengeFriend => 'Challenge Friend';

  @override
  String get hubHPlayGameFlashcardFocus => 'Flashcard Focus';

  @override
  String get hubHPlayGameApiLanguages => 'Games API Languages';

  @override
  String get hubHPlayGameEnhancedCatalog => 'Games Enhanced Catalog';

  @override
  String get hubHPlayGameMatchingPairs => 'Matching Pairs';

  @override
  String get hubHPlayBack => 'Back to Play';

  @override
  String get hubHPlayNotAvailableTitle => 'Not available yet';

  @override
  String hubHPlayNotAvailableWhat(String name) {
    return '$name is not available yet.';
  }

  @override
  String get hubHPlayNotAvailableWhy => 'This screen is not built yet.';

  @override
  String get hubHPlayNotAvailableNext => 'Go back to Play.';

  @override
  String get hubHPlayEmptyWhat => 'The shelves have no games.';

  @override
  String get hubHPlayEmptyWhy => 'No game came back.';

  @override
  String get hubHPlayEmptyNext => 'Try again.';

  @override
  String get hubHPlayErrorWhat => 'The game list did not open.';

  @override
  String get hubHPlayErrorWhy => 'The list did not come back.';

  @override
  String get hubHPlayErrorNext => 'Try again.';

  @override
  String get hubHPlayOfflineWhy => 'These games are not saved on the phone.';

  @override
  String get hubHPlayShelfEmptyWhat => 'This shelf has no game.';

  @override
  String get hubHPlayShelfEmptyWhy => 'No game is listed on this shelf.';

  @override
  String get hubHPlayShelfEmptyNext => 'Open the Arcade.';

  @override
  String get hubHPlayOpenArcade => 'Open the Arcade';

  @override
  String get hubHVillageTitle => 'Village';

  @override
  String get hubHVillageMap => 'Village map';

  @override
  String get hubHVillageCircles => 'Circles';

  @override
  String get hubHVillageSquare => 'Square';

  @override
  String get hubHVillageChats => 'Chats';

  @override
  String get hubHVillageStatus => 'Status';

  @override
  String get hubHVillageClips => 'Clips';

  @override
  String get hubHVillageRadio => 'Radio';

  @override
  String get hubHVillageSchool => 'School';

  @override
  String get hubHVillageElderHut => 'Elder Hut';

  @override
  String get hubHVillageCorrections => 'Corrections';

  @override
  String get hubHVillageCreate => 'Create';

  @override
  String get hubHVillageVerify => 'Verify';

  @override
  String get hubHVillageBack => 'Back to Village';

  @override
  String get hubHVillageLocked => 'Locked';

  @override
  String get hubHVillagePreview => 'Preview';

  @override
  String get hubHVillageOpenAnyway => 'Open anyway';

  @override
  String get hubHVillageGuardian => 'A guardian must open this.';

  @override
  String get hubHVillageUnlocksA2 => 'Unlocks at A2.';

  @override
  String get hubHVillageUnlocksB1 => 'Unlocks at B1.';

  @override
  String hubHVillageLockedSemantics(String name, String line) {
    return '$name, Locked. $line';
  }

  @override
  String get hubHVillageNotAvailableTitle => 'Not available yet';

  @override
  String hubHVillageNotAvailableWhat(String name) {
    return '$name is not available yet.';
  }

  @override
  String get hubHVillageNotAvailableWhy => 'This screen is not built yet.';

  @override
  String get hubHVillageNotAvailableNext => 'Go back to Village.';

  @override
  String get hubHVillageEmptyWhat => 'No places yet.';

  @override
  String get hubHVillageEmptyWhy => 'The place list is empty.';

  @override
  String get hubHVillageEmptyNext => 'Try again.';

  @override
  String get hubHVillageErrorWhat => 'Village did not open.';

  @override
  String get hubHVillageErrorWhy => 'The place list did not come back.';

  @override
  String get hubHVillageErrorNext => 'Try again.';

  @override
  String get hubHVillageOfflineWhy => 'Village is not saved on the phone.';

  @override
  String get hubHMeTitle => 'Me';

  @override
  String get hubHMeProfile => 'Profile and avatar';

  @override
  String get hubHMeProgress => 'Progress';

  @override
  String get hubHMeAchievements => 'Achievements';

  @override
  String get hubHMeLeagues => 'Leagues';

  @override
  String get hubHMeFamily => 'Family';

  @override
  String get hubHMePlus => 'Plus';

  @override
  String get hubHMeSettings => 'Settings';

  @override
  String get hubHMeAbout => 'About';

  @override
  String get hubHMeBack => 'Back to Me';

  @override
  String get hubHMeLeave => 'Back';

  @override
  String get hubHMeNotAvailableTitle => 'Not available yet';

  @override
  String hubHMeNotAvailableWhat(String name) {
    return '$name is not available yet.';
  }

  @override
  String get hubHMeNotAvailableWhy => 'This screen is not built yet.';

  @override
  String get hubHMeNotAvailableNext => 'Go back to Me.';

  @override
  String get hubHMeEmptyWhat => 'Me has nothing to open yet.';

  @override
  String get hubHMeEmptyWhy => 'No profile is saved.';

  @override
  String get hubHMeEmptyNext => 'Open Profile and avatar.';

  @override
  String get hubHMeOpenProfile => 'Open Profile';

  @override
  String get hubHMeErrorWhat => 'Me did not open.';

  @override
  String get hubHMeErrorWhy => 'The list did not come back.';

  @override
  String get hubHMeErrorNext => 'Try again.';

  @override
  String get hubHMeOfflineWhy => 'Me is not saved on the phone.';

  @override
  String get hubHMeNoName => 'No name is saved.';

  @override
  String get hubHMeNoAvatar => 'No avatar is saved.';

  @override
  String get hubHMeAvatar => 'Avatar';

  @override
  String get hubHMeProfileEmptyWhat => 'No profile is saved on this phone.';

  @override
  String get hubHMeProfileEmptyWhy => 'A name and avatar have not been saved.';

  @override
  String get hubHMeProfileEmptyNext => 'Go back to Me.';

  @override
  String get lensBridge => 'Conversation Bridge';

  @override
  String get lensPermissionWhat => 'The camera is blocked.';

  @override
  String get lensPermissionWhy =>
      'LingAfriq does not have permission to use the camera.';

  @override
  String get lensPermissionNext => 'Open Settings and allow the camera.';

  @override
  String get lensOfflineTranslateWhy =>
      'Live Translate needs the network to listen and translate.';

  @override
  String get lensRecognizerMissingWhat =>
      'Point & Say cannot name this offline.';

  @override
  String get lensRecognizerMissingWhy =>
      'The on-device recognizer is not on this phone.';

  @override
  String get lensRecognizerMissingNext =>
      'Connect, then open Point & Say again. This phone has no on-device recognizer.';

  @override
  String get lensNoWordWhat => 'No word is open.';

  @override
  String get lensNoWordWhy => 'Point & Say has not named a word.';

  @override
  String get lensNoWordNext =>
      'Point at one thing, then open Living Dictionary.';

  @override
  String get practiceGamePlayingLabel => 'Practice game';

  @override
  String get practiceGameSaveFailedWhat => 'This round was not saved.';

  @override
  String get practiceGameSaveFailedWhy =>
      'The learner record did not reach the outbox.';

  @override
  String get practiceGameSaveFailedNext =>
      'Try again. This round is not marked saved.';

  @override
  String get practiceGameRetry => 'Try again';

  @override
  String get practiceGameSaved => 'Saved to your learner record.';

  @override
  String get practiceGameUnavailable => 'Unavailable';

  @override
  String get directoryTitle => 'All features';

  @override
  String get directoryOpenSemantics => 'Open all features';

  @override
  String get directorySearchLabel => 'Search features';

  @override
  String get directoryLocked => 'Locked';

  @override
  String directoryUnlocksAt(String stage) {
    return 'Unlocks at $stage.';
  }

  @override
  String get directoryPreview => 'Preview';

  @override
  String directoryOpenFeature(String feature) {
    return 'Open $feature';
  }

  @override
  String directoryLockedSemantics(
    String feature,
    String stage,
    String preview,
  ) {
    return '$feature, Locked. Unlocks at $stage. $preview';
  }

  @override
  String get directoryEmptyTitle => 'No match';

  @override
  String directoryEmptyWhat(String query) {
    return 'Nothing matches $query.';
  }

  @override
  String get directoryEmptyWhy => 'That name is not in the directory.';

  @override
  String get directoryEmptyNext => 'Try another name.';

  @override
  String get directoryEmptyAction => 'Clear search';

  @override
  String get directoryBack => 'Back to Me';

  @override
  String get revRvMeHandleTitle => 'Global handle';

  @override
  String get revRvMeHandleEmptyWhat => 'No handle is saved.';

  @override
  String get revRvMeHandleEmptyWhy =>
      'Friends cannot find you by a handle yet.';

  @override
  String get revRvMeHandleEmptyNext => 'Choose a handle.';

  @override
  String get revRvMeHandleChoose => 'Choose a handle';

  @override
  String get revRvMeHandleErrorWhat => 'The handle did not open.';

  @override
  String get revRvMeHandleErrorWhy => 'The saved handle did not come back.';

  @override
  String get revRvMeHandleErrorNext => 'Try again.';

  @override
  String get revRvMeHandleOfflineWhy => 'The handle is not saved on the phone.';

  @override
  String get revRvMeHandleCurrent => 'Current handle';

  @override
  String get revRvMeHandleField => 'Handle';

  @override
  String get revRvMeHandleHint => 'Type the handle you want.';

  @override
  String get revRvMeHandleServer =>
      'The server checks that this handle is unique and not profane.';

  @override
  String get revRvMeHandleSave => 'Save handle';

  @override
  String get revRvMeHandleSaved => 'Handle saved.';

  @override
  String get revRvMeHandleNeeded => 'Enter a handle before saving.';

  @override
  String get revRvMeHandleRejected => 'The server rejected this handle.';

  @override
  String get revRvMeHandleCheckWhat => 'The handle was not saved.';

  @override
  String get revRvMeHandleCheckWhy =>
      'Uniqueness and profanity could not be checked.';

  @override
  String get revRvMeHandleCheckNext => 'Try again. Nothing was saved.';

  @override
  String get revRvMeHandleSaveWhat => 'The handle was not saved.';

  @override
  String get revRvMeHandleSaveWhy => 'The server did not keep this handle.';

  @override
  String get revRvMeHandleSaveNext => 'Try again. Nothing was saved.';

  @override
  String get revRvMeAboutEmptyWhat => 'No story is saved.';

  @override
  String get revRvMeAboutEmptyWhy => 'About has nothing to show.';

  @override
  String get revRvMeAboutEmptyNext => 'Go back to Me.';

  @override
  String get revRvMeAboutErrorWhat => 'About did not open.';

  @override
  String get revRvMeAboutErrorWhy => 'The story did not come back.';

  @override
  String get revRvMeAboutErrorNext => 'Try again.';

  @override
  String get revRvMeAboutOfflineWhy => 'About is not saved on the phone.';

  @override
  String get revRvTodayChallengesEmptyWhat => 'No challenges are saved.';

  @override
  String get revRvTodayChallengesEmptyWhy => 'Today has no challenge list yet.';

  @override
  String get revRvTodayChallengesEmptyNext => 'Go back to Today.';

  @override
  String get revRvTodayChallengesErrorWhat => 'Challenges did not open.';

  @override
  String get revRvTodayChallengesErrorWhy =>
      'The challenge list did not come back.';

  @override
  String get revRvTodayChallengesErrorNext => 'Try again.';

  @override
  String get revRvTodayChallengesOfflineWhy =>
      'Challenges are not saved on the phone.';

  @override
  String revRvTodayChallengesProgress(int current, int target) {
    return '$current of $target';
  }

  @override
  String get revRvLearnReviewDashboard => 'Review dashboard';

  @override
  String get revRvLearnReviewEmptyWhat => 'No review is saved.';

  @override
  String get revRvLearnReviewEmptyWhy => 'There is no review to show.';

  @override
  String get revRvLearnReviewEmptyNext => 'Open Path and start a lesson.';

  @override
  String get revRvLearnReviewFailWhat => 'The review did not open.';

  @override
  String get revRvLearnReviewFailWhy => 'The review list did not come back.';

  @override
  String get revRvLearnReviewFailNext => 'Try again.';

  @override
  String get revRvLearnReviewOfflineWhy =>
      'This review is not saved on the phone.';

  @override
  String get revRvLearnVocabDashboard => 'Vocabulary dashboard';

  @override
  String get revRvLearnVocabEmptyWhat => 'No saved word yet.';

  @override
  String get revRvLearnVocabEmptyWhy => 'Words you save show up here.';

  @override
  String get revRvLearnVocabEmptyNext =>
      'Long-press a target-language word and save it.';

  @override
  String get revRvLearnVocabFailWhat => 'The word list did not open.';

  @override
  String get revRvLearnVocabFailWhy => 'The saved words did not come back.';

  @override
  String get revRvLearnVocabFailNext => 'Try again.';

  @override
  String get revRvLearnVocabOfflineWhy =>
      'These words are not saved on the phone.';

  @override
  String get revRvLearnRecapEmptyTitle => 'No recap yet';

  @override
  String get revRvLearnRecapEmptyWhat => 'This lesson has no recap.';

  @override
  String get revRvLearnRecapEmptyWhy => 'The lesson has not been finished.';

  @override
  String get revRvLearnRecapEmptyNext => 'Open Path and start a lesson.';

  @override
  String get revRvLearnRecapFailWhat => 'The recap did not open.';

  @override
  String get revRvLearnRecapFailWhy => 'The lesson recap did not come back.';

  @override
  String get revRvLearnRecapFailNext => 'Try again.';

  @override
  String get revRvLearnRecapOfflineWhy =>
      'This recap is not saved on the phone.';

  @override
  String get revRvLearnRecapWords => 'Words from this lesson';

  @override
  String get revRvLearnDownloadsEmptyTitle => 'Nothing is saved';

  @override
  String get revRvLearnDownloadsEmptyWhat => 'Nothing is saved on the phone.';

  @override
  String get revRvLearnDownloadsEmptyWhy => 'No lesson pack is on this phone.';

  @override
  String get revRvLearnDownloadsEmptyNext =>
      'Open Path and choose a lesson to save.';

  @override
  String get revRvLearnDownloadsFailWhat => 'The download did not finish.';

  @override
  String get revRvLearnDownloadsFailWhy => 'The lesson pack did not come back.';

  @override
  String get revRvLearnDownloadsFailNext => 'Try again.';

  @override
  String get revRvLearnDownloadsStorageUnknown => 'Storage use is unknown.';

  @override
  String revRvLearnDownloadsStorage(String size) {
    return 'Storage use: $size';
  }

  @override
  String get revRvLearnDownloadsInProgress => 'Download in progress.';

  @override
  String get revRvShadowEmptyWhat => 'No clip is ready.';

  @override
  String get revRvShadowEmptyWhy => 'Shadowing has nothing to play.';

  @override
  String get revRvShadowEmptyNext => 'Go back to Speak.';

  @override
  String get revRvShadowNoAttemptWhat => 'No attempt yet.';

  @override
  String get revRvShadowNoAttemptWhy => 'You have not spoken this clip.';

  @override
  String get revRvShadowNoAttemptNext => 'Record when you are ready.';

  @override
  String get revRvShadowRecord => 'Record';

  @override
  String get revRvShadowErrorWhat => 'Shadowing did not open.';

  @override
  String get revRvShadowErrorWhy => 'The clip did not come back.';

  @override
  String get revRvShadowScoreErrorWhat => 'The attempt was not scored.';

  @override
  String get revRvShadowScoreErrorWhy =>
      'Nothing from that attempt is still on screen.';

  @override
  String get revRvShadowErrorNext => 'Try again.';

  @override
  String get revRvShadowPractice =>
      'Pronunciation scoring is unavailable. You can keep practising without a ranked score.';

  @override
  String get revRvShadowUnsure =>
      'We could not score this clearly. No score is shown.';

  @override
  String get revRvShadowScoreLabel => 'Score';

  @override
  String revRvShadowScoreValue(int percent) {
    return '$percent%';
  }

  @override
  String get revRvShadowOfflineWhy => 'Shadowing is not saved on the phone.';

  @override
  String get revRvAudioFollowing => 'Following';

  @override
  String get revRvAudioFollowers => 'Followers';

  @override
  String get revRvAudioScheduled => 'Scheduled sessions';

  @override
  String get revRvAudioSpeak => 'Speak';

  @override
  String get revRvAudioHost => 'Host';

  @override
  String get revRvAudioBack => 'Back to Radio';

  @override
  String get revRvAudioFollowingEmptyWhat => 'No one is on this list.';

  @override
  String get revRvAudioFollowingEmptyWhy => 'There is no one to show.';

  @override
  String get revRvAudioFollowingEmptyNext => 'Go back to Radio.';

  @override
  String get revRvAudioFollowingFailWhat => 'The list did not open.';

  @override
  String get revRvAudioFollowingFailWhy => 'The list did not come back.';

  @override
  String get revRvAudioFollowingFailNext => 'Try again.';

  @override
  String get revRvAudioFollowingOfflineWhy =>
      'This list is not saved on the phone.';

  @override
  String get revRvAudioScheduledEmptyWhat => 'No session is scheduled.';

  @override
  String get revRvAudioScheduledEmptyWhy => 'There is no session to show.';

  @override
  String get revRvAudioScheduledEmptyNext => 'Go back to Radio.';

  @override
  String get revRvAudioScheduledFailWhat => 'The sessions did not open.';

  @override
  String get revRvAudioScheduledFailWhy =>
      'The session list did not come back.';

  @override
  String get revRvAudioScheduledFailNext => 'Try again.';

  @override
  String get revRvAudioScheduledOfflineWhy =>
      'These sessions are not saved on the phone.';

  @override
  String revRvAudioHostedBy(String name) {
    return 'Hosted by $name';
  }

  @override
  String revRvAudioSessionSemantics(String name) {
    return 'Scheduled session: $name.';
  }

  @override
  String revRvAudioSessionWhen(String date, String time) {
    return '$date $time';
  }

  @override
  String get hubHSpeakRoleplaySummary => 'Scenario summary';

  @override
  String get hubHSpeakRoleplayProgress => 'Roleplay progress';

  @override
  String get revRvSpeakCoachEmptyWhat => 'No conversation is saved.';

  @override
  String get revRvSpeakCoachEmptyWhy =>
      'There is no conversation story to show.';

  @override
  String get revRvSpeakCoachEmptyNext => 'Go back to Speak.';

  @override
  String get revRvSpeakCoachErrorWhat => 'Coach insights did not open.';

  @override
  String get revRvSpeakCoachErrorWhy =>
      'The conversation story did not come back.';

  @override
  String get revRvSpeakCoachErrorNext => 'Try again.';

  @override
  String get revRvSpeakCoachOfflineWhy =>
      'Coach insights are not saved on the phone.';

  @override
  String get revRvSpeakSummaryEmptyWhat => 'No scenario summary is ready.';

  @override
  String get revRvSpeakSummaryEmptyWhy => 'No completed scenario is saved.';

  @override
  String get revRvSpeakSummaryEmptyNext => 'Go back to Speak.';

  @override
  String get revRvSpeakSummaryErrorWhat => 'The scenario summary did not open.';

  @override
  String get revRvSpeakSummaryErrorWhy =>
      'Nothing from that scenario is still on screen.';

  @override
  String get revRvSpeakSummaryErrorNext => 'Try again.';

  @override
  String get revRvSpeakSummaryOfflineWhy =>
      'This summary is not saved on the phone.';

  @override
  String get revRvSpeakProgressEmptyWhat => 'No scenarios are listed.';

  @override
  String get revRvSpeakProgressEmptyWhy => 'No completed scenario is saved.';

  @override
  String get revRvSpeakProgressEmptyNext => 'Go back to Speak.';

  @override
  String get revRvSpeakProgressErrorWhat => 'Roleplay progress did not open.';

  @override
  String get revRvSpeakProgressErrorWhy =>
      'The scenario list did not come back.';

  @override
  String get revRvSpeakProgressErrorNext => 'Try again.';

  @override
  String get revRvSpeakProgressOfflineWhy =>
      'Roleplay progress is not saved on the phone.';

  @override
  String get revRvSpeakPronunciation => 'Pronunciation';

  @override
  String get revRvSpeakTone => 'Tone';

  @override
  String revRvSpeakScoreValue(int percent) {
    return '$percent%';
  }

  @override
  String get revRvSpeakUnsure =>
      'We could not score this clearly. No score is shown.';

  @override
  String get revRvSpeakPractice =>
      'Pronunciation scoring is unavailable. You can keep practising without a ranked score.';

  @override
  String get revRvSpeakTopics => 'Topics';

  @override
  String get revRvSpeakVocabulary => 'Words from this scenario';

  @override
  String get revRvSpeakGrammar => 'Grammar from this scenario';

  @override
  String get revRvSpeakCorrections => 'Corrections';

  @override
  String get revRvSpeakRefresh => 'Refresh';

  @override
  String revRvSpeakSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String revRvSpeakMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String revRvSpeakWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String revRvSpeakTurnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns',
      one: '1 turn',
    );
    return '$_temp0';
  }

  @override
  String revRvSpeakCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Completed $count times',
      one: 'Completed 1 time',
    );
    return '$_temp0';
  }

  @override
  String revRvSpeakSceneSemantics(String name) {
    return 'Scenario: $name.';
  }
}
