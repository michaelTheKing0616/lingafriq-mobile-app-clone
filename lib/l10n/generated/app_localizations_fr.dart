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
}
