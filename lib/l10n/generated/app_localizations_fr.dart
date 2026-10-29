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
  String get logout => 'Deconnexion';

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
  String get lessonComplete => 'Lecon Terminee!';

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
    return 'Premium $premium/mois\nFamille $family/mois\nÀ vie $lifetime, paiement unique';
  }

  @override
  String paywallChargedTo(String store) {
    return 'Débité sur votre compte $store.';
  }

  @override
  String get paywallRenewsAuto =>
      'Les forfaits mensuels se renouvellent automatiquement au même prix jusqu\'à résiliation. L\'offre à vie ne se renouvelle pas.';

  @override
  String paywallRenewsOn(String date) {
    return 'Votre forfait se renouvelle le $date.';
  }

  @override
  String paywallTrialOffered(int days, String price) {
    return 'Essai gratuit de $days jours, puis $price/mois sauf résiliation au moins 24 h avant la fin.';
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
}
