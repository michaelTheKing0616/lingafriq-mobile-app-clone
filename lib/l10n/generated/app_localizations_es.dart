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
  String chatPeerTyping(String name) {
    return '$name is typing…';
  }

  @override
  String get polieTranslationSourceLabel => 'From';

  @override
  String get polieTranslationTargetLabel => 'To';
}
