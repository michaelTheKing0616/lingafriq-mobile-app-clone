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
  String get gameWordMatchConnectMeaningTitle => 'Connect the Meaning';

  @override
  String get gameWordMatchConnectMeaningSubtitle =>
      'Tap a word to hear its voice, then match it to its anchor.';

  @override
  String get gameWordMatchEnglishLabel => 'English';
}
