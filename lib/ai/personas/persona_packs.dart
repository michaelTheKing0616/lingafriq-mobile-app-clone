// P11-015 — Persona collection packs (mirrors node-backend packs.ts).

import 'historical_persona_registry.dart';

enum PersonaDossierStatus { authored, planned }

enum PersonaPackId {
  queensOfAfrica,
  scholarsOfTimbuktu,
  independenceGeneration,
  writersAndThinkers,
}

class PersonaPackFigure {
  final String personaId;
  final String displayName;
  final List<String> languageCodes;
  final PersonaDossierStatus dossierStatus;

  const PersonaPackFigure({
    required this.personaId,
    required this.displayName,
    required this.languageCodes,
    required this.dossierStatus,
  });
}

class PersonaPack {
  final PersonaPackId packId;
  final String title;
  final String copyKey;
  final List<PersonaPackFigure> figures;

  const PersonaPack({
    required this.packId,
    required this.title,
    required this.copyKey,
    required this.figures,
  });
}

enum FigureRenderState { available, comingSoon }

class PersonaPackCatalog {
  PersonaPackCatalog._();

  static const Set<String> _authoredDossierIds = {
    'yaa_asantewaa',
    'nkrumah_kwame',
    'shaka_zulu',
    'ahmed_baba',
    'thomas_mofolo',
  };

  static const List<PersonaPack> all = [
    PersonaPack(
      packId: PersonaPackId.queensOfAfrica,
      title: 'Queens of Africa',
      copyKey: 'persona.pack.queens',
      figures: [
        PersonaPackFigure(
          personaId: 'yaa_asantewaa',
          displayName: 'Yaa Asantewaa',
          languageCodes: ['tw', 'en'],
          dossierStatus: PersonaDossierStatus.authored,
        ),
        PersonaPackFigure(
          personaId: 'nzinga_queen',
          displayName: 'Queen Nzinga',
          languageCodes: ['pt', 'kg'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
        PersonaPackFigure(
          personaId: 'amina_zazzau',
          displayName: 'Queen Amina of Zazzau',
          languageCodes: ['ha', 'ar'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
        PersonaPackFigure(
          personaId: 'moremi_ajasoro',
          displayName: 'Moremi Ajasoro',
          languageCodes: ['yo', 'en'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
      ],
    ),
    PersonaPack(
      packId: PersonaPackId.scholarsOfTimbuktu,
      title: 'Scholars of Timbuktu',
      copyKey: 'persona.pack.timbuktu',
      figures: [
        PersonaPackFigure(
          personaId: 'ahmed_baba',
          displayName: 'Ahmed Baba',
          languageCodes: ['ar', 'en'],
          dossierStatus: PersonaDossierStatus.authored,
        ),
        PersonaPackFigure(
          personaId: 'mansa_musa',
          displayName: 'Mansa Musa',
          languageCodes: ['ar', 'bm'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
        PersonaPackFigure(
          personaId: 'dan_fodio_usman',
          displayName: 'Usman dan Fodio',
          languageCodes: ['ha', 'ar'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
      ],
    ),
    PersonaPack(
      packId: PersonaPackId.independenceGeneration,
      title: 'Independence Generation',
      copyKey: 'persona.pack.independence',
      figures: [
        PersonaPackFigure(
          personaId: 'nkrumah_kwame',
          displayName: 'Kwame Nkrumah',
          languageCodes: ['en', 'nzi'],
          dossierStatus: PersonaDossierStatus.authored,
        ),
        PersonaPackFigure(
          personaId: 'lumumba_patrice',
          displayName: 'Patrice Lumumba',
          languageCodes: ['fr', 'ln'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
        PersonaPackFigure(
          personaId: 'nyerere_julius',
          displayName: 'Julius Nyerere',
          languageCodes: ['sw', 'en'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
        PersonaPackFigure(
          personaId: 'sankara_thomas',
          displayName: 'Thomas Sankara',
          languageCodes: ['fr', 'mos'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
      ],
    ),
    PersonaPack(
      packId: PersonaPackId.writersAndThinkers,
      title: 'Writers & Thinkers',
      copyKey: 'persona.pack.writers',
      figures: [
        PersonaPackFigure(
          personaId: 'thomas_mofolo',
          displayName: 'Thomas Mofolo',
          languageCodes: ['st', 'en'],
          dossierStatus: PersonaDossierStatus.authored,
        ),
        PersonaPackFigure(
          personaId: 'diop_cheikh_anta',
          displayName: 'Cheikh Anta Diop',
          languageCodes: ['wo', 'fr'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
        PersonaPackFigure(
          personaId: 'achebe_chinua',
          displayName: 'Chinua Achebe',
          languageCodes: ['en', 'ig'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
        PersonaPackFigure(
          personaId: 'senghor_leopold',
          displayName: 'Léopold Sédar Senghor',
          languageCodes: ['fr', 'wo'],
          dossierStatus: PersonaDossierStatus.planned,
        ),
      ],
    ),
  ];

  static FigureRenderState renderState(PersonaPackFigure figure) =>
      figure.dossierStatus == PersonaDossierStatus.authored
          ? FigureRenderState.available
          : FigureRenderState.comingSoon;

  static bool canStart(PersonaPackFigure figure) {
    if (figure.dossierStatus != PersonaDossierStatus.authored) return false;
    return _authoredDossierIds.contains(figure.personaId) &&
        DossierBackedPersonaRoster.isV1DossierBacked(figure.personaId);
  }

  static PersonaPackFigure? findFigure(String personaId) {
    final pid = personaId.trim().toLowerCase();
    for (final pack in all) {
      for (final figure in pack.figures) {
        if (figure.personaId == pid) return figure;
      }
    }
    return null;
  }

  static PersonaPack? packContaining(String personaId) {
    final pid = personaId.trim().toLowerCase();
    for (final pack in all) {
      if (pack.figures.any((f) => f.personaId == pid)) return pack;
    }
    return null;
  }
}
