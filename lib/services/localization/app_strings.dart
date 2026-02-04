/// App string translations for dynamic app language.
/// When user sets app language to Yorùbá (or others), UI labels use these.
/// Keys are English; values are per-language. Add more keys and languages as needed.
import 'package:lingafriq/services/localization/dynamic_localization_service.dart';

class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'Dashboard': {'en': 'Dashboard', 'yo': 'Aṣayan Aṣayan', 'fr': 'Tableau de bord', 'sw': 'Dashibodi'},
    'Curriculum': {'en': 'Curriculum', 'yo': 'Ẹ̀kọ́', 'fr': 'Programme', 'sw': 'Mtaala'},
    'Tutor Mode': {'en': 'Tutor Mode', 'yo': 'Ọnà Ẹ̀kọ́', 'fr': 'Mode tuteur', 'sw': 'Hali ya Mwalimu'},
    'AI Assistant (Polie)': {'en': 'AI Assistant (Polie)', 'yo': 'Alagbata Ẹ̀rọ (Polie)', 'fr': 'Assistant IA (Polie)', 'sw': 'Msaidizi wa AI (Polie)'},
    'Games': {'en': 'Games', 'yo': 'Ere', 'fr': 'Jeux', 'sw': 'Michezo'},
    'Cultural Magazine': {'en': 'Cultural Magazine', 'yo': 'Ìwé Ìròyìn Aṣa', 'fr': 'Magazine culturel', 'sw': 'Gazeti ya Utamaduni'},
    'Import Media': {'en': 'Import Media', 'yo': 'Gba Awọn Ohun Amóhùnmáwòrán', 'fr': 'Importer média', 'sw': 'Ingiza Vyombo'},
    'Create Content': {'en': 'Create Content', 'yo': 'Ṣẹda Akoonu', 'fr': 'Créer du contenu', 'sw': 'Unda Maudhui'},
    'Global Chat': {'en': 'Global Chat', 'yo': 'Ọ̀rọ̀ Agbaye', 'fr': 'Chat global', 'sw': 'Mazungumzo ya Ulimwengu'},
    'Private Chat': {'en': 'Private Chat', 'yo': 'Ọ̀rọ̀ Ikọ̀kọ̀', 'fr': 'Chat privé', 'sw': 'Mazungumzo ya Kibinafsi'},
    'Live Classroom': {'en': 'Live Classroom', 'yo': 'Yàrá Ẹ̀kọ́ Lailẹgbẹ', 'fr': 'Classe en direct', 'sw': 'Darasa la Moja kwa Moja'},
    'Language Villages': {'en': 'Language Villages', 'yo': 'Ilú Èdè', 'fr': 'Villages de langues', 'sw': 'Vijiji vya Lugha'},
    'Practice Rooms': {'en': 'Practice Rooms', 'yo': 'Yàrá Idaraya', 'fr': 'Salles de pratique', 'sw': 'Vyumba vya Mazoezi'},
    'My Tribes': {'en': 'My Tribes', 'yo': 'Àwọn Ẹgbẹ́ Mi', 'fr': 'Mes tribus', 'sw': 'Koo Zangu'},
    'Badges': {'en': 'Badges', 'yo': 'Àwọn Àmì Ẹyẹ', 'fr': 'Badges', 'sw': 'Begi'},
    'Leaderboards': {'en': 'Leaderboards', 'yo': 'Ìwé Ìgbórí', 'fr': 'Classements', 'sw': 'Ubao wa Viongozi'},
    'Profile': {'en': 'Profile', 'yo': 'Àkọlé', 'fr': 'Profil', 'sw': 'Wasifu'},
    'Settings': {'en': 'Settings', 'yo': 'Àwọn Ìṣètò', 'fr': 'Paramètres', 'sw': 'Mipangilio'},
    'Dark Mode': {'en': 'Dark Mode', 'yo': 'Àkókò Dúdú', 'fr': 'Mode sombre', 'sw': 'Hali ya Giza'},
    'Logout': {'en': 'Logout', 'yo': 'Jade', 'fr': 'Déconnexion', 'sw': 'Ondoka'},
    'Main': {'en': 'Main', 'yo': 'Akọ', 'fr': 'Principal', 'sw': 'Kuu'},
    'Learning': {'en': 'Learning', 'yo': 'Ẹ̀kọ́', 'fr': 'Apprentissage', 'sw': 'Kusoma'},
    'Community': {'en': 'Community', 'yo': 'Agbègbè', 'fr': 'Communauté', 'sw': 'Jumuiya'},
    'Achievements': {'en': 'Achievements', 'yo': 'Àwọn Èrè', 'fr': 'Réalisations', 'sw': 'Mafanikio'},
    'Account': {'en': 'Account', 'yo': 'Àkọọ́lẹ̀', 'fr': 'Compte', 'sw': 'Akaunti'},
    'Home': {'en': 'Home', 'yo': 'Ilé', 'fr': 'Accueil', 'sw': 'Nyumbani'},
    'Courses': {'en': 'Courses', 'yo': 'Ẹ̀kọ́', 'fr': 'Cours', 'sw': 'Kozi'},
    'Standings': {'en': 'Standings', 'yo': 'Ìpo', 'fr': 'Classement', 'sw': 'Nafasi'},
    'Menu': {'en': 'Menu', 'yo': 'Àkọọ́lẹ̀', 'fr': 'Menu', 'sw': 'Menyu'},
    'LIVE': {'en': 'LIVE', 'yo': 'Lailẹgbẹ', 'fr': 'EN DIRECT', 'sw': 'MOJA KWA MOJA'},
    'Create Classroom': {'en': 'Create Classroom', 'yo': 'Ṣẹda Yàrá Ẹ̀kọ́', 'fr': 'Créer une classe', 'sw': 'Unda Darasa'},
    'Room Name': {'en': 'Room Name', 'yo': 'Orukọ Yàrá', 'fr': 'Nom de la salle', 'sw': 'Jina la Chumba'},
    'Back': {'en': 'Back', 'yo': 'Padà', 'fr': 'Retour', 'sw': 'Rudi'},
    'Leave': {'en': 'Leave', 'yo': 'Kuro', 'fr': 'Quitter', 'sw': 'Ondoka'},
    'Video': {'en': 'Video', 'yo': 'Fidio', 'fr': 'Vidéo', 'sw': 'Video'},
    'Audio': {'en': 'Audio', 'yo': 'Ohun', 'fr': 'Audio', 'sw': 'Sauti'},
    'Raise': {'en': 'Raise', 'yo': 'Gbe Sọwọ', 'fr': 'Lever la main', 'sw': 'Inua Mkono'},
    'Mute': {'en': 'Mute', 'yo': 'Dakẹ', 'fr': 'Muet', 'sw': 'Zima Sauti'},
    'Teacher': {'en': 'Teacher', 'yo': 'Olùkọ́', 'fr': 'Enseignant', 'sw': 'Mwalimu'},
    'Participants': {'en': 'Participants', 'yo': 'Àwọn Olùkópa', 'fr': 'Participants', 'sw': 'Washiriki'},
    'You': {'en': 'You', 'yo': 'Ìwọ', 'fr': 'Vous', 'sw': 'Wewe'},
    'Close': {'en': 'Close', 'yo': 'Pa', 'fr': 'Fermer', 'sw': 'Funga'},
    'Promote': {'en': 'Promote', 'yo': 'Gbega', 'fr': 'Promouvoir', 'sw': 'Kuza'},
    'Demote': {'en': 'Demote', 'yo': 'Sọ Kale', 'fr': 'Rétrograder', 'sw': 'Shusha'},
    'Biometric Authentication': {'en': 'Biometric Authentication', 'yo': 'Ìjẹ́rìí Ẹ̀rọ Ẹ̀dá', 'fr': 'Authentification biométrique', 'sw': 'Uthibitishaji wa Kibiolojia'},
    'App Language': {'en': 'App Language', 'yo': 'Èdè App', 'fr': 'Langue de l\'app', 'sw': 'Lugha ya Programu'},
    'Select Language': {'en': 'Select Language', 'yo': 'Yan Èdè', 'fr': 'Choisir la langue', 'sw': 'Chagua Lugha'},
  };

  /// Returns the translated string for the current app language. Falls back to English.
  static String tr(String key) {
    final code = DynamicLocalizationService.currentLanguage.code;
    final map = _strings[key];
    if (map == null) return key;
    return map[code] ?? map['en'] ?? key;
  }
}
